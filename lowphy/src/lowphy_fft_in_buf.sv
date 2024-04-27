// File: lowphy_fft_in_buf.sv
// Brief: Buffer the input data, remove CP. Latency 12291 clock ticks.
`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy_fft_in_buf (
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
  logic [ 8:0] current_symbol;

  logic [ 9:0] wr_addr;
  logic [31:0] wr_data;
  logic        wr_we;

  logic [ 9:0] rd_addr;
  logic        rd_en;
  logic        rd_en_d;
  logic [31:0] rd_data;


  // Current sample counter

  always_ff @(posedge clk) begin
    if (rst | din_sos) begin
      current_sample <= '0;
    end else if (~&current_sample)begin
      current_sample <= current_sample + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst | din_sof) begin
      current_symbol <= '0;
    end else if (din_sos) begin
      current_symbol <= current_symbol + 1;
    end
  end


  // Write UL data to port A
  // Only write first 4096 points to buffer, so CP remove is done here

  always_ff @(posedge clk) begin
    wr_data <= din_data;
  end

  assign wr_we = (current_sample[12] == 0) && (current_sample[1:0] == 2'b01);

  assign wr_addr = current_sample[11:2];


  // Read data from port B

  assign rd_addr = current_sample[9:0];

  assign rd_en   = (current_sample[12:10] == 3'b011);

  always_ff @(posedge clk) begin
    rd_en_d <= rd_en;
  end


  // Output

  assign dout_data = rd_data;

  always_ff @(posedge clk) begin
    dout_valid <= rd_en_d;
  end

  // sof/sos need to be delayed to match data output
  always_ff @(posedge clk) begin
    dout_sof <= (current_symbol == 0) && (current_sample == {3'b011, 10'd1});
  end

  always_ff @(posedge clk) begin
    dout_sos <= (current_sample == {3'b011, 10'd1});
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
      .WRITE_MODE_B           ("read_first"),
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
      .rstb          (~rd_en_d),
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

endmodule

`default_nettype wire
