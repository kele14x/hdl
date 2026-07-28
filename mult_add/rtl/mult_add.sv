`timescale 1 ns / 1 ps
//
`default_nettype none

module mult_add #(
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int C_WIDTH  = 16,
    parameter int P_WIDTH  = 16,
    parameter int SHIFT    = 15,
    //
    parameter int ROUND    = 0,
    parameter int SATURATE = 0
) (
    input  wire                       clk,
    input  wire                       rst,
    //
    input  wire signed [A_WIDTH-1:0]  a,
    input  wire signed [B_WIDTH-1:0]  b,
    input  wire signed [C_WIDTH-1:0]  c,
    //
    output wire signed [P_WIDTH-1:0]  p,
    output wire                       ovf
);

  /* verilator lint_off UNUSEDPARAM */
  localparam int Latency = 4;
  localparam int FullWidth = (A_WIDTH + B_WIDTH > C_WIDTH) ? (A_WIDTH + B_WIDTH + 1) : (C_WIDTH + 1);
  localparam int SignExp = P_WIDTH + SHIFT - FullWidth;

  initial begin : drc_check
    assert (A_WIDTH >= 1)
    else begin
      $error("[%m]: A_WIDTH (%0d) is outside of valid range.", A_WIDTH);
    end

    assert (B_WIDTH >= 1)
    else begin
      $error("[%m]: B_WIDTH (%0d) is outside of valid range.", B_WIDTH);
    end

    assert (C_WIDTH >= 1)
    else begin
      $error("[%m]: C_WIDTH (%0d) is outside of valid range.", C_WIDTH);
    end

    assert (P_WIDTH >= 1)
    else begin
      $error("[%m]: P_WIDTH (%0d) is outside of valid range.", P_WIDTH);
    end

    assert (SHIFT >= 0)
    else begin
      $error("[%m]: SHIFT (%0d) is outside of valid range.", SHIFT);
    end

    assert (ROUND == 0 || ROUND == 1)
    else begin
      $error("[%m]: ROUND (%0d) value is outside of valid range.", ROUND);
    end

    assert (SATURATE == 0 || SATURATE == 1)
    else begin
      $error("[%m]: SATURATE (%0d) value is outside of valid range.", SATURATE);
    end
  end

  localparam logic signed [FullWidth-1:0] Rng = ((ROUND != 0) && (SHIFT > 0)) ? (1 << (SHIFT - 1)) : 0;

  logic signed [  A_WIDTH-1:0] a_d;
  logic signed [  B_WIDTH-1:0] b_d;
  logic signed [  C_WIDTH-1:0] c_d;
  logic signed [  C_WIDTH-1:0] c_dd;
  logic signed [FullWidth-1:0] c_full;

  logic signed [FullWidth-1:0] m;
  logic signed [FullWidth-1:0] p_full;

  logic signed [  P_WIDTH-1:0] p_ext;
  logic signed [  P_WIDTH-1:0] p_sat;
  logic signed [  P_WIDTH-1:0] p_reg;

  logic                        ovf_s;
  logic                        ovf_r;
  logic                        overflow;
  logic                        underflow;

  always_ff @(posedge clk) begin
    a_d <= a;
  end

  always_ff @(posedge clk) begin
    b_d <= b;
  end

  always_ff @(posedge clk) begin
    c_d  <= c;
    c_dd <= c_d;
  end

  assign c_full = {{(FullWidth - C_WIDTH) {c_dd[C_WIDTH-1]}}, c_dd};

  always_ff @(posedge clk) begin
    m <= a_d * b_d;
  end

  always_ff @(posedge clk) begin
    p_full <= m + c_full + Rng;
  end

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

  assign p_sat = ((SATURATE != 0) && overflow) ? {1'b0, {P_WIDTH - 1{1'b1}}} :
                 ((SATURATE != 0) && underflow) ? {1'b1, {P_WIDTH - 1{1'b0}}} : p_ext;

  always_ff @(posedge clk) begin
    if (rst) begin
      p_reg <= '0;
      ovf_r <= '0;
    end else begin
      p_reg <= p_sat;
      ovf_r <= ovf_s;
    end
  end

  assign p   = p_reg;
  assign ovf = ovf_r;

endmodule

`default_nettype wire
