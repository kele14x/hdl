/*
 * Asynchronous FIFO (First In First Out)
 *
 * This module implements an asynchronous FIFO (First In First Out) buffer.
 * It allows data to be written and read at different clock domains, providing
 * a mechanism to handle data transfer between systems operating at different
 * clock frequencies. The FIFO depth, latency, and data width are configurable
 * parameters, allowing for flexibility in various applications. The module
 * includes reset synchronization and gray code conversion for safe data
 * transfer between the write and read domains.
 *
 * Interface:
 *   rst         : Asynchronous reset signal, active high. The reset signal is
 *                 synchronized to both the write and read clock domains.
 *   wr_clk      : Write clock signal.
 *   wr_en       : Write enable signal.
 *   wr_din      : Data input for writing to the FIFO.
 *   wr_full     : Flag indicating if the FIFO is full.
 *   rd_clk      : Read clock signal.
 *   rd_en       : Read enable signal.
 *   rd_dout     : Data output for reading from the FIFO.
 *   rd_empty    : Flag indicating if the FIFO is empty.

 * Parameters:
 *   FIFO_DEPTH   : Depth of the FIFO, configurable from 4 to 32768.
 *   FIFO_LATENCY : Latency of the FIFO, configurable from 1 to 3.
 *   DATA_WIDTH   : Width of the data bus, configurable from 1 to 4096.
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module fifo_async #(
    parameter int FIFO_DEPTH   = 512,
    parameter int FIFO_LATENCY = 3,
    parameter int DATA_WIDTH   = 16
) (
    // Common to write and read domain
    input var                   rst,
    // Write interface
    input var                   wr_clk,
    input var                   wr_en,
    input var  [DATA_WIDTH-1:0] wr_din,
    output var                  wr_full,
    // Read interface
    input var                   rd_clk,
    input var                   rd_en,
    output var [DATA_WIDTH-1:0] rd_dout,
    output var                  rd_empty
);

  // Local parameters

  localparam int AddrWidth = $clog2(FIFO_DEPTH);

  localparam logic OutputReg = FIFO_LATENCY >= 2 ? 1 : 0;

  localparam logic FabricReg = FIFO_LATENCY >= 3 ? 1 : 0;

  // Check parameters

  initial begin : drc_check
    assert (FIFO_DEPTH >= 4 && FIFO_DEPTH <= 32768)
    else $error("[%m]: FIFO_DEPTH (%0d) is outside of valid range 4-32768.", FIFO_DEPTH);

    assert ((FIFO_DEPTH & (FIFO_DEPTH - 1)) == 0)
    else $error("[%m]: FIFO_DEPTH (%0d) is not a power of 2.", FIFO_DEPTH);

    assert (FIFO_LATENCY >= 1 && FIFO_LATENCY <= 3)
    else $error("[%m]: FIFO_LATENCY (%0d) is outside of valid range 1-3.", FIFO_LATENCY);

    assert (DATA_WIDTH >= 1 && DATA_WIDTH <= 4096)
    else $error("[%m]: DATA_WIDTH (%0d) is outside of valid range 1-4096.", DATA_WIDTH);
  end

  // Signals

  wire                     wr_rst;

  logic [     AddrWidth:0] wr_count;
  wire  [     AddrWidth:0] wr_count_rd;
  wire  [     AddrWidth:0] wr_count_next;
  wire  [   AddrWidth-1:0] wr_addr;
  wire                     wr_en_mem;

  wire                     rd_rst;

  logic [     AddrWidth:0] rd_count;
  wire  [     AddrWidth:0] rd_count_wr;
  wire  [     AddrWidth:0] rd_count_next;
  wire  [   AddrWidth-1:0] rd_addr;
  wire  [FIFO_LATENCY-1:0] rd_en_mem;

  wire  [  DATA_WIDTH-1:0] rd_dout_s;

  logic [  FIFO_LATENCY:0] valid;

  genvar i;

  // Main

  // Write pointer

  always_ff @(posedge wr_clk) begin
    if (wr_rst) begin
      wr_count <= 0;
    end else begin
      wr_count <= wr_count_next;
    end
  end

  assign wr_count_next = wr_en_mem ? (wr_count + 1'd1) : wr_count;

  assign wr_addr = wr_count[AddrWidth-1:0];

  assign wr_en_mem = !wr_full && wr_en;

  // Full flag

  always_ff @(posedge wr_clk) begin
    if (wr_rst) begin
      wr_full <= 1'b1;
    end else if ((wr_count_next[AddrWidth-1:0] == rd_count_wr[AddrWidth-1:0]) &&
      (wr_count_next[AddrWidth] != rd_count_wr[AddrWidth])) begin
      wr_full <= 1'b1;
    end else begin
      wr_full <= 1'b0;
    end
  end

  // Read pointer

  always_ff @(posedge rd_clk) begin
    if (rd_rst) begin
      rd_count <= 0;
    end else begin
      rd_count <= rd_count_next;
    end
  end

  assign rd_count_next = rd_en_mem[0] ? rd_count + 1'd1 : rd_count;

  assign rd_addr = rd_count[AddrWidth-1:0];

  // RAM read
  // For FIFO, every level of rd_en of output pipeline need to controlled individually.
  // The read enable could be explained as: If there is data at current level and any
  // of down level pipeline is not valid (empty). The data sink's `rden` could be seen
  // as a valid flag

  generate
    for (i = 0; i < FIFO_LATENCY; i = i + 1) begin : g_rd_en_mem
      assign rd_en_mem[i] = valid[i] && (~&valid[FIFO_LATENCY:i+1] || rd_en);
    end
  endgenerate

  // The valid flags

  generate
    for (i = 0; i <= FIFO_LATENCY; i = i + 1) begin : g_valid

      if (i == 0) begin : g_first

        // `Valid[0]` marks there is valid at RAM
        always_ff @(posedge rd_clk) begin
          if (rd_rst) begin
            valid[0] <= 1'b0;
          end else if (rd_count_next == wr_count_rd) begin
            valid[0] <= 1'b0;
          end else begin
            valid[0] <= 1'b1;
          end
        end

      end else begin : g_left

        // Left `valid` marks if the data is valid at pipeline
        always_ff @(posedge rd_clk) begin
          if (rd_rst) begin
            valid[i] <= 1'b0;
          end else if (~&valid[FIFO_LATENCY:i] || rd_en) begin
            valid[i] <= valid[i-1];
          end else begin
            valid[i] <= valid[i];
          end
        end

      end
    end
  endgenerate

  // Empty flag

  assign rd_empty = ~valid[FIFO_LATENCY];

  // Optional output register

  generate
    if (FabricReg == 0) begin : g_no_reg

      always_comb begin
        rd_dout = rd_dout_s;
      end

    end else begin : g_reg

      always_ff @(posedge rd_clk) begin
        if (rd_rst) begin
          rd_dout <= 0;
        end else if (rd_en_mem[2]) begin
          rd_dout <= rd_dout_s;
        end
      end

    end
  endgenerate

  // The dual-port memory

  ram_sdp #(
      .ADDR_WIDTH  (AddrWidth),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(OutputReg + 1),
      .INIT_FILE   ("NONE")
  ) i_ram (
      .clka (wr_clk),
      .wea  (wr_en_mem),
      .addra(wr_addr),
      .dina (wr_din),
      //
      .clkb (rd_clk),
      .rstb (rd_rst),
      .enb  (rd_en_mem[OutputReg:0]),
      .addrb(rd_addr),
      .doutb(rd_dout_s)
  );

  // Reset synchronization

  cdc_async_rst #(
      .DEST_SYNC_FF   (4),
      .INIT_SYNC_FF   (0),
      .RST_ACTIVE_HIGH(1)
  ) i_wr_rst (
      .src_arst (rst),
      .dest_clk (wr_clk),
      .dest_arst(wr_rst)
  );

  cdc_async_rst #(
      .DEST_SYNC_FF   (4),
      .INIT_SYNC_FF   (0),
      .RST_ACTIVE_HIGH(1)
  ) i_rd_rst (
      .src_arst (rst),
      .dest_clk (rd_clk),
      .dest_arst(rd_rst)
  );

  // Write / read domain gray code CDC

  cdc_gray #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .REG_OUTPUT  (0),
      .WIDTH       (AddrWidth + 1)
  ) i_wr2rd_gray (
      .src_clk     (wr_clk),
      .src_in_bin  (wr_count),
      //
      .dest_clk    (rd_clk),
      .dest_out_bin(wr_count_rd)
  );

  cdc_gray #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .REG_OUTPUT  (0),
      .WIDTH       (AddrWidth + 1)
  ) i_rd2wr_gray (
      .src_clk     (rd_clk),
      .src_in_bin  (rd_count),
      //
      .dest_clk    (wr_clk),
      .dest_out_bin(rd_count_wr)
  );

endmodule

`default_nettype wire
