`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult4 #(
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 16,
    parameter int SHIFT    = 15,
    parameter int ROUND    = 0,
    parameter int SATURATE = 0
) (

    input  logic                      clk,
    input  logic                      rst,
    //
    input  logic signed [A_WIDTH-1:0] ar,
    input  logic signed [A_WIDTH-1:0] ai,
    //
    input  logic signed [B_WIDTH-1:0] br,
    input  logic signed [B_WIDTH-1:0] bi,
    //
    output logic signed [P_WIDTH-1:0] pr,
    output logic signed [P_WIDTH-1:0] pi,
    //
    output logic                      ovf
);

  /* verilator lint_off UNUSEDPARAM */
  localparam int Latency = 5;
  localparam int FullWidth = A_WIDTH + B_WIDTH + 1;
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

  logic signed [A_WIDTH-1:0] ar_d;
  logic signed [A_WIDTH-1:0] ar_dd;

  logic signed [A_WIDTH-1:0] ai_d;
  logic signed [A_WIDTH-1:0] ai_dd;

  logic signed [B_WIDTH-1:0] br_d;
  logic signed [B_WIDTH-1:0] br_dd;

  logic signed [B_WIDTH-1:0] bi_d;

  logic signed [FullWidth-1:0] m_rr;
  logic signed [FullWidth-1:0] p_rr;
  logic signed [FullWidth-1:0] m_ii;
  logic signed [FullWidth-1:0] p_ii;
  logic signed [FullWidth-1:0] pr_int;

  logic signed [FullWidth-1:0] m_ri;
  logic signed [FullWidth-1:0] p_ri;
  logic signed [FullWidth-1:0] m_ir;
  logic signed [FullWidth-1:0] p_ir;
  logic signed [FullWidth-1:0] pi_int;

  logic signed [P_WIDTH-1:0] pr_ext;
  logic signed [P_WIDTH-1:0] pr_sat;
  logic signed [P_WIDTH-1:0] pr_reg;

  logic signed [P_WIDTH-1:0] pi_ext;
  logic signed [P_WIDTH-1:0] pi_sat;
  logic signed [P_WIDTH-1:0] pi_reg;

  logic pr_ovf_s;
  logic pi_ovf_s;
  logic ovf_r;
  logic pr_overflow;
  logic pi_overflow;
  logic pr_underflow;
  logic pi_underflow;

  always_ff @(posedge clk) begin
    ar_d  <= ar;
    ar_dd <= ar_d;
    ai_d  <= ai;
    ai_dd <= ai_d;
    br_d  <= br;
    br_dd <= br_d;
    bi_d  <= bi;
  end

  // Real component
  always_ff @(posedge clk) begin
    m_ii <= ai_d * bi_d;
    p_ii <= m_ii - Rng;
  end

  always_ff @(posedge clk) begin
    m_rr <= ar_dd * br_dd;
    p_rr <= m_rr - p_ii;
  end

  // Imaginary component
  always_ff @(posedge clk) begin
    m_ri <= ar_d * bi_d;
    p_ri <= m_ri + Rng;
  end

  always_ff @(posedge clk) begin
    m_ir <= ai_dd * br_dd;
    p_ir <= m_ir + p_ri;
  end

  assign pr_int = p_rr;
  assign pi_int = p_ir;

  generate
    if (SignExp > 0) begin : g_sgexp
      assign pr_ext = {{SignExp{pr_int[FullWidth-1]}}, pr_int[FullWidth-1:SHIFT]};
      assign pi_ext = {{SignExp{pi_int[FullWidth-1]}}, pi_int[FullWidth-1:SHIFT]};
    end else begin : g_no_sgexp
      assign pr_ext = pr_int[SHIFT+P_WIDTH-1:SHIFT];
      assign pi_ext = pi_int[SHIFT+P_WIDTH-1:SHIFT];
    end
  endgenerate

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

  assign pr_sat = ((SATURATE != 0) && pr_overflow) ? {1'b0, {P_WIDTH - 1{1'b1}}} :
                  ((SATURATE != 0) && pr_underflow) ? {1'b1, {P_WIDTH - 1{1'b0}}} : pr_ext;
  assign pi_sat = ((SATURATE != 0) && pi_overflow) ? {1'b0, {P_WIDTH - 1{1'b1}}} :
                  ((SATURATE != 0) && pi_underflow) ? {1'b1, {P_WIDTH - 1{1'b0}}} : pi_ext;

  always_ff @(posedge clk) begin
    if (rst) begin
      pr_reg <= '0;
      pi_reg <= '0;
      ovf_r  <= '0;
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
