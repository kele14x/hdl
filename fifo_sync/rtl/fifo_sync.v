// File: fifo_sync.sv
// Brief: First-word fall-through (FWFT) FIFO.
`timescale 1 ns / 1 ps
//
`default_nettype none

module fifo_sync #(
    parameter integer FIFO_DEPTH   = 512,
    parameter integer FIFO_LATENCY = 3,
    parameter integer DATA_WIDTH   = 16
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
    output reg  [DATA_WIDTH-1:0] dout,
    output wire                  empty
);

  // Local parameters

  localparam integer AddrWidth = $clog2(FIFO_DEPTH);

  localparam reg OutputReg = FIFO_LATENCY >= 2 ? 1 : 0;

  localparam reg FabricReg = FIFO_LATENCY >= 3 ? 1 : 0;

  // Check parameters

  // verilog_format: off
  initial begin
    // Check FIFO depth
    if (FIFO_DEPTH < 4 || 32768 < FIFO_DEPTH) begin
      $display("[%m]: FIFO depth (FIFO_DEPTH) must be within the range 4 to 32768, got %d.", FIFO_DEPTH);
      #1 $finish;
    end

    // Check input FIFO latency
    if (FIFO_LATENCY < 1 || 3 < FIFO_LATENCY) begin
      $display("[%m]: FIFO latency (FIFO_LATENCY) must be within the range 1 to 3, got %d.", FIFO_LATENCY);
      #1 $finish;
    end

    // Check data width
    if (DATA_WIDTH < 1 || 4096 < DATA_WIDTH) begin
      $display("[%m]: Data width (DATA_WIDTH) must be within the range 1 to 4096, got %0d.", DATA_WIDTH);
      #1 $finish;
    end
  end
  // verilog_format: on

  // Signals

  reg  [     AddrWidth:0] wr_count;
  wire [     AddrWidth:0] wr_count_next;
  wire [   AddrWidth-1:0] wr_addr;
  wire                    wr_en_mem;

  reg  [     AddrWidth:0] rd_count;
  wire [     AddrWidth:0] rd_count_next;
  wire [   AddrWidth-1:0] rd_addr;
  wire [FIFO_LATENCY-1:0] rd_en_mem;

  wire [  DATA_WIDTH-1:0] rd_data;

  reg  [  FIFO_LATENCY:0] valid;

  genvar i;

  // Main

  // Write pointer

  always @(posedge clk) begin
    if (rst) begin
      wr_count <= 0;
    end else begin
      wr_count <= wr_count_next;
    end
  end

  assign wr_count_next = wr_en_mem ? (wr_count + 1) : wr_count;

  assign wr_addr = wr_count[AddrWidth-1:0];

  assign wr_en_mem = !full && wren;

  // Read pointer

  always @(posedge clk) begin
    if (rst) begin
      rd_count <= 0;
    end else begin
      rd_count <= rd_count_next;
    end
  end

  assign rd_count_next = rd_en_mem[0] ? rd_count + 1 : rd_count;

  assign rd_addr = rd_count[AddrWidth-1:0];

  // RAM read
  // For FIFO, every level of rd_en of output pipeline need to controlled individually.
  // The read enable could be explained as: If there is data at current level and any
  // of down level pipeline is not valid (empty). The data sink's `rden` could be seen
  // as a valid flag

  generate
    for (i = 0; i < FIFO_LATENCY; i = i + 1) begin : g_rd_en_mem
      assign rd_en_mem[i] = valid[i] && (~&valid[FIFO_LATENCY:i+1] || rden);
    end
  endgenerate

  // The valid flags

  generate
    for (i = 0; i <= FIFO_LATENCY; i = i + 1) begin : g_valid

      if (i == 0) begin : g_first

        // `Valid[0]` marks there is valid at RAM
        always @(posedge clk) begin
          if (rst) begin
            valid[0] <= 1'b0;
          end else if (wr_count_next == rd_count_next) begin
            valid[0] <= 1'b0;
          end else begin
            valid[0] <= 1'b1;
          end
        end

      end else begin : g_left

        // Left `valid` marks if the data is valid at pipeline
        always @(posedge clk) begin
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

  // Empty flag

  assign empty = ~valid[FIFO_LATENCY];

  // Full flag

  always @(posedge clk) begin
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
      .READ_LATENCY(OutputReg + 1),
      .INIT_WORD   (0),
      .INIT_FILE   ("")
  ) i_ram (
      .clka (clk),
      .ena  (wr_en_mem),
      .wea  (wr_en_mem),
      .addra(wr_addr),
      .dina (din),
      //
      .clkb (clk),
      .rstb ({OutputReg + 1{rst}}),
      .enb  (rd_en_mem[OutputReg:0]),
      .addrb(rd_addr),
      .doutb(rd_data)
  );

  generate
    if (FabricReg == 0) begin : g_no_reg

      always @(*) begin
        dout = rd_data;
      end

    end else begin : g_reg

      always @(posedge clk) begin
        if (rst) begin
          dout <= 0;
        end else if (rd_en_mem[2]) begin
          dout <= rd_data;
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire
