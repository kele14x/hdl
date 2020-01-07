/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module spi_slave_cdc #(parameter C_DATA_WIDTH = 1) (
    input  wire                    clk ,
    input  wire [C_DATA_WIDTH-1:0] din ,
    output wire [C_DATA_WIDTH-1:0] dout
);

    (* ASYNC_REG="true" *)
    (* IOB="true" *)
    reg [C_DATA_WIDTH-1:0] sync0;

    (* ASYNC_REG="true" *)
    reg [C_DATA_WIDTH-1:0] sync1;

    always @ (posedge clk) begin
        sync0 <= din;
        sync1 <= sync0;
    end

    assign dout = sync1;

endmodule

`default_nettype wire
