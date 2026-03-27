/*
 * Complex Multiplier Module
 *
 * This module performs complex multiplication of two complex numbers:
 * (ar + j*ai) * (br + j*bi) = (ar*br - ai*bi) + j*(ar*bi + ai*br)
 *
 * Parameters:
 *   A_WIDTH: Bit width of input A (ar and ai)
 *   B_WIDTH: Bit width of input B (br and bi)
 *   P_WIDTH: Bit width of output P (pr and pi)
 *   SHIFT:   Number of bits to shift the result (for fixed-point arithmetic)
 *
 * Inputs:
 *   clk:     Clock signal
 *   rst:     Reset signal
 *   ar, ai:  Real and imaginary parts of input A
 *   br, bi:  Real and imaginary parts of input B
 *
 * Outputs:
 *   pr, pi:  Real and imaginary parts of the product
 *   ovf:     Overflow indicator
 *
 * The module uses a 6-stage pipeline to improve performance and timing.
 * It also handles potential overflow conditions and applies appropriate scaling.
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult #(
    parameter integer A_WIDTH  = 16,
    parameter integer B_WIDTH  = 16,
    parameter integer P_WIDTH  = 16,
    parameter integer SHIFT    = 15,
    //
    parameter integer ROUND    = 1'b0,
    parameter integer SATURATE = 1'b0
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
    output wire signed [P_WIDTH-1:0] pr,
    output wire signed [P_WIDTH-1:0] pi,
    //
    output wire                      ovf
);

  // Parameters

  localparam integer Latency = 7;
  localparam integer FullWidth = A_WIDTH + B_WIDTH + 1;
  localparam integer SignExp = P_WIDTH + SHIFT - FullWidth;

  localparam signed [FullWidth-1:0] Rng = (ROUND && (SHIFT > 0)) ? (1 << (SHIFT - 1)) : 0;

  // Registers

  reg signed  [  A_WIDTH-1:0] ar_d;
  reg signed  [  A_WIDTH-1:0] ar_dd;
  reg signed  [  A_WIDTH-1:0] ar_ddd;
  reg signed  [  A_WIDTH-1:0] ar_dddd;

  reg signed  [  A_WIDTH-1:0] ai_d;
  reg signed  [  A_WIDTH-1:0] ai_dd;
  reg signed  [  A_WIDTH-1:0] ai_ddd;
  reg signed  [  A_WIDTH-1:0] ai_dddd;

  reg signed  [  B_WIDTH-1:0] br_d;
  reg signed  [  B_WIDTH-1:0] br_dd;
  reg signed  [  B_WIDTH-1:0] br_ddd;

  reg signed  [  B_WIDTH-1:0] bi_d;
  reg signed  [  B_WIDTH-1:0] bi_dd;
  reg signed  [  B_WIDTH-1:0] bi_ddd;

  reg signed  [    A_WIDTH:0] addcommon;

  reg signed  [    B_WIDTH:0] addr;
  reg signed  [    B_WIDTH:0] addi;

  reg signed  [FullWidth-1:0] mult0;
  reg signed  [FullWidth-1:0] multr;
  reg signed  [FullWidth-1:0] multi;
  reg signed  [FullWidth-1:0] pr_int;
  reg signed  [FullWidth-1:0] pi_int;
  reg signed  [FullWidth-1:0] common;
  reg signed  [FullWidth-1:0] commonr1;
  reg signed  [FullWidth-1:0] commonr2;

  wire signed [  P_WIDTH-1:0] pr_ext;
  wire signed [  P_WIDTH-1:0] pr_sat;
  reg signed  [  P_WIDTH-1:0] pr_reg;

  wire signed [  P_WIDTH-1:0] pi_ext;
  wire signed [  P_WIDTH-1:0] pi_sat;
  reg signed  [  P_WIDTH-1:0] pi_reg;

  wire                        pr_ovf_s;
  wire                        pi_ovf_s;
  reg                         ovf_r;
  wire                        pr_overflow;
  wire                        pi_overflow;
  wire                        pr_underflow;
  wire                        pi_underflow;

  // Main

  // Delay taps, tools will automatically absorb registers into DSP and
  // duplicate if needed
  always @(posedge clk) begin
    ar_d     <= ar;
    ar_dd    <= ar_d;
    ar_ddd   <= ar_dd;
    ar_dddd  <= ar_ddd;
    ai_d     <= ai;
    ai_dd    <= ai_d;
    ai_ddd   <= ai_dd;
    ai_dddd  <= ai_ddd;
    br_d     <= br;
    br_dd    <= br_d;
    br_ddd   <= br_dd;
    bi_d     <= bi;
    bi_dd    <= bi_d;
    bi_ddd   <= bi_dd;
    commonr1 <= common;
    commonr2 <= common;
  end

  // Common factor (ar - ai) x bi, shared for the calculations of the real and imaginary final products
  always @(posedge clk) begin
    addcommon <= ar_d - ai_d;
    mult0     <= addcommon * bi_dd;
    common    <= mult0 + Rng;
  end

  // Real product ar * (br - bi) + (ar - ai) * bi = ar * br - ai * bi
  always @(posedge clk) begin
    addr   <= br_ddd - bi_ddd;
    multr  <= addr * ar_dddd;
    pr_int <= multr + commonr1;
  end

  // Imaginary product ai * (br + bi) + (ar - ai) * bi = ai * br + ar + bi
  always @(posedge clk) begin
    addi   <= br_ddd + bi_ddd;
    multi  <= addi * ai_dddd;
    pi_int <= multi + commonr2;
  end

  // Sign extension and truncate
  generate
    if (SignExp > 0) begin : g_sgexp
      assign pr_ext = {{SignExp{pr_int[FullWidth-1]}}, pr_int[FullWidth-1:SHIFT]};
      assign pi_ext = {{SignExp{pi_int[FullWidth-1]}}, pi_int[FullWidth-1:SHIFT]};
    end else begin : g_no_sgexp
      assign pr_ext = pr_int[SHIFT+P_WIDTH-1:SHIFT];
      assign pi_ext = pi_int[SHIFT+P_WIDTH-1:SHIFT];
    end
  endgenerate

  // Overflow indicator
  generate
    if (SignExp >= 0) begin : g_no_ovf

      assign pr_ovf_s = 1'b0;
      assign pi_ovf_s = 1'b0;
      assign pr_overflow = 1'b0;
      assign pi_overflow = 1'b0;
      assign pr_underflow = 1'b0;
      assign pi_underflow = 1'b0;

    end else begin : g_ovf

      assign pr_ovf_s = ~(&pr_int[FullWidth-1:P_WIDTH+SHIFT-1] || ~|pr_int[FullWidth-1:P_WIDTH+SHIFT-1]);
      assign pi_ovf_s = ~(&pi_int[FullWidth-1:P_WIDTH+SHIFT-1] || ~|pi_int[FullWidth-1:P_WIDTH+SHIFT-1]);
      assign pr_overflow = pr_ovf_s & ~pr_int[FullWidth-1];
      assign pi_overflow = pi_ovf_s & ~pi_int[FullWidth-1];
      assign pr_underflow = pr_ovf_s & pr_int[FullWidth-1];
      assign pi_underflow = pi_ovf_s & pi_int[FullWidth-1];

    end
  endgenerate

  assign pr_sat = (SATURATE && pr_overflow) ? {1'b0, {P_WIDTH - 1{1'b1}}} :
                  (SATURATE && pr_underflow) ? {1'b1, {P_WIDTH - 1{1'b0}}} : pr_ext;
  assign pi_sat = (SATURATE && pi_overflow) ? {1'b0, {P_WIDTH - 1{1'b1}}} :
                  (SATURATE && pi_underflow) ? {1'b1, {P_WIDTH - 1{1'b0}}} : pi_ext;

  always @(posedge clk) begin
    if (rst) begin
      pr_reg <= 0;
      pi_reg <= 0;
      ovf_r  <= 0;
    end else begin
      pr_reg <= pr_sat;
      pi_reg <= pi_sat;
      ovf_r  <= pr_ovf_s || pi_ovf_s;
    end
  end

  assign pr  = pr_reg;
  assign pi  = pi_reg;
  assign ovf = ovf_r;

endmodule

`default_nettype wire
