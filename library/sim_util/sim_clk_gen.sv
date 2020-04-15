/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module sim_clk_gen #(
    parameter CLK_FREQ_HZ  = 100000000,
    parameter RST_POLARITY = 1        ,
    parameter RST_CYCLES   = 10
) (
    output var logic clk,
    output var logic rst
);

    // Clock period in ns
    localparam CLK_PERIOD_NS = 10**9 / CLK_FREQ_HZ;

    // Parameter check
    initial begin
        if (RST_POLARITY > 1) begin
            $error("Reset polarity's value is out of range.");
        end
    end

    // Reset generation
    initial begin
        rst = !RST_POLARITY;
        repeat(RST_CYCLES) begin
            @(posedge clk);
        end
        rst <= RST_POLARITY;
    end

    // Clock generation
    always begin
        clk = 0;
        #(CLK_PERIOD_NS/2) clk = 1;
        #(CLK_PERIOD_NS/2);
    end

endmodule
