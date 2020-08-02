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
    output reg  [ 2:0] rtd_bram_addr[0:NUM_OF_BOARD-1],
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

    localparam FRAME_LENGTH = 112;

    reg start;

    reg [6:0] state_cnt;

    reg [31:0] frame_type = 32'h1234abcd;
    reg [31:0] frame_sequence;

    reg [31:0] ts_sec;
    reg [31:0] ts_nsec;

    reg         fixed_valid;
    reg  [23:0] fixed_data ;
    wire        float_valid;
    wire [31:0] float_data ;

    reg [31:0] rtc_sec;
    reg [31:0] rtc_nsec;

    reg[8:0] irq_ext;


    //--------------------------------------------------------------------------
    // RTC

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            rtc_sec <= 'd0;
        end else if (rtc_nsec == 10**9 - 8) begin
            rtc_sec <= rtc_sec + 1;
        end
    end

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            rtc_nsec <= 'd0;
        end else begin
            rtc_nsec <= (rtc_nsec >= 10**9 - 8) ? 0 : rtc_nsec + 8;
        end
    end


    //--------------------------------------------------------------------------
    // Start detect

    // TODO: Need a solid logic to handle all 6 board's data
    always_ff @ (posedge clk) begin
        if (~resetn) begin
            start <= 1'b0;
        end else begin
            start <= tc_drdy[0];
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
    // FSM

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            state_cnt <= 'hFF;
        end else if (start) begin
            state_cnt <= 'd0;
        end else if (state_cnt <= (FRAME_LENGTH - 1)) begin
            state_cnt <= state_cnt + 1;
        end else begin
            state_cnt <= 'hFF;
        end
    end


    //--------------------------------------------------------------------------
    // Read from external module

    generate
        for (genvar i = 0; i < NUM_OF_BOARD; i++) begin

            // At state 8 ~ 55, readout TC data

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    tc_bram_en[i] <= 1'b0;
                end else begin
                    tc_bram_en[i] <= (i*8+8 <= state_cnt && state_cnt <=i*8+15);
                end
            end

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    tc_bram_addr[i] <= 'b0;
                end else if (&state_cnt) begin
                    tc_bram_addr[i] <= 'b0;
                end else if (i*8+8 <= state_cnt && state_cnt <=i*8+15) begin
                    tc_bram_addr[i] <= tc_bram_addr[i] + 1;
                end
            end

            // As state 56 ~ 103, readout RTC data

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    rtd_bram_en[i] <= 1'b0;
                end else begin
                    rtd_bram_en[i] <= (i*8+56 <= state_cnt && state_cnt <=i*8+63);
                end
            end

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    rtd_bram_addr[i] <= 'b0;
                end else if (&state_cnt) begin
                    rtd_bram_addr[i] <= 'b0;
                end else if (i*8+56 <= state_cnt && state_cnt <=i*8+63) begin
                    rtd_bram_addr[i] <=  rtd_bram_addr[i] + 1;
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
            fixed_valid <= (9 <= state_cnt && state_cnt <= 104);
        end
    end

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            fixed_data <= 'b0;
        end else if (9 <= state_cnt && state_cnt <= 56) begin
            fixed_data <= (tc_bram_dout[(state_cnt-9)/8] - 24'h800000);
        end else if (57 <= state_cnt && state_cnt <= 104) begin
            fixed_data <= (rtd_bram_dout[(state_cnt-57)/8] - 24'h800000);
        end
    end

    //--------------------------------------------------------------------------
    // BRAM Write processes

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_en   <= 1'b0;
        end else begin
            bram_en   <= (state_cnt <= (FRAME_LENGTH - 1));
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_we   <= 4'h0;
        end else begin
            bram_we   <= (state_cnt <= (FRAME_LENGTH - 1)) ? 4'hF : 4'h0;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_addr <= 'd0;
        end else begin
            bram_addr <= (state_cnt <= (FRAME_LENGTH - 1)) ? {state_cnt, 2'b00} : 13'b0;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_din <= 'd0;
        end else begin
            if (state_cnt == 'd0) bram_din <= frame_type;
            else if (state_cnt == 'd1) bram_din <= frame_sequence;
            else if (state_cnt == 'd2) bram_din <= ts_sec;
            else if (state_cnt == 'd3) bram_din <= ts_nsec;
            else if (state_cnt <= 'd15) bram_din <= 'd0; // reserved header space
            // 16 ~ 111
            else if (state_cnt <= 'd111) bram_din <= float_data;
            else bram_din <= 'd0;
        end
    end


    //--------------------------------------------------------------------------
    // IRQ


    always_ff @ (posedge clk) begin
        if (~resetn) begin
            irq_ext <= 'd0;
        end else begin
            if (state_cnt == 'd99) begin
                irq_ext <= 'd1;
            end else if (|irq_ext) begin
                irq_ext <= irq_ext + 1;
            end else begin
                irq_ext <= 'd0;
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            irq <= 1'b0;
        end else begin
            irq <= |irq_ext;
        end
    end

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
