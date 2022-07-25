// File: mult.sv
// Brief: Multiplier
`timescale 1 ns / 1 ps
//
`default_nettype none

module mult #(
    parameter integer A_WIDTH  = 16,
    parameter integer B_WIDTH  = 16,
    parameter integer P_WIDTH  = 16,
    parameter integer SRA_BITS = 15
) (
    input var                       clk,
    input var  signed [A_WIDTH-1:0] a,
    input var  signed [B_WIDTH-1:0] b,
    output var signed [P_WIDTH-1:0] p,
    output var                      ovf
);

  localparam integer FullWidth = A_WIDTH + B_WIDTH;

  localparam signed [FullWidth-1:0] Rnd = (1 <<< SRA_BITS - 1);

  logic signed [  A_WIDTH-1:0] ar;
  logic signed [  B_WIDTH-1:0] br;
  logic signed [FullWidth-1:0] mreg;
  logic signed [FullWidth-1:0] preg;

  // Full width multiplier
  always_ff @(posedge clk) begin
    ar   <= a;
    br   <= b;
    mreg <= ar * br;
    preg <= mreg + Rnd;
  end

  // Sign extend and truncate
  always @(posedge clk) begin
    p <= (preg >>> SRA_BITS);
  end

  // Overflow detection
  generate
    if (P_WIDTH + SRA_BITS >= A_WIDTH + B_WIDTH) begin : g_no_ovf
      initial begin
        ovf = 1'b0;
      end
    end else begin : g_ovf
      always @(posedge clk) begin
        if (preg[FullWidth-1:P_WIDTH+SRA_BITS-1] != '0 &&
          preg[FullWidth-1:P_WIDTH+SRA_BITS-1] != '1) begin
          ovf <= 1'b1;
        end else begin
          ovf <= 1'b0;
        end
      end
    end
  endgenerate

endmodule

`default_nettype wire
