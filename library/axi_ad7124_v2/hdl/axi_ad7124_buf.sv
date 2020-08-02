/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_buf #(parameter BUFFER_ADDR_WIDTH = 5) (
    // Data I/F from SPI
    //-------------
    input  wire                         clk              ,
    input  wire                         resetn           ,
    //
    input  wire                         trigger          ,
    output reg                          drdy             ,
    //
    input  wire                         offload_sdi_valid,
    output wire                         offload_sdi_ready,
    input  wire [                  7:0] offload_sdi_data ,
    // BRAM I/F
    //---------
    input  wire                         bram_clk         ,
    input  wire                         bram_rst         ,
    //
    input  wire                         bram_en          ,
    input  wire [BUFFER_ADDR_WIDTH-3:0] bram_addr        ,
    output reg  [                 31:0] bram_dout
);


    localparam FRAME_LENGTH = 32;

    reg [7:0] buf_mem [0:(2**BUFFER_ADDR_WIDTH-1)];

    reg  [BUFFER_ADDR_WIDTH-1:0] wr_addr;
    wire                         wr_en  ;
    wire [                  7:0] wr_data;

    reg [BUFFER_ADDR_WIDTH-3:0] rd_addr;

    // Memory write FSM

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            wr_addr <= 'd0;
        end else if (trigger) begin
            wr_addr <= 'd0;
        end else if (offload_sdi_valid) begin
            wr_addr <= ((wr_addr == FRAME_LENGTH - 1) ? 'd0 : (wr_addr + 1));
        end
    end

    assign wr_en = offload_sdi_valid;

    assign wr_data = offload_sdi_data;

    assign offload_sdi_ready = 1'b1;

    // Memory write port

    always_ff @ (posedge clk) begin
        if (wr_en) begin
            buf_mem[wr_addr] <= wr_data;
        end
    end

    // Memory read port

    always_ff @ (posedge bram_clk) begin
        if (bram_rst) begin
            bram_dout <= 'd0;
        end else if (bram_en) begin
            bram_dout <= { buf_mem[bram_addr*4+3], buf_mem[bram_addr*4+2],
                buf_mem[bram_addr*4+1], buf_mem[bram_addr*4] };
        end
    end

    // drdy

    always_ff @ (posedge clk) begin
        if (~resetn) begin
            drdy <= 1'b0;
        end else if ((wr_addr == FRAME_LENGTH - 1) && offload_sdi_valid) begin
            drdy <= 1'b1;
        end else begin
            drdy <= 1'b0;
        end
    end

endmodule

`default_nettype wire
