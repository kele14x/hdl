// File: nlf_lut.sv
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
    input var                    bank,
    input var  [INDEX_WIDTH-1:0] index,
    output var [ LUT_WIDTH -1:0] dout,
    // Write Interface
    input var                    ctrl_clk,
    input var                    ctrl_rst,
    //
    input var  [  INDEX_WIDTH:0] ctrl_lut_addr,
    input var                    ctrl_lut_en,
    input var                    ctrl_lut_we,
    input var  [ LUT_WIDTH -1:0] ctrl_lut_din,
    output var [ LUT_WIDTH -1:0] ctrl_lut_dout
);

  // LUT
  //====

  xpm_memory_tdpram #(
      .ADDR_WIDTH_A           (INDEX_WIDTH + 1),
      .ADDR_WIDTH_B           (INDEX_WIDTH + 1),
      .AUTO_SLEEP_TIME        (0),                                   // disable
      .BYTE_WRITE_WIDTH_A     (LUT_WIDTH),
      .BYTE_WRITE_WIDTH_B     (LUT_WIDTH),
      .CASCADE_HEIGHT         (0),                                   // auto
      .CLOCKING_MODE          ("independent_clock"),
      .ECC_MODE               ("no_ecc"),
      .MEMORY_INIT_FILE       ("none"),
      .MEMORY_INIT_PARAM      ("0"),
      .MEMORY_OPTIMIZATION    ("true"),
      .MEMORY_PRIMITIVE       ("auto"),
      .MEMORY_SIZE            (LUT_WIDTH * 2 ** (INDEX_WIDTH + 1)),
      .MESSAGE_CONTROL        (1),
      .READ_DATA_WIDTH_A      (LUT_WIDTH),
      .READ_DATA_WIDTH_B      (LUT_WIDTH),
      .READ_LATENCY_A         (1),
      .READ_LATENCY_B         (3),
      .READ_RESET_VALUE_A     ("0"),
      .READ_RESET_VALUE_B     ("0"),
      .RST_MODE_A             ("SYNC"),
      .RST_MODE_B             ("SYNC"),
      .SIM_ASSERT_CHK         (1),
      .USE_EMBEDDED_CONSTRAINT(0),
      .USE_MEM_INIT           (1),
      .USE_MEM_INIT_MMI       (0),
      .WAKEUP_TIME            ("disable_sleep"),
      .WRITE_DATA_WIDTH_A     (LUT_WIDTH),
      .WRITE_DATA_WIDTH_B     (LUT_WIDTH),
      .WRITE_MODE_A           ("no_change"),
      .WRITE_MODE_B           ("no_change"),
      .WRITE_PROTECT          (1)
  ) i_lut (
      // Port A
      .clka          (ctrl_clk),
      .rsta          (ctrl_rst),
      .addra         (ctrl_lut_addr), // {bank, index}
      .ena           (ctrl_lut_en),
      .wea           (ctrl_lut_we),
      .regcea        (1'b1),
      .dina          (ctrl_lut_din),
      .douta         (ctrl_lut_dout),
      // ECC A
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      .sbiterra      (  /* not used */),
      .dbiterra      (  /* not used */),
      // Port b
      .clkb          (clk),
      .rstb          (rst),
      .addrb         ({bank, index}),
      .enb           (1'b1),
      .web           (1'b0),
      .regceb        (1'b1),
      .dinb          ({LUT_WIDTH{1'b0}}),
      .doutb         (dout),
      // ECC b
      .injectsbiterrb(1'b0),
      .injectdbiterrb(1'b0),
      .sbiterrb      (  /* not used */),
      .dbiterrb      (  /* not used */),
      // async
      .sleep         (1'b0)
  );

endmodule

`default_nettype wire
