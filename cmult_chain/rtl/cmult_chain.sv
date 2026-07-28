// File: cmult_chain.sv
// Brief: Complex Multiplier Chain. This module could be act as a base of
//        complex FIR filter.
`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult_chain #(
    parameter int NUM_TAPS = 8,
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 16,
    parameter int SRA_BITS = 15
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


  localparam int PWidthInt = A_WIDTH + B_WIDTH + 1 + $clog2(NUM_TAPS);


  wire signed [PWidthInt-1:0] pc_s[NUM_TAPS+1];
  wire signed [PWidthInt-1:0] pr_s[NUM_TAPS+1];
  wire signed [PWidthInt-1:0] pi_s[NUM_TAPS+1];

  wire ovf_r, ovf_i;

  assign pc_s[0] = (1 << (SRA_BITS - 1));
  assign pr_s[0] = 0;
  assign pi_s[0] = 0;

  generate
    genvar i;
    for (i = 0; i < NUM_TAPS; i = i + 1) begin : g_stage

      cmult_chain_stage #(
          .A_WIDTH(A_WIDTH),
          .B_WIDTH(B_WIDTH),
          .P_WIDTH(PWidthInt)
      ) i_core (
          .clk   (clk),
          .rst   (rst),
          //
          .ar    (ar[i]),
          .ai    (ai[i]),
          .br    (br[i]),
          .bi    (bi[i]),
          //
          .pc_in (pc_s[i]),
          .pr_in (pr_s[i]),
          .pi_in (pi_s[i]),
          //
          .pc_out(pc_s[i+1]),
          .pr_out(pr_s[i+1]),
          .pi_out(pi_s[i+1])
      );

    end
  endgenerate

  adder #(
      .A_WIDTH (PWidthInt),
      .B_WIDTH (PWidthInt),
      .P_WIDTH (P_WIDTH),
      .SHIFT(SRA_BITS)
  ) i_adder_r (
      .clk(clk),
      .rst(rst),
      .a  (pc_s[NUM_TAPS]),
      .b  (pr_s[NUM_TAPS]),
      .sub(1'b0),
      .p  (pr),
      .ovf(ovf_r)
  );

  adder #(
      .A_WIDTH (PWidthInt),
      .B_WIDTH (PWidthInt),
      .P_WIDTH (P_WIDTH),
      .SHIFT(SRA_BITS)
  ) i_adder_i (
      .clk(clk),
      .rst(rst),
      .a  (pc_s[NUM_TAPS]),
      .b  (pi_s[NUM_TAPS]),
      .sub(1'b0),
      .p  (pi),
      .ovf(ovf_i)
  );

  assign ovf = ovf_r || ovf_i;

endmodule

`default_nettype wire
