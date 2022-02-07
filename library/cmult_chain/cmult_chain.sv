// File: cmult_chain.sv
// Brief: Complex multiplier, chained together.

`timescale 1 ns / 1 ps `default_nettype none

module cmult_chain #(
    parameter int NUM_TAPS = 8,
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 16,
    parameter int SRABITS  = 15
) (
    input var                       clk,
    input var                       rst,
    //
    input var  signed [A_WIDTH-1:0] ar [NUM_TAPS],
    input var  signed [A_WIDTH-1:0] ai [NUM_TAPS],
    //
    input var  signed [B_WIDTH-1:0] br [NUM_TAPS],
    input var  signed [B_WIDTH-1:0] bi [NUM_TAPS],
    //
    output var signed [P_WIDTH-1:0] pr,
    output var signed [P_WIDTH-1:0] pi,
    // Overflow indicator
    output var                      ovf
);


  localparam int Latency = NUM_TAPS + 4;
  localparam int PWidthInt = A_WIDTH + B_WIDTH + 1 + $clog2(NUM_TAPS);

  logic [PWidthInt-1:0] pc_in, pr_in, pi_in;
  logic [PWidthInt-1:0] pc_out, pr_out, pi_out;

  logic ovf_r, ovf_i;

  assign pc_in = (1 << (SRABITS - 1));
  assign pr_in = 0;
  assign pi_in = 0;

  cmult_chain_core #(
      .NUM_TAPS(NUM_TAPS),
      .A_WIDTH (A_WIDTH),
      .B_WIDTH (B_WIDTH),
      .P_WIDTH (PWidthInt)
  ) i_core (
      .clk   (clk),
      .rst   (rst),
      .ar    (ar),
      .ai    (ai),
      .br    (br),
      .bi    (bi),
      .pc_in (pc_in),
      .pr_in (pr_in),
      .pi_in (pi_in),
      .pc_out(pc_out),
      .pr_out(pr_out),
      .pi_out(pi_out)
  );

  adder #(
      .A_WIDTH (PWidthInt),
      .B_WIDTH (PWidthInt),
      .P_WIDTH (P_WIDTH),
      .SRA_BITS(SRABITS)
  ) i_adder_r (
      .clk    (clk),
      .rst    (rst),
      .a      (pc_out),
      .b      (pr_out),
      .add_sub(1'b0),
      .p      (pr),
      .ovf    (ovf_r)
  );

  adder #(
      .A_WIDTH (PWidthInt),
      .B_WIDTH (PWidthInt),
      .P_WIDTH (P_WIDTH),
      .SRA_BITS(SRABITS)
  ) i_adder_i (
      .clk    (clk),
      .rst    (rst),
      .a      (pc_out),
      .b      (pi_out),
      .add_sub(1'b0),
      .p      (pi),
      .ovf    (ovf_i)
  );

  assign ovf = ovf_r || ovf_i;

endmodule

`default_nettype wire
