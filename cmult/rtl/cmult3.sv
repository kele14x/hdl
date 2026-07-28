`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult3 #(
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 16,
    parameter int SHIFT    = 15,
    parameter bit ROUND    = 1'b0,
    parameter bit SATURATE = 1'b0
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
  localparam int Latency = 7;
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

  logic signed [  A_WIDTH-1:0] ar_d;
  logic signed [  A_WIDTH-1:0] ar_dd;
  logic signed [  A_WIDTH-1:0] ar_ddd;
  logic signed [  A_WIDTH-1:0] ar_dddd;

  logic signed [  A_WIDTH-1:0] ai_d;
  logic signed [  A_WIDTH-1:0] ai_dd;
  logic signed [  A_WIDTH-1:0] ai_ddd;
  logic signed [  A_WIDTH-1:0] ai_dddd;

  logic signed [  B_WIDTH-1:0] br_d;
  logic signed [  B_WIDTH-1:0] br_dd;
  logic signed [  B_WIDTH-1:0] br_ddd;

  logic signed [  B_WIDTH-1:0] bi_d;
  logic signed [  B_WIDTH-1:0] bi_dd;
  logic signed [  B_WIDTH-1:0] bi_ddd;

  logic signed [    A_WIDTH:0] addcommon;

  logic signed [    B_WIDTH:0] addr;
  logic signed [    B_WIDTH:0] addi;

  logic signed [FullWidth-1:0] mult0;
  logic signed [FullWidth-1:0] multr;
  logic signed [FullWidth-1:0] multi;
  logic signed [FullWidth-1:0] pr_int;
  logic signed [FullWidth-1:0] pi_int;
  logic signed [FullWidth-1:0] common;
  logic signed [FullWidth-1:0] commonr1;
  logic signed [FullWidth-1:0] commonr2;

  logic signed [  P_WIDTH-1:0] pr_ext;
  logic signed [  P_WIDTH-1:0] pr_sat;
  logic signed [  P_WIDTH-1:0] pr_reg;

  logic signed [  P_WIDTH-1:0] pi_ext;
  logic signed [  P_WIDTH-1:0] pi_sat;
  logic signed [  P_WIDTH-1:0] pi_reg;

  logic                        pr_ovf_s;
  logic                        pi_ovf_s;
  logic                        ovf_r;
  logic                        pr_overflow;
  logic                        pi_overflow;
  logic                        pr_underflow;
  logic                        pi_underflow;

  // Delay taps, tools will automatically absorb registers into DSP and
  // duplicate if needed
  always_ff @(posedge clk) begin
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
  always_ff @(posedge clk) begin
    addcommon <= ar_d - ai_d;
    mult0     <= addcommon * bi_dd;
    common    <= mult0 + Rng;
  end

  // Real product ar * (br - bi) + (ar - ai) * bi = ar * br - ai * bi
  always_ff @(posedge clk) begin
    addr   <= br_ddd - bi_ddd;
    multr  <= addr * ar_dddd;
    pr_int <= multr + commonr1;
  end

  // Imaginary product ai * (br + bi) + (ar - ai) * bi = ai * br + ar + bi
  always_ff @(posedge clk) begin
    addi   <= br_ddd + bi_ddd;
    multi  <= addi * ai_dddd;
    pi_int <= multi + commonr2;
  end

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
