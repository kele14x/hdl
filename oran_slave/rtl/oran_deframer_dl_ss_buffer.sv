// File: oran_deframer_dl_ss_buffer.sv
// Breif: Deframer section data buffer. Only section data is write into this
//        this buffer.
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer_dl_ss_buffer #(
    // Buffer size in 64-bit width
    parameter int BUFFER_SIZE   = 4096,
    // Number of symbol pointers
    parameter int BUFFER_SYMBOL = 10
) (
    input var                              clk,
    input var                              rst,
    //
    input var                              timer_sos,
    //
    input var  [                     63:0] s_axis_data_tdata,
    input var                              s_axis_data_tvalid,
    input var                              s_axis_data_tlast,
    input var  [$clog2(BUFFER_SYMBOL)-1:0] s_axis_data_tuser,
    // Latency = 4
    input var  [$clog2(BUFFER_SYMBOL)-1:0] buffer_rd_bank,
    input var  [                     10:0] buffer_rd_addr,
    input var                              buffer_rd_en,
    output var [                     65:0] buffer_rd_dout,
    // Control I/F
    //------------
    input var  [                     15:0] ctrl_buffer_addr_offset[BUFFER_SYMBOL]
);

  // All symbols are stored in a shared buffer
  // The buffer size is 4k x 64-bit buffer (cost ~=8 BRAM per symbol)
  localparam int AddrWidth = $clog2(BUFFER_SIZE);
  // Stores last,valid,data, so 66
  localparam int DataWidth = 66;

  // Buffer write signal

  logic [$clog2(BUFFER_SYMBOL)-1:0] r0_wr_bank;
  logic [                     10:0] r0_wr_addr [BUFFER_SYMBOL];
  logic                             r0_wr_en;
  logic [            DataWidth-1:0] r0_wr_din;

  logic [            AddrWidth-1:0] r1_wr_addr;
  logic                             r1_wr_en;
  logic [            DataWidth-1:0] r1_wr_din;

  // Buffer read signal

  logic [            AddrWidth-1:0] r0_rd_addr;
  logic                             r0_rd_en;
  logic                             r0_rd_en_d;
  logic [            DataWidth-1:0] r0_rd_dout;


  // Write side
  //-----------

  always_ff @(posedge clk) begin
    r0_wr_bank <= s_axis_data_tuser;
  end

  always_ff @(posedge clk) begin
    r0_wr_en <= s_axis_data_tvalid && (s_axis_data_tuser < BUFFER_SYMBOL);
  end

  always_ff @(posedge clk) begin
    r0_wr_din <= {s_axis_data_tlast, s_axis_data_tvalid, s_axis_data_tdata};
  end

  generate
    for (genvar i = 0; i < BUFFER_SYMBOL; i++) begin

      always_ff @(posedge clk) begin
        if (rst) begin
          r0_wr_addr[i] <= '0;
        end else if (buffer_rd_bank == i && timer_sos) begin
          r0_wr_addr[i] <= '0;
        end else if (r0_wr_en && (r0_wr_bank == i)) begin
          r0_wr_addr[i] <= r0_wr_addr[i] + 1;
        end
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    r1_wr_addr <= r0_wr_addr[r0_wr_bank] + ctrl_buffer_addr_offset[r0_wr_bank];
  end

  always_ff @(posedge clk) begin
    r1_wr_en <= r0_wr_en;
  end

  always_ff @(posedge clk) begin
    r1_wr_din <= r0_wr_din;
  end

  // Read side
  //----------

  // Make sure we readout write bank (symbol), so pointer is managed by buffer
  // itself
  always_ff @(posedge clk) begin
    r0_rd_addr <= buffer_rd_addr + ctrl_buffer_addr_offset[buffer_rd_bank];
  end

  always_ff @(posedge clk) begin
    if (buffer_rd_bank < BUFFER_SYMBOL) begin
      r0_rd_en <= buffer_rd_en;
    end else begin
      r0_rd_en <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    r0_rd_en_d <= r0_rd_en;
  end

  // Data output
  always_ff @(posedge clk) begin
    buffer_rd_dout <= r0_rd_dout;
  end


  // The buffer
  //-----------

  // The multi-symbol buffer
  // The read latency (side B) should be 2, so total layency is 3
  // TODO: share buffer between symbols so each symbol could cost less than 2k size

  xpm_memory_sdpram #(
      .ADDR_WIDTH_A           (AddrWidth),
      .ADDR_WIDTH_B           (AddrWidth),
      .AUTO_SLEEP_TIME        (0),
      .BYTE_WRITE_WIDTH_A     (DataWidth),
      .CASCADE_HEIGHT         (0),
      .CLOCKING_MODE          ("common_clock"),
      .ECC_MODE               ("no_ecc"),
      .MEMORY_INIT_FILE       ("none"),
      .MEMORY_INIT_PARAM      ("0"),
      .MEMORY_OPTIMIZATION    ("true"),
      .MEMORY_PRIMITIVE       ("block"),
      .MEMORY_SIZE            (DataWidth * (2 ** AddrWidth)),
      .MESSAGE_CONTROL        (0),
      .READ_DATA_WIDTH_B      (DataWidth),
      .READ_LATENCY_B         (2),
      .READ_RESET_VALUE_B     ("0"),
      .RST_MODE_A             ("SYNC"),
      .RST_MODE_B             ("SYNC"),
      .SIM_ASSERT_CHK         (0),
      .USE_EMBEDDED_CONSTRAINT(0),
      .USE_MEM_INIT           (1),
      .USE_MEM_INIT_MMI       (0),
      .WAKEUP_TIME            ("disable_sleep"),
      .WRITE_DATA_WIDTH_A     (DataWidth),
      .WRITE_MODE_B           ("read_first"),
      .WRITE_PROTECT          (1)
  ) i_data_ram (
      .clka          (clk),
      .ena           (r1_wr_en),
      .wea           (r1_wr_en),
      .addra         (r1_wr_addr),
      .dina          (r1_wr_din),
      //
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      //
      .clkb          (clk),
      .rstb          (~r0_rd_en_d),
      .enb           (r0_rd_en),
      .regceb        (r0_rd_en_d),
      .addrb         (r0_rd_addr),
      .doutb         (r0_rd_dout),
      //
      .sbiterrb      (),
      .dbiterrb      (),
      //
      .sleep         (1'b0)
  );

endmodule

`default_nettype wire
