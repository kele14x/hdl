// File: adder.sv
// Brief: Simple signed adder.
`timescale 1 ns / 1 ps
//
`default_nettype none

module adder #(
    parameter int A_WIDTH = 16,
    parameter int B_WIDTH = 16,
    parameter int P_WIDTH = 17,
    parameter int SHIFT   = 0
) (
    input var                       clk,
    input var                       rst,
    //
    input var  signed [A_WIDTH-1:0] a,
    input var  signed [B_WIDTH-1:0] b,
    input var                       sub,
    output var signed [P_WIDTH-1:0] p,
    //
    output var                      ovf
);

  localparam int Latency = 1;
  localparam int FullWidth = (A_WIDTH >= B_WIDTH) ? A_WIDTH + 1 : B_WIDTH + 1;
  localparam int SignExp = P_WIDTH + SHIFT - FullWidth;

  localparam logic signed [FullWidth-1:0] Rng = SHIFT > 0 ? 1 << (SHIFT - 1) : 0;

  logic signed [FullWidth-1:0] p_full;

  // Full adder without truncate or sign expansion
  always @(posedge clk) begin
    p_full <= sub ? a - b : a + b;
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
