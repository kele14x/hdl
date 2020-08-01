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


    // Data frame

    reg [31:0] frame_type = 32'h1234abcd;
    reg [31:0] frame_sequence;

    reg [31:0] ts_sec;
    reg [31:0] ts_nsec;


    // RTC

    reg [31:0] rtc_sec;
    reg [31:0] rtc_nsec;

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


    // BRAM Write State Machine

    localparam FRAME_LENGTH = 100;

    reg start;

    reg [6:0] bram_wr_stat;


    // When to start write to BRAM

    // TODO: Need a solid logic to handle all 6 board's data
    always_ff @ (posedge clk) begin
        if (~resetn) begin
            start <= 1'b0;
        end else begin
            start <= tc_drdy[0];
        end
    end


    // Frame header

    always_ff @ (posedge bram_clk) begin
        if (start) begin
            ts_sec <= rtc_sec;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (start) begin
            ts_nsec <= rtc_nsec;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (start) begin
            frame_sequence <= frame_sequence + 1;
        end
    end


    // BRAM signals

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_wr_stat <= 'hFF;
        end else if (start) begin
            bram_wr_stat <= 'd0;
        end else if (bram_wr_stat <= (FRAME_LENGTH - 1)) begin
            bram_wr_stat <= bram_wr_stat + 1;
        end else begin
            bram_wr_stat <= 'hFF;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_en   <= 1'b0;
        end else begin
            bram_en   <= (bram_wr_stat <= (FRAME_LENGTH - 1));
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_we   <= 4'h0;
        end else begin
            bram_we   <= (bram_wr_stat <= (FRAME_LENGTH - 1)) ? 4'hF : 4'h0;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_addr <= 'd0;
        end else begin
            bram_addr <= (bram_wr_stat <= (FRAME_LENGTH - 1)) ? bram_wr_stat : 13'b0;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_din <= 'd0;
        end else begin
            if (bram_wr_stat == 'd0) bram_din <= frame_type;
            else if (bram_wr_stat == 'd1) bram_din <= frame_sequence;
            else if (bram_wr_stat == 'd2) bram_din <= ts_sec;
            else if (bram_wr_stat == 'd3) bram_din <= ts_nsec;
            // 4 ~ 51
            else if (bram_wr_stat <= 'd11) bram_din <= tc_bram_dout[0];
            else if (bram_wr_stat <= 'd19) bram_din <= tc_bram_dout[1];
            else if (bram_wr_stat <= 'd27) bram_din <= tc_bram_dout[2];
            else if (bram_wr_stat <= 'd35) bram_din <= tc_bram_dout[3];
            else if (bram_wr_stat <= 'd43) bram_din <= tc_bram_dout[4];
            else if (bram_wr_stat <= 'd51) bram_din <= tc_bram_dout[5];
            // 52 ~ 99
            else if (bram_wr_stat <= 'd59) bram_din <= rtd_bram_dout[0];
            else if (bram_wr_stat <= 'd67) bram_din <= rtd_bram_dout[1];
            else if (bram_wr_stat <= 'd75) bram_din <= rtd_bram_dout[2];
            else if (bram_wr_stat <= 'd83) bram_din <= rtd_bram_dout[3];
            else if (bram_wr_stat <= 'd91) bram_din <= rtd_bram_dout[4];
            else if (bram_wr_stat <= 'd99) bram_din <= rtd_bram_dout[5];
            else bram_din <= 'd0;
        end
    end

    // Read from external module

    generate
        for (genvar i = 0; i < NUM_OF_BOARD; i++) begin

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    tc_bram_en[i] <= 1'b0;
                end else begin
                    tc_bram_en[i] <= (i*6+3 <= bram_wr_stat && bram_wr_stat <=i*6+10);
                end
            end

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    tc_bram_addr[i] <= 'b0;
                end else begin
                    tc_bram_addr[i] <= (i*6+3 <= bram_wr_stat && bram_wr_stat <=i*6+10) ?
                        (bram_wr_stat - i*6 - 3) : 'b0;
                end
            end

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    rtd_bram_en[i] <= 1'b0;
                end else begin
                    rtd_bram_en[i] <= (i*6+51 <= bram_wr_stat && bram_wr_stat <=i*6+58);
                end
            end

            always_ff @ (posedge clk) begin
                if (~resetn) begin
                    rtd_bram_addr[i] <= 'b0;
                end else begin
                    rtd_bram_addr[i] <= (i*6+51 <= bram_wr_stat && bram_wr_stat <=i*6+58) ?
                        (bram_wr_stat - i*6 - 51) : 'b0;
                end
            end

        end
    endgenerate



    // IRQ

    reg[8:0] irq_ext;

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            irq_ext <= 'd0;
        end else begin
            if (bram_wr_stat == 'd99) begin
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


endmodule

`default_nettype wire
