// file: srs_adaptor_fwd.sv
// brief: Forward necessary SRS C-Plane message to next module as SRS
//        configuration.
// TODO: Be smart enough to not forward same message twice or more
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_fwd (
    // XORIF
    //======
    input var         clk_400m,
    input var         rst_400m,
    // SRS Filter
    input var  [ 3:0] srs_cc,
    input var  [11:0] srs_symbol,
    input var  [ 3:0] srs_numsymbol,
    input var         srs_valid,
    // DFE
    //====
    input var         clk_491m52,
    input var         rst_491m52,
    // SRS Configuration Forward
    output var [ 3:0] srs_cfg_cc,
    output var [11:0] srs_cfg_symbol,
    output var [ 3:0] srs_cfg_numsymbol,
    output var        srs_cfg_valid
);


  // SRS C-Plane message CDC to clk_491m52
  //======================================

  logic srs_send;
  logic srs_rcv;

  // Put all data into a CDC handshake buffer, assume the incoming SRS message
  // will not come too offen, so we have enough time to forward it to next
  // block. XPM_CDC_HANDSHAKE requires us deassert `srs_send` if seen `srs_rcv`
  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      srs_send <= 1'b0;
    end else if (srs_valid) begin
      srs_send <= 1'b1;
    end else if (srs_rcv) begin
      srs_send <= 1'b0;
    end
  end

  // DEST_EXT_HSK = 0 will use internal handshake, so `dest_req` will be only
  // one tick pulse.
  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (20)
  ) xpm_cdc_handshake_inst (
      .src_clk (clk_400m),
      .src_in  ({srs_cc, srs_symbol, srs_numsymbol}),
      .src_send(srs_send),
      .src_rcv (srs_rcv),
      //
      .dest_clk(clk_491m52),
      .dest_out({srs_cfg_cc, srs_cfg_symbol, srs_cfg_numsymbol}),
      .dest_req(srs_cfg_valid),
      .dest_ack(1'b0)
  );

endmodule

`default_nettype wire
