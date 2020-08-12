/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_fusion #(parameter NUM_OF_BOARD = 6) (
    // UP interface
    //-------------
    input  wire        clk                            ,
    input  wire        resetn                         ,
    //
    input  wire [31:0] rtc_sec                        ,
    input  wire [31:0] rtc_nsec                       ,
    // TC I/F
    output wire        tc_bram_clk  [0:NUM_OF_BOARD-1],
    output wire        tc_bram_rst  [0:NUM_OF_BOARD-1],
    output reg         tc_bram_en   [0:NUM_OF_BOARD-1],
    output reg  [ 2:0] tc_bram_addr [0:NUM_OF_BOARD-1],
    input  wire [31:0] tc_bram_dout [0:NUM_OF_BOARD-1],
    //
    input  wire        tc_drdy      [0:NUM_OF_BOARD-1],
    // RTD I/F
    output wire        rtd_bram_clk [0:NUM_OF_BOARD-1],
    output wire        rtd_bram_rst [0:NUM_OF_BOARD-1],
    output reg         rtd_bram_en  [0:NUM_OF_BOARD-1],
    output reg  [ 3:0] rtd_bram_addr[0:NUM_OF_BOARD-1],
    input  wire [31:0] rtd_bram_dout[0:NUM_OF_BOARD-1],
    //
    input  wire        rtd_drdy     [0:NUM_OF_BOARD-1],
    // BRAM I/F
    //---------
    output wire        bram_clk                       ,
    output wire        bram_rst                       ,
    output reg         bram_en                        ,
    output reg  [ 3:0] bram_we                        ,
    output reg  [12:0] bram_addr                      ,
    output reg  [31:0] bram_din                       ,
    input  wire [31:0] bram_dout                      ,
    // Interrupt
    output reg         irq
);


    reg [31:0] frame_type = 32'h1234abcd;
    reg [31:0] frame_sequence;

    reg [31:0] ts_sec;
    reg [31:0] ts_nsec;

    reg         fixed_valid;
    reg  [23:0] fixed_data ;
    wire        float_valid;
    wire [31:0] float_data ;

    reg irq_ext;


    //--------------------------------------------------------------------------
    // Start detect
    // All 6 ADC board may not complete synced. The different maybe 2 MCLK. One
    // MCLK is 1/512kHz = 1.95 us, in this case. It's 244 clocks / MCLK. We will
    // wait 1024 clocks until timeout.


    typedef enum {S_RST, S_IDLE, S_WAIT, S_GO} state_t;

    state_t state, next_state;

    reg any_drdy;
    reg [9:0] timeout_cnt;
    wire start, timeout;

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            state <= S_RST;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        any_drdy = 0;
        for (int i = 0; i < NUM_OF_BOARD; i++) begin
            any_drdy = any_drdy | tc_drdy[i];
        end
    end

    always_comb begin
        case(state)
            S_RST  : next_state = S_IDLE;
            S_IDLE : next_state = any_drdy ? S_WAIT : S_IDLE;
            S_WAIT : next_state = timeout ? S_GO : S_WAIT;
            S_GO   : next_state = S_IDLE;
            default: next_state = S_RST;
        endcase
    end

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            timeout_cnt <= 'd0;
        end else if (next_state == S_WAIT) begin
            timeout_cnt <= &timeout_cnt ? timeout_cnt : timeout_cnt + 1;
        end else begin
            timeout_cnt <= 'd0;
        end
    end

    assign timeout = &timeout_cnt;

    assign start = (state == S_GO);


    //--------------------------------------------------------------------------
    // FSM

    localparam FRAME_LENGTH = 124;

    reg [6:0] bram_wr_cnt;

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_wr_cnt <= 'hFF;
        end else if (start) begin
            bram_wr_cnt <= 'd0;
        end else if (bram_wr_cnt <= (FRAME_LENGTH - 1)) begin
            bram_wr_cnt <= bram_wr_cnt + 1;
        end else begin
            bram_wr_cnt <= 'hFF;
        end
    end


    //--------------------------------------------------------------------------
    // Frame header update

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            ts_sec <= 0;
        end else if (start) begin
            ts_sec <= rtc_sec;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            ts_nsec <= 0;
        end else if (start) begin
            ts_nsec <= rtc_nsec;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            frame_sequence <= 'd0;
        end else if (start) begin
            frame_sequence <= frame_sequence + 1;
        end
    end


    //--------------------------------------------------------------------------
    // Read from external module

    generate
        for (genvar i = 0; i < NUM_OF_BOARD; i++) begin

            // At state 8 ~ 55, readout TC data

            logic tc_bram_en_lut[0:127];
            
            initial begin
                for (int j = 0; j < 128; j++) begin
                    tc_bram_en_lut[j] = (i*8+8 <= j && j <=i*8+15);
                end
            end

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    tc_bram_en[i] <= 1'b0;
                end else begin
                    tc_bram_en[i] <= tc_bram_en_lut[bram_wr_cnt];
                end
            end

            logic tc_bram_addr_lut[0:127];

            initial begin
                for (int j = 0; j < 128; j++) begin
                    tc_bram_addr_lut[j] = (j - i*8 - 8);
                end
            end

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    tc_bram_addr[i] <= 'b0;
                end else begin
                    tc_bram_addr[i] <= tc_bram_addr_lut[bram_wr_cnt];
                end
            end

            // As state 56 ~ 115, readout RTC data

            logic rtd_bram_en_lut[0:127];

            initial begin
                for (int j = 0; j < 128; j++) begin
                    rtd_bram_en_lut[j] = (i*10+56 <= j && j <=i*10+65);
                end
            end

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    rtd_bram_en[i] <= 1'b0;
                end else begin
                    rtd_bram_en[i] <= rtd_bram_en_lut[bram_wr_cnt];
                end
            end

            logic rtd_bram_addr_lut[0:127];

            initial begin
                for (int j = 0; j < 128; j++) begin
                    rtd_bram_addr_lut[j] = (j - i*10 - 56);
                end
            end

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    rtd_bram_addr[i] <= 'b0;
                end else begin
                    rtd_bram_addr[i] <=  rtd_bram_addr_lut[bram_wr_cnt];
                end
            end

        end
    endgenerate


    //--------------------------------------------------------------------------
    // Fixed to float convert

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            fixed_valid <= 1'b0;
        end else begin
            fixed_valid <= (9 <= bram_wr_cnt && bram_wr_cnt <= 116);
        end
    end

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            fixed_data <= 'b0;
        end else if (9 <= bram_wr_cnt && bram_wr_cnt <= 56) begin
            fixed_data <= (tc_bram_dout[(bram_wr_cnt-9)/8] - 24'h800000);
        // RTD data to fixed
        end else if (57 <= bram_wr_cnt && bram_wr_cnt <= 66) begin
            fixed_data <= (rtd_bram_dout[0] - 24'h800000);
        end else if (67 <= bram_wr_cnt && bram_wr_cnt <= 76) begin
            fixed_data <= (rtd_bram_dout[1] - 24'h800000);
        end else if (77 <= bram_wr_cnt && bram_wr_cnt <= 86) begin
            fixed_data <= (rtd_bram_dout[2] - 24'h800000);
        end else if (87 <= bram_wr_cnt && bram_wr_cnt <= 96) begin
            fixed_data <= (rtd_bram_dout[3] - 24'h800000);
        end else if (97 <= bram_wr_cnt && bram_wr_cnt <= 106) begin
            fixed_data <= (rtd_bram_dout[4] - 24'h800000);
        end else if (107 <= bram_wr_cnt && bram_wr_cnt <= 116) begin
            fixed_data <= (rtd_bram_dout[5] - 24'h800000);
        end
    end

    //--------------------------------------------------------------------------
    // BRAM Write processes

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_en   <= 1'b0;
        end else begin
            bram_en   <= (bram_wr_cnt <= (FRAME_LENGTH - 1));
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_we   <= 4'h0;
        end else begin
            bram_we   <= (bram_wr_cnt <= (FRAME_LENGTH - 1)) ? 4'hF : 4'h0;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_addr <= 'd0;
        end else begin
            bram_addr <= (bram_wr_cnt <= (FRAME_LENGTH - 1)) ? {bram_wr_cnt, 2'b00} : 13'b0;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_din <= 'd0;
        end else begin
            if (bram_wr_cnt == 'd0) bram_din <= frame_type;
            else if (bram_wr_cnt == 'd1) bram_din <= frame_sequence;
            else if (bram_wr_cnt == 'd2) bram_din <= ts_sec;
            else if (bram_wr_cnt == 'd3) bram_din <= ts_nsec;
            else if (bram_wr_cnt <= 'd15) bram_din <= 'd0; // reserved header space
            // 16 ~ 123
            else if (bram_wr_cnt <= 'd123) bram_din <= float_data;
            else bram_din <= 'd0;
        end
    end


    //--------------------------------------------------------------------------
    // IRQ

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            irq_ext = 1'b0;
        end else begin
            irq_ext = (bram_wr_cnt == 'd99);
        end
    end

    pulse_ext i_pulse_ext (
        .clk     (clk    ),
        .rst     (~resetn),
        .pulse_in(irq_ext),
        .ext_out (irq    )
    );


    //--------------------------------------------------------------------------
    // Net mapping

    generate
        for (genvar i = 0; i < NUM_OF_BOARD; i++) begin
            assign tc_bram_clk[i]  = clk;
            assign tc_bram_rst[i]  = ~resetn;
            assign rtd_bram_clk[i] = clk;
            assign rtd_bram_rst[i] = ~resetn;
        end
    endgenerate

    assign bram_clk = clk;
    assign bram_rst = ~resetn;

    //
    axi_ad7124_fixed2float i_axi_ad7124_fixed2float (
        .aclk                (clk        ),
        .aresetn             (resetn     ),
        .s_axis_a_tvalid     (fixed_valid),
        .s_axis_a_tdata      (fixed_data ),
        .m_axis_result_tvalid(float_valid),
        .m_axis_result_tdata (float_data )
    );

endmodule

`default_nettype wire
