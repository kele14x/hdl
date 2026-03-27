/**
 * Adder Module
 *
 * This module implements a configurable adder/subtractor with optional shifting and overflow detection.
 *
 * Parameters:
 * - A_WIDTH: Width of input A (default: 16 bits)
 * - B_WIDTH: Width of input B (default: 16 bits)
 * - P_WIDTH: Width of output P (default: 17 bits)
 * - SHIFT: Number of bits to right-shift the result (default: 0)
 *
 * Ports:
 * - clk: Clock input
 * - rst: Reset input (unused in current implementation)
 * - a: Input A
 * - b: Input B
 * - sub: Subtraction control (0 for addition, 1 for subtraction)
 * - p: Output result
 * - ovf: Overflow indicator
 *
 * Operation:
 * 1. Performs addition or subtraction based on 'sub' input
 * 2. Applies right shift if SHIFT > 0
 * 3. Handles sign extension or truncation based on output width
 * 4. Detects overflow when applicable
 *
 * Latency: 1 clock cycle
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module adder #(
    parameter integer A_WIDTH  = 16,
    parameter integer B_WIDTH  = 16,
    parameter integer P_WIDTH  = 17,
    parameter integer SHIFT    = 0,
    //
    parameter reg     ROUND    = 1'b0,
    parameter reg     SATURATE = 1'b0
) (
    input  wire                      clk,
    input  wire                      rst,
    //
    input  wire signed [A_WIDTH-1:0] a,
    input  wire signed [B_WIDTH-1:0] b,
    input  wire                      sub,
    //
    output wire signed [P_WIDTH-1:0] p,
    output wire                      ovf
);

  // Parameters

  localparam integer Latency = 1;
  localparam integer FullWidth = (A_WIDTH >= B_WIDTH) ? A_WIDTH + 1 : B_WIDTH + 1;
  localparam integer SignExp = P_WIDTH + SHIFT - FullWidth;

  localparam signed [FullWidth-1:0] Rng = (ROUND && (SHIFT > 0)) ? (1 << (SHIFT - 1)) : 0;

  // Signals

  wire signed [FullWidth-1:0] p_full;

  wire signed [  P_WIDTH-1:0] p_ext;
  wire signed [  P_WIDTH-1:0] p_sat;
  reg signed  [  P_WIDTH-1:0] p_reg;

  wire                        ovf_s;
  reg                         ovf_r;
  wire                        overflow;
  wire                        underflow;

  // Main

  // Full adder without truncate or sign expansion
  assign p_full = sub ? (a - b + Rng) : (a + b + Rng);

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
