// File: adder.v
// Brief: Simple adder, usually you does not need this module unless you want a
//        clear hierarchy to help analyzing the synthesis result.
`timescale 1 ns / 1 ps
//
`default_nettype none

module adder #(
    parameter integer A_WIDTH  = 16,
    parameter integer B_WIDTH  = 16,
    parameter integer P_WIDTH  = 17,
    parameter integer SRA_BITS = 0
) (
    input  wire                      clk,
    input  wire                      rst,
    input  wire signed [A_WIDTH-1:0] a,
    input  wire signed [B_WIDTH-1:0] b,
    input  wire                      add_sub,
    output reg  signed [P_WIDTH-1:0] p,
    output reg                       ovf
);

  localparam integer FULL_WIDTH = (A_WIDTH >= B_WIDTH) ? A_WIDTH + 1 : B_WIDTH + 1;

  wire signed [FULL_WIDTH-1:0] p_s;

  // Full adder without truncate or sign expansion
  assign p_s = add_sub ? a - b : a + b;

  // Sign expansion and truncate
  generate
    if (P_WIDTH + SRA_BITS > FULL_WIDTH) begin : g_sign_exp
      always @(posedge clk) begin
        p <= {{P_WIDTH + SRA_BITS - FULL_WIDTH{p_s[FULL_WIDTH-1]}}, p_s[FULL_WIDTH-1:SRA_BITS]};
      end
    end else begin : g_no_exp
      always @(posedge clk) begin
        p <= p_s[P_WIDTH+SRA_BITS-1:SRA_BITS];
      end
    end
  endgenerate

  // Overflow indicator
  generate
    if (P_WIDTH + SRA_BITS >= FULL_WIDTH) begin : g_no_ovf
      initial begin
        ovf = 1'b0;
      end
    end else begin : g_ovf
      always @(posedge clk) begin
        ovf <= ~(&p_s[FULL_WIDTH-1:P_WIDTH+SRA_BITS-1] || &(~p_s[FULL_WIDTH-1:P_WIDTH+SRA_BITS-1]));
      end
    end
  endgenerate

endmodule

`default_nettype wire
