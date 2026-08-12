// This module does the following:
// - Filter out none eCPRI packets
// - Remove MAC header, which is not useful for following processing
// - Moves Ethernet packet to `internal_bus_clk` domain
// - Test if the packet size is correct
// - Forward packet to next stage
`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_deframer (
    // Rx Ethernet I/F
    //----------------
    input var         rx_eth_clk,
    input var         rx_eth_rst,
    //
    input var  [31:0] s_axis_tdata,
    input var  [ 3:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var         s_axis_tuser,
    input var         s_axis_tvalid,
    //
    input var  [79:0] rx_ptp_timestamp,
    input var         rx_ptp_timestamp_valid,
    // Internal I/F
    //-------------
    input var         clk,
    input var         rst,
    //
    output var [31:0] m_axis_tdata,
    output var [ 3:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var        m_axis_tvalid,
    //
    output var [31:0] m_ptp_tdata,
    output var [ 3:0] m_ptp_tkeep,
    output var        m_ptp_tlast,
    output var [79:0] m_ptp_tuser,
    output var        m_ptp_tvalid,
    input var         m_ptp_tready,
    //
    output var [31:0] m_message_tdata,
    output var [ 3:0] m_message_tkeep,
    output var        m_message_tlast,
    output var        m_message_tvalid,
    input var         m_message_tready,
    // eCPRI parse ports
    //------------------
    output var        m_mac_header_valid,
    output var [47:0] m_mac_dest_mac,
    output var [47:0] m_mac_source_mac,
    output var        m_mac_with_vlan,
    output var [15:0] m_mac_vlan_tag,
    output var [15:0] m_mac_ethertype,
    //
    output var        m_ecpri_header_valid,
    output var        m_ecpri_concat,
    output var [ 7:0] m_ecpri_messagetype,
    output var [15:0] m_ecpri_payloadsize,
    //
    output var        m_trans_header_valid,
    output var [15:0] m_trans_rtc_pc_id,
    output var [ 7:0] m_trans_seqid,
    output var        m_trans_ebit,
    output var [ 6:0] m_trans_subseqid,
    //
    output var        m_odm_header_valid,
    output var [ 7:0] m_odm_measurementid,
    output var [ 7:0] m_odm_actiontype,
    output var [79:0] m_odm_timestamp,
    output var [63:0] m_odm_compensation,
    output var [79:0] m_odm_timestamp2,
    //
    output var [15:0] stat_topology_id
);

  // Signals

  wire [31:0] m0_ptp_tdata;
  wire [ 3:0] m0_ptp_tkeep;
  wire        m0_ptp_tlast;
  wire [79:0] m0_ptp_tuser;
  wire        m0_ptp_tvalid;

  wire [31:0] m0_message_tdata;
  wire [ 3:0] m0_message_tkeep;
  wire        m0_message_tlast;
  wire        m0_message_tvalid;

  wire [31:0] s0_axis_tdata;
  wire [ 3:0] s0_axis_tkeep;
  wire        s0_axis_tlast;
  wire [79:0] s0_axis_tuser;
  wire        s0_axis_tvalid;

  wire [31:0] s1_axis_tdata;
  wire [ 3:0] s1_axis_tkeep;
  wire        s1_axis_tlast;
  wire [79:0] s1_axis_tuser;
  wire        s1_axis_tvalid;

  wire [31:0] s2_axis_tdata;
  wire [ 3:0] s2_axis_tkeep;
  wire        s2_axis_tlast;
  wire [79:0] s2_axis_tuser;
  wire        s2_axis_tvalid;

  wire        unused_stat_corrupt_pkt;
  wire        unused_ptp_err_discard;
  wire        unused_message_err_discard;
  wire        unused_message_tuser;

  // Main

  ecpri_deframer_demux i_demux (
      // Ethernet I/F
      .rx_eth_clk            (rx_eth_clk),
      .rx_eth_rst            (rx_eth_rst),
      //
      .s_axis_tdata          (s_axis_tdata),
      .s_axis_tkeep          (s_axis_tkeep),
      .s_axis_tlast          (s_axis_tlast),
      .s_axis_tuser          (s_axis_tuser),
      .s_axis_tvalid         (s_axis_tvalid),
      //
      .rx_ptp_timestamp      (rx_ptp_timestamp),
      .rx_ptp_timestamp_valid(rx_ptp_timestamp_valid),
      // Internal I/F
      .clk                   (clk),
      .rst                   (rst),
      // eCPRI message
      .m_axis_tdata          (s0_axis_tdata),
      .m_axis_tkeep          (s0_axis_tkeep),
      .m_axis_tlast          (s0_axis_tlast),
      .m_axis_tvalid         (s0_axis_tvalid),
      .m_axis_tuser          (s0_axis_tuser),
      // PTP message
      .m_ptp_tdata           (m0_ptp_tdata),
      .m_ptp_tkeep           (m0_ptp_tkeep),
      .m_ptp_tlast           (m0_ptp_tlast),
      .m_ptp_tvalid          (m0_ptp_tvalid),
      .m_ptp_tuser           (m0_ptp_tuser),
      // none-eCPRI message
      .m_message_tdata       (m0_message_tdata),
      .m_message_tkeep       (m0_message_tkeep),
      .m_message_tlast       (m0_message_tlast),
      .m_message_tvalid      (m0_message_tvalid),
      //
      .stat_corrupt_pkt      (unused_stat_corrupt_pkt)
  );

  axis_fifo_alt #(
      .ASYNC_MODE  (0),
      .FIFO_DEPTH  (4096),
      .FIFO_LATENCY(3),
      .USER_WIDTH  (80)
  ) i_ptp_fifo (
      .s_axis_aclk   (clk),
      .s_axis_aresetn(!rst),
      //
      .s_axis_tdata  (m0_ptp_tdata),
      .s_axis_tkeep  (m0_ptp_tkeep),
      .s_axis_tlast  (m0_ptp_tlast),
      .s_axis_tuser  (m0_ptp_tuser),
      .s_axis_tvalid (m0_ptp_tvalid),
      //
      .m_axis_aclk   (clk),
      //
      .m_axis_tdata  (m_ptp_tdata),
      .m_axis_tkeep  (m_ptp_tkeep),
      .m_axis_tlast  (m_ptp_tlast),
      .m_axis_tuser  (m_ptp_tuser),
      .m_axis_tvalid (m_ptp_tvalid),
      .m_axis_tready (m_ptp_tready),
      //
      .err_discard   (unused_ptp_err_discard)
  );

  axis_fifo_alt #(
      .ASYNC_MODE  (0),
      .FIFO_DEPTH  (4096),
      .FIFO_LATENCY(3),
      .USER_WIDTH  (1)
  ) i_message_fifo (
      .s_axis_aclk   (clk),
      .s_axis_aresetn(!rst),
      //
      .s_axis_tdata  (m0_message_tdata),
      .s_axis_tkeep  (m0_message_tkeep),
      .s_axis_tlast  (m0_message_tlast),
      .s_axis_tuser  ('b0),
      .s_axis_tvalid (m0_message_tvalid),
      //
      .m_axis_aclk   (clk),
      //
      .m_axis_tdata  (m_message_tdata),
      .m_axis_tkeep  (m_message_tkeep),
      .m_axis_tlast  (m_message_tlast),
      .m_axis_tuser  (unused_message_tuser),
      .m_axis_tvalid (m_message_tvalid),
      .m_axis_tready (m_message_tready),
      //
      .err_discard   (unused_message_err_discard)
  );

  ecpri_deframer_eth i_eth (
      .clk               (clk),
      .rst               (rst),
      //
      .s_axis_tdata      (s0_axis_tdata),
      .s_axis_tkeep      (s0_axis_tkeep),
      .s_axis_tlast      (s0_axis_tlast),
      .s_axis_tuser      (s0_axis_tuser),
      .s_axis_tvalid     (s0_axis_tvalid),
      //
      .m_axis_tdata      (s1_axis_tdata),
      .m_axis_tkeep      (s1_axis_tkeep),
      .m_axis_tlast      (s1_axis_tlast),
      .m_axis_tuser      (s1_axis_tuser),
      .m_axis_tvalid     (s1_axis_tvalid),
      //
      .m_mac_header_valid(m_mac_header_valid),
      .m_mac_dest_mac    (m_mac_dest_mac),
      .m_mac_source_mac  (m_mac_source_mac),
      .m_mac_with_vlan   (m_mac_with_vlan),
      .m_mac_vlan_tag    (m_mac_vlan_tag),
      .m_mac_ethertype   (m_mac_ethertype)
  );

  ecpri_deframer_common i_common (
      .clk                 (clk),
      .rst                 (rst),
      //
      .s_axis_tdata        (s1_axis_tdata),
      .s_axis_tkeep        (s1_axis_tkeep),
      .s_axis_tlast        (s1_axis_tlast),
      .s_axis_tuser        (s1_axis_tuser),
      .s_axis_tvalid       (s1_axis_tvalid),
      //
      .m_axis_tdata        (s2_axis_tdata),
      .m_axis_tkeep        (s2_axis_tkeep),
      .m_axis_tlast        (s2_axis_tlast),
      .m_axis_tuser        (s2_axis_tuser),
      .m_axis_tvalid       (s2_axis_tvalid),
      //
      .m_ecpri_header_valid(m_ecpri_header_valid),
      .m_ecpri_concat      (m_ecpri_concat),
      .m_ecpri_messagetype (m_ecpri_messagetype),
      .m_ecpri_payloadsize (m_ecpri_payloadsize)
  );

  ecpri_deframer_iq i_iq (
      .clk                 (clk),
      .rst                 (rst),
      //
      .s_axis_tdata        (s2_axis_tdata),
      .s_axis_tkeep        (s2_axis_tkeep),
      .s_axis_tlast        (s2_axis_tlast),
      .s_axis_tvalid       (s2_axis_tvalid && (m_ecpri_messagetype == 0)),
      //
      .m_axis_tdata        (m_axis_tdata),
      .m_axis_tkeep        (m_axis_tkeep),
      .m_axis_tlast        (m_axis_tlast),
      .m_axis_tvalid       (m_axis_tvalid),
      //
      .m_trans_header_valid(m_trans_header_valid),
      .m_trans_rtc_pc_id   (m_trans_rtc_pc_id),
      .m_trans_seqid       (m_trans_seqid),
      .m_trans_ebit        (m_trans_ebit),
      .m_trans_subseqid    (m_trans_subseqid)
  );

  ecpri_deframer_odm i_odm (
      .clk                (clk),
      .rst                (rst),
      //
      .s_axis_tdata       (s2_axis_tdata),
      .s_axis_tkeep       (s2_axis_tkeep),
      .s_axis_tlast       (s2_axis_tlast),
      .s_axis_tvalid      (s2_axis_tvalid && (m_ecpri_messagetype == 5)),
      .s_axis_tuser       (s2_axis_tuser),
      //
      .m_odm_header_valid (m_odm_header_valid),
      .m_odm_measurementid(m_odm_measurementid),
      .m_odm_actiontype   (m_odm_actiontype),
      .m_odm_timestamp    (m_odm_timestamp),
      .m_odm_compensation (m_odm_compensation),
      .m_odm_timestamp2   (m_odm_timestamp2),
      //
      .stat_topology_id   (stat_topology_id)
  );

endmodule

`default_nettype wire
