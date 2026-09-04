
// File: fifo_srl.sv
// Brief: First-word fall-through (FWFT) FIFO.
`timescale 1 ns / 1 ps
//
`default_nettype none

module fifo_srl #(
    parameter int FIFO_DEPTH = 16,
    parameter int DATA_WIDTH = 16
) (
    // Common to write and read
    input var                   clk,
    input var                   rst,
    // Write interface
    input var                   wren,
    input var  [DATA_WIDTH-1:0] din,
    output var                  full,
    // Read interface
    input var                   rden,
    output var [DATA_WIDTH-1:0] dout,
    output var                  empty
);

  // Local parameters

  localparam int AddrWidth = $clog2(FIFO_DEPTH);

  // DRC

  initial begin : drc_check
    assert (FIFO_DEPTH >= 4 && FIFO_DEPTH <= 32768)
    else $error("[%m]: FIFO_DEPTH (%0d) is outside of valid range 4-32768.", FIFO_DEPTH);

    assert ((FIFO_DEPTH & (FIFO_DEPTH - 1)) == 0)
    else $error("[%m]: FIFO_DEPTH (%0d) is not a power of 2.", FIFO_DEPTH);

    assert (DATA_WIDTH >= 1 && DATA_WIDTH <= 4096)
    else $error("[%m]: DATA_WIDTH (%0d) is outside of valid range 1-4096.", DATA_WIDTH);
  end

  // Signals

  logic [AddrWidth-1:0] addr;
  logic [AddrWidth-1:0] addr_next;

  logic                 shift;

  logic                 full_r;
  logic                 full_next;

  logic                 empty_r;
  logic                 empty_next;

  // Main

  // The state of FIFO could be determined by `addr` and `empty`.
  //   Empty     - `empty = 1`, `addr = 0`
  //   1 data    - `empty = 0`, `addr = 0`
  //   2~15 data - `empty = 0`, `15 > addr > 0`
  //   Full      - `empty = 0`, `addr = 15`
  // Other combination of `empty` and `addr` is invalid

  // SRL address pointer

  always_ff @(posedge clk) begin
    if (rst) begin
      addr <= '0;
    end else begin
      addr <= addr_next;
    end
  end

  always_comb begin
    if (addr == '0) begin  // FIFO could be empty or not empty
      if (!empty && wren && !rden) begin
        addr_next = addr + 1;
      end else begin
        addr_next = addr;
      end
    end else if (addr == '1) begin  // FIFO is full
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

  always_ff @(posedge clk) begin
    if (rst) begin
      empty_r <= 1'b1;
    end else begin
      empty_r <= empty_next;
    end
  end

  always_comb begin
    if (addr_next != '0 || wren) begin
      empty_next = 1'b0;
    end else if (rden && addr == '0) begin
      empty_next = 1'b1;
    end else begin
      empty_next = empty_r;
    end
  end

  assign empty = empty_r;

  // Full flag

  always_ff @(posedge clk) begin
    if (rst) begin
      full_r <= 1'b1;
    end else begin
      full_r <= full_next;
    end
  end

  always_comb begin
    if (addr_next == '1) begin
      full_next = 1'b1;
    end else begin
      full_next = 1'b0;
    end
  end

  assign full  = full_r;

  // Shift

  assign shift = (wren && !full_r);

  // SRL

  srl #(
      .ADDR_WIDTH(AddrWidth),
      .DATA_WIDTH(DATA_WIDTH),
      .OUTPUT_REG(0)
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
