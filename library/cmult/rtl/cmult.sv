// File: cmult.sv
// Brief: 3-DSP complex multiplier.
`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult #(
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 16,
    parameter int SRA_BITS = 15
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


  localparam int Latency = 8;

  logic signed [A_WIDTH-1:0] ar_d, ar_dd, ar_ddd, ar_dddd, ar_ddddd;
  logic signed [A_WIDTH-1:0] ai_d, ai_dd, ai_ddd, ai_dddd, ai_ddddd;

  logic signed [B_WIDTH-1:0] bi_d, bi_dd, bi_ddd, bi_dddd;
  logic signed [B_WIDTH-1:0] br_d, br_dd, br_ddd, br_dddd;

  logic signed [A_WIDTH:0] addcommon;
  logic signed [B_WIDTH:0] addr, addi;
  logic signed [A_WIDTH+B_WIDTH:0] mult0, multr, multi, pr_int, pi_int;
  logic signed [A_WIDTH+B_WIDTH:0] common, common_d, commonr1, commonr2;

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

  // DSP1
  // Common factor (ar - ai) * bi, shared for the calculations of the real and
  // imaginary final products
  always_ff @(posedge clk) begin
    addcommon <= ar_d - ai_d;
    mult0     <= addcommon * bi_dd;
    common    <= mult0 + (1 << (SRA_BITS - 1));
  end

  // DSP2
  // Real product ar * (br - bi) + (ar - ai) * bi = ar * br - ai * bi
  always_ff @(posedge clk) begin
    addr   <= br_dddd - bi_dddd;
    multr  <= addr * ar_ddddd;
    pr_int <= multr + commonr1;
  end

  // DSP3
  // Imaginary product ai * (br + bi) + (ar - ai) * bi = ai * br + ar + bi
  always_ff @(posedge clk) begin
    addi   <= br_dddd + bi_dddd;
    multi  <= addi * ai_ddddd;
    pi_int <= multi + commonr2;
  end

  always_ff @(posedge clk) begin
    pr <= pr_int[P_WIDTH+SRA_BITS-1:SRA_BITS];
    pi <= pi_int[P_WIDTH+SRA_BITS-1:SRA_BITS];
  end

  generate
    if (P_WIDTH + SRA_BITS >= A_WIDTH + B_WIDTH + 1) begin : g_no_ovf

      // Output is full width, no overflow will happen
      initial begin
        ovf = '0;
      end

    end else begin : g_ovf

      always_ff @(posedge clk) begin
        if (pr_int[A_WIDTH+B_WIDTH:P_WIDTH+SRA_BITS-1] != '0 &&
          pr_int[A_WIDTH+B_WIDTH:P_WIDTH+SRA_BITS-1] != '1) begin
          ovf <= 1'b1;
        end else if (pi_int[A_WIDTH+B_WIDTH:P_WIDTH+SRA_BITS-1] != '0 &&
          pi_int[A_WIDTH+B_WIDTH:P_WIDTH+SRA_BITS-1] != '1) begin
          ovf <= 1'b1;
        end else begin
          ovf <= 1'b0;
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire
