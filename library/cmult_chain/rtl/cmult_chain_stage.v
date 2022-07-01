// File: cmult_chain_stage.sv
// Brief: Single DSP stage for Complex Multiplier Chain module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult_chain_stage #(
    parameter integer A_WIDTH = 16,
    parameter integer B_WIDTH = 16,
    parameter integer P_WIDTH = 36
) (
    input  wire                      clk,
    input  wire                      rst,
    //
    input  wire signed [A_WIDTH-1:0] ar,
    input  wire signed [A_WIDTH-1:0] ai,
    //
    input  wire signed [B_WIDTH-1:0] br,
    input  wire signed [B_WIDTH-1:0] bi,
    //
    input  wire signed [P_WIDTH-1:0] pc_in,
    input  wire signed [P_WIDTH-1:0] pr_in,
    input  wire signed [P_WIDTH-1:0] pi_in,
    //
    output reg signed  [P_WIDTH-1:0] pc_out,
    output reg signed  [P_WIDTH-1:0] pr_out,
    output reg signed  [P_WIDTH-1:0] pi_out
);


  localparam integer Latency = 3;


  reg signed [A_WIDTH-1:0] ar_d, ar_dd;
  reg signed [A_WIDTH-1:0] ai_d, ai_dd;

  reg signed [B_WIDTH-1:0] br_d;
  reg signed [B_WIDTH-1:0] bi_d, bi_dd;

  reg signed [A_WIDTH:0] addcommon;
  reg signed [B_WIDTH:0] addr, addi;
  reg signed [A_WIDTH+B_WIDTH:0] multc, multr, multi;

  // Delay taps, tools will automatically absorb registers into DSP and
  // duplicate if needed
  always @(posedge clk) begin
    ar_d  <= ar;
    ar_dd <= ar_d;
    ai_d  <= ai;
    ai_dd <= ai_d;
    br_d  <= br;
    bi_d  <= bi;
    bi_dd <= bi_d;
  end

  // DSP1
  // Common factor (ar - ai) * bi, shared for the calculations of the real and
  // imaginary final products
  always @(posedge clk) begin
    addcommon <= ar_d - ai_d;
    multc     <= addcommon * bi_dd;
    pc_out    <= multc + pc_in;
  end

  // DSP2
  // Real product ar * (br - bi) + (ar - ai) * bi = ar * br - ai * bi
  always @(posedge clk) begin
    addr   <= br_d - bi_d;
    multr  <= addr * ar_dd;
    pr_out <= multr + pr_in;
  end

  // DSP3
  // Imaginary product ai * (br + bi) + (ar - ai) * bi = ai * br + ar + bi
  always @(posedge clk) begin
    addi   <= br_d + bi_d;
    multi  <= addi * ai_dd;
    pi_out <= multi + pi_in;
  end

endmodule

`default_nettype wire
