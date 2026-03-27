/**
 * Multiplier Module
 *
 * This module implements a configurable multiplier with optional shifting and overflow detection.
 *
 * Parameters:
 * - A_WIDTH: Width of input A (default: 16 bits)
 * - B_WIDTH: Width of input B (default: 16 bits)
 * - P_WIDTH: Width of output P (default: 16 bits)
 * - SHIFT: Number of bits to right-shift the result (default: 15)
 *
 * Ports:
 * - clk: Clock input
 * - rst: Reset input
 * - a: Input A
 * - b: Input B
 * - p: Output result
 * - ovf: Overflow indicator
 *
 * Operation:
 * 1. Performs multiplication of inputs A and B
 * 2. Applies rounding by adding 2^(SHIFT-1) to the result
 * 3. Applies right shift by SHIFT bits
 * 4. Handles sign extension or truncation based on output width
 * 5. Detects overflow when applicable
 *
 * Latency: 4 clock cycles
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module mult_add #(
    parameter A_WIDTH  = 16,
    parameter B_WIDTH  = 16,
    parameter C_WIDTH  = 16,
    parameter P_WIDTH  = 16,
    parameter SHIFT    = 15,
    //
    parameter ROUND    = 1'b0,
    parameter SATURATE = 1'b0
) (
    input  wire                      clk,
    input  wire                      rst,
    //
    input  wire signed [A_WIDTH-1:0] a,
    input  wire signed [B_WIDTH-1:0] b,
    input  wire signed [C_WIDTH-1:0] c,
    //
    output wire signed [P_WIDTH-1:0] p,
    output wire                      ovf
);

  // Parameters

  localparam integer Latency = 4;
  localparam integer FullWidth = A_WIDTH + B_WIDTH > C_WIDTH ? A_WIDTH + B_WIDTH + 1 : C_WIDTH + 1;
  localparam integer SignExp = P_WIDTH + SHIFT - FullWidth;

  localparam signed [FullWidth-1:0] Rng = (ROUND && (SHIFT > 0)) ? (1 << (SHIFT - 1)) : 0;

  // Signals

  reg signed  [  A_WIDTH-1:0] a_d;

  reg signed  [  B_WIDTH-1:0] b_d;

  reg signed  [  C_WIDTH-1:0] c_d;
  reg signed  [  C_WIDTH-1:0] c_dd;

  reg signed  [FullWidth-1:0] m;
  reg signed  [FullWidth-1:0] p_full;

  wire signed [  P_WIDTH-1:0] p_ext;
  wire signed [  P_WIDTH-1:0] p_sat;
  reg signed  [  P_WIDTH-1:0] p_reg;

  wire                        ovf_s;
  reg                         ovf_r;
  wire                        overflow;
  wire                        underflow;

  // Main

  always @(posedge clk) begin
    a_d <= a;
  end

  always @(posedge clk) begin
    b_d <= b;
  end

  always @(posedge clk) begin
    c_d  <= c;
    c_dd <= c_d;
  end

  always @(posedge clk) begin
    m <= a_d * b_d;
  end

  // Full multiplier without truncate or sign expansion
  always @(posedge clk) begin
    p_full <= m + c_dd + Rng;
  end

  // Sign expansion and truncate
  generate
    if (SignExp > 0) begin : g_sgexp

      assign p_ext = {{SignExp{p_full[FullWidth-1]}}, p_full[FullWidth-1:SHIFT]};

    end else begin : g_no_sgexp

      assign p_ext = p_full[P_WIDTH+SHIFT-1:SHIFT];

    end
  endgenerate

  // Overflow indicator
  generate
    if (SignExp >= 0) begin : g_no_ovf

      assign ovf_s = 1'b0;
      assign overflow = 1'b0;
      assign underflow = 1'b0;

    end else begin : g_ovf

      assign ovf_s = ~(&p_full[FullWidth-1:P_WIDTH+SHIFT-1] || ~|p_full[FullWidth-1:P_WIDTH+SHIFT-1]);
      assign overflow = ovf_s & ~p_full[FullWidth-1];
      assign underflow = ovf_s & p_full[FullWidth-1];

    end
  endgenerate

  assign p_sat = (SATURATE && overflow) ? {1'b0, {P_WIDTH - 1{1'b1}}} :
                 (SATURATE && underflow) ? {1'b1, {P_WIDTH - 1{1'b0}}} : p_ext;

  always @(posedge clk) begin
    if (rst) begin
      p_reg <= 0;
      ovf_r <= 0;
    end else begin
      p_reg <= p_sat;
      ovf_r <= ovf_s;
    end
  end

  assign p   = p_reg;
  assign ovf = ovf_r;

endmodule

`default_nettype wire
