// File: cmult_chain.sv
// Brief: Complex multiplier, chained together.

`timescale 1 ns / 1 ps `default_nettype none

module cmult_chain #(
    parameter int NUM_TAPS = 8,
    parameter int AWIDTH   = 16,
    parameter int BWIDTH   = 16,
    parameter int PWIDTH   = 16,
    parameter int SRABITS  = 15
) (
    input var  logic              clk,
    input var  logic              rst,
    //
    input var  logic [AWIDTH-1:0] ar [NUM_TAPS],
    input var  logic [AWIDTH-1:0] ai [NUM_TAPS],
    //
    input var  logic [BWIDTH-1:0] br [NUM_TAPS],
    input var  logic [BWIDTH-1:0] bi [NUM_TAPS],
    //
    output var logic [PWIDTH-1:0] pr,
    output var logic [PWIDTH-1:0] pi,
    // Overflow indicator
    output var logic              ovf
);


  localparam int Latency = NUM_TAPS + 4;
  localparam int PWidthInt = AWIDTH + BWIDTH + $clog2(NUM_TAPS);

  logic [PWidthInt-1:0] pc_int[NUM_TAPS+1];
  logic [PWidthInt-1:0] pr_int[NUM_TAPS+1];
  logic [PWidthInt-1:0] pi_int[NUM_TAPS+1];

  logic ovf_r, ovf_i;

  assign pc_int[0] = (1 << (SRABITS - 1));
  assign pr_int[0] = 0;
  assign pi_int[0] = 0;

  generate
    for (genvar i = 0; i < NUM_TAPS; i++) begin
      cmult_chain_pe #(
          .AWIDTH(AWIDTH),
          .BWIDTH(BWIDTH),
          .PWIDTH(PWidthInt)
      ) i_cmult_chain_pe (
          .clk   (clk),
          .rst   (rst),
          .ar    (ar[i]),
          .ai    (ai[i]),
          .br    (br[i]),
          .bi    (bi[i]),
          .pc_in (pc_int[i]),
          .pr_in (pr_int[i]),
          .pi_in (pi_int[i]),
          .pc_out(pc_int[i+1]),
          .pr_out(pr_int[i+1]),
          .pi_out(pi_int[i+1])
      );
    end
  endgenerate

  adder #(
      .A_WIDTH (PWidthInt),
      .B_WIDTH (PWidthInt),
      .P_WIDTH (PWIDTH),
      .SRA_BITS(SRABITS)
  ) adder_r_i (
      .clk    (clk),
      .rst    (rst),
      .a      (pc_int[NUM_TAPS]),
      .b      (pr_int[NUM_TAPS]),
      .add_sub(1'b1),
      .p      (pr),
      .ovf    (ovf_r)
  );

  adder #(
      .A_WIDTH (PWidthInt),
      .B_WIDTH (PWidthInt),
      .P_WIDTH (PWIDTH),
      .SRA_BITS(SRABITS)
  ) adder_i_i (
      .clk    (clk),
      .rst    (rst),
      .a      (pc_int[NUM_TAPS]),
      .b      (pi_int[NUM_TAPS]),
      .add_sub(1'b1),
      .p      (pi),
      .ovf    (ovf_i)
  );

  assign ovf = ovf_r || ovf_i;

endmodule

`default_nettype wire
