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
  //=================

  localparam int AddrWidth = $clog2(FIFO_DEPTH);


  // Signals
  //========

  logic [AddrWidth-1:0] addr;
  logic [AddrWidth-1:0] addr_next;

  logic shift;
  logic full_next;
  logic empty_next;

  // Main
  //=====

  // SRL address pointer

  always_ff @(posedge clk) begin
    if (rst) begin
      addr <= '0;
    end else begin
      addr <= addr_next;
    end
  end

  always_comb begin
    if (addr == '0) begin // FIFO could be empty or not empty
      if (!empty && wren && !rden) begin
        addr_next = addr + 1;
      end else begin
        addr_next = addr;
      end
    end else if (addr == '1) begin // FIFO is full
      if (rden) begin
        addr_next = addr - 1;
      end else begin
        addr_next = addr;
      end
    end else begin // not full or empty
      if (!wren && rden) begin
        addr_next = addr - 1;
      end else if (wren && !rden) begin
        addr_next = addr + 1;
      end else begin
        addr_next = addr;
      end
    end
  end

  // Full flag

  always_ff @(posedge clk) begin
    if (rst) begin
      full <= 1'b1;
    end else begin
      full <= full_next;
    end
  end

  always_comb begin
    if (addr_next == '1) begin
      full_next = 1'b1;
    end else begin
      full_next = 1'b0;
    end
  end

  // Empty flag

  always_ff @(posedge clk) begin
    if (rst) begin
      empty <= 1'b1;
    end else begin
      empty <= empty_next;
    end
  end

  always_comb begin
    if (addr_next != '0 || wren) begin
      empty_next = 1'b0;
    end else if (rden && addr == '0) begin
      empty_next = 1'b1;
    end else begin
      empty_next = empty;
    end
  end

  assign shift = (wren && !full);


  srl #(
      .SIM_INIT  (1'b1),
      .OUTPU_REG (1'b0),
      .ADDR_WIDTH(AddrWidth),
      .DATA_WIDTH(DATA_WIDTH)
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


  //

  covergroup cg @(posedge clk);
    c1: coverpoint addr;
  endgroup

  cg cover_inst = new();

endmodule

`default_nettype wire
