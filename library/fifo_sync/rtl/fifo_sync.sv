// File: fifo_sync.sv
// Brief: First-word fall-through (FWFT) FIFO.
`timescale 1 ns / 1 ps
//
`default_nettype none

module fifo_sync #(
    parameter int FIFO_DEPTH   = 512,
    parameter int FIFO_LATENCY = 1,
    parameter int DATA_WIDTH   = 16,
    parameter bit FWFT_MODE    = 1
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

  logic [     AddrWidth:0] wr_count;
  logic [     AddrWidth:0] wr_count_next;
  logic [   AddrWidth-1:0] wr_addr;
  logic                    wr_en_mem;

  logic [     AddrWidth:0] rd_count;
  logic [     AddrWidth:0] rd_count_next;
  logic [   AddrWidth-1:0] rd_addr;
  logic [FIFO_LATENCY-1:0] rd_en_mem;

  // Main
  //=====

  // Write pointer

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_count <= '0;
    end else begin
      wr_count <= wr_count_next;
    end
  end

  always_comb begin
    if (wr_en_mem) begin
      wr_count_next = wr_count + 1;
    end else begin
      wr_count_next = wr_count;
    end
  end

  assign wr_addr   = wr_count[AddrWidth-1:0];

  assign wr_en_mem = !full && wren;


  // Read pointer

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_count <= '0;
    end else begin
      rd_count <= rd_count_next;
    end
  end

  always_comb begin
    if (rd_en_mem[0]) begin
      rd_count_next = rd_count + 1;
    end else begin
      rd_count_next = rd_count;
    end
  end

  assign rd_addr = rd_count[AddrWidth-1:0];

  always @(*) begin
    rd_en_mem[0] = !empty && rden;
  end

  always @(posedge clk) begin
    for (int i = 1; i < FIFO_LATENCY; i++) begin
      rd_en_mem[i] <= rd_en_mem[i-1];
    end
  end


  // Status flag

  always_ff @(posedge clk) begin
    if (rst) begin
      empty <= 1'b0;
    end else if (wr_count_next == rd_count_next) begin
      empty <= 1'b1;
    end else begin
      empty <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      full <= 1'b0;
    end else if ((wr_count_next[AddrWidth-1:0] == rd_count_next[AddrWidth-1:0]) &&
      (wr_count_next[AddrWidth] != rd_count_next[AddrWidth])) begin
      full <= 1'b1;
    end else begin
      full <= 1'b0;
    end
  end

  ram_sdp #(
      .ADDR_WIDTH  (AddrWidth),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(FIFO_LATENCY),
      .INIT_WORD   ('0)
  ) i_ram (
      .clka (clk),
      .ena  (wr_en_mem),
      .wea  (wr_en_mem),
      .addra(wr_addr),
      .dina (din),
      //
      .clkb (clk),
      .rstb (rst),
      .enb  (rd_en_mem),
      .addrb(rd_addr),
      .doutb(dout)
  );

endmodule

`default_nettype wire
