/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_fusion #(parameter NUM_OF_BOARD = 6) (
    // Clock & Reset
    //--------------
    input  var logic        clk                                        ,
    input  var logic        resetn                                     ,
    // RTC
    //----
    input  var logic [31:0] rtc_sec                                    ,
    input  var logic [31:0] rtc_nsec                                   ,
    // TC I/F
    //-------
    // Data
    output var logic        tc_bram_en               [0:NUM_OF_BOARD-1],
    output var logic [ 2:0] tc_bram_addr             [0:NUM_OF_BOARD-1],
    input  var logic [31:0] tc_bram_dout             [0:NUM_OF_BOARD-1],
    // Sync
    output var logic        tc_sync                  [0:NUM_OF_BOARD-1],
    // Data Handshake
    input  var logic        tc_valid                 [0:NUM_OF_BOARD-1],
    output var logic        tc_ready                 [0:NUM_OF_BOARD-1],
    // RTD I/F
    //========
    output var logic        rtd_bram_en              [0:NUM_OF_BOARD-1],
    output var logic [ 3:0] rtd_bram_addr            [0:NUM_OF_BOARD-1],
    input  var logic [31:0] rtd_bram_dout            [0:NUM_OF_BOARD-1],
    // Measurement
    //============
    input  var logic        measure_start                              ,
    output var logic        measure_ready                              ,
    output var logic        measure_done                               ,
    // Control I/F
    //============
    input  var logic        ctrl_reset                                 ,
    //
    input  var logic        ctrl_measure_immediate                     ,
    input  var logic        ctrl_measure_continuous                    ,
    input  var logic [31:0] ctrl_measure_count                         ,
    output var logic [ 2:0] stat_measure_state                         ,
    //
    input  var logic        ctrl_fifo_read                             ,
    output var logic [31:0] stat_fifo_data                             ,
    output var logic        stat_fifo_empty                            ,
    //
    output var logic        irq
);


    localparam FRAME_LENGTH = 112;


    logic [31:0] ts_sec ;
    logic [31:0] ts_nsec;

    logic [31:0] measure_id;
    logic [31:0] measure_count;

    logic [9:0] mcs_cnt ;
    logic       mcs_done;

    logic all_drdy;

    logic [6:0] get_cnt ;
    logic       get_done;

    logic        fifo_rst ;
    logic [31:0] fifo_din ;
    logic        fifo_wren;
    logic        fifo_full;



    logic irq_ext;

    //--------------------------------------------------------------------------
    // Start detect
    // All 6 ADC board may not complete synced. The different maybe 2 MCLK. One
    // MCLK is 1/512kHz = 1.95 us, in this case. It's 244 clocks / MCLK. We will
    // wait 1024 clocks until timeout.


    typedef enum {
        S_RST , // Under reset
        S_IDLE, // Nothing to do, wait `measure_start`
        S_MCS , // Multi chip sync
        S_CLR , // Clear previous data
        S_WAIT, // Wait data ready
        S_GET , // Read data and build frame
        S_FIN , // Captured one frame
        S_DONE  // Measurement done
    } state_t;

    state_t state, state_next;

    always_ff @ (posedge clk) begin
        if ((~resetn) || ctrl_reset) begin
            state <= S_RST;
        end else begin
            state <= state_next;
        end
    end


    always_comb begin
        case(state)
            S_RST   : state_next = S_IDLE;
            S_IDLE  : state_next = (measure_start || ctrl_measure_immediate || ctrl_measure_continuous) ? S_MCS : S_IDLE;
            S_MCS   : state_next = mcs_done ? S_CLR : S_MCS;
            S_CLR   : state_next = S_WAIT;
            S_WAIT  : state_next = all_drdy ? S_GET : S_WAIT;
            S_GET   : state_next = get_done ? S_FIN : S_GET;
            S_FIN   : state_next = (measure_count >= ctrl_measure_count) ? S_DONE : S_WAIT;
            S_DONE  : state_next = S_IDLE;
            default : state_next = S_RST;
        endcase
    end


    always_ff @ (posedge clk) begin
        stat_measure_state <=
            (state == S_RST ) ? 'd0 :
            (state == S_IDLE) ? 'd1 :
            (state == S_MCS ) ? 'd2 :
            (state == S_CLR ) ? 'd3 :
            (state == S_WAIT) ? 'd4 :
            (state == S_FIN ) ? 'd5 :
            (state == S_DONE) ? 'd6 : 'd0;
    end

    //--------------------------------------------------------------------------
    // Measurement

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            measure_id <= 'd0;
        end else if (state == S_IDLE && (measure_start || ctrl_measure_immediate || ctrl_measure_continuous)) begin
            measure_id <= measure_id + 1;;
        end
    end

    always_ff @ (posedge clk) begin
        if (state_next == S_WAIT || state_next == S_GET) begin
            measure_count <= measure_count;
        end else if (state_next == S_FIN) begin
            measure_count <= measure_count + 1;
        end else begin
            measure_count <= 'd0;
        end
    end

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            measure_done <= 1'b0;
        end else begin
            measure_done <= (state_next == S_DONE);
        end
    end


    always_ff @ (posedge clk) begin
        if (~resetn) begin
            tc_ready <= '{NUM_OF_BOARD{1'b0}};
        end else begin
            tc_ready <= (state_next == S_FIN || state_next == S_CLR) ? '{NUM_OF_BOARD{1'b1}} : '{NUM_OF_BOARD{1'b0}};
        end
    end

    //--------------------------------------------------------------------------
    // MCS

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            mcs_cnt <= 'd0;
        end else if (state_next == S_MCS) begin
            mcs_cnt <= mcs_done ? mcs_cnt : mcs_cnt + 1;
        end else begin
            mcs_cnt <= 'd0;
        end
    end

    assign mcs_done = (&mcs_cnt);

    always_ff @ (posedge clk) begin
        tc_sync <= (state_next == S_MCS) ? '{NUM_OF_BOARD{1'b1}} : '{NUM_OF_BOARD{1'b0}};
    end

    //--------------------------------------------------------------------------
    // WAIT

    always_comb begin
        all_drdy = 1;
        for (int i = 0; i < NUM_OF_BOARD; i++) begin
            all_drdy = all_drdy & tc_valid[i];
        end
    end

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            ts_sec <= 0;
        end else if (state == S_WAIT && all_drdy) begin
            ts_sec <= rtc_sec;
        end
    end

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            ts_nsec <= 0;
        end else if (state == S_WAIT && all_drdy) begin
            ts_nsec <= rtc_nsec;
        end
    end

    //--------------------------------------------------------------------------
    // GET

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            get_cnt <= 'd0;
        end else if (state_next == S_GET) begin
            get_cnt <= get_cnt + 1;
        end else begin
            get_cnt <= 'd0;
        end
    end

    always_comb begin
        get_done <= (get_cnt == FRAME_LENGTH);
    end

    always_ff @ (posedge clk) begin
        fifo_wren <= |get_cnt;
    end

    always_ff @ (posedge clk) begin
        fifo_din <= ('d1 == get_cnt ) ? "DATA" :
            ('d2 == get_cnt ) ? FRAME_LENGTH :
            ('d3 == get_cnt ) ? measure_id :
            ('d4 == get_cnt ) ? measure_count :
            ('d5 == get_cnt ) ? ts_sec :
            ('d6 == get_cnt ) ? ts_nsec :
            ('d7  <= get_cnt && get_cnt <= 'd14) ? tc_bram_dout[0] :
            ('d15 <= get_cnt && get_cnt <= 'd22) ? tc_bram_dout[1] :
            ('d23 <= get_cnt && get_cnt <= 'd30) ? tc_bram_dout[2] :
            ('d31 <= get_cnt && get_cnt <= 'd38) ? tc_bram_dout[3] :
            ('d39 <= get_cnt && get_cnt <= 'd46) ? tc_bram_dout[4] :
            ('d47 <= get_cnt && get_cnt <= 'd54) ? tc_bram_dout[5] :
            ('d55 <= get_cnt && get_cnt <= 'd64) ? rtd_bram_dout[0] :
            ('d65 <= get_cnt && get_cnt <= 'd74) ? rtd_bram_dout[1] :
            ('d75 <= get_cnt && get_cnt <= 'd84) ? rtd_bram_dout[2] :
            ('d85 <= get_cnt && get_cnt <= 'd94) ? rtd_bram_dout[3] :
            ('d95 <= get_cnt && get_cnt <= 'd104) ? rtd_bram_dout[4] :
            ('d105 <= get_cnt && get_cnt <= 'd114) ? rtd_bram_dout[5] : 'b0;
    end



    // At state 5 ~ 52, readout TC data,
    // 8 per board, 48 total

    generate
        for (genvar i = 0; i < NUM_OF_BOARD; i++) begin

            always_ff @ (posedge clk) begin
                tc_bram_en[i] <= ((5+i*8) <= get_cnt && get_cnt <= (12+i*8));
            end

            always_ff @ (posedge clk) begin
                if ((5+i*8) <= get_cnt && get_cnt <= (12+i*8)) begin
                    tc_bram_addr[i] <= (get_cnt - (5+i*8));
                end else begin
                    tc_bram_addr[i] <= 'b0;
                end
            end

            // As state 55 ~ 114, readout RTC data
            // 10 per board, 60 total

            always_ff @ (posedge clk) begin
                rtd_bram_en[i] <= ((53+i*10) <= get_cnt && get_cnt <= (62+i*10));
            end

            always_ff @ (posedge clk) begin
                if  ((53+i*10) <= get_cnt && get_cnt <= (53+i*10)) begin
                    rtd_bram_addr[i] <= (get_cnt - (53+i*10));
                end else begin
                    rtd_bram_addr[i] <= 'd0;
                end
            end

        end
    endgenerate


    //--------------------------------------------------------------------------
    // FIFO

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            fifo_rst <= 1'b1;
        end else begin
            fifo_rst <= ctrl_reset;
        end
    end

    axi_ad7124_fifo i_axi_ad7124_fifo (
        .clk  (clk            ),
        .rst  (fifo_rst       ),
        //
        .din  (fifo_din       ),
        .wr_en(fifo_wren      ),
        .full (fifo_full      ),
        //
        .rd_en(ctrl_fifo_read ),
        .dout (stat_fifo_data ),
        .empty(stat_fifo_empty)
    );

    pulse_ext i_pulse_ext (
        .clk     (clk    ),
        .rst     (~resetn),
        .pulse_in(irq_ext),
        .ext_out (irq    )
    );

    //--------------------------------------------------------------------------
    // IRQ

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            irq_ext = 1'b0;
        end else begin
            irq_ext = (state_next == S_FIN);
        end
    end


endmodule

`default_nettype wire
