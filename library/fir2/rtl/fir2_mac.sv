// File: fir2_mac.sv
// Brief: Multiplier at each stage for ch_fir module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module fir2_mac #(
    parameter int A_WIDTH = 16,
    parameter int B_WIDTH = 16,
    parameter int D_WIDTH = 16,
    parameter int P_WIDTH = 33
) (
    input var                       clk,
    input var  signed [A_WIDTH-1:0] a,
    input var  signed [B_WIDTH-1:0] b,
    input var  signed [D_WIDTH-1:0] d,
    input var                       op,
    input var  signed [P_WIDTH-1:0] pin,
    output var signed [P_WIDTH-1:0] pout
);

  localparam int ADWidth = (A_WIDTH > D_WIDTH ? A_WIDTH : D_WIDTH) + 1;

  logic signed [A_WIDTH-1:0] ar;
  logic signed [B_WIDTH-1:0] br;
  logic signed [D_WIDTH-1:0] dr;

  logic opr, oprr, oprrr;

  logic signed [ADWidth-1:0] ad;
  logic signed [P_WIDTH-1:0] mreg;
  logic signed [P_WIDTH-1:0] preg;

  always @(posedge clk) begin
    ar    <= a;
    br    <= b;
    dr    <= d;
    opr   <= op;
    oprr  <= opr;
    oprrr <= oprr;
    ad    <= ar + dr;
    mreg  <= ad * br;
    if (oprrr) begin
      preg <= mreg + pin;
    end else begin
      preg <= mreg + preg;
    end
  end

  assign pout = preg;

endmodule

`default_nettype wire
