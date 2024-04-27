// File: cmult.sv
// Brief: 3-DSP complex multiplier.
`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult #(
    parameter int A_WIDTH = 16,
    parameter int B_WIDTH = 16,
    parameter int P_WIDTH = 16,
    parameter int SHIFT   = 15
) (
    input var                clk,
    input var                rst,
    //
    input var  [A_WIDTH-1:0] ar,
    input var  [A_WIDTH-1:0] ai,
    //
    input var  [B_WIDTH-1:0] br,
    input var  [B_WIDTH-1:0] bi,
    //
    output var [P_WIDTH-1:0] pr,
    output var [P_WIDTH-1:0] pi,
    // Overflow indicator
    output var               ovf
);

  localparam int Latency = 7;
  localparam int FullWidth = A_WIDTH + B_WIDTH + 1;
  localparam int SignExp = P_WIDTH + SHIFT - FullWidth;

  localparam logic signed [FullWidth-1:0] Rng = SHIFT == 0 ? '0 : (1 << (SHIFT - 1));

  logic signed [A_WIDTH-1:0] ar_d;
  logic signed [A_WIDTH-1:0] ar_dd;
  logic signed [A_WIDTH-1:0] ar_ddd;
  logic signed [A_WIDTH-1:0] ar_dddd;
  logic signed [A_WIDTH-1:0] ar_ddddd;

  logic signed [A_WIDTH-1:0] ai_d;
  logic signed [A_WIDTH-1:0] ai_dd;
  logic signed [A_WIDTH-1:0] ai_ddd;
  logic signed [A_WIDTH-1:0] ai_dddd;
  logic signed [A_WIDTH-1:0] ai_ddddd;

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
  logic signed [FullWidth-1:0] pr_int;
  logic signed [FullWidth-1:0] pi_int;
  logic signed [FullWidth-1:0] common;
  logic signed [FullWidth-1:0] common_d;
  logic signed [FullWidth-1:0] commonr1;
  logic signed [FullWidth-1:0] commonr2;

  // Delay taps, tools will automatically absorb registers into DSP and
  // duplicate if needed
  always_ff @(posedge clk) begin
    ar_d     <= ar;
    ar_dd    <= ar_d;
    ar_ddd   <= ar_dd;
    ar_dddd  <= ar_ddd;
    ar_ddddd <= ar_dddd;
    ai_d     <= ai;
    ai_dd    <= ai_d;
    ai_ddd   <= ai_dd;
    ai_dddd  <= ai_ddd;
    ai_ddddd <= ai_dddd;
    br_d     <= br;
    br_dd    <= br_d;
    br_ddd   <= br_dd;
    br_dddd  <= br_ddd;
    bi_d     <= bi;
    bi_dd    <= bi_d;
    bi_ddd   <= bi_dd;
    bi_dddd  <= bi_ddd;
    common_d <= common;
    commonr1 <= common_d;
    commonr2 <= common_d;
  end

  // Common factor (ar - ai) x bi, shared for the calculations of the real and imaginary final products
  always @(posedge clk) begin
    addcommon <= ar_d - ai_d;
    mult0     <= addcommon * bi_dd;
    common    <= mult0 + Rng;
  end

  // Real product ar * (br - bi) + (ar - ai) * bi = ar * br - ai * bi
  always @(posedge clk) begin
    addr   <= br_dddd - bi_dddd;
    multr  <= addr * ar_dddd;
    pr_int <= multr + commonr1;
  end

  // Imaginary product ai * (br + bi) + (ar - ai) * bi = ai * br + ar + bi
  always @(posedge clk) begin
    addi   <= br_dddd + bi_dddd;
    multi  <= addi * ai_dddd;
    pi_int <= multi + commonr2;
  end

  generate
    if (SignExp > 0) begin : g_no_sgexp
      assign pr = {{SignExp{pr_int[FullWidth-1]}}, pr_int[FullWidth-1:SHIFT]};
      assign pi = {{SignExp{pr_int[FullWidth-1]}}, pi_int[FullWidth-1:SHIFT]};
    end else begin : g_sgexp
      assign pr = pr_int[SHIFT+P_WIDTH-1:SHIFT];
      assign pi = pi_int[SHIFT+P_WIDTH-1:SHIFT];
    end
  endgenerate

  generate
    if (SignExp >= 0) begin : g_no_ovf

      assign ovf = 1'b0;

    end else begin : g_ovf

      assign ovf =
        ~(pr_int[FullWidth-1:P_WIDTH+SHIFT-1] == '1 ||
        pr_int[FullWidth-1:P_WIDTH+SHIFT-1] == '0) ||
        ~(pi_int[FullWidth-1:P_WIDTH+SHIFT-1] == '1 ||
        pi_int[FullWidth-1:P_WIDTH+SHIFT-1] == '0);

    end
  endgenerate

endmodule

`default_nettype wire
