`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult #(
    parameter int A_WIDTH = 16,
    parameter int B_WIDTH = 16,
    parameter int P_WIDTH = 16,
    parameter int SHIFT   = 14
) (
    input var                clk,
    input var                rst_n,
    //
    input var  [A_WIDTH-1:0] ar,
    input var  [A_WIDTH-1:0] ai,
    //
    input var  [B_WIDTH-1:0] br,
    input var  [B_WIDTH-1:0] bi,
    //
    output var [P_WIDTH-1:0] pr,
    output var [P_WIDTH-1:0] pi,
    //
    output var               err_ovf
);

  localparam int Latency = 4;
  localparam int SignExp = SHIFT + P_WIDTH - A_WIDTH - B_WIDTH - 1;
  localparam logic signed [A_WIDTH+B_WIDTH:0] Rng = SHIFT > 0 ? 1 << (SHIFT - 1) : 0;

  logic signed [A_WIDTH-1:0] ar_d1;
  logic signed [A_WIDTH-1:0] ar_d2;
  logic signed [A_WIDTH-1:0] ar_d3;
  logic signed [A_WIDTH-1:0] ai_d1;
  logic signed [A_WIDTH-1:0] ai_d2;
  logic signed [A_WIDTH-1:0] ai_d3;

  logic signed [B_WIDTH-1:0] br_d1;
  logic signed [B_WIDTH-1:0] br_d2;
  logic signed [B_WIDTH-1:0] br_d3;
  logic signed [B_WIDTH-1:0] bi_d1;
  logic signed [B_WIDTH-1:0] bi_d2;
  logic signed [B_WIDTH-1:0] bi_d3;

  logic signed [A_WIDTH+B_WIDTH-1:0] mrr;
  logic signed [A_WIDTH+B_WIDTH-1:0] mri;

  logic signed [A_WIDTH+B_WIDTH-1:0] mir;
  logic signed [A_WIDTH+B_WIDTH-1:0] mii;

  logic signed [A_WIDTH+B_WIDTH:0] pr_int;
  logic signed [A_WIDTH+B_WIDTH:0] pi_int;


  always_ff @(posedge clk) begin
    ar_d1 <= ar;
    ai_d1 <= ai;
    br_d1 <= br;
    bi_d1 <= bi;
    ar_d2 <= ar_d1;
    ai_d2 <= ai_d1;
    br_d2 <= br_d1;
    bi_d2 <= bi_d1;
    ar_d3 <= ar_d2;
    ai_d3 <= ai_d2;
    br_d3 <= br_d2;
    bi_d3 <= bi_d2;
  end

  always_comb begin
    mrr = ar_d3 * br_d3;
    mri = ai_d3 * bi_d3;
  end

  always_comb begin
    mir = ar_d3 * bi_d3;
    mii = ai_d3 * br_d3;
  end

  always_ff @(posedge clk) begin
    pr_int <= mrr - mri + Rng;
    pi_int <= mir + mii + Rng;
  end

  generate
    if (SignExp > 0) begin : g_no_sgexp
      assign pr = {{SignExp{pr_int[A_WIDTH+B_WIDTH]}}, pr_int[A_WIDTH+B_WIDTH:SHIFT]};
      assign pi = {{SignExp{pr_int[A_WIDTH+B_WIDTH]}}, pi_int[A_WIDTH+B_WIDTH:SHIFT]};
    end else begin : g_sgexp
      assign pr = pr_int[SHIFT+P_WIDTH-1:SHIFT];
      assign pi = pi_int[SHIFT+P_WIDTH-1:SHIFT];
    end
  endgenerate

  generate
    if (SignExp >= 0) begin : g_no_ovf

      assign err_ovf = 1'b0;

    end else begin : g_ovf

      assign err_ovf = ~(pr_int[A_WIDTH+B_WIDTH:P_WIDTH+SHIFT-1] == '1 ||
        pr_int[A_WIDTH+B_WIDTH:P_WIDTH+SHIFT-1] == '0) ||
        ~(pi_int[A_WIDTH+B_WIDTH:P_WIDTH+SHIFT-1] == '1 ||
        pi_int[A_WIDTH+B_WIDTH:P_WIDTH+SHIFT-1] == '0);

    end
  endgenerate

endmodule
