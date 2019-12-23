/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module cdc_bits #(
    parameter C_BIT_WIDTH = 1,
    parameter C_NUM_STAGE = 2
) (
    input  wire [C_BIT_WIDTH-1:0] din    ,
    input  wire                   out_clk,
    output wire [C_BIT_WIDTH-1:0] dout
);

    initial begin
        assert (C_NUM_STAGE < 2) else
            $error("Number of synchronous stages must be 2 or large");
    end

    (* ASYNC_REG="true" *)
        reg [C_BIT_WIDTH-1:0] cdc_reg[0:C_NUM_STAGE-1];

    initial begin
        for (int i = 0; i < C_NUM_STAGE; i++) begin
            cdc_reg[i] <= 'd0;
        end
    end

    always_ff @ (posedge out_clk) begin
        cdc_reg[0] <= din;
        for (int i = 1; i < C_NUM_STAGE; i++) begin
            cdc_reg[i] = cdc_reg[i-1];
        end
    end

    assign dout = cdc_reg[C_NUM_STAGE-1];

endmodule
