`timescale 1 ns / 1 ps
//
`default_nettype none

module shift_ram #(
    parameter int WIDTH       = 8,
    parameter int DEPTH       = 8,
    parameter int PACKED_URAM = 0,
    parameter     RAM_STYLE   = "AUTO"
) (
    input var              clk,
    input var              rst,
    input var              cen,
    //
    input var  [WIDTH-1:0] din,
    output var [WIDTH-1:0] dout
);

  // Local parameters

  // One input register, two RAM read stages, and one output register account
  // for four cycles of the requested delay. The remaining delay is stored in
  // a read-first circular RAM.
  localparam int RamDepth = DEPTH - 4;
  localparam int AddrWidth = RamDepth > 1 ? $clog2(RamDepth) : 1;
  localparam int RamReadLatency = 2;

  // Check parameters

  initial begin : drc_check
    assert (DEPTH >= 5 && DEPTH <= 16384)
    else $error("[%m]: DEPTH (%0d) must be within the range 5 to 16384.", DEPTH);

    assert (PACKED_URAM == 0 || PACKED_URAM == 1)
    else $error("[%m]: PACKED_URAM (%0d) must be 0 or 1.", PACKED_URAM);

    assert (PACKED_URAM == 0 || (WIDTH == 36 && DEPTH == 8192))
    else $error("[%m]: PACKED_URAM requires WIDTH=36 and DEPTH=8192.");
  end

  // Signals

  logic [     AddrWidth-1:0] addr;
  logic [         WIDTH-1:0] dina;
  logic [         WIDTH-1:0] ram_dout;
  logic [RamReadLatency-1:0] vld;

  // Shared read/write address. Count down so the non-power-of-two wrap detects
  // zero rather than comparing against a wide terminal-count constant.

  always_ff @(posedge clk) begin
    if (rst) begin
      addr <= {AddrWidth{1'b0}};
    end else if (cen) begin
      if (addr == {AddrWidth{1'b0}}) begin
        addr <= AddrWidth'(RamDepth - 1);
      end else begin
        addr <= addr - 1'b1;
      end
    end
  end

  // Register data before it reaches the RAM input.
  always_ff @(posedge clk) begin
    if (cen) begin
      dina <= din;
    end
  end

  generate
    if (PACKED_URAM != 0) begin : g_packed_uram
      ram_sp_uram_8k36 i_ram_sp (
          .clk (clk),
          .en  ({RamReadLatency{cen}}),
          .we  (cen),
          .addr(addr),
          .din (dina),
          .dout(ram_dout)
      );
    end else begin : g_standard_ram
      ram_sp #(
          .ADDR_WIDTH  (AddrWidth),
          .DATA_WIDTH  (WIDTH),
          .WRITE_MODE  ("READ_FIRST"),
          .READ_LATENCY(RamReadLatency),
          .DEPTH       (RamDepth),
          .INIT_FILE   ("NONE"),
          .RAM_STYLE   (RAM_STYLE)
      ) i_ram_sp (
          .clk (clk),
          .rst (1'b0),
          .en  ({RamReadLatency{cen}}),
          .we  (cen),
          .addr(addr),
          .din (dina),
          .dout(ram_dout)
      );
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (rst) begin
      vld <= {RamReadLatency{1'b0}};
    end else if (cen) begin
      vld <= {vld[RamReadLatency-2:0], 1'b1};
    end
  end

  // vld only clears on reset and fills monotonically while cen is active.
  // Holding the reset value until the first valid word is equivalent to the
  // previous width-wide output mask, while allowing the data register CE to
  // absorb the valid control.
  always_ff @(posedge clk) begin
    if (rst) begin
      dout <= {WIDTH{1'b0}};
    end else if (cen && vld[RamReadLatency-1]) begin
      dout <= ram_dout;
    end
  end

endmodule

`default_nettype wire
