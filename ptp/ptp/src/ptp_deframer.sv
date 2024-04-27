// File: ptp_master.sv
// Brief: PTP Master implemented by FPGA.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_deframer (
    input var         clk,
    input var         rst,
    //
    input var  [64:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    input var  [79:0] s_axis_tuser,                   // RX TS
    // PTP parse ports
    //----------------
    // Common Header
    output var        m_hdr_header_valid,
    output var [ 3:0] m_hdr_transportSpecific,
    output var [ 3:0] m_hdr_messageType,
    output var [ 3:0] m_hdr_versionPTP,
    output var [15:0] m_hdr_messageLength,
    output var [ 7:0] m_hdr_domainNumber,
    output var [15:0] m_hdr_flagField,
    output var [63:0] m_hdr_correctionField,
    output var [79:0] m_hdr_sourcePortIdentity,
    output var [15:0] m_hdr_sequenceId,
    output var [ 7:0] m_hdr_controlField,
    output var [ 7:0] m_hdr_logMessageInterval,
    // Body
    output var        m_bdy_body_valid,
    output var [79:0] m_bdy_originTimestamp,
    output var [15:0] m_bdy_currentUtcOffset,
    output var [ 7:0] m_bdy_grandmasterPriority1,
    output var [31:0] m_bdy_grandmasterClockQUality,
    output var [ 7:0] m_bdy_grandmasterPriority2,
    output var [63:0] m_bdy_grandmasterIdentity,
    output var [15:0] m_bdy_stepsRemoved,
    output var [ 7:0] m_bdy_timeSource,
    output var [79:0] m_bdy_requestingPortIdentity
);

  ptp_deframer_filter i_filter (
      .clk               (clk),
      .rst               (rst),
      //
      .s_axis_tdata      (s_axis_tdata),
      .s_axis_tkeep      (s_axis_tkeep),
      .s_axis_tvalid     (s_axis_tvalid),
      .s_axis_tlast      (s_axis_tlast),
      .s_axis_tuser      (s_axis_tuser),        // Rx TS
      // DL Carrier ports
      .m_axis_tdata      (m_axis_tdata),
      .m_axis_tkeep      (m_axis_tkeep),
      .m_axis_tvalid     (m_axis_tvalid),
      .m_axis_tlast      (m_axis_tlast),
      .m_axis_tuser      (m_axis_tuser),
      //
      .m_mac_header_valid(m_mac_header_valid),
      .m_mac_dest_mac    (m_mac_dest_mac),
      .m_mac_source_mac  (m_mac_source_mac),
      .m_mac_with_vlan   (m_mac_with_vlan),
      .m_mac_vlan_tag    (m_mac_vlan_tag),
      .m_mac_ethertype   (m_mac_ethertype)
  );

  ptp_deframer_hdr i_hdr (
      .clk                     (clk),
      .rst                     (rst),
      //
      .s_axis_tdata            (s_axis_tdata),
      .s_axis_tkeep            (s_axis_tkeep),
      .s_axis_tvalid           (s_axis_tvalid),
      .s_axis_tlast            (s_axis_tlast),
      .s_axis_tuser            (s_axis_tuser),
      //
      .m_axis_tdata            (m_axis_tdata),
      .m_axis_tkeep            (m_axis_tkeep),
      .m_axis_tvalid           (m_axis_tvalid),
      .m_axis_tlast            (m_axis_tlast),
      .m_axis_tuser            (m_axis_tuser),
      // PTP parse ports
      //----------------
      // Common Header
      .m_hdr_header_valid      (m_hdr_header_valid),
      .m_hdr_transportSpecific (m_hdr_transportSpecific),
      .m_hdr_messageType       (m_hdr_messageType),
      .m_hdr_versionPTP        (m_hdr_versionPTP),
      .m_hdr_messageLength     (m_hdr_messageLength),
      .m_hdr_domainNumber      (m_hdr_domainNumber),
      .m_hdr_flagField         (m_hdr_flagField),
      .m_hdr_correctionField   (m_hdr_correctionField),
      .m_hdr_sourcePortIdentity(m_hdr_sourcePortIdentity),
      .m_hdr_sequenceId        (m_hdr_sequenceId),
      .m_hdr_controlField      (m_hdr_controlField),
      .m_hdr_logMessageInterval(m_hdr_logMessageInterval)
  );

  ptp_deframer_body i_body (
      .clk                          (clk),
      .rst                          (rst),
      //
      .s_axis_tdata                 (s_axis_tdata),
      .s_axis_tkeep                 (s_axis_tkeep),
      .s_axis_tvalid                (s_axis_tvalid),
      .s_axis_tlast                 (s_axis_tlast),
      .s_axis_tuser                 (s_axis_tuser),
      //
      .m_axis_tdata                 (m_axis_tdata),
      .m_axis_tkeep                 (m_axis_tkeep),
      .m_axis_tvalid                (m_axis_tvalid),
      .m_axis_tlast                 (m_axis_tlast),
      .m_axis_tuser                 (m_axis_tuser),
      // PTP parse ports
      //----------------
      .m_bdy_body_valid             (m_bdy_body_valid),
      // Common
      .m_bdy_originTimestamp        (m_bdy_originTimestamp),
      // Announce
      .m_bdy_currentUtcOffset       (m_bdy_currentUtcOffset),
      .m_bdy_grandmasterPriority1   (m_bdy_grandmasterPriority1),
      .m_bdy_grandmasterClockQUality(m_bdy_grandmasterClockQUality),
      .m_bdy_grandmasterPriority2   (m_bdy_grandmasterPriority2),
      .m_bdy_grandmasterIdentity    (m_bdy_grandmasterIdentity),
      .m_bdy_stepsRemoved           (m_bdy_stepsRemoved),
      .m_bdy_timeSource             (m_bdy_timeSource),
      // Delay_Resp
      .m_bdy_requestingPortIdentity (m_bdy_requestingPortIdentity)
  );

  ptp_deframer_tlv i_tlv (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tkeep (s_axis_tkeep),
      .s_axis_tvalid(s_axis_tvalid),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tuser (s_axis_tuser)
  );

endmodule

`default_nettype wire
