// File: ptp_master.sv
// Brief: PTP Master implemented by FPGA.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_channel (
    // TX
    //---
    input var         eth_tx_clk,
    input var         eth_tx_rst,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    input var         m_axis_tready,
    output var [55:0] m_axis_tuser,
    // Timestamp
    input var  [95:0] s_axis_txts_tdata,
    input var         s_axis_txts_tvalid,
    // RX
    //---
    input var         eth_rx_clk,
    input var         eth_rx_rst,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    input var  [79:0] s_axis_tuser,
    // Internal domain
    //----------------
    input var         clk,
    input var         rst,
    //
    input var         ctrl_enable,
    input var         ctrl_soft_reset,
    input var         ctrl_force_slave,
    input var         ctrl_sync_interval,
    input var         ctrl_delay_req_internal
);

  ptp_ctrl i_ctrl (
      .clk              (clk),
      .rst              (rst),
      //
      .s_send_sync      (s_send_sync),
      .s_send_announce  (s_send_announce),
      .s_send_delay_req (s_send_delay_req),
      .s_send_delay_resp(s_send_delay_resp)
  );

  ptp_framer i_framer (
      .eth_tx_clk       (eth_tx_clk),
      .eth_tx_rst       (eth_tx_rst),
      //
      .m_axis_tdata     (m_axis_tdata),
      .m_axis_tkeep     (m_axis_tkeep),
      .m_axis_tvalid    (m_axis_tvalid),
      .m_axis_tlast     (m_axis_tlast),
      .m_axis_tready    (m_axis_tready),
      .m_axis_tuser     (m_axis_tuser),      // TX Ctrl
      //
      .clk              (clk),
      .rst              (rst),
      //
      .s_send_sync      (s_send_sync),
      .s_send_announce  (s_send_announce),
      .s_send_delay_req (s_send_delay_req),
      .s_send_delay_resp(s_send_delay_resp)
  );


  ptp_deframer i_deframer (
      .eth_rx_clk                   (eth_rx_clk),
      .eth_rx_rst                   (eth_rx_rst),
      //
      .s_axis_tdata                 (s_axis_tdata),
      .s_axis_tkeep                 (s_axis_tkeep),
      .s_axis_tvalid                (s_axis_tvalid),
      .s_axis_tlast                 (s_axis_tlast),
      .s_axis_tuser                 (s_axis_tuser),                   // RX TS
      // PTP parse ports
      //----------------
      // Common Header
      .m_hdr_header_valid           (m_hdr_header_valid),
      .m_hdr_transportSpecific      (m_hdr_transportSpecific),
      .m_hdr_messageType            (m_hdr_messageType),
      .m_hdr_versionPTP             (m_hdr_versionPTP),
      .m_hdr_messageLength          (m_hdr_messageLength),
      .m_hdr_domainNumber           (m_hdr_domainNumber),
      .m_hdr_flagField              (m_hdr_flagField),
      .m_hdr_correctionField        (m_hdr_correctionField),
      .m_hdr_sourcePortIdentity     (m_hdr_sourcePortIdentity),
      .m_hdr_sequenceId             (m_hdr_sequenceId),
      .m_hdr_controlField           (m_hdr_controlField),
      .m_hdr_logMessageInterval     (m_hdr_logMessageInterval),
      // Body
      .m_bdy_body_valid             (m_bdy_body_valid),
      .m_bdy_originTimestamp        (m_bdy_originTimestamp),
      .m_bdy_currentUtcOffset       (m_bdy_currentUtcOffset),
      .m_bdy_grandmasterPriority1   (m_bdy_grandmasterPriority1),
      .m_bdy_grandmasterClockQUality(m_bdy_grandmasterClockQUality),
      .m_bdy_grandmasterPriority2   (m_bdy_grandmasterPriority2),
      .m_bdy_grandmasterIdentity    (m_bdy_grandmasterIdentity),
      .m_bdy_stepsRemoved           (m_bdy_stepsRemoved),
      .m_bdy_timeSource             (m_bdy_timeSource),
      .m_bdy_requestingPortIdentity (m_bdy_requestingPortIdentity)
  );

endmodule

`default_nettype wire
