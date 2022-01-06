// File: cmult_chain.sv
// Brief: Complex multiplier, chained together

`timescale 1 ns / 1 ps `default_nettype none

module cmult_chain_pe #(
    parameter int AWIDTH = 16,
    parameter int BWIDTH = 16,
    parameter int PWIDTH = 48
) (
    input var  logic                     clk,
    input var  logic                     rst,
    //
    input var  logic signed [AWIDTH-1:0] ar,
    input var  logic signed [AWIDTH-1:0] ai,
    //
    input var  logic signed [BWIDTH-1:0] br,
    input var  logic signed [BWIDTH-1:0] bi,
    //
    input var  logic signed [PWIDTH-1:0] pc_in,
    input var  logic signed [PWIDTH-1:0] pr_in,
    input var  logic signed [PWIDTH-1:0] pi_in,
    //
    output var logic signed [PWIDTH-1:0] pc_out,
    output var logic signed [PWIDTH-1:0] pr_out,
    output var logic signed [PWIDTH-1:0] pi_out
);


  localparam int Latency = 4;

  logic signed [AWIDTH-1:0] ar_d, ar_dd;
  logic signed [AWIDTH-1:0] ai_d, ai_dd;

  logic signed [BWIDTH-1:0] br_d;
  logic signed [BWIDTH-1:0] bi_d, bi_dd;

  logic signed [AWIDTH:0] addcommon;
  logic signed [BWIDTH:0] addr, addi;
  logic signed [AWIDTH+BWIDTH:0] mult0, multr, multi;

  // Delay taps, tools will automatically absorb registers into DSP and
  // duplicate if needed
  always_ff @(posedge clk) begin
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
  always_ff @(posedge clk) begin
    addcommon <= ar_d - ai_d;
    mult0     <= addcommon * bi_dd;
    pc_out    <= mult0 + $signed(pc_in);
  end

  // DSP2
  // Real product ar * (br - bi) + (ar - ai) * bi = ar * br - ai * bi
  always_ff @(posedge clk) begin
    addr   <= br_d - bi_d;
    multr  <= addr * ar_dd;
    pr_out <= multr + $signed(pr_in);
  end

  // DSP3
  // Imaginary product ai * (br + bi) + (ar - ai) * bi = ai * br + ar + bi
  always_ff @(posedge clk) begin
    addi   <= br_d + bi_d;
    multi  <= addi * ai_dd;
    pi_out <= multi + $signed(pi_in);
  end

endmodule

`default_nettype wire
