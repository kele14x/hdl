`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_framer (
    input var          clk_dsp,
    input var          rst_dsp_n,
    //
    input var  [ 15:0] din_dr,
    input var  [ 15:0] din_di,
    input var          din_dv,
    input var          sync_in,
    input var  [119:0] hdr_in,
    // ORAN
    //-----
    input var          clk_eth_xran,
    input var          rst_eth_xran_n,
    //
    output var [127:0] avst_source_u_data,
    output var         avst_source_u_valid,
    output var         avst_source_u_startofpacket,
    output var         avst_source_u_endofpacket,
    input var          avst_source_u_ready,
    // ORAN sideband
    output var [ 15:0] tx_u_size,
    //
    output var [ 15:0] tx_u_pc_id,
    output var [ 15:0] tx_u_seq_id,
    //
    output var         tx_u_dataDirection,
    output var [  2:0] tx_u_payloadVersion,
    output var [  3:0] tx_u_filterIndex,
    output var [  7:0] tx_u_frameId,
    output var [  3:0] tx_u_subframeId,
    output var [  5:0] tx_u_slotID,
    output var [  5:0] tx_u_symbolid,
    //
    output var [ 11:0] tx_u_sectionId,
    output var         tx_u_rb,
    output var         tx_u_symInc,
    output var [  9:0] tx_u_startPrb,
    output var [  7:0] tx_u_numPrb,
    //
    output var [  7:0] tx_u_udCompHdr
);

  logic [63:0] avst_source_data;
  logic        avst_source_valid;
  logic        avst_source_startofpacket;
  logic        avst_source_endofpacket;
  logic        avst_source_ready;

  prach_framer_buffer u_buffer (
      .clk                      (clk_dsp),
      .rst_n                    (rst_dsp_n),
      //
      .din_dr                   (din_dr),
      .din_di                   (din_di),
      .din_dv                   (din_dv),
      .sync_in                  (sync_in),
      .hdr_in                   (hdr_in),
      //
      .avst_source_data         (avst_source_data),
      .avst_source_valid        (avst_source_valid),
      .avst_source_startofpacket(avst_source_startofpacket),
      .avst_source_endofpacket  (avst_source_endofpacket),
      .avst_source_ready        (avst_source_ready)
  );

  prach_framer_cdc u_cdc (
      .clk_dsp                    (clk_dsp),
      .rst_dsp_n                  (rst_dsp_n),
      //
      .avst_sink_data             (avst_source_data),
      .avst_sink_valid            (avst_source_valid),
      .avst_sink_startofpacket    (avst_source_startofpacket),
      .avst_sink_endofpacket      (avst_source_endofpacket),
      .avst_sink_ready            (avst_source_ready),
      // ORAN
      //-----
      .clk_eth_xran               (clk_eth_xran),
      .rst_eth_xran_n             (rst_eth_xran_n),
      //
      .avst_source_u_data         (avst_source_u_data),
      .avst_source_u_valid        (avst_source_u_valid),
      .avst_source_u_startofpacket(avst_source_u_startofpacket),
      .avst_source_u_endofpacket  (avst_source_u_endofpacket),
      .avst_source_u_ready        (avst_source_u_ready),
      // ORAN sideband
      .tx_u_size                  (tx_u_size),
      //
      .tx_u_pc_id                 (tx_u_pc_id),
      .tx_u_seq_id                (tx_u_seq_id),
      //
      .tx_u_dataDirection         (tx_u_dataDirection),
      .tx_u_payloadVersion        (tx_u_payloadVersion),
      .tx_u_filterIndex           (tx_u_filterIndex),
      .tx_u_frameId               (tx_u_frameId),
      .tx_u_subframeId            (tx_u_subframeId),
      .tx_u_slotID                (tx_u_slotID),
      .tx_u_symbolid              (tx_u_symbolid),
      //
      .tx_u_sectionId             (tx_u_sectionId),
      .tx_u_rb                    (tx_u_rb),
      .tx_u_symInc                (tx_u_symInc),
      .tx_u_startPrb              (tx_u_startPrb),
      .tx_u_numPrb                (tx_u_numPrb),
      //
      .tx_u_udCompHdr             (tx_u_udCompHdr)
  );

endmodule

`default_nettype wire
