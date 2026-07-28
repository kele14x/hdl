// File: cmult_chain_stage.sv
// Brief: Single DSP stage for Complex Multiplier Chain module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult_chain_stage #(
    parameter int A_WIDTH = 16,
    parameter int B_WIDTH = 16,
    parameter int P_WIDTH = 36
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
    input var  signed [P_WIDTH-1:0] pc_in,
    input var  signed [P_WIDTH-1:0] pr_in,
    input var  signed [P_WIDTH-1:0] pi_in,
    //
    output var signed [P_WIDTH-1:0] pc_out,
    output var signed [P_WIDTH-1:0] pr_out,
    output var signed [P_WIDTH-1:0] pi_out
);


  localparam int MultWidth = A_WIDTH + B_WIDTH + 1;

  logic signed [P_WIDTH-1:0] multc_ext, multr_ext, multi_ext;
  logic [P_WIDTH-1:0] rst_mask;


  logic signed [A_WIDTH-1:0] ar_d, ar_dd;
  logic signed [A_WIDTH-1:0] ai_d, ai_dd;

  logic signed [B_WIDTH-1:0] br_d;
  logic signed [B_WIDTH-1:0] bi_d, bi_dd;

  logic signed [A_WIDTH:0] addcommon;
  logic signed [B_WIDTH:0] addr, addi;
  logic signed [A_WIDTH+B_WIDTH:0] multc, multr, multi;

  // Delay taps, tools will automatically absorb registers into DSP and
  // duplicate if needed
  always_ff @(posedge clk) begin
    ar_d  <= ar;
    ar_dd <= ar_d;
    ai_d  <= ai;
    ai_dd <= ai_d;
    br_d  <= br;
    bi_d  <= bi;
    bi_dd <= bi_d;
  end

  assign multc_ext = {{(P_WIDTH-MultWidth){multc[MultWidth-1]}}, multc};
  assign multr_ext = {{(P_WIDTH-MultWidth){multr[MultWidth-1]}}, multr};
  assign multi_ext = {{(P_WIDTH-MultWidth){multi[MultWidth-1]}}, multi};
  assign rst_mask = {P_WIDTH{rst & 1'b0}};

  // DSP1
  // Common factor (ar - ai) * bi, shared for the calculations of the real and
  // imaginary final products
  always_ff @(posedge clk) begin
    addcommon <= ar_d - ai_d;
    multc     <= addcommon * bi_dd;
    pc_out    <= multc_ext + pc_in + rst_mask;
  end

  // DSP2
  // Real product ar * (br - bi) + (ar - ai) * bi = ar * br - ai * bi
  always_ff @(posedge clk) begin
    addr   <= br_d - bi_d;
    multr  <= addr * ar_dd;
    pr_out <= multr_ext + pr_in;
  end

  // DSP3
  // Imaginary product ai * (br + bi) + (ar - ai) * bi = ai * br + ar + bi
  always_ff @(posedge clk) begin
    addi   <= br_d + bi_d;
    multi  <= addi * ai_dd;
    pi_out <= multi_ext + pi_in;
  end

endmodule

`default_nettype wire
