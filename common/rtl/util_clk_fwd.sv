`timescale 1 ns / 1 ps
`default_nettype none

module util_clk_fwd (
    input var  clk_i,
    output var clk_o
);

  assign clk_o = ~clk_i;

endmodule

`default_nettype wire
