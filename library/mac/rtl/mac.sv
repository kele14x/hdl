// File: mac.sv
// Brief: MAC is a simple, portable, and efficient implementation of the
//  Multiply Adder Circuit, which is basic component of DSP related stuff.
`timescale 1 ns / 1 ps
//
`default_nettype none

module mac #(
    parameter integer A_WIDTH = 16,
    parameter integer B_WIDTH = 16,
    parameter integer C_WIDTH = 33,
    parameter integer D_WIDTH = 16,
    parameter integer P_WIDTH = 34
) (
    input var                       clk,
    input var                       rst,
    input var  signed [A_WIDTH-1:0] a,
    input var  signed [B_WIDTH-1:0] b,
    input var  signed [C_WIDTH-1:0] c,
    input var  signed [D_WIDTH-1:0] d,
    output var signed [P_WIDTH-1:0] p
);

  // Pipeline registers
  logic signed [           A_WIDTH-1:0] ar;
  logic signed [           B_WIDTH-1:0] br;
  logic signed [           C_WIDTH-1:0] cr;
  logic signed [           D_WIDTH-1:0] dr;

  // DSP registers
  logic signed [A_WIDTH + D_WIDTH -1:0] adreg;
  logic signed [           P_WIDTH-1:0] mreg;
  logic signed [           P_WIDTH-1:0] preg;

  always_ff @(posedge clk) begin
    ar     <= a;
    br     <= b;
    cr     <= c;
    dr     <= d;
    adrreg <= ar + dr;
    mreg   <= adreg * br;
    preg   <= mreg + cr;
  end

  assign p = preg;

endmodule

`default_nettype wire
