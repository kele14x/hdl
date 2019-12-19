/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module spi_axis_sfr (
    input  wire        clk        ,
    input  wire        rst        ,
    // Write
    input  wire [11:0] wr_addr    ,
    input  wire [15:0] wr_data    ,
    input  wire        wr_en      ,
    // Read
    input  wire [11:0] rd_addr    ,
    input  wire        rd_en      ,
    output reg  [15:0] tx_data    ,
    // SFRs
    output wire        sfr_SRR_RST
);

    localparam C_ADDR_SRR = 12'b01;

    always_ff @ (posedge clk) begin
        if (wr_en && wr_addr == C_ADDR_SRR) begin
            if (wr_data == 16'h000A) begin
                sft_SRR_RST = 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
