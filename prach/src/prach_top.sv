`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_top (
    // Clock & Reset
    //--------------
    input var          clk_dsp,
    input var          rst_dsp_n,
    // Ant 0,1,2,3,4,5,6,7 interleaved
    input var  [ 15:0] din_dr_cc0,
    input var  [ 15:0] din_dr_cc1,
    input var  [ 15:0] din_dr_cc2,
    input var  [ 15:0] din_di_cc0,
    input var  [ 15:0] din_di_cc1,
    input var  [ 15:0] din_di_cc2,
    input var  [  2:0] din_chn,
    input var          sync_in,
    // Output
    //-------
    input var          clk_eth_xran,
    input var          rst_eth_xran_n,
    // C-Plane
    input var          avst_sink_c_valid,
    input var          avst_sink_c_startofpacket,
    input var          avst_sink_c_endofpacket,
    input var          avst_sink_c_error,
    //
    input var  [ 15:0] rx_c_rtc_id,
    input var  [ 15:0] rx_c_seq_id,
    //
    input var          rx_c_dataDirection,
    input var  [  2:0] rx_c_payloadVersion,
    input var  [  3:0] rx_c_filterIndex,
    input var  [  7:0] rx_c_frameId,
    input var  [  3:0] rx_c_subframeId,
    input var  [  5:0] rx_c_slotId,
    input var  [  5:0] rx_c_symbolId,
    input var  [  7:0] rx_c_sectionType,
    //
    input var  [ 15:0] rx_c_timeOffset,
    input var  [  7:0] rx_c_frameStructure,
    input var  [ 15:0] rx_c_cpLength,
    input var  [  7:0] rx_c_udCompHdr,
    //
    input var  [ 11:0] rx_c_sectionId,
    input var          rx_c_rb,
    input var          rx_c_symInc,
    input var  [  9:0] rx_c_startPrbc,
    input var  [  7:0] rx_c_numPrbc,
    input var  [ 11:0] rx_c_reMask,
    input var  [  3:0] rx_c_numSymbol,
    input var          rx_c_ef,
    input var  [ 14:0] rx_c_beamid,
    input var  [ 23:0] rx_c_freqOffset,
    // U-Plane
    output var [127:0] avst_source_u_data,
    output var         avst_source_u_valid,
    output var         avst_source_u_startofpacket,
    output var         avst_source_u_endofpacket,
    input var          avst_source_u_ready,
    //
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

  logic [ 15:0] resync_dout_dr     [3];
  logic [ 15:0] resync_dout_di     [3];
  logic [  7:0] resync_dout_chn;
  logic         resync_sync_out;

  logic [ 15:0] ddc_dout_dr;
  logic [ 15:0] ddc_dout_di;
  logic [  7:0] ddc_dout_chn;
  logic         ddc_sync_out;

  logic [ 15:0] buffer_dout_dr;
  logic [ 15:0] buffer_dout_di;
  logic         buffer_dout_dv;
  logic         buffer_sync_out;
  logic [119:0] buffer_hdr_out;

  logic [ 15:0] fft_dout_dr;
  logic [ 15:0] fft_dout_di;
  logic         fft_dout_dv;
  logic         fft_sync_out;
  logic [119:0] fft_hdr_out;

  logic         c_valid            [3] [8];
  logic [ 16:0] c_frequency_offset;
  logic [ 19:0] c_time_offset;
  logic [  3:0] c_num_symbol;
  logic [119:0] c_header;

  logic [ 16:0] ctrl_fcw           [3] [8];


  prach_c_plane u_c_plane (
      .clk                      (clk_eth_xran),
      .rst_n                    (rst_eth_xran_n),
      // C-Plane
      .avst_sink_c_valid        (avst_sink_c_valid),
      .avst_sink_c_startofpacket(avst_sink_c_startofpacket),
      .avst_sink_c_endofpacket  (avst_sink_c_endofpacket),
      .avst_sink_c_error        (avst_sink_c_error),
      //
      .rx_c_rtc_id              (rx_c_rtc_id),
      .rx_c_seq_id              (rx_c_seq_id),
      //
      .rx_c_dataDirection       (rx_c_dataDirection),
      .rx_c_payloadVersion      (rx_c_payloadVersion),
      .rx_c_filterIndex         (rx_c_filterIndex),
      .rx_c_frameId             (rx_c_frameId),
      .rx_c_subframeId          (rx_c_subframeId),
      .rx_c_slotId              (rx_c_slotId),
      .rx_c_symbolId            (rx_c_symbolId),
      .rx_c_sectionType         (rx_c_sectionType),
      //
      .rx_c_timeOffset          (rx_c_timeOffset),
      .rx_c_frameStructure      (rx_c_frameStructure),
      .rx_c_cpLength            (rx_c_cpLength),
      .rx_c_udCompHdr           (rx_c_udCompHdr),
      //
      .rx_c_sectionId           (rx_c_sectionId),
      .rx_c_rb                  (rx_c_rb),
      .rx_c_symInc              (rx_c_symInc),
      .rx_c_startPrbc           (rx_c_startPrbc),
      .rx_c_numPrbc             (rx_c_numPrbc),
      .rx_c_reMask              (rx_c_reMask),
      .rx_c_numSymbol           (rx_c_numSymbol),
      .rx_c_ef                  (rx_c_ef),
      .rx_c_beamid              (rx_c_beamid),
      .rx_c_freqOffset          (rx_c_freqOffset),
      //
      .c_valid                  (c_valid),
      .c_frequency_offset       (c_frequency_offset),
      .c_time_offset            (c_time_offset),
      .c_num_symbol             (c_num_symbol),
      .c_header                 (c_header)
  );

  generate
    for (genvar cc = 0; cc < 3; cc++) begin : g_cc
      for (genvar ant = 0; ant < 8; ant++) begin : g_ant

        always_ff @(posedge clk_eth_xran) begin
          if (~rst_eth_xran_n) begin
            ctrl_fcw[cc][ant] <= '0;
          end else if (c_valid[cc][ant]) begin
            ctrl_fcw[cc][ant] <= c_frequency_offset;
          end
        end

      end
    end
  endgenerate


  prach_resync u_resync (
      .clk       (clk_dsp),
      .rst_n     (rst_dsp_n),
      //
      .din_dr_cc0(din_dr_cc0),
      .din_dr_cc1(din_dr_cc1),
      .din_dr_cc2(din_dr_cc2),
      .din_di_cc0(din_di_cc0),
      .din_di_cc1(din_di_cc1),
      .din_di_cc2(din_di_cc2),
      .din_chn   (din_chn),
      .sync_in   (sync_in),
      //
      .dout_dr   (resync_dout_dr),
      .dout_di   (resync_dout_di),
      .dout_chn  (resync_dout_chn),
      .sync_out  (resync_sync_out)
  );

  prach_ddc u_ddc (
      .clk     (clk_dsp),
      .rst_n   (rst_dsp_n),
      //
      .din_dr  (resync_dout_dr),
      .din_di  (resync_dout_di),
      .din_chn (resync_dout_chn),
      .sync_in (resync_sync_out),
      //
      .dout_dr (ddc_dout_dr),
      .dout_di (ddc_dout_di),
      .dout_chn(ddc_dout_chn),
      .sync_out(ddc_sync_out),
      //
      .ctrl_fcw(ctrl_fcw)
  );

  prach_buffer u_buffer (
      .clk           (clk_dsp),
      .rst_n         (rst_dsp_n),
      //
      .din_dr        (ddc_dout_dr),
      .din_di        (ddc_dout_di),
      .din_chn       (ddc_dout_chn),
      .sync_in       (ddc_sync_out),
      //
      .dout_dr       (buffer_dout_dr),
      .dout_di       (buffer_dout_di),
      .dout_dv       (buffer_dout_dv),
      .sync_out      (buffer_sync_out),
      .hdr_out       (buffer_hdr_out),
      //
      .clk_eth_xran  (clk_eth_xran),
      .rst_eth_xran_n(rst_eth_xran_n),
      //
      .c_valid       (c_valid),
      .c_header      (c_header),
      .c_time_offset (c_time_offset),
      .c_num_symbol  (c_num_symbol)
  );

  prach_fft u_fft (
      .clk     (clk_dsp),
      .rst_n   (rst_dsp_n),
      //
      .din_dr  (buffer_dout_dr),
      .din_di  (buffer_dout_di),
      .din_dv  (buffer_dout_dv),
      .sync_in (buffer_sync_out),
      .hdr_in  (buffer_hdr_out),
      //
      .dout_dr (fft_dout_dr),
      .dout_di (fft_dout_di),
      .dout_dv (fft_dout_dv),
      .sync_out(fft_sync_out),
      .hdr_out (fft_hdr_out)
  );

  prach_framer u_framer (
      .clk_dsp                    (clk_dsp),
      .rst_dsp_n                  (rst_dsp_n),
      //
      .din_dr                     (fft_dout_dr),
      .din_di                     (fft_dout_di),
      .din_dv                     (fft_dout_dv),
      .sync_in                    (fft_sync_out),
      .hdr_in                     (fft_hdr_out),
      // ORAN
      .clk_eth_xran               (clk_eth_xran),
      .rst_eth_xran_n             (rst_eth_xran_n),
      //
      .avst_source_u_data         (avst_source_u_data),
      .avst_source_u_valid        (avst_source_u_valid),
      .avst_source_u_startofpacket(avst_source_u_startofpacket),
      .avst_source_u_endofpacket  (avst_source_u_endofpacket),
      .avst_source_u_ready        (avst_source_u_ready),
      //
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
