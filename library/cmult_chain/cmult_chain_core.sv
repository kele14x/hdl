// File: cmult_chain.sv
// Brief: Complex multiplier, chained together

`timescale 1 ns / 1 ps `default_nettype none

module cmult_chain_core #(
    parameter int NUM_TAPS = 8,
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 36
) (
    input var  logic                      clk,
    input var  logic                      rst,
    //
    input var  logic signed [A_WIDTH-1:0] ar [NUM_TAPS],
    input var  logic signed [A_WIDTH-1:0] ai [NUM_TAPS],
    //
    input var  logic signed [B_WIDTH-1:0] br [NUM_TAPS],
    input var  logic signed [B_WIDTH-1:0] bi [NUM_TAPS],
    //
    input var  logic signed [P_WIDTH-1:0] pc_in,
    input var  logic signed [P_WIDTH-1:0] pr_in,
    input var  logic signed [P_WIDTH-1:0] pi_in,
    //
    output var logic signed [P_WIDTH-1:0] pc_out,
    output var logic signed [P_WIDTH-1:0] pr_out,
    output var logic signed [P_WIDTH-1:0] pi_out
);


  localparam int Latency = 3 + NUM_TAPS;

  logic signed [P_WIDTH-1:0] pc_s [NUM_TAPS+1];
  logic signed [P_WIDTH-1:0] pr_s [NUM_TAPS+1];
  logic signed [P_WIDTH-1:0] pi_s [NUM_TAPS+1];


  assign pc_s[0] = pc_in;
  assign pr_s[0] = pr_in;
  assign pi_s[0] = pi_in;

  assign pc_out = pc_s[NUM_TAPS];
  assign pr_out = pr_s[NUM_TAPS];
  assign pi_out = pi_s[NUM_TAPS];

  generate
    for (genvar i = 0; i < NUM_TAPS; i++) begin : g_taps

      logic signed [A_WIDTH-1:0] ar_d, ar_dd;
      logic signed [A_WIDTH-1:0] ai_d, ai_dd;

      logic signed [B_WIDTH-1:0] br_d;
      logic signed [B_WIDTH-1:0] bi_d, bi_dd;

      logic signed [A_WIDTH:0] addcommon;
      logic signed [B_WIDTH:0] addr, addi;
      logic signed [A_WIDTH+B_WIDTH:0] multc, multr, multi;

      // Delay taps, tools will automatically absorb registers into DSP and
      // duplicate if needed
      always_ff @(posedge clk) begin
        ar_d  <= ar[i];
        ar_dd <= ar_d;
        ai_d  <= ai[i];
        ai_dd <= ai_d;
        br_d  <= br[i];
        bi_d  <= bi[i];
        bi_dd <= bi_d;
      end

      // DSP1
      // Common factor (ar - ai) * bi, shared for the calculations of the real and
      // imaginary final products
      always_ff @(posedge clk) begin
        addcommon <= ar_d - ai_d;
        multc     <= addcommon * bi_dd;
        pc_s[i+1] <= multc + pc_s[i];
      end

      // DSP2
      // Real product ar * (br - bi) + (ar - ai) * bi = ar * br - ai * bi
      always_ff @(posedge clk) begin
        addr      <= br_d - bi_d;
        multr     <= addr * ar_dd;
        pr_s[i+1] <= multr + pr_s[i];
      end

      // DSP3
      // Imaginary product ai * (br + bi) + (ar - ai) * bi = ai * br + ar + bi
      always_ff @(posedge clk) begin
        addi      <= br_d + bi_d;
        multi     <= addi * ai_dd;
        pi_s[i+1] <= multi + pi_s[i];
      end

    end
  endgenerate

endmodule

`default_nettype wire
