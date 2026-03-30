`timescale 1 ns / 1 ps
//
`default_nettype none

module adder #(
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 17,
    parameter int SHIFT    = 0,
    //
    parameter bit ROUND    = 1'b0,
    parameter bit SATURATE = 1'b0
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

  localparam int Latency = 1;
  localparam int FullWidth = (A_WIDTH >= B_WIDTH) ? A_WIDTH + 1 : B_WIDTH + 1;
  localparam int SignExp = P_WIDTH + SHIFT - FullWidth;

  localparam signed [FullWidth-1:0] Rng = (ROUND && (SHIFT > 0)) ? (1 << (SHIFT - 1)) : 0;

  logic signed [FullWidth-1:0] a_full;
  logic signed [FullWidth-1:0] b_full;

  logic signed [FullWidth-1:0] p_full;
  logic signed [  P_WIDTH-1:0] p_ext;
  logic signed [  P_WIDTH-1:0] p_sat;
  logic signed [  P_WIDTH-1:0] p_reg;

  logic                        ovf_s;
  logic                        ovf_r;
  logic                        overflow;
  logic                        underflow;

  assign a_full = {{(FullWidth - A_WIDTH) {a[A_WIDTH-1]}}, a};
  assign b_full = {{(FullWidth - B_WIDTH) {b[B_WIDTH-1]}}, b};

  assign p_full = sub ? (a_full - b_full + Rng) : (a_full + b_full + Rng);

  generate
    if (SignExp > 0) begin : g_sgexp
      assign p_ext = {{SignExp{p_full[FullWidth-1]}}, p_full[FullWidth-1:SHIFT]};
    end else begin : g_no_sgexp
      assign p_ext = p_full[P_WIDTH+SHIFT-1:SHIFT];
    end
  endgenerate

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

  always_ff @(posedge clk) begin
    if (rst) begin
      p_reg <= '0;
      ovf_r <= 1'b0;
    end else begin
      p_reg <= p_sat;
      ovf_r <= ovf_s;
    end
  end

  assign p   = p_reg;
  assign ovf = ovf_r;

endmodule

`default_nettype wire
