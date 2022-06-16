// File: cmult.v
// Brief: 3-DSP complex multiplier.
`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult #(
    parameter integer A_WIDTH  = 16,
    parameter integer B_WIDTH  = 16,
    parameter integer P_WIDTH  = 16,
    parameter integer SRA_BITS = 15
) (
    input  wire               clk,
    input  wire               rst,
    //
    input  wire [A_WIDTH-1:0] ar,
    input  wire [A_WIDTH-1:0] ai,
    //
    input  wire [B_WIDTH-1:0] br,
    input  wire [B_WIDTH-1:0] bi,
    //
    output reg  [P_WIDTH-1:0] pr,
    output reg  [P_WIDTH-1:0] pi,
    // Overflow indicator
    output reg                ovf
);


  localparam integer Latency = 8;

  reg signed [A_WIDTH-1:0] ar_d, ar_dd, ar_ddd, ar_dddd, ar_ddddd;
  reg signed [A_WIDTH-1:0] ai_d, ai_dd, ai_ddd, ai_dddd, ai_ddddd;

  reg signed [B_WIDTH-1:0] bi_d, bi_dd, bi_ddd, bi_dddd;
  reg signed [B_WIDTH-1:0] br_d, br_dd, br_ddd, br_dddd;

  reg signed [A_WIDTH:0] addcommon;
  reg signed [B_WIDTH:0] addr, addi;
  reg signed [A_WIDTH+B_WIDTH:0] mult0, multr, multi, pr_int, pi_int;
  reg signed [A_WIDTH+B_WIDTH:0] common, common_d, commonr1, commonr2;

  // Delay taps, tools will automatically absorb registers into DSP and
  // duplicate if needed
  always @(posedge clk) begin
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

  // DSP1
  // Common factor (ar - ai) * bi, shared for the calculations of the real and
  // imaginary final products
  always @(posedge clk) begin
    addcommon <= ar_d - ai_d;
    mult0     <= addcommon * bi_dd;
    common    <= mult0 + (1 << (SRA_BITS - 1));
  end

  // DSP2
  // Real product ar * (br - bi) + (ar - ai) * bi = ar * br - ai * bi
  always @(posedge clk) begin
    addr   <= br_dddd - bi_dddd;
    multr  <= addr * ar_ddddd;
    pr_int <= multr + commonr1;
  end

  // DSP3
  // Imaginary product ai * (br + bi) + (ar - ai) * bi = ai * br + ar + bi
  always @(posedge clk) begin
    addi   <= br_dddd + bi_dddd;
    multi  <= addi * ai_ddddd;
    pi_int <= multi + commonr2;
  end

  always @(posedge clk) begin
    pr <= pr_int[P_WIDTH+SRA_BITS-1:SRA_BITS];
    pi <= pi_int[P_WIDTH+SRA_BITS-1:SRA_BITS];
  end

  generate
    if (P_WIDTH + SRA_BITS >= A_WIDTH + B_WIDTH + 1) begin : g_no_ovf

      // Output is full width, no overflow will happen
      initial begin
        ovf = 'b0;
      end

    end else begin : g_ovf

      always @(posedge clk) begin
        ovf <= ~(&pr_int[A_WIDTH+B_WIDTH:P_WIDTH+SRA_BITS-1] ||
                &(~pr_int[A_WIDTH+B_WIDTH:P_WIDTH+SRA_BITS-1])) || ~(
                &pi_int[A_WIDTH+B_WIDTH:P_WIDTH+SRA_BITS-1] || &(~pi_int[A_WIDTH+B_WIDTH:P_WIDTH+SRA_BITS-1]));
      end

    end
  endgenerate

endmodule

`default_nettype wire
