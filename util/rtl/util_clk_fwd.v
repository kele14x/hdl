`timescale 1 ns / 1 ps
`default_nettype none

module util_clk_fwd (
    input  wire clk_i,
    output wire clk_o
);

  assign clk_o = ~clk_i;

endmodule

`default_nettype wire
