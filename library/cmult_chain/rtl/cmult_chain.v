// File: cmult_chain.v
// Brief: Complex Multiplier Chain. This module could be act as a base of
//        complex FIR filter.
`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult_chain #(
    parameter integer NUM_TAPS = 8,
    parameter integer A_WIDTH  = 16,
    parameter integer B_WIDTH  = 16,
    parameter integer P_WIDTH  = 16,
    parameter integer SRA_BITS = 15
) (
    input  wire                               clk,
    input  wire                               rst,
    // [A_WIDTH-1:0] ax [NUM_TAPS] compressed in 1-D signal
    input  wire        [A_WIDTH*NUM_TAPS-1:0] ar,
    input  wire        [A_WIDTH*NUM_TAPS-1:0] ai,
    // [B_WIDTH-1:0] bx [NUM_TAPS] compressed in 1-D signal
    input  wire        [B_WIDTH*NUM_TAPS-1:0] br,
    input  wire        [B_WIDTH*NUM_TAPS-1:0] bi,
    //
    output wire signed [         P_WIDTH-1:0] pr,
    output wire signed [         P_WIDTH-1:0] pi,
    // Overflow indicator
    output wire                               ovf
);


  localparam integer Latency = NUM_TAPS + 4;
  localparam integer PWidthInt = A_WIDTH + B_WIDTH + 1 + $clog2(NUM_TAPS);

  wire signed [  A_WIDTH-1:0] ar_s[0:NUM_TAPS-1];
  wire signed [  A_WIDTH-1:0] ai_s[0:NUM_TAPS-1];

  wire signed [  B_WIDTH-1:0] br_s[0:NUM_TAPS-1];
  wire signed [  B_WIDTH-1:0] bi_s[0:NUM_TAPS-1];

  wire signed [PWidthInt-1:0] pc_s[0:NUM_TAPS];
  wire signed [PWidthInt-1:0] pr_s[0:NUM_TAPS];
  wire signed [PWidthInt-1:0] pi_s[0:NUM_TAPS];

  wire ovf_r, ovf_i;

  assign pc_s[0] = (1 << (SRA_BITS - 1));
  assign pr_s[0] = 0;
  assign pi_s[0] = 0;

  generate
    genvar i;
    for (i = 0; i < NUM_TAPS; i = i + 1) begin : g_stage

      assign ar_s[i] = $signed(ar[A_WIDTH*(i+1)-1:A_WIDTH*i]);
      assign ai_s[i] = $signed(ai[A_WIDTH*(i+1)-1:A_WIDTH*i]);

      assign br_s[i] = $signed(br[B_WIDTH*(i+1)-1:B_WIDTH*i]);
      assign bi_s[i] = $signed(bi[B_WIDTH*(i+1)-1:B_WIDTH*i]);

      cmult_chain_stage #(
          .A_WIDTH(A_WIDTH),
          .B_WIDTH(B_WIDTH),
          .P_WIDTH(PWidthInt)
      ) i_core (
          .clk   (clk),
          .rst   (rst),
          //
          .ar    (ar_s[i]),
          .ai    (ai_s[i]),
          .br    (br_s[i]),
          .bi    (bi_s[i]),
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
      .SRA_BITS(SRA_BITS)
  ) i_adder_r (
      .clk    (clk),
      .rst    (rst),
      .a      (pc_s[NUM_TAPS]),
      .b      (pr_s[NUM_TAPS]),
      .add_sub(1'b0),
      .p      (pr),
      .ovf    (ovf_r)
  );

  adder #(
      .A_WIDTH (PWidthInt),
      .B_WIDTH (PWidthInt),
      .P_WIDTH (P_WIDTH),
      .SRA_BITS(SRA_BITS)
  ) i_adder_i (
      .clk    (clk),
      .rst    (rst),
      .a      (pc_s[NUM_TAPS]),
      .b      (pi_s[NUM_TAPS]),
      .add_sub(1'b0),
      .p      (pi),
      .ovf    (ovf_i)
  );

  assign ovf = ovf_r || ovf_i;

endmodule

`default_nettype wire
