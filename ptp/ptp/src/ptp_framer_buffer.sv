// File: ptp_master.sv
// Brief: PTP Master implemented by FPGA.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_framer_buffer (
    input var         clk,
    input var         rst,
    //
    input var  [55:0] push_tuser,
    input var         push_tuser_valid,
    //
    input var  [63:0] push_data,
    input var  [ 2:0] push_data_bytes,
    input var         push_data_valid,
    //
    input var         eth_tx_clk,
    input var         eth_tx_rst,
    //
    output var [63:0] m_axis_tdata,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    input var         m_axis_tready,
    output var [55:0] m_axis_tuser      // TX Ctrl
);


  localparam int BufferDepth = 1024;

  localparam int AddrWidth = $clog2(BufferDepth) + 1;

  // Write clock domain

  logic [         63:0] wr_data_buf;
  logic [          2:0] wr_data_cnt;

  logic [AddrWidth-1:0] wr_addr;
  logic [         63:0] wr_data;
  logic                 wr_en;
  logic                 wr_full;
  logic [AddrWidth-1:0] rd_addr_wr;

  logic [AddrWidth-1:0] wr_addr_pkg;

  // Read clock domain

  logic [AddrWidth-1:0] rd_addr;
  logic [         63:0] rd_data;
  logic                 rd_empty;
  logic [AddrWidth-1:0] wr_addr_rd;

  // Cached wr data

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_data_cnt <= '0;
    end else if (push_data_valid) begin
      wr_data_cnt <= wr_data_cnt + push_data_bytes;
    end
  end

  always_ff @(posedge clk) begin
    if (push_data_valid) begin
      wr_data_buf

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_addr <= '0;
    end else if (wr_en) begin
      wr_addr <= wr_addr + 1;
    end
  end



  assign wr_full = (wr_addr[AddrWidth-2:0] == rd_addr_wr[AddrWidth-2:0]) &&
                   (wr_addr[AddrWidth-1] != rd_addr_wr[AddrWidth-1]);

  //

  always_ff @(posedge eth_tx_clk) begin
    if (eth_tx_rst) begin
      rd_addr <= '0;
    end else begin
      rd_addr <= ;
    end
  end

  assign rd_empty = (wr_addr_rd == rd_addr);


  xpm_memory_sdpram #(
      .ADDR_WIDTH_A           ($clog2(BufferDepth)),
      .ADDR_WIDTH_B           ($clog2(BufferDepth)),
      .AUTO_SLEEP_TIME        (0),
      .BYTE_WRITE_WIDTH_A     (64),
      .CASCADE_HEIGHT         (0),
      .CLOCKING_MODE          ("independent_clock"),
      .ECC_MODE               ("no_ecc"),
      .MEMORY_INIT_FILE       ("none"),
      .MEMORY_INIT_PARAM      ("0"),
      .MEMORY_OPTIMIZATION    ("true"),
      .MEMORY_PRIMITIVE       ("auto"),
      .MEMORY_SIZE            (BufferDepth * 64),
      .MESSAGE_CONTROL        (0),
      .READ_DATA_WIDTH_B      (64),
      .READ_LATENCY_B         (2),
      .READ_RESET_VALUE_B     ("0"),
      .RST_MODE_A             ("SYNC"),
      .RST_MODE_B             ("SYNC"),
      .SIM_ASSERT_CHK         (0),
      .USE_EMBEDDED_CONSTRAINT(0),
      .USE_MEM_INIT           (1),
      .USE_MEM_INIT_MMI       (0),
      .WAKEUP_TIME            ("disable_sleep"),
      .WRITE_DATA_WIDTH_A     (64),
      .WRITE_MODE_B           ("no_change"),
      .WRITE_PROTECT          (1)
  ) xpm_memory_sdpram_inst (
      .clka          (clk),
      .ena           (wr_en),
      .wea           (wr_en),
      .addra         (wr_addr),
      .dina          (wr_data),
      //
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      //
      .clkb          (eth_tx_clk),
      .rstb          (1'b0),
      .enb           (1'b1),
      .regceb        (1'b1),
      .addrb         (rd_addr),
      .doutb         (rd_data),
      //
      .sbiterrb      (  /* not used */),
      .dbiterrb      (  /* not used */),
      //
      .sleep         (1'b0)
  );

endmodule

`default_nettype wire
