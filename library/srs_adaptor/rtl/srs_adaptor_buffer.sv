// file: srs_adaptor_buffer.sv
// brief: 2 symbol ping-pong buffer for SRS
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_buffer (
    // Writer
    //=======
    input var         clk_491m52,
    input var         rst_491m52,
    //
    input var         bram_bank,     // !@clk_400m
    //
    input var  [11:0] bram_wr_addr,  // 4096 * 24b
    input var         bram_wr_en,
    input var  [23:0] bram_wr_data,
    // Reader
    //=======
    input var         clk_400m,
    input var         rst_400m,
    //
    input var  [ 9:0] bram_rd_addr,  // 1024 * 96b
    input var         bram_rd_en,    // !connect to all registers in output pipe
    output var [95:0] bram_rd_data   // 4 RE
);

  logic        bram_bank_s;
  logic [12:0] bram_wr_addr_s;
  logic [10:0] bram_rd_addr_s;


  //
  xpm_cdc_single #(
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_INPUT_REG (0)
  ) xpm_cdc_srs_run_bank (
      .src_clk (  /* Not used */),
      .src_in  (bram_bank),
      .dest_clk(clk_491m52),
      .dest_out(bram_bank_s)
  );

  assign bram_wr_addr_s = {bram_bank_s, bram_wr_addr};
  assign bram_rd_addr_s = {~bram_bank, bram_rd_addr};

  // Simple dual port RAM, 8192 * 24b or 2048 * 96b
  // 1-bit MSB is ping-pong bank switch and hard synced
  srs_adaptor_runner_sdp i_srs_adaptor_runner_sdp (
      // Write port
      .clka (clk_491m52),
      .addra(bram_wr_addr_s),  // 0 ~ 8192
      .ena  (bram_wr_en),
      .wea  (bram_wr_en),      // 1 RE
      .dina (bram_wr_data),
      // Read port
      .clkb (clk_400m),
      .rstb (rst_400m),
      .addrb(bram_rd_addr_s),  // 0 ~ 2048
      .enb  (bram_rd_en),      // connect to all registers in output pipe
      .doutb(bram_rd_data)
  );

endmodule

`default_nettype wire
