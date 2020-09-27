/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_buf #(
    parameter integer BUFFER_ADDR_WIDTH = 5 ,
    parameter integer FRAME_LENGTH      = 32
) (
    // Data I/F from SPI
    //-------------
    input  var logic                         clk              ,
    input  var logic                         rst              ,
    // AXIS
    input  var logic                         offload_sdi_valid,
    output var logic                         offload_sdi_ready,
    input  var logic [                  7:0] offload_sdi_data ,
    // MISC
    input  var logic                         trigger          ,
    // HS
    output var logic                         data_valid       ,
    input  var logic                         data_ready       ,
    // BRAM I/F
    //---------
    input  var logic                         bram_en          ,
    input  var logic [BUFFER_ADDR_WIDTH-3:0] bram_addr        ,
    output var logic [                 31:0] bram_dout
);


    logic  [7:0] buf_mem [0:(2**BUFFER_ADDR_WIDTH-1)];

    logic [BUFFER_ADDR_WIDTH-1:0] wr_addr;
    logic                         wr_en  ;
    logic [                  7:0] wr_data;

    logic  [BUFFER_ADDR_WIDTH-3:0] rd_addr;

    // Memory write FSM

    always_ff @ (posedge clk) begin
        if (rst) begin
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

    always_ff @ (posedge clk) begin
        if (rst) begin
            bram_dout <= 'd0;
        end else if (bram_en) begin
            bram_dout <= { buf_mem[bram_addr*4], buf_mem[bram_addr*4+1],
                buf_mem[bram_addr*4+2], buf_mem[bram_addr*4+3] };
        end
    end

    // data_valid

    always_ff @ (posedge clk) begin
        if (rst) begin
            data_valid <= 1'b0;
        end else if ((wr_addr == FRAME_LENGTH - 1) && offload_sdi_valid) begin
            data_valid <= 1'b1;
        end else if (data_ready) begin
            data_valid <= 1'b0;
        end
    end

endmodule

`default_nettype wire
