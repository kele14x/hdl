// File: nlf.sv
// Brief: LUT for nlf module

`timescale 1 ns / 1 ps `default_nettype none

module nlf_lut #(
    parameter int INDEX_WIDTH = 8,
    parameter int LUT_WIDTH   = 32
) (
    // Read Interface
    input var                    clk,
    input var                    rst,
    //
    input var  [INDEX_WIDTH-1:0] index,
    output var [ LUT_WIDTH -1:0] dout,
    // Write Interface
    input var                    ctrl_clk,
    input var                    ctrl_rst,
    //
    input var  [INDEX_WIDTH-1:0] ctrl_wr_addr,
    input var                    ctrl_wr_en,
    input var  [ LUT_WIDTH -1:0] ctrl_wr_din
);

  // LUT
  //====

  xpm_memory_sdpram #(
      .ADDR_WIDTH_A           (INDEX_WIDTH),
      .ADDR_WIDTH_B           (INDEX_WIDTH),
      .AUTO_SLEEP_TIME        (0),                            // disable
      .BYTE_WRITE_WIDTH_A     (LUT_WIDTH),
      .CASCADE_HEIGHT         (0),                            // auto
      .CLOCKING_MODE          ("independent_clock"),
      .ECC_MODE               ("no_ecc"),
      .MEMORY_INIT_FILE       ("none"),
      .MEMORY_INIT_PARAM      ("0"),
      .MEMORY_OPTIMIZATION    ("true"),
      .MEMORY_PRIMITIVE       ("auto"),
      .MEMORY_SIZE            (LUT_WIDTH * 2 ** INDEX_WIDTH),
      .MESSAGE_CONTROL        (0),
      .READ_DATA_WIDTH_B      (LUT_WIDTH),
      .READ_LATENCY_B         (2),
      .READ_RESET_VALUE_B     ("0"),
      .RST_MODE_A             ("SYNC"),
      .RST_MODE_B             ("SYNC"),
      .SIM_ASSERT_CHK         (1),
      .USE_EMBEDDED_CONSTRAINT(0),
      .USE_MEM_INIT           (1),
      .USE_MEM_INIT_MMI       (0),
      .WAKEUP_TIME            ("disable_sleep"),
      .WRITE_DATA_WIDTH_A     (LUT_WIDTH),
      .WRITE_MODE_B           ("no_change"),
      .WRITE_PROTECT          (1)
  ) i_lut (
      // write a
      .clka          (ctrl_clk),
      .addra         (ctrl_wr_addr),
      .ena           (ctrl_wr_en),
      .wea           (ctrl_wr_en),
      .dina          (ctrl_wr_din),
      // read b
      .clkb          (clk),
      .rstb          (rst),
      .addrb         (index),
      .enb           (1'b1),
      .regceb        (1'b1),
      .doutb         (dout),
      // ecc b
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      .sbiterrb      (  /* not used */),
      .dbiterrb      (  /* not used */),
      // async
      .sleep         (1'b0)
  );

endmodule

`default_nettype wire
