/**
 * Variable Length Shift Register Look-Up Table (LUT) Module
 *
 * This module implements a configurable shift register with selectable depth.
 *
 * Parameters:
 * - ADDR_WIDTH: Width of the address input (default: 4)
 * - DATA_WIDTH: Width of input and output data (default: 8)
 * - OUTPUT_REG: Enable output register (0: disabled, 1: enabled, default: 1)
 * - INIT: Zero-initialize the shift register in simulation (default: 1)
 *
 * Ports:
 * - clk: Clock input
 * - rst: Reset input
 * - cen: Clock enable input
 * - addr: Address input to select shift register depth
 * - din: Input data
 * - dout: Output data
 *
 * Operation:
 * 1. Data is shifted through the register chain on each clock cycle when cen is high
 * 2. The depth of the shift register is dynamically selectable using the addr input
 * 3. The output is taken from the register at the position specified by addr
 * 4. When OUTPUT_REG is 1, an additional output register is used
 *
 * Depth (Latency): addr + 1 clock cycles or addr + 2 clock cycles (with OUTPUT_REG)
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module srl #(
    parameter int ADDR_WIDTH = 4,
    parameter int DATA_WIDTH = 8,
    //
    parameter bit OUTPUT_REG = 1'b1,
    parameter bit INIT       = 1'b1
) (
    // Read Interface
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  cen,
    //
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

  logic [DATA_WIDTH-1:0] dsrl[2**ADDR_WIDTH];

  logic [DATA_WIDTH-1:0] dout_s;

  initial begin
    if (INIT) begin
      for (int i = 0; i < 2 ** ADDR_WIDTH; i = i + 1) begin
        dsrl[i] = 'b0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (cen) begin
      dsrl[0] <= din;
      for (int i = 1; i < 2 ** ADDR_WIDTH; i = i + 1) begin
        dsrl[i] <= dsrl[i-1];
      end
    end
  end

  generate
    if (OUTPUT_REG == 0) begin : g_no_reg

      always_comb begin
        dout_s = dsrl[addr];
      end

    end else begin : g_reg

      always_ff @(posedge clk) begin
        if (rst) begin
          dout_s <= {DATA_WIDTH{1'b0}};
        end else if (cen) begin
          dout_s <= dsrl[addr];
        end
      end

    end
  endgenerate

  assign dout = dout_s;

endmodule

`default_nettype wire
