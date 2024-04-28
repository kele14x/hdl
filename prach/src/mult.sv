`timescale 1 ns / 1 ps
//
`default_nettype none

module mult #(
    parameter int A_WIDTH = 16,
    parameter int B_WIDTH = 16,
    parameter int P_WIDTH = 16,
    parameter int SHIFT   = 14
) (
    input var                clk,
    input var                rst_n,
    //
    input var  [A_WIDTH-1:0] a,
    input var  [B_WIDTH-1:0] b,
    output var [P_WIDTH-1:0] p,
    //
    output var               err_ovf
);

  localparam int Latency = 4;
  localparam int SignExp = SHIFT + P_WIDTH - A_WIDTH - B_WIDTH;
  localparam logic signed [A_WIDTH+B_WIDTH-1:0] Rng = SHIFT > 0 ? 1 << (SHIFT - 1) : 0;

  logic signed [A_WIDTH-1:0] a_d1;
  logic signed [A_WIDTH-1:0] a_d2;
  logic signed [A_WIDTH-1:0] a_d3;

  logic signed [B_WIDTH-1:0] b_d1;
  logic signed [B_WIDTH-1:0] b_d2;
  logic signed [B_WIDTH-1:0] b_d3;

  logic signed [A_WIDTH+B_WIDTH-1:0] mult;

  always_ff @(posedge clk) begin
    a_d1 <= a;
    a_d2 <= a_d1;
    a_d3 <= a_d2;
  end

  always_ff @(posedge clk) begin
    b_d1 <= b;
    b_d2 <= b_d1;
    b_d3 <= b_d2;
  end

  always_ff @(posedge clk) begin
    mult <= a_d3 * b_d3 + Rng;
  end

  generate
    if (SignExp > 0) begin : g_no_sgexp
      assign p = {{SignExp{mult[A_WIDTH+B_WIDTH-1]}}, mult[A_WIDTH+B_WIDTH-1:SHIFT]};
    end else begin : g_sgexp
      assign p = mult[SHIFT+P_WIDTH-1:SHIFT];
    end
  endgenerate

  generate
    if (SignExp >= 0) begin : g_no_ovf

      assign err_ovf = 1'b0;

    end else begin : g_ovf

      assign err_ovf = ~(mult[A_WIDTH+B_WIDTH-1:P_WIDTH+SHIFT-1] == '1 ||
        mult[A_WIDTH+B_WIDTH-1:P_WIDTH+SHIFT-1] == '0);

    end
  endgenerate

endmodule
