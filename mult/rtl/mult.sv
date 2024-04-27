// File: mult.sv
// Brief: Multiplier
`timescale 1 ns / 1 ps
//
`default_nettype none

module mult #(
    parameter int A_WIDTH = 16,
    parameter int B_WIDTH = 16,
    parameter int P_WIDTH = 16,
    parameter int SHIFT   = 15
) (
    input var                clk,
    input var                rst,
    //
    input var  [A_WIDTH-1:0] a,
    input var  [B_WIDTH-1:0] b,
    output var [P_WIDTH-1:0] p,
    //
    output var               ovf
);

  localparam int Latency = 4;
  localparam int FullWidth = A_WIDTH + B_WIDTH;
  localparam int SignExp = P_WIDTH + SHIFT - FullWidth;

  localparam logic signed [FullWidth-1:0] Rng = SHIFT > 0 ? 1 << (SHIFT - 1) : 0;

  logic signed [  A_WIDTH-1:0] a_d;
  logic signed [  B_WIDTH-1:0] b_d;
  logic signed [FullWidth-1:0] m;
  logic signed [FullWidth-1:0] p_full;

  always_ff @(posedge clk) begin
    a_d <= a;
  end

  always_ff @(posedge clk) begin
    b_d <= b;
  end

  always_ff @(posedge clk) begin
    m <= a_d * b_d + Rng;
  end

  // Full multiplier without truncate or sign expansion
  always_ff @(posedge clk) begin
    p_full <= m;
  end

  // Sign expansion and truncate
  generate
    if (SignExp > 0) begin : g_no_sgexp
      assign p = {{SignExp{p_full[FullWidth-1]}}, p_full[FullWidth-1:SHIFT]};
    end else begin : g_sgexp
      assign p = p_full[P_WIDTH+SHIFT-1:SHIFT];
    end
  endgenerate

  // Overflow indicator
  generate
    if (SignExp >= 0) begin : g_no_ovf

      assign ovf = 1'b0;

    end else begin : g_ovf

      assign ovf = ~(p_full[FullWidth-1:P_WIDTH+SHIFT-1] == '1 ||
        p_full[A_WIDTH+B_WIDTH-1:P_WIDTH+SHIFT-1] == '0);

    end
  endgenerate

endmodule

`default_nettype wire
