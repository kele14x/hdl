// eCPRI Interface Slave IP Core
`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_if #(
    parameter int HAS_ODM_FUNCTION = 1,
    parameter int HAS_STATISTICS   = 1
) (
    // Ethernet I/F
    //-------------
    // Rx Ethernet ports
    input var         rx_eth_clk,
    input var         rx_eth_rst,
    //
    input var  [31:0] s_eth_defm_tdata,
    input var  [ 3:0] s_eth_defm_tkeep,
    input var         s_eth_defm_tlast,
    input var         s_eth_defm_tuser,
    input var         s_eth_defm_tvalid,
    // Tx Ethernet ports
    input var         tx_eth_clk,
    input var         tx_eth_rst,
    //
    output var [31:0] m_eth_fram_tdata,
    output var [ 3:0] m_eth_fram_tkeep,
    output var        m_eth_fram_tlast,
    output var        m_eth_fram_tuser,
    output var        m_eth_fram_tvalid,
    input var         m_eth_fram_tready,
    // PTP ports
    input var  [79:0] rx_ptp_timestamp,
    input var         rx_ptp_timestamp_valid,
    //
    output var [ 1:0] tx_ptp_1588op,
    output var [15:0] tx_ptp_tag_field,
    input var  [79:0] tx_ptp_timestamp,
    input var  [15:0] tx_ptp_timestamp_tag,
    input var         tx_ptp_timestamp_valid,
    // Internal interface
    //-------------------
    input var         clk,
    input var         rst,
    // Deframer ports
    output var [31:0] m_axis_tdata,
    output var [ 3:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var        m_axis_tvalid,
    //
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
    // PTP
    output var [31:0] m_ptp_tdata,
    output var [ 3:0] m_ptp_tkeep,
    output var        m_ptp_tlast,
    output var [79:0] m_ptp_tuser,
    output var        m_ptp_tvalid,
    input var         m_ptp_tready,
    // OAM
    output var [31:0] m_message_tdata,
    output var [ 3:0] m_message_tkeep,
    output var        m_message_tlast,
    output var        m_message_tvalid,
    input var         m_message_tready,
    // Framer ports
    input var  [31:0] s_axis_tdata,
    input var  [ 3:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var         s_axis_tvalid,
    output var        s_axis_tready,
    //
    input var  [ 7:0] s_trans_messagetype,
    input var  [15:0] s_trans_payloadsize,
    input var  [15:0] s_trans_rtc_pc_id,
    // PTP
    input var  [31:0] s_ptp_tdata,
    input var  [ 3:0] s_ptp_tkeep,
    input var         s_ptp_tlast,
    input var  [17:0] s_ptp_tuser,
    input var         s_ptp_tvalid,
    output var        s_ptp_tready,
    // OAM
    input var  [31:0] s_message_tdata,
    input var  [ 3:0] s_message_tkeep,
    input var         s_message_tlast,
    input var         s_message_tvalid,
    output var        s_message_tready,
    // Control & Status
    //-----------------
    input var         ctrl_clk,
    input var         ctrl_rst,
    //
    input var         ctrl_defm_reset,
    input var         ctrl_fram_reset,
    //
    input var         ctrl_defm_en,
    input var         ctrl_fram_en,
    //
    input var         ctrl_tick_snap,
    input var         ctrl_tick_clear,
    //
    input var  [47:0] ctrl_defm_dest_mac,
    input var  [47:0] ctrl_defm_src_mac,
    input var         ctrl_defm_has_vlan,
    input var  [15:0] ctrl_defm_vlan_tag,
    //
    input var         ctrl_defm_dest_mac_flt_en,
    input var         ctrl_defm_src_mac_flt_en,
    input var  [47:0] ctrl_defm_src_mac_flt_mask,
    input var         ctrl_defm_vlan_flt_en,
    input var  [15:0] ctrl_defm_vlan_flt_mask,
    //
    input var  [47:0] ctrl_fram_dest_mac,
    input var  [47:0] ctrl_fram_src_mac,
    input var         ctrl_fram_has_vlan,
    input var  [15:0] ctrl_fram_vlan_tag,
    //
    input var  [15:0] ctrl_topology_id,
    //
    input var         ctrl_odm_en,
    input var  [31:0] ctrl_odm_meas_interval,
    //
    output var [31:0] stat_defm_total_pkt_cnt,
    output var [31:0] stat_defm_ecpri_pkt_cnt,
    output var [31:0] stat_defm_trans_pkt_cnt,
    output var [31:0] stat_defm_odm_pkt_cnt,
    //
    output var [31:0] stat_fram_total_pkt_cnt,
    output var [31:0] stat_fram_ecpri_pkt_cnt,
    output var [31:0] stat_fram_trans_pkt_cnt,
    output var [31:0] stat_fram_odm_pkt_cnt,
    //
    output var [31:0] stat_ts_diff_ingress_ns,
    output var [47:0] stat_ts_diff_ingress_sec,
    //
    output var [31:0] stat_ts_diff_egress_ns,
    output var [47:0] stat_ts_diff_egress_sec,
    //
    output var [15:0] stat_topology_id
);

  wire unused_control_inputs = &{1'b0,
    ctrl_defm_reset, ctrl_fram_reset, ctrl_defm_en, ctrl_fram_en,
    ctrl_defm_dest_mac, ctrl_defm_src_mac, ctrl_defm_has_vlan, ctrl_defm_vlan_tag,
    ctrl_defm_dest_mac_flt_en, ctrl_defm_src_mac_flt_en, ctrl_defm_src_mac_flt_mask,
    ctrl_defm_vlan_flt_en, ctrl_defm_vlan_flt_mask
  };

  wire [79:0] tx_ptp_timestamp_s;
  wire [15:0] tx_ptp_timestamp_tag_s;
  wire tx_ptp_timestamp_valid_s;
  wire unused_tx_ptp_timestamp_ready;

  wire [15:0] stat_topology_id_s;

  wire s0_axis_odm_tvalid;
  wire s0_axis_odm_tready;

  wire [7:0] s0_odm_measurementid;
  wire [7:0] s0_odm_actiontype;
  wire [79:0] s0_odm_timestamp;
  wire [63:0] s0_odm_compensation;

  ecpri_deframer i_deframer (
      .rx_eth_clk            (rx_eth_clk),
      .rx_eth_rst            (rx_eth_rst),
      // Ethernet I/F
      .s_axis_tdata          (s_eth_defm_tdata),
      .s_axis_tkeep          (s_eth_defm_tkeep),
      .s_axis_tlast          (s_eth_defm_tlast),
      .s_axis_tuser          (s_eth_defm_tuser),
      .s_axis_tvalid         (s_eth_defm_tvalid),
      //
      .rx_ptp_timestamp      (rx_ptp_timestamp),
      .rx_ptp_timestamp_valid(rx_ptp_timestamp_valid),
      // Internal I/F
      .clk                   (clk),
      .rst                   (rst),
      //
      .m_axis_tdata          (m_axis_tdata),
      .m_axis_tkeep          (m_axis_tkeep),
      .m_axis_tlast          (m_axis_tlast),
      .m_axis_tvalid         (m_axis_tvalid),
      //
      .m_ptp_tdata           (m_ptp_tdata),
      .m_ptp_tkeep           (m_ptp_tkeep),
      .m_ptp_tlast           (m_ptp_tlast),
      .m_ptp_tuser           (m_ptp_tuser),
      .m_ptp_tvalid          (m_ptp_tvalid),
      .m_ptp_tready          (m_ptp_tready),
      //
      .m_message_tdata       (m_message_tdata),
      .m_message_tkeep       (m_message_tkeep),
      .m_message_tlast       (m_message_tlast),
      .m_message_tvalid      (m_message_tvalid),
      .m_message_tready      (m_message_tready),
      // eCPRI parse ports
      .m_mac_header_valid    (m_mac_header_valid),
      .m_mac_dest_mac        (m_mac_dest_mac),
      .m_mac_source_mac      (m_mac_source_mac),
      .m_mac_with_vlan       (m_mac_with_vlan),
      .m_mac_vlan_tag        (m_mac_vlan_tag),
      .m_mac_ethertype       (m_mac_ethertype),
      //
      .m_ecpri_header_valid  (m_ecpri_header_valid),
      .m_ecpri_concat        (m_ecpri_concat),
      .m_ecpri_messagetype   (m_ecpri_messagetype),
      .m_ecpri_payloadsize   (m_ecpri_payloadsize),
      //
      .m_trans_header_valid  (m_trans_header_valid),
      .m_trans_rtc_pc_id     (m_trans_rtc_pc_id),
      .m_trans_seqid         (m_trans_seqid),
      .m_trans_ebit          (m_trans_ebit),
      .m_trans_subseqid      (m_trans_subseqid),
      //
      .m_odm_header_valid    (m_odm_header_valid),
      .m_odm_measurementid   (m_odm_measurementid),
      .m_odm_actiontype      (m_odm_actiontype),
      .m_odm_timestamp       (m_odm_timestamp),
      .m_odm_compensation    (m_odm_compensation),
      .m_odm_timestamp2      (m_odm_timestamp2),
      //
      .stat_topology_id      (stat_topology_id_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (16)
  ) i_cdc_ctrl_topology_id (
      .src_clk (1'b1),
      .src_in  (stat_topology_id_s),
      //
      .dest_clk(ctrl_clk),
      .dest_out(stat_topology_id)
  );

  ecpri_framer i_framer (
      // Ethernet I/F
      .tx_eth_clk         (tx_eth_clk),
      .tx_eth_rst         (tx_eth_rst),
      //
      .m_axis_tdata       (m_eth_fram_tdata),
      .m_axis_tkeep       (m_eth_fram_tkeep),
      .m_axis_tlast       (m_eth_fram_tlast),
      .m_axis_tuser       (m_eth_fram_tuser),
      .m_axis_tvalid      (m_eth_fram_tvalid),
      .m_axis_tready      (m_eth_fram_tready),
      //
      .tx_ptp_1588op      (tx_ptp_1588op),
      .tx_ptp_tag_field   (tx_ptp_tag_field),
      // Internal I/F
      .clk                (clk),
      .rst                (rst),
      //
      .s_axis_tdata       (s_axis_tdata),
      .s_axis_tkeep       (s_axis_tkeep),
      .s_axis_tvalid      (s_axis_tvalid),
      .s_axis_tlast       (s_axis_tlast),
      .s_axis_tready      (s_axis_tready),
      //
      .s_trans_messagetype(s_trans_messagetype),
      .s_trans_payloadsize(s_trans_payloadsize),
      .s_trans_rtc_pc_id  (s_trans_rtc_pc_id),
      //
      .s_axis_odm_tvalid  (s0_axis_odm_tvalid),
      .s_axis_odm_tready  (s0_axis_odm_tready),
      //
      .s_odm_measurementid(s0_odm_measurementid),
      .s_odm_actiontype   (s0_odm_actiontype),
      .s_odm_timestamp    (s0_odm_timestamp),
      .s_odm_compensation (s0_odm_compensation),
      //
      .s_ptp_tdata        (s_ptp_tdata),
      .s_ptp_tkeep        (s_ptp_tkeep),
      .s_ptp_tlast        (s_ptp_tlast),
      .s_ptp_tuser        (s_ptp_tuser),
      .s_ptp_tvalid       (s_ptp_tvalid),
      .s_ptp_tready       (s_ptp_tready),
      //
      .s_message_tdata    (s_message_tdata),
      .s_message_tkeep    (s_message_tkeep),
      .s_message_tlast    (s_message_tlast),
      .s_message_tvalid   (s_message_tvalid),
      .s_message_tready   (s_message_tready),
      //
      .ctrl_dest_mac      (ctrl_fram_dest_mac),
      .ctrl_src_mac       (ctrl_fram_src_mac),
      .ctrl_has_vlan      (ctrl_fram_has_vlan),
      .ctrl_vlan_tag      (ctrl_fram_vlan_tag),
      //
      .ctrl_topology_id   (ctrl_topology_id)
  );

  generate
    if (HAS_ODM_FUNCTION != 0) begin : g_odm

      cdc_handshake_f #(
          .DEST_EXT_HSK(1),
          .DEST_SYNC_FF(4),
          .INIT_SYNC_FF(1),
          .SRC_SYNC_FF (4),
          .WIDTH       (96)
      ) i_cdc_tx_ptp_timestamp (
          .src_clk   (tx_eth_clk),
          .src_in    ({tx_ptp_timestamp_tag, tx_ptp_timestamp}),
          .src_valid (tx_ptp_timestamp_valid),
          .src_ready (unused_tx_ptp_timestamp_ready),
          //
          .dest_clk  (clk),
          .dest_out  ({tx_ptp_timestamp_tag_s, tx_ptp_timestamp_s}),
          .dest_valid(tx_ptp_timestamp_valid_s),
          .dest_ready(1'b1)
      );

      ecpri_odm i_odm (
          .clk                     (clk),
          .rst                     (rst),
          //
          .tx_ptp_timestamp        (tx_ptp_timestamp_s),
          .tx_ptp_timestamp_tag    (tx_ptp_timestamp_tag_s),
          .tx_ptp_timestamp_valid  (tx_ptp_timestamp_valid_s),
          //
          .s_odm_header_valid      (m_odm_header_valid),
          .s_odm_measurementid     (m_odm_measurementid),
          .s_odm_actiontype        (m_odm_actiontype),
          .s_odm_timestamp         (m_odm_timestamp),
          .s_odm_compensation      (m_odm_compensation),
          .s_odm_timestamp2        (m_odm_timestamp2),
          //
          .m_axis_tvalid           (s0_axis_odm_tvalid),
          .m_axis_tready           (s0_axis_odm_tready),
          //
          .m_odm_measurementid     (s0_odm_measurementid),
          .m_odm_actiontype        (s0_odm_actiontype),
          .m_odm_timestamp         (s0_odm_timestamp),
          .m_odm_compensation      (s0_odm_compensation),
          //
          .ctrl_clk                (ctrl_clk),
          .ctrl_rst                (ctrl_rst),
          //
          .ctrl_en                 (ctrl_odm_en),
          .ctrl_meas_interval      (ctrl_odm_meas_interval),
          //
          .stat_ts_diff_ingress_ns (stat_ts_diff_ingress_ns),
          .stat_ts_diff_ingress_sec(stat_ts_diff_ingress_sec),
          //
          .stat_ts_diff_egress_ns  (stat_ts_diff_egress_ns),
          .stat_ts_diff_egress_sec (stat_ts_diff_egress_sec)
      );

    end
  endgenerate

  generate
    if (HAS_STATISTICS != 0) begin : g_statistics

      ecpri_statistics i_statistics (
          .clk                    (clk),
          .rst                    (rst),
          // Deframer ports
          .m_mac_header_valid     (m_mac_header_valid),
          .m_mac_dest_mac         (m_mac_dest_mac),
          .m_mac_source_mac       (m_mac_source_mac),
          .m_mac_with_vlan        (m_mac_with_vlan),
          .m_mac_vlan_tag         (m_mac_vlan_tag),
          .m_mac_ethertype        (m_mac_ethertype),
          //
          .m_ecpri_header_valid   (m_ecpri_header_valid),
          .m_ecpri_concat         (m_ecpri_concat),
          .m_ecpri_messagetype    (m_ecpri_messagetype),
          .m_ecpri_payloadsize    (m_ecpri_payloadsize),
          //
          .m_trans_header_valid   (m_trans_header_valid),
          .m_trans_rtc_pc_id      (m_trans_rtc_pc_id),
          .m_trans_seqid          (m_trans_seqid),
          .m_trans_ebit           (m_trans_ebit),
          .m_trans_subseqid       (m_trans_subseqid),
          //
          .m_odm_header_valid     (m_odm_header_valid),
          .m_odm_measurementid    (m_odm_measurementid),
          .m_odm_actiontype       (m_odm_actiontype),
          .m_odm_timestamp        (m_odm_timestamp),
          .m_odm_compensation     (m_odm_compensation),
          .m_odm_timestamp2       (m_odm_timestamp2),
          // Framer ports
          .s_trans_header_valid   (s_axis_tvalid && s_axis_tready && s_axis_tlast),
          .s_trans_messagetype    (s_trans_messagetype),
          .s_trans_payloadsize    (s_trans_payloadsize),
          .s_trans_rtc_pc_id      (s_trans_rtc_pc_id),
          //
          .s_odm_header_valid     (s0_axis_odm_tvalid && s0_axis_odm_tready),
          .s_odm_measurementid    (s0_odm_measurementid),
          .s_odm_actiontype       (s0_odm_actiontype),
          .s_odm_timestamp        (s0_odm_timestamp),
          .s_odm_compensation     (s0_odm_compensation),
          // Control & Status
          .ctrl_clk               (ctrl_clk),
          .ctrl_rst               (ctrl_rst),
          //
          .ctrl_tick_snap         (ctrl_tick_snap),
          .ctrl_tick_clear        (ctrl_tick_clear),
          //
          .stat_defm_total_pkt_cnt(stat_defm_total_pkt_cnt),
          .stat_defm_ecpri_pkt_cnt(stat_defm_ecpri_pkt_cnt),
          .stat_defm_trans_pkt_cnt(stat_defm_trans_pkt_cnt),
          .stat_defm_odm_pkt_cnt  (stat_defm_odm_pkt_cnt),
          //
          .stat_fram_total_pkt_cnt(stat_fram_total_pkt_cnt),
          .stat_fram_ecpri_pkt_cnt(stat_fram_ecpri_pkt_cnt),
          .stat_fram_trans_pkt_cnt(stat_fram_trans_pkt_cnt),
          .stat_fram_odm_pkt_cnt  (stat_fram_odm_pkt_cnt)
      );

    end
  endgenerate

endmodule

`default_nettype wire
