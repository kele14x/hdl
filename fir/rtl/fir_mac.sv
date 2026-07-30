// File: fir_mac.sv
// Brief: Multiplier adder element for fir module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module fir_mac #(
    parameter int A_WIDTH = 16,
    parameter int B_WIDTH = 16,
    parameter int D_WIDTH = 16,
    parameter int P_WIDTH = 33
) (
    input var                       clk,
    input var  signed [A_WIDTH-1:0] a,
    input var  signed [B_WIDTH-1:0] b,
    input var  signed [D_WIDTH-1:0] d,
    input var  signed [P_WIDTH-1:0] pin,
    output var signed [P_WIDTH-1:0] pout
);

  localparam int ADWidth = (A_WIDTH > D_WIDTH ? A_WIDTH : D_WIDTH) + 1;

  logic signed [A_WIDTH-1:0] ar;
  logic signed [B_WIDTH-1:0] br;
  logic signed [D_WIDTH-1:0] dr;

  logic signed [ADWidth-1:0] ad;
  logic signed [P_WIDTH-1:0] mreg;
  logic signed [P_WIDTH-1:0] preg;

  always_ff @(posedge clk) begin
    ar   <= a;
    br   <= b;
    dr   <= d;
    ad   <= ar + dr;
    mreg <= ad * br;
    preg <= mreg + pin;
  end

  assign pout = preg;

endmodule

`default_nettype wire
