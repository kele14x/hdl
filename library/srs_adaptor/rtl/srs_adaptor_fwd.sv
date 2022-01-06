// file: srs_adaptor_fwd.sv
// brief: Forward necessary SRS C-Plane message to next module as SRS
//        configuration. It tries to be smart enough to not forward same
//        message twice or more.
// note: This module assume two SRS C-Plane message will not arrive too close.
//
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_fwd #(
    parameter int NUM_CC = 2
) (
    // XORIF
    //======
    input var         clk_400m,
    input var         rst_400m,
    // UL Timing
    input var  [11:0] s_ul_sym_num     [NUM_CC],
    input var         s_ul_update      [NUM_CC],
    // SRS Filter
    input var  [ 2:0] srs_cc,
    input var  [11:0] srs_symbol,
    input var  [ 3:0] srs_numsymbol,
    input var         srs_valid,
    // DFE
    //====
    input var         clk_184m32,
    input var         rst_184m32,
    // SRS Configuration Forward
    output var [ 2:0] srs_cfg_cc,
    output var [11:0] srs_cfg_symbol,
    output var [ 3:0] srs_cfg_numsymbol,
    output var        srs_cfg_valid
);


  localparam int DataWidth = ($size(srs_cc) + $size(srs_symbol) + $size(srs_numsymbol));


  // CDC
  //=====
  // SRS C-Plane message CDC to clk_184m32

  logic [DataWidth-1:0] srs_prev, srs_in, srs_out;
  logic srs_send;
  logic srs_rcv;

  logic srs_new;

  assign srs_new = srs_valid && !srs_send && !srs_rcv && {
    srs_cc, srs_symbol, srs_numsymbol
  } != srs_prev;

  // Put all data into a CDC handshake buffer, assume the incoming SRS message
  // will not come too often, so we have enough time to forward it to next
  // block. XPM_CDC_HANDSHAKE requires us deassert `srs_send` if seen `srs_rcv`
  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      srs_send <= 1'b0;
    end else if (srs_new) begin
      srs_send <= 1'b1;
    end else if (srs_rcv) begin
      srs_send <= 1'b0;
    end
  end

  // Buffer the forwarded message for this radio frame, it's more convenient not
  // forward same information again and again.
  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      srs_prev <= '1;
    end else if (srs_new) begin
      srs_prev <= {srs_cc, srs_symbol, srs_numsymbol};
    end else begin
      for (int i = 0; i < NUM_CC; i++) begin
        if (s_ul_update[i] && s_ul_sym_num[i] == 0) begin
          srs_prev <= '1;
        end
      end
    end
  end

  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      srs_in <= '0;
    end else if (srs_new) begin
      srs_in <= {srs_cc, srs_symbol, srs_numsymbol};
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
      .WIDTH         (DataWidth)
  ) xpm_cdc_handshake_inst (
      .src_clk (clk_400m),
      .src_in  (srs_in),
      .src_send(srs_send),
      .src_rcv (srs_rcv),
      //
      .dest_clk(clk_184m32),
      .dest_out(srs_out),
      .dest_req(srs_cfg_valid),
      .dest_ack(1'b0)
  );

  assign {srs_cfg_cc, srs_cfg_symbol, srs_cfg_numsymbol} = srs_out;

endmodule

`default_nettype wire
