`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult #(
    parameter int A_WIDTH    = 16,
    parameter int B_WIDTH    = 16,
    parameter int P_WIDTH    = 16,
    parameter int SHIFT      = 15,
    parameter int ROUND      = 0,
    parameter int SATURATE   = 0,
    parameter int USE_3_MULT = 0
) (
    input var                       clk,
    input var                       rst,
    //
    input var  signed [A_WIDTH-1:0] ar,
    input var  signed [A_WIDTH-1:0] ai,
    //
    input var  signed [B_WIDTH-1:0] br,
    input var  signed [B_WIDTH-1:0] bi,
    //
    output var signed [P_WIDTH-1:0] pr,
    output var signed [P_WIDTH-1:0] pi,
    //
    output var                      ovf
);

  /* verilator lint_off UNUSEDPARAM */
  localparam int Latency = (USE_3_MULT != 0) ? 7 : 5;
  /* verilator lint_on UNUSEDPARAM */
  localparam int FullWidth = A_WIDTH + B_WIDTH + 1;

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

    assert (SHIFT < FullWidth)
    else begin
      $error("[%m]: SHIFT (%0d) must be smaller than the full width (%0d).", SHIFT, FullWidth);
    end

    assert (ROUND == 0 || ROUND == 1)
    else begin
      $error("[%m]: ROUND (%0d) value is outside of valid range.", ROUND);
    end

    assert (SATURATE == 0 || SATURATE == 1)
    else begin
      $error("[%m]: SATURATE (%0d) value is outside of valid range.", SATURATE);
    end

    assert (USE_3_MULT == 0 || USE_3_MULT == 1)
    else begin
      $error("[%m]: USE_3_MULT (%0d) value is outside of valid range.", USE_3_MULT);
    end
  end

  logic signed [FullWidth-1:0] pr_int;
  logic signed [FullWidth-1:0] pi_int;

  generate
    if (USE_3_MULT != 0) begin : g_3_mult
      logic signed [A_WIDTH-1:0] ar_d;
      logic signed [A_WIDTH-1:0] ar_dd;
      logic signed [A_WIDTH-1:0] ar_ddd;
      logic signed [A_WIDTH-1:0] ar_dddd;

      logic signed [A_WIDTH-1:0] ai_d;
      logic signed [A_WIDTH-1:0] ai_dd;
      logic signed [A_WIDTH-1:0] ai_ddd;
      logic signed [A_WIDTH-1:0] ai_dddd;

      logic signed [B_WIDTH-1:0] br_d;
      logic signed [B_WIDTH-1:0] br_dd;
      logic signed [B_WIDTH-1:0] br_ddd;

      logic signed [B_WIDTH-1:0] bi_d;
      logic signed [B_WIDTH-1:0] bi_dd;
      logic signed [B_WIDTH-1:0] bi_ddd;

      logic signed [A_WIDTH:0] addcommon;

      logic signed [B_WIDTH:0] addr;
      logic signed [B_WIDTH:0] addi;

      logic signed [FullWidth-1:0] mult0;
      logic signed [FullWidth-1:0] multr;
      logic signed [FullWidth-1:0] multi;
      logic signed [FullWidth-1:0] pr_int_3;
      logic signed [FullWidth-1:0] pi_int_3;
      logic signed [FullWidth-1:0] common;
      logic signed [FullWidth-1:0] commonr1;
      logic signed [FullWidth-1:0] commonr2;

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
        common    <= mult0;
      end

      // Real product ar * (br - bi) + (ar - ai) * bi = ar * br - ai * bi
      always_ff @(posedge clk) begin
        addr     <= br_ddd - bi_ddd;
        multr    <= addr * ar_dddd;
        pr_int_3 <= multr + commonr1;
      end

      // Imaginary product ai * (br + bi) + (ar - ai) * bi = ai * br + ar + bi
      always_ff @(posedge clk) begin
        addi     <= br_ddd + bi_ddd;
        multi    <= addi * ai_dddd;
        pi_int_3 <= multi + commonr2;
      end

      assign pr_int = pr_int_3;
      assign pi_int = pi_int_3;
    end else begin : g_4_mult
      logic signed [  A_WIDTH-1:0] ar_d;
      logic signed [  A_WIDTH-1:0] ar_dd;

      logic signed [  A_WIDTH-1:0] ai_d;
      logic signed [  A_WIDTH-1:0] ai_dd;

      logic signed [  B_WIDTH-1:0] br_d;
      logic signed [  B_WIDTH-1:0] br_dd;

      logic signed [  B_WIDTH-1:0] bi_d;

      logic signed [FullWidth-1:0] m_rr;
      logic signed [FullWidth-1:0] p_rr;
      logic signed [FullWidth-1:0] m_ii;
      logic signed [FullWidth-1:0] p_ii;

      logic signed [FullWidth-1:0] m_ri;
      logic signed [FullWidth-1:0] p_ri;
      logic signed [FullWidth-1:0] m_ir;
      logic signed [FullWidth-1:0] p_ir;

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
        p_ii <= m_ii;
      end

      always_ff @(posedge clk) begin
        m_rr <= ar_dd * br_dd;
        p_rr <= m_rr - p_ii;
      end

      // Imaginary component
      always_ff @(posedge clk) begin
        m_ri <= ar_d * bi_d;
        p_ri <= m_ri;
      end

      always_ff @(posedge clk) begin
        m_ir <= ai_dd * br_dd;
        p_ir <= m_ir + p_ri;
      end

      assign pr_int = p_rr;
      assign pi_int = p_ir;
    end
  endgenerate

  wire signed [P_WIDTH-1:0] pr_sat;
  logic signed [P_WIDTH-1:0] pr_reg;

  wire signed [P_WIDTH-1:0] pi_sat;
  logic signed [P_WIDTH-1:0] pi_reg;

  wire pr_ovf_s;
  wire pi_ovf_s;
  logic ovf_r;

  type_case #(
      .IN_WIDTH (FullWidth),
      .OUT_WIDTH(P_WIDTH),
      .TRUNC    (SHIFT),
      .ROUND    (ROUND),
      .SATURATE (SATURATE)
  ) i_tc_pr (
      .din (pr_int),
      .dout(pr_sat),
      .ovf (pr_ovf_s)
  );

  type_case #(
      .IN_WIDTH (FullWidth),
      .OUT_WIDTH(P_WIDTH),
      .TRUNC    (SHIFT),
      .ROUND    (ROUND),
      .SATURATE (SATURATE)
  ) i_tc_pi (
      .din (pi_int),
      .dout(pi_sat),
      .ovf (pi_ovf_s)
  );

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
