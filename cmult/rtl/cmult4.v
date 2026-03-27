`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult4 #(
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

  localparam integer Latency = 5;
  localparam integer FullWidth = A_WIDTH + B_WIDTH + 1;
  localparam integer SignExp = P_WIDTH + SHIFT - FullWidth;

  localparam signed [FullWidth-1:0] Rng = (ROUND && (SHIFT > 0)) ? (1 << (SHIFT - 1)) : 0;

  // Signals

  reg signed  [  A_WIDTH-1:0] ar_d;
  reg signed  [  A_WIDTH-1:0] ar_dd;

  reg signed  [  A_WIDTH-1:0] ai_d;
  reg signed  [  A_WIDTH-1:0] ai_dd;

  reg signed  [  B_WIDTH-1:0] br_d;
  reg signed  [  B_WIDTH-1:0] br_dd;

  reg signed  [  B_WIDTH-1:0] bi_d;

  reg signed  [FullWidth-1:0] m_rr;
  reg signed  [FullWidth-1:0] p_rr;
  reg signed  [FullWidth-1:0] m_ii;
  reg signed  [FullWidth-1:0] p_ii;
  wire signed [FullWidth-1:0] pr_int;

  reg signed  [FullWidth-1:0] m_ri;
  reg signed  [FullWidth-1:0] p_ri;
  reg signed  [FullWidth-1:0] m_ir;
  reg signed  [FullWidth-1:0] p_ir;
  wire signed [FullWidth-1:0] pi_int;

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

  always @(posedge clk) begin
    ar_d  <= ar;
    ar_dd <= ar_d;
    ai_d  <= ai;
    ai_dd <= ai_d;
    br_d  <= br;
    br_dd <= br_d;
    bi_d  <= bi;
  end

  // Real component
  always @(posedge clk) begin
    m_ii <= ai_d * bi_d;
    p_ii <= m_ii - Rng;
  end

  always @(posedge clk) begin
    m_rr <= ar_dd * br_dd;
    p_rr <= m_rr - p_ii;
  end

  // Imaginary component
  always @(posedge clk) begin
    m_ri <= ar_d * bi_d;
    p_ri <= m_ri + Rng;
  end

  always @(posedge clk) begin
    m_ir <= ai_dd * br_dd;
    p_ir <= m_ir + p_ri;
  end

  // Sign extension and truncate
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
