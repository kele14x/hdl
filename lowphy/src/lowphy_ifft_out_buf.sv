// File: lowphy_ifft_out_buf.sv
// Brief: This module performs the following things:
//        1. Use a DDS to shift center freqency of time domain data
//        2. Buffer 1 symbol data and write to output. Read and write could be
//           performed at same time, so Ping-Pong buffer is not needed.
`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy_ifft_out_buf (
    input var         clk,
    input var         rst,
    //
    input var         din_sof,
    input var         din_sos,
    input var  [31:0] din_data,
    input var         din_valid,
    //
    output var        dout_sof,
    output var        dout_sos,
    output var [31:0] dout_data,
    output var        dout_valid
);

  logic [12:0] current_sample;

  logic [ 9:0] wr_addr;
  logic [31:0] wr_data;
  logic        wr_we;

  logic [ 9:0] rd_addr;
  logic        rd_en;
  logic        rd_en_d;
  logic [31:0] rd_data;


  // Current sample counter
  //-----------------------

  always_ff @(posedge clk) begin
    if (rst | din_sos) begin
      current_sample <= '0;
    end else begin
      current_sample <= current_sample + 1;
    end
  end


  // Write FFT data to port A

  always_ff @(posedge clk) begin
    wr_data <= din_data;
  end

  always_ff @(posedge clk) begin
    wr_we <= din_valid;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_addr <= '0;
    end else if (din_sos) begin
      wr_addr <= '0;
    end else if (din_valid) begin
      wr_addr <= wr_addr + 1;
    end
  end


  // The dual port RAM

  xpm_memory_sdpram #(
      .ADDR_WIDTH_A           (10),
      .ADDR_WIDTH_B           (10),
      .AUTO_SLEEP_TIME        (0),
      .BYTE_WRITE_WIDTH_A     (32),
      .CASCADE_HEIGHT         (0),
      .CLOCKING_MODE          ("common_clock"),
      .ECC_MODE               ("no_ecc"),
      .MEMORY_INIT_FILE       ("none"),
      .MEMORY_INIT_PARAM      ("0"),
      .MEMORY_OPTIMIZATION    ("true"),
      .MEMORY_PRIMITIVE       ("block"),
      .MEMORY_SIZE            (1024 * 32),
      .MESSAGE_CONTROL        (0),
      .READ_DATA_WIDTH_B      (32),
      .READ_LATENCY_B         (2),
      .READ_RESET_VALUE_B     ("0"),
      .RST_MODE_A             ("SYNC"),
      .RST_MODE_B             ("SYNC"),
      .SIM_ASSERT_CHK         (0),
      .USE_EMBEDDED_CONSTRAINT(0),
      .USE_MEM_INIT           (1),
      .USE_MEM_INIT_MMI       (0),
      .WAKEUP_TIME            ("disable_sleep"),
      .WRITE_DATA_WIDTH_A     (32),
      .WRITE_MODE_B           ("no_change"),
      .WRITE_PROTECT          (1)
  ) xpm_memory_sdpram_inst (
      .clka          (clk),
      .ena           (wr_we),
      .wea           (wr_we),
      .addra         (wr_addr),
      .dina          (wr_data),
      //
      .injectdbiterra(1'b0),
      .injectsbiterra(1'b0),
      //
      .clkb          (clk),
      .rstb          (1'b0),
      .enb           (rd_en),
      .regceb        (rd_en_d),
      .addrb         (rd_addr),
      .doutb         (rd_data),
      //
      .dbiterrb      (),
      .sbiterrb      (),
      //
      .sleep         (1'b0)
  );


  // Read FFT data from port B
  // The RAM is read every 4 clock ticks, effective sample rate is 122.88 Msps
  // Also CP insertion is done here, implemented using Cycle Suffix, that is
  // copy first serval samples from beginbing to end. This requires some
  // processing before FFT, but saves processing time and RAM resource

  assign rd_addr = current_sample[11:2];

  // Delay rd_en for 1 tick, this ensure data is write and store
  assign rd_en   = (current_sample[1:0] == 2'b01);

  always_ff @(posedge clk) begin
    rd_en_d <= rd_en;
  end


  // Output

  assign dout_data = rd_data;

  always_ff @(posedge clk) begin
    dout_valid <= rd_en_d;
  end

  // Latency is 4: valid -> we(1), RAM we -> store, read (2)
  delay #(
      .WIDTH(2),
      .DEPTH(4)
  ) i1_sof_delay (
      .clk (clk),
      .din ({din_sof, din_sos}),
      .dout({dout_sof, dout_sos})
  );

endmodule

`default_nettype wire
