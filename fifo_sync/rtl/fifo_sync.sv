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
  localparam int RamLatency = FIFO_LATENCY >= 2 ? 2 : 1;
  localparam bit FabricReg = FIFO_LATENCY >= 3;


  // DRC
  //====

  initial begin : drc_check
    assert (4 <= FIFO_DEPTH && FIFO_DEPTH <= 32768 && (FIFO_DEPTH & (FIFO_DEPTH - 1)) == 0)
    else begin
      $fatal(1, "FIFO_DEPTH must be a power of two within the range 4 to 32768, got %0d.",
             FIFO_DEPTH);
    end

    assert (1 <= FIFO_LATENCY && FIFO_LATENCY <= 3)
    else begin
      $fatal(1, "FIFO_LATENCY must be within the range 1 to 3, got %0d.", FIFO_LATENCY);
    end

    assert (1 <= DATA_WIDTH && DATA_WIDTH <= 4096)
    else begin
      $fatal(1, "DATA_WIDTH must be within the range 1 to 4096, got %0d.", DATA_WIDTH);
    end

    assert (FWFT_MODE)
    else begin
      $fatal(1, "fifo_sync only supports FWFT_MODE=1.");
    end
  end


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

  logic [  DATA_WIDTH-1:0] rd_data;
  logic [  FIFO_LATENCY:0] valid;


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


  // Read pipeline enables

  generate
    for (genvar i = 0; i < FIFO_LATENCY; i++) begin : g_rd_en_mem
      assign rd_en_mem[i] = valid[i] && (~&valid[FIFO_LATENCY:i+1] || rden);
    end
  endgenerate


  // Valid flags

  generate
    for (genvar i = 0; i <= FIFO_LATENCY; i++) begin : g_valid
      if (i == 0) begin : g_first
        always_ff @(posedge clk) begin
          if (rst) begin
            valid[0] <= 1'b0;
          end else if (wr_count_next == rd_count_next) begin
            valid[0] <= 1'b0;
          end else begin
            valid[0] <= 1'b1;
          end
        end
      end else begin : g_left
        always_ff @(posedge clk) begin
          if (rst) begin
            valid[i] <= 1'b0;
          end else if (~&valid[FIFO_LATENCY:i] || rden) begin
            valid[i] <= valid[i-1];
          end else begin
            valid[i] <= valid[i];
          end
        end
      end
    end
  endgenerate

  assign empty = !valid[FIFO_LATENCY];


  // Full flag

  always_ff @(posedge clk) begin
    if (rst) begin
      full <= 1'b1;
    end else if ((wr_count_next[AddrWidth-1:0] == rd_count_next[AddrWidth-1:0]) &&
      (wr_count_next[AddrWidth] != rd_count_next[AddrWidth])) begin
      full <= 1'b1;
    end else begin
      full <= 1'b0;
    end
  end


  // The dual-port memory

  ram_sdp #(
      .ADDR_WIDTH  (AddrWidth),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(RamLatency),
      .INIT_WORD   ('0),
      .INIT_FILE   ("")
  ) i_ram (
      .clka (clk),
      .ena  (wr_en_mem),
      .wea  (wr_en_mem),
      .addra(wr_addr),
      .dina (din),
      //
      .clkb (clk),
      .rstb ({RamLatency{rst}}),
      .enb  (rd_en_mem[RamLatency-1:0]),
      .addrb(rd_addr),
      .doutb(rd_data)
  );

  generate
    if (!FabricReg) begin : g_no_reg
      always_comb begin
        dout = rd_data;
      end
    end else begin : g_reg
      always_ff @(posedge clk) begin
        if (rst) begin
          dout <= '0;
        end else if (rd_en_mem[2]) begin
          dout <= rd_data;
        end
      end
    end
  endgenerate

endmodule

`default_nettype wire
