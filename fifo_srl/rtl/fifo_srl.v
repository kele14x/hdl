/**
 * FIFO (First-In-First-Out) Module using Shift Register LUT (SRL)
 *
 * This module implements a FIFO using a Shift Register LUT for efficient
 * resource utilization in FPGAs.
 *
 * Parameters:
 * - FIFO_DEPTH: Depth of the FIFO (default: 16)
 * - DATA_WIDTH: Width of input and output data (default: 16)
 *
 * Ports:
 * - clk: Clock input
 * - rst: Reset input
 * - wren: Write enable input
 * - din: Input data
 * - full: Full status output
 * - rden: Read enable input
 * - dout: Output data
 * - empty: Empty status output
 *
 * Operation:
 * 1. Data is written to the FIFO when wren is high and the FIFO is not full
 * 2. Data is read from the FIFO when rden is high and the FIFO is not empty
 * 3. The FIFO uses a single SRL to store all data, with a pointer to manage read/write operations
 * 4. Full and empty status signals are provided for external control
 *
 * Note: This implementation is optimized for FPGAs with SRL resources
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module fifo_srl #(
    parameter integer FIFO_DEPTH = 16,
    parameter integer DATA_WIDTH = 16
) (
    // Common to write and read
    input  wire                  clk,
    input  wire                  rst,
    // Write interface
    input  wire                  wren,
    input  wire [DATA_WIDTH-1:0] din,
    output reg                   full,
    // Read interface
    input  wire                  rden,
    output wire [DATA_WIDTH-1:0] dout,
    output reg                   empty
);

  // Local parameters

  localparam integer AddrWidth = $clog2(FIFO_DEPTH);

  // Signals

  // Change logic to reg
  reg  [AddrWidth-1:0] addr;
  reg  [AddrWidth-1:0] addr_next;

  wire                 shift;
  reg                  full_next;
  reg                  empty_next;

  // Main

  // The state of FIFO could be determined by `addr` and `empty`.
  //   Empty     - `empty = 1`, `addr = 0`
  //   1 data    - `empty = 0`, `addr = 0`
  //   2~15 data - `empty = 0`, `15 > addr > 0`
  //   Full      - `empty = 0`, `addr = 15`
  // Other combination of `empty` and `addr` is invalid

  // SRL address pointer
  always @(posedge clk) begin
    if (rst) begin
      addr <= 0;
    end else begin
      addr <= addr_next;
    end
  end

  always @* begin
    if (addr == 0) begin  // FIFO could be empty or not empty
      if (!empty && wren && !rden) begin
        addr_next = addr + 1;
      end else begin
        addr_next = addr;
      end
    end else if (&addr) begin  // FIFO is full
      if (rden) begin
        addr_next = addr - 1;
      end else begin
        addr_next = addr;
      end
    end else begin  // not full or empty
      if (!wren && rden) begin
        addr_next = addr - 1;
      end else if (wren && !rden) begin
        addr_next = addr + 1;
      end else begin
        addr_next = addr;
      end
    end
  end

  // Empty flag

  always @(posedge clk) begin
    if (rst) begin
      empty <= 1'b1;
    end else begin
      empty <= empty_next;
    end
  end

  always @* begin
    if (addr_next != 0 || wren) begin
      empty_next = 1'b0;
    end else if (rden && addr == 0) begin
      empty_next = 1'b1;
    end else begin
      empty_next = empty;
    end
  end

  // Full flag

  always @(posedge clk) begin
    if (rst) begin
      full <= 1'b1;
    end else begin
      full <= full_next;
    end
  end

  always @(*) begin
    if (&addr_next) begin
      full_next = 1'b1;
    end else begin
      full_next = 1'b0;
    end
  end

  // Shift

  assign shift = (wren && !full);

  srl #(
      .ADDR_WIDTH(AddrWidth),
      .DATA_WIDTH(DATA_WIDTH),
      .OUTPUT_REG(1'b0),
      .INIT      (1'b1)
  ) i_srl (
      // Read Interface
      .clk (clk),
      .rst (rst),
      .cen (shift),
      //
      .addr(addr),
      .din (din),
      .dout(dout)
  );

endmodule

`default_nettype wire
