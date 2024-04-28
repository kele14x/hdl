// File: tb_prach_top.sv
// Brief: This is actually a test wrapper for cocotb testbench and DUT
//        (prach_top). Clock generation is done here to improve simulation
//        performance.
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_prach_top (
    // DFE
    //----
    output var         clk_dsp,
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
    // O-RAN
    //------
    output var         clk_eth_xran,
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

  // 491.52 MHz
  initial begin
    clk_dsp = 1'b0;
    forever begin
      #(1.017) clk_dsp = ~clk_dsp;
    end
  end

  // 402.83203125 MHz
  initial begin
    clk_eth_xran = 1'b0;
    forever begin
      #(1.241) clk_eth_xran = ~clk_eth_xran;
    end
  end

  // DUT

  prach_top DUT (.*);

endmodule

`default_nettype wire
