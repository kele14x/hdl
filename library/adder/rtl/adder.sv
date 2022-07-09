// File: adder.sv
// Brief: Simple signed adder.
`timescale 1 ns / 1 ps
//
`default_nettype none

module adder #(
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 17,
    parameter int SRA_BITS = 0
) (
    input var                       clk,
    input var                       rst,
    input var  signed [A_WIDTH-1:0] a,
    input var  signed [B_WIDTH-1:0] b,
    input var                       sub,
    output var signed [P_WIDTH-1:0] p,
    output var                      ovf
);

  localparam integer FullWidth = (A_WIDTH >= B_WIDTH) ? A_WIDTH + 1 : B_WIDTH + 1;

  wire signed [FullWidth-1:0] p_full;

  // Full adder without truncate or sign expansion
  assign p_full = sub ? a - b : a + b;

  // Sign expansion and truncate
  always @(posedge clk) begin
    p <= (p_full >>> SRA_BITS);
  end

  // Overflow indicator
  generate
    if (P_WIDTH + SRA_BITS >= FullWidth) begin : g_no_ovf
      initial begin
        ovf = 1'b0;
      end
    end else begin : g_ovf
      always @(posedge clk) begin
        if (p_full[FullWidth-1:P_WIDTH+SRA_BITS-1] == '0) begin
          ovf <= 1'b0;
        end else if (p_full[FullWidth-1:P_WIDTH+SRA_BITS-1] == '1) begin
          ovf <= 1'b0;
        end else begin
          ovf <= 1'b1;
        end
      end
    end
  endgenerate

endmodule

`default_nettype wire
