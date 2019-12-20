/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module spi_axi_spi_cdc #(parameter C_DATA_WIDTH = 1) (
    input  wire                    clk ,
    input  wire [C_DATA_WIDTH-1:0] din ,
    output wire [C_DATA_WIDTH-1:0] dout
);

    (* ASYNC_REG="true" *)
    (* IOB="true" *)
    reg [C_DATA_WIDTH-1:0] din_cdc_reg1;

    (* ASYNC_REG="true" *)
    reg [C_DATA_WIDTH-1:0] din_cdc_reg2;

    always_ff @ (posedge clk) begin
        din_cdc_reg1 <= din;
        din_cdc_reg2 <= din_cdc_reg1;
    end

    assign dout = din_cdc_reg2;

endmodule

`default_nettype wire
