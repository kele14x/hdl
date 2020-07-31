/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_buf #(parameter NUM_OF_BOARD = 6) (
    // UP interface
    //-------------
    input  wire        aclk                           ,
    input  wire        aresetn                        ,
    // AXIS I/F
    input  wire        tc_sdi_valid[0:NUM_OF_BOARD-1] ,
    output wire        tc_sdi_ready[0:NUM_OF_BOARD-1] ,
    input  wire [ 7:0] tc_sdi_data [0:NUM_OF_BOARD-1] ,
    input  wire        tc_drdy     [0:NUM_OF_BOARD-1] ,
    //
    input  wire        rtd_sdi_valid[0:NUM_OF_BOARD-1],
    output wire        rtd_sdi_ready[0:NUM_OF_BOARD-1],
    input  wire [ 7:0] rtd_sdi_data [0:NUM_OF_BOARD-1],
    input  wire        rtd_drdy     [0:NUM_OF_BOARD-1],
    // BRAM I/F
    //---------
    output wire        bram_clk                       ,
    output wire        bram_rst                       ,
    output reg         bram_en                        ,
    output reg  [ 3:0] bram_we                        ,
    output reg  [12:0] bram_addr                      ,
    output reg  [31:0] bram_wrdata                    ,
    input  wire [31:0] bram_rddata                    ,
    // Interrupt
    output reg         irq
);

    localparam FRAME_LENGTH = 100;

    // Data frame

    reg [31:0] frame_type;
    reg [31:0] frame_sequence;

    reg [31:0] ts_sec;
    reg [31:0] ts_nsec;

    wire [31:0] tc_data [0:47];
    wire [31:0] rtd_data [0:47];

    // Buffer
    // 8x32 buffer for sampled data

    // TC
    reg [7:0] tc_buf [0:NUM_OF_BOARD-1][0:31];
    reg [5:0] tc_buf_stat[0:NUM_OF_BOARD-1];

    // RTD
    reg [7:0] rtd_buf [0:NUM_OF_BOARD-1][0:31];
    reg [5:0] rtd_buf_stat[0:NUM_OF_BOARD-1];

    generate
        for (genvar i = 0; i < NUM_OF_BOARD; i++) begin : g_buf

            always_ff @ (posedge aclk) begin
                if (~aresetn) begin
                    tc_buf_stat[i] <= 'h0;
                end else if (tc_drdy[i]) begin
                    tc_buf_stat[i] <= 'd0;
                end else if (tc_sdi_valid[i]) begin
                    tc_buf_stat[i] <= tc_buf_stat[i] + 1;
                end else begin
                    tc_buf_stat[i] <= tc_buf_stat[i];
                end
            end


            always_ff @ (posedge aclk) begin
                if (~aresetn) begin
                    for (int j = 0; j < 32; j++)
                        tc_buf[i][j] <= 'd0;
                end else if (tc_sdi_valid[i]) begin
                    tc_buf[i][tc_buf_stat[i]] <= tc_sdi_data[i];
                end
            end


            always_ff @ (posedge aclk) begin
                if (~aresetn) begin
                    rtd_buf_stat[i] <= 'h0;
                end else if (rtd_drdy[i]) begin
                    rtd_buf_stat[i] <= 'd0;
                end else if (rtd_sdi_valid[i]) begin
                    rtd_buf_stat[i] <= rtd_buf_stat[i] + 1;
                end else begin
                    rtd_buf_stat[i] <= rtd_buf_stat[i];
                end
            end

            always_ff @ (posedge aclk) begin
                if (~aresetn) begin
                    for (int j = 0; j < 32; j++)
                        rtd_buf[i][j] <= 'd0;
                end else if (rtd_sdi_valid[i]) begin
                    rtd_buf[i][rtd_buf_stat[i]] <= rtd_sdi_data[i];
                end
            end

        end
    endgenerate

    // Trigger when 6 board's data is ready

    reg trig, trig_d;

    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
            trig <= 1'b0;
            trig_d <= 1'b0;
        end else begin
            trig <= &{tc_buf_stat[0][5], tc_buf_stat[1][5], tc_buf_stat[2][5],
                      tc_buf_stat[3][5], tc_buf_stat[4][5], tc_buf_stat[5][5]};
            trig_d <= trig;
        end
    end

    // BRAM Write State Machine

    reg [6:0] bram_wr_stat;

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_wr_stat <= 'hFF;
        end else if (trig == 1'b1 && trig_d == 1'b0) begin
            bram_wr_stat <= 'd0;
        end else if (bram_wr_stat <= (FRAME_LENGTH - 1)) begin
            bram_wr_stat <= bram_wr_stat + 1;
        end else begin
            bram_wr_stat <= 'hFF;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_en <= 1'b0;
            bram_we <= 4'h0;
            bram_addr <= 'd0;
        end else begin
            bram_en <= (bram_wr_stat <= (FRAME_LENGTH - 1)) ? 1'b1 : 1'b0;
            bram_we <= (bram_wr_stat <= (FRAME_LENGTH - 1)) ? 4'hF : 4'h0;
            bram_addr <= (bram_wr_stat <= (FRAME_LENGTH - 1)) ? bram_wr_stat : 13'b0;
        end
    end

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_wrdata <= 'd0;
        end else begin
            if (bram_wr_stat == 'd0) bram_wrdata <= frame_type;
            else if (bram_wr_stat == 'd1) bram_wrdata <= frame_sequence;
            else if (bram_wr_stat == 'd2) bram_wrdata <= ts_sec;
            else if (bram_wr_stat == 'd3) bram_wrdata <= ts_nsec;
            else if (bram_wr_stat <= 'd51) bram_wrdata <= tc_data[bram_wr_stat - 4];
            else if (bram_wr_stat <= 'd99) bram_wrdata <= rtd_data[bram_wr_stat - 52];
            else bram_wrdata <= 'd0;
        end
    end


    // IRQ

    reg[8:0] irq_ext;

    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
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

    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
            irq <= 1'b0;
        end else begin
            irq <= |irq_ext;
        end
    end

    // Net mapping

    assign bram_clk = aclk;
    assign bram_rst = ~aresetn;

    generate
        for (genvar i = 0; i < NUM_OF_BOARD; i++) begin
            assign tc_sdi_ready[i] = 1'b1;
            assign rtd_sdi_ready[i] = 1'b1;
        end
    endgenerate

    generate
        for (genvar i = 0; i < NUM_OF_BOARD; i++) begin
            for (genvar j = 0; j < 32; j++) begin 
                assign tc_data[i*8+j/4][31-(j%4)*8-:8] = tc_buf[i][j];
                assign rtd_data[i*8+j/4][31-(j%4)*8-:8] = rtd_buf[i][j];
            end
        end
    endgenerate


endmodule

`default_nettype wire
