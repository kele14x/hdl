// File: srl.v
// Brief: Addressable Shift Registers.
//        Latency is 2 + addr
`timescale 1 ns / 1 ps
//
`default_nettype none

module srl #(
    parameter integer SIM_INIT   = 1,
    parameter integer ADDR_WIDTH = 4,
    parameter integer DATA_WIDTH = 8
) (
    // Read Interface
    input  wire                  clk,
    input  wire                  cen,
    //
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout
);

  // Put the shifting path in first index
  reg [2**ADDR_WIDTH-1:0] dsrl[DATA_WIDTH];

  generate
    if (SIM_INIT) begin : g_init
      initial begin
        integer i;
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin
          dsrl[i] = 'b0;
        end
      end
    end
  endgenerate

  generate
    gevar i;
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin : g_srl

      always @(posedge clk) begin
        if (cen) begin
          dsrl[i] <= {dsrl[i][2**ADDR_WIDTH-2:0], din[i]};
        end
      end

      always @(posedge clk) begin
        if (cen) begin
          dout[i] <= dsrl[i][addr];
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire
