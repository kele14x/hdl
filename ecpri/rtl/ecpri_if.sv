// eCPRI Interface Slave IP Core
`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_if #(
    parameter logic HAS_ODM_FUNCTION = 1'b1,
    parameter logic HAS_STATISTICS   = 1'b1
) (
    // Ethernet I/F
    //-------------
    // Rx Ethernet ports
    input  wire        rx_eth_clk,
    input  wire        rx_eth_rst,
    //
    input  wire [31:0] s_eth_defm_tdata,
    input  wire [ 3:0] s_eth_defm_tkeep,
    input  wire        s_eth_defm_tlast,
    input  wire        s_eth_defm_tuser,
    input  wire        s_eth_defm_tvalid,
    // Tx Ethernet ports
    input  wire        tx_eth_clk,
    input  wire        tx_eth_rst,
    //
    output wire [31:0] m_eth_fram_tdata,
    output wire [ 3:0] m_eth_fram_tkeep,
    output wire        m_eth_fram_tlast,
    output wire        m_eth_fram_tuser,
    output wire        m_eth_fram_tvalid,
    input  wire        m_eth_fram_tready,
    // PTP ports
    input  wire [79:0] rx_ptp_timestamp,
    input  wire        rx_ptp_timestamp_valid,
    //
    output wire [ 1:0] tx_ptp_1588op,
    output wire [15:0] tx_ptp_tag_field,
    input  wire [79:0] tx_ptp_timestamp,
    input  wire [15:0] tx_ptp_timestamp_tag,
    input  wire        tx_ptp_timestamp_valid,
    // Internal interface
    //-------------------
    input  wire        clk,
    input  wire        rst,
    // Deframer ports
    output wire [31:0] m_axis_tdata,
    output wire [ 3:0] m_axis_tkeep,
    output wire        m_axis_tlast,
    output wire        m_axis_tvalid,
    //
    output wire        m_mac_header_valid,
    output wire [47:0] m_mac_dest_mac,
    output wire [47:0] m_mac_source_mac,
    output wire        m_mac_with_vlan,
    output wire [15:0] m_mac_vlan_tag,
    output wire [15:0] m_mac_ethertype,
    //
    output wire        m_ecpri_header_valid,
    output wire        m_ecpri_concat,
    output wire [ 7:0] m_ecpri_messagetype,
    output wire [15:0] m_ecpri_payloadsize,
    //
    output wire        m_trans_header_valid,
    output wire [15:0] m_trans_rtc_pc_id,
    output wire [ 7:0] m_trans_seqid,
    output wire        m_trans_ebit,
    output wire [ 6:0] m_trans_subseqid,
    //
    output wire        m_odm_header_valid,
    output wire [ 7:0] m_odm_measurementid,
    output wire [ 7:0] m_odm_actiontype,
    output wire [79:0] m_odm_timestamp,
    output wire [63:0] m_odm_compensation,
    output wire [79:0] m_odm_timestamp2,
    // PTP
    output wire [31:0] m_ptp_tdata,
    output wire [ 3:0] m_ptp_tkeep,
    output wire        m_ptp_tlast,
    output wire [79:0] m_ptp_tuser,
    output wire        m_ptp_tvalid,
    input  wire        m_ptp_tready,
    // OAM
    output wire [31:0] m_message_tdata,
    output wire [ 3:0] m_message_tkeep,
    output wire        m_message_tlast,
    output wire        m_message_tvalid,
    input  wire        m_message_tready,
    // Framer ports
    input  wire [31:0] s_axis_tdata,
    input  wire [ 3:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    //
    input  wire [ 7:0] s_trans_messagetype,
    input  wire [15:0] s_trans_payloadsize,
    input  wire [15:0] s_trans_rtc_pc_id,
    // PTP
    input  wire [31:0] s_ptp_tdata,
    input  wire [ 3:0] s_ptp_tkeep,
    input  wire        s_ptp_tlast,
    input  wire [17:0] s_ptp_tuser,
    input  wire        s_ptp_tvalid,
    output wire        s_ptp_tready,
    // OAM
    input  wire [31:0] s_message_tdata,
    input  wire [ 3:0] s_message_tkeep,
    input  wire        s_message_tlast,
    input  wire        s_message_tvalid,
    output wire        s_message_tready,
    // Control & Status
    //-----------------
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    input  wire        ctrl_defm_reset,
    input  wire        ctrl_fram_reset,
    //
    input  wire        ctrl_defm_en,
    input  wire        ctrl_fram_en,
    //
    input  wire        ctrl_tick_snap,
    input  wire        ctrl_tick_clear,
    //
    input  wire [47:0] ctrl_defm_dest_mac,
    input  wire [47:0] ctrl_defm_src_mac,
    input  wire        ctrl_defm_has_vlan,
    input  wire [15:0] ctrl_defm_vlan_tag,
    //
    input  wire        ctrl_defm_dest_mac_flt_en,
    input  wire        ctrl_defm_src_mac_flt_en,
    input  wire [47:0] ctrl_defm_src_mac_flt_mask,
    input  wire        ctrl_defm_vlan_flt_en,
    input  wire [15:0] ctrl_defm_vlan_flt_mask,
    //
    input  wire [47:0] ctrl_fram_dest_mac,
    input  wire [47:0] ctrl_fram_src_mac,
    input  wire        ctrl_fram_has_vlan,
    input  wire [15:0] ctrl_fram_vlan_tag,
    //
    input  wire [15:0] ctrl_topology_id,
    //
    input  wire        ctrl_odm_en,
    input  wire [31:0] ctrl_odm_meas_interval,
    //
    output wire [31:0] stat_defm_total_pkt_cnt,
    output wire [31:0] stat_defm_ecpri_pkt_cnt,
    output wire [31:0] stat_defm_trans_pkt_cnt,
    output wire [31:0] stat_defm_odm_pkt_cnt,
    //
    output wire [31:0] stat_fram_total_pkt_cnt,
    output wire [31:0] stat_fram_ecpri_pkt_cnt,
    output wire [31:0] stat_fram_trans_pkt_cnt,
    output wire [31:0] stat_fram_odm_pkt_cnt,
    //
    output wire [31:0] stat_ts_diff_ingress_ns,
    output wire [47:0] stat_ts_diff_ingress_sec,
    //
    output wire [31:0] stat_ts_diff_egress_ns,
    output wire [47:0] stat_ts_diff_egress_sec,
    //
    output wire [15:0] stat_topology_id
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
    if (HAS_ODM_FUNCTION) begin : g_odm

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
    if (HAS_STATISTICS) begin : g_statistics

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
