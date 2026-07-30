`timescale 1 ns / 1 ps
//
`default_nettype none

module coe (
    // AXI4-Lite
    //----------
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,
    //
    input  wire [ 31:0] s_axi_awaddr,
    input  wire [  2:0] s_axi_awprot,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,
    //
    input  wire [ 31:0] s_axi_wdata,
    input  wire [  3:0] s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,
    //
    output wire [  1:0] s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,
    //
    input  wire [ 31:0] s_axi_araddr,
    input  wire [  2:0] s_axi_arprot,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,
    //
    output wire [ 31:0] s_axi_rdata,
    output wire [  1:0] s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,
    // Ethernet
    //---------
    // Ethernet Rx
    input  wire         rx_eth_clk,
    input  wire         rx_eth_rst,
    //
    input  wire [ 31:0] s_eth_rx_tdata,
    input  wire [  3:0] s_eth_rx_tkeep,
    input  wire         s_eth_rx_tlast,
    input  wire         s_eth_rx_tuser,
    input  wire         s_eth_rx_tvalid,
    // Ethernet Tx
    input  wire         tx_eth_clk,
    input  wire         tx_eth_rst,
    //
    output wire [ 31:0] m_eth_tx_tdata,
    output wire [  3:0] m_eth_tx_tkeep,
    output wire         m_eth_tx_tlast,
    output wire         m_eth_tx_tuser,
    output wire         m_eth_tx_tvalid,
    input  wire         m_eth_tx_tready,
    // PTP interface
    input  wire [ 79:0] rx_ptp_timestamp,
    input  wire         rx_ptp_timestamp_valid,
    //
    output wire [  1:0] tx_ptp_1588op,
    output wire [ 15:0] tx_ptp_tag_field,
    input  wire [ 79:0] tx_ptp_timestamp,
    input  wire [ 15:0] tx_ptp_timestamp_tag,
    input  wire         tx_ptp_timestamp_valid,
    // Timer ports
    output wire [ 79:0] ctl_rx_systemtimer,
    output wire [ 79:0] ctl_tx_systemtimer,
    // GPIO
    input  wire         stat_rx_status,
    // Internal Clock Domain
    //----------------------
    input  wire         clk,
    input  wire         rst,
    //
    input  wire         pps_in,
    //
    input  wire [ 47:0] tod_sec,
    input  wire [ 31:0] tod_ns,
    //
    input  wire [ 15:0] topology_id,
    // Message I/F
    output wire [ 31:0] m_message_tdata,
    output wire [  3:0] m_message_tkeep,
    output wire         m_message_tlast,
    output wire         m_message_tvalid,
    input  wire         m_message_tready,
    //
    input  wire [ 31:0] s_message_tdata,
    input  wire [  3:0] s_message_tkeep,
    input  wire         s_message_tlast,
    input  wire         s_message_tvalid,
    output wire         s_message_tready,
    // Radio I/F
    output wire [767:0] m_axis_rx_tdata,
    output wire [  7:0] m_axis_rx_tuser,
    output wire         m_axis_rx_tlast,
    output wire         m_axis_rx_tvalid,
    input  wire         m_axis_rx_tready,
    //
    input  wire [767:0] s_axis_tx_tdata,
    input  wire [  7:0] s_axis_tx_tuser,
    input  wire         s_axis_tx_tlast,
    input  wire         s_axis_tx_tvalid,
    output wire         s_axis_tx_tready
);

  // Signals

  wire        stat_rx_status_cdc;

  wire        ctrl_tick_snap;
  wire        ctrl_tick_clear;

  // Deframer signals

  wire        ctrl_defm_en;
  wire        ctrl_defm_reset;

  wire [15:0] ctrl_defm_seq_en;
  wire [95:0] ctrl_defm_seq_id;

  wire [ 8:0] ctrl_defm_ts_offset;

  wire [47:0] ctrl_defm_dest_mac;
  wire [47:0] ctrl_defm_src_mac;
  wire        ctrl_defm_has_vlan;
  wire [15:0] ctrl_defm_vlan_tag;

  wire        ctrl_defm_src_mac_flt_en;
  wire        ctrl_defm_dest_mac_flt_en;
  wire [47:0] ctrl_defm_src_mac_flt_mask;
  wire        ctrl_defm_vlan_flt_en;
  wire [15:0] ctrl_defm_vlan_flt_mask;

  wire [31:0] stat_defm_total_pkt_cnt;
  wire [31:0] stat_defm_ecpri_pkt_cnt;
  wire [31:0] stat_defm_trans_pkt_cnt;
  wire [31:0] stat_defm_odm_pkt_cnt;

  wire [31:0] stat_defm_conflict_cnt;

  // Framer signals

  wire        ctrl_fram_en;
  wire        ctrl_fram_reset;

  wire [15:0] ctrl_fram_seq_en;
  wire [95:0] ctrl_fram_seq_id;
  wire [ 7:0] ctrl_fram_seq_cnt;

  wire [47:0] ctrl_fram_dest_mac;
  wire [47:0] ctrl_fram_src_mac;
  wire        ctrl_fram_has_vlan;
  wire [15:0] ctrl_fram_vlan_tag;

  wire [31:0] stat_fram_total_pkt_cnt;
  wire [31:0] stat_fram_ecpri_pkt_cnt;
  wire [31:0] stat_fram_trans_pkt_cnt;
  wire [31:0] stat_fram_odm_pkt_cnt;

  // ODM signals

  wire        ctrl_odm_en;
  wire [31:0] ctrl_odm_meas_interval;

  wire [31:0] stat_ts_diff_ingress_ns;
  wire [47:0] stat_ts_diff_ingress_sec;

  wire [31:0] stat_ts_diff_egress_ns;
  wire [47:0] stat_ts_diff_egress_sec;

  wire [31:0] stat_rx_resync_cnt;
  wire [31:0] stat_tx_resync_cnt;

  wire [15:0] stat_topology_id;
  wire [15:0] stat_lp_topology_id;

  // Transaction signals

  wire [31:0] m0_axis_tdata;
  wire [ 3:0] m0_axis_tkeep;
  wire        m0_axis_tlast;
  wire        m0_axis_tvalid;
  //
  wire        m0_mac_header_valid;
  wire [47:0] m0_mac_dest_mac;
  wire [47:0] m0_mac_source_mac;
  wire        m0_mac_with_vlan;
  wire [15:0] m0_mac_vlan_tag;
  wire [15:0] m0_mac_ethertype;

  wire        m0_ecpri_header_valid;
  wire        m0_ecpri_concat;
  wire [ 7:0] m0_ecpri_messagetype;
  wire [15:0] m0_ecpri_payloadsize;
  //
  wire        m0_trans_header_valid;
  wire [15:0] m0_trans_rtc_pc_id;
  wire [ 7:0] m0_trans_seqid;
  wire        m0_trans_ebit;
  wire [ 6:0] m0_trans_subseqid;
  //
  wire        m0_odm_header_valid;
  wire [ 7:0] m0_odm_measurementid;
  wire [ 7:0] m0_odm_actiontype;
  wire [79:0] m0_odm_timestamp;
  wire [63:0] m0_odm_compensation;
  wire [79:0] m0_odm_timestamp2;

  wire [31:0] s0_axis_tdata;
  wire [ 3:0] s0_axis_tkeep;
  wire        s0_axis_tlast;
  wire        s0_axis_tvalid;
  wire        s0_axis_tready;
  //
  wire [ 7:0] s0_trans_messagetype;
  wire [15:0] s0_trans_payloadsize;
  wire [15:0] s0_trans_rtc_pc_id;

  wire unused_axi_addr = &{1'b0, s_axi_awaddr[31:10], s_axi_araddr[31:10],
    stat_fram_total_pkt_cnt, stat_fram_ecpri_pkt_cnt, stat_fram_trans_pkt_cnt,
    stat_fram_odm_pkt_cnt,
    m0_mac_header_valid, m0_mac_dest_mac, m0_mac_source_mac, m0_mac_with_vlan,
    m0_mac_vlan_tag, m0_mac_ethertype, m0_ecpri_header_valid, m0_ecpri_concat,
    m0_ecpri_messagetype, m0_ecpri_payloadsize, m0_odm_header_valid,
    m0_odm_measurementid, m0_odm_actiontype, m0_odm_timestamp,
    m0_odm_compensation, m0_odm_timestamp2};

  assign ctrl_defm_reset = 1'b0;
  assign ctrl_fram_reset = 1'b0;
  assign ctrl_defm_has_vlan = 1'b0;
  assign ctrl_defm_vlan_tag = 16'd0;
  assign ctrl_defm_src_mac_flt_mask = 48'd0;
  assign ctrl_defm_vlan_flt_en = 1'b0;
  assign ctrl_defm_vlan_flt_mask = 16'd0;

  wire [31:0] unused_ptp_tdata;
  wire [ 3:0] unused_ptp_tkeep;
  wire        unused_ptp_tlast;
  wire [79:0] unused_ptp_tuser;
  wire        unused_ptp_tvalid;
  wire        unused_s_ptp_tready;

  // Main

  coe_regs i_regs (
      .s_axi_aclk                   (s_axi_aclk),
      .s_axi_aresetn                (s_axi_aresetn),
      //
      .s_axi_awaddr                 (s_axi_awaddr[9:0]),
      .s_axi_awprot                 (s_axi_awprot),
      .s_axi_awvalid                (s_axi_awvalid),
      .s_axi_awready                (s_axi_awready),
      //
      .s_axi_wdata                  (s_axi_wdata),
      .s_axi_wstrb                  (s_axi_wstrb),
      .s_axi_wvalid                 (s_axi_wvalid),
      .s_axi_wready                 (s_axi_wready),
      //
      .s_axi_bresp                  (s_axi_bresp),
      .s_axi_bvalid                 (s_axi_bvalid),
      .s_axi_bready                 (s_axi_bready),
      //
      .s_axi_araddr                 (s_axi_araddr[9:0]),
      .s_axi_arprot                 (s_axi_arprot),
      .s_axi_arvalid                (s_axi_arvalid),
      .s_axi_arready                (s_axi_arready),
      //
      .s_axi_rdata                  (s_axi_rdata),
      .s_axi_rresp                  (s_axi_rresp),
      .s_axi_rvalid                 (s_axi_rvalid),
      .s_axi_rready                 (s_axi_rready),
      // stat.rx_status,
      .stat_rx_status_in            (stat_rx_status_cdc),
      // tick.snap,
      .tick_snap_in                 (1'b0),
      .tick_snap_out                (ctrl_tick_snap),
      // tick.clear,
      .tick_clear_in                (1'b0),
      .tick_clear_out               (ctrl_tick_clear),
      // defm_ctrl.en,
      .defm_ctrl_en_out             (ctrl_defm_en),
      // defm_ctrl.src_mac_flt_en,
      .defm_ctrl_src_mac_flt_en_out (ctrl_defm_src_mac_flt_en),
      // defm_ctrl.dest_mac_flt_en,
      .defm_ctrl_dest_mac_flt_en_out(ctrl_defm_dest_mac_flt_en),
      // defm_src_mac_l.val,
      .defm_src_mac_l_val_out       (ctrl_defm_src_mac[31:0]),
      // defm_src_mac_h.val,
      .defm_src_mac_h_val_out       (ctrl_defm_src_mac[47:32]),
      // defm_dest_mac_l.val,
      .defm_dest_mac_l_val_out      (ctrl_defm_dest_mac[31:0]),
      // defm_dest_mac_h.val,
      .defm_dest_mac_h_val_out      (ctrl_defm_dest_mac[47:32]),
      // defm_seq_en.val,
      .defm_seq_en_val_out          (ctrl_defm_seq_en),
      // defm_seq_id_0.id0,
      .defm_seq_id_0_id0_out        (ctrl_defm_seq_id[5:0]),
      // defm_seq_id_0.id1,
      .defm_seq_id_0_id1_out        (ctrl_defm_seq_id[11:6]),
      // defm_seq_id_0.id2,
      .defm_seq_id_0_id2_out        (ctrl_defm_seq_id[17:12]),
      // defm_seq_id_0.id3,
      .defm_seq_id_0_id3_out        (ctrl_defm_seq_id[23:18]),
      // defm_seq_id_1.id0,
      .defm_seq_id_1_id0_out        (ctrl_defm_seq_id[29:24]),
      // defm_seq_id_1.id1,
      .defm_seq_id_1_id1_out        (ctrl_defm_seq_id[35:30]),
      // defm_seq_id_1.id2,
      .defm_seq_id_1_id2_out        (ctrl_defm_seq_id[41:36]),
      // defm_seq_id_1.id3,
      .defm_seq_id_1_id3_out        (ctrl_defm_seq_id[47:42]),
      // defm_seq_id_2.id0,
      .defm_seq_id_2_id0_out        (ctrl_defm_seq_id[53:48]),
      // defm_seq_id_2.id1,
      .defm_seq_id_2_id1_out        (ctrl_defm_seq_id[59:54]),
      // defm_seq_id_2.id2,
      .defm_seq_id_2_id2_out        (ctrl_defm_seq_id[65:60]),
      // defm_seq_id_2.id3,
      .defm_seq_id_2_id3_out        (ctrl_defm_seq_id[71:66]),
      // defm_seq_id_3.id0,
      .defm_seq_id_3_id0_out        (ctrl_defm_seq_id[77:72]),
      // defm_seq_id_3.id1,
      .defm_seq_id_3_id1_out        (ctrl_defm_seq_id[83:78]),
      // defm_seq_id_3.id2,
      .defm_seq_id_3_id2_out        (ctrl_defm_seq_id[89:84]),
      // defm_seq_id_3.id3,
      .defm_seq_id_3_id3_out        (ctrl_defm_seq_id[95:90]),
      // defm_ts_offset.val,
      .defm_ts_offset_val_out       (ctrl_defm_ts_offset),
      // defm_conflict_cnt.val,
      .defm_conflict_cnt_val_in     (stat_defm_conflict_cnt),
      // defm_total_pkt_cnt.val,
      .defm_total_pkt_cnt_val_in    (stat_defm_total_pkt_cnt),
      // defm_ecpri_pkt_cnt.val,
      .defm_ecpri_pkt_cnt_val_in    (stat_defm_ecpri_pkt_cnt),
      // defm_trans_pkt_cnt.val,
      .defm_trans_pkt_cnt_val_in    (stat_defm_trans_pkt_cnt),
      // defm_odm_pkt_cnt.val,
      .defm_odm_pkt_cnt_val_in      (stat_defm_odm_pkt_cnt),
      // fram_ctrl.en,
      .fram_ctrl_en_out             (ctrl_fram_en),
      // fram_dest_mac_l.val,
      .fram_dest_mac_l_val_out      (ctrl_fram_dest_mac[31:0]),
      // fram_dest_mac_h.val,
      .fram_dest_mac_h_val_out      (ctrl_fram_dest_mac[47:32]),
      // fram_src_mac_l.val,
      .fram_src_mac_l_val_out       (ctrl_fram_src_mac[31:0]),
      // fram_src_mac_h.val,
      .fram_src_mac_h_val_out       (ctrl_fram_src_mac[47:32]),
      // fram_vlan_ctrl.vlan_tag,
      .fram_vlan_ctrl_vlan_tag_out  (ctrl_fram_vlan_tag),
      // fram_vlan_ctrl.has_vlan,
      .fram_vlan_ctrl_has_vlan_out  (ctrl_fram_has_vlan),
      // fram_seq_en.val,
      .fram_seq_en_val_out          (ctrl_fram_seq_en),
      // fram_seq_id_0.id0,
      .fram_seq_id_0_id0_out        (ctrl_fram_seq_id[5:0]),
      // fram_seq_id_0.id1,
      .fram_seq_id_0_id1_out        (ctrl_fram_seq_id[11:6]),
      // fram_seq_id_0.id2,
      .fram_seq_id_0_id2_out        (ctrl_fram_seq_id[17:12]),
      // fram_seq_id_0.id3,
      .fram_seq_id_0_id3_out        (ctrl_fram_seq_id[23:18]),
      // fram_seq_id_1.id0,
      .fram_seq_id_1_id0_out        (ctrl_fram_seq_id[29:24]),
      // fram_seq_id_1.id1,
      .fram_seq_id_1_id1_out        (ctrl_fram_seq_id[35:30]),
      // fram_seq_id_1.id2,
      .fram_seq_id_1_id2_out        (ctrl_fram_seq_id[41:36]),
      // fram_seq_id_1.id3,
      .fram_seq_id_1_id3_out        (ctrl_fram_seq_id[47:42]),
      // fram_seq_id_2.id0,
      .fram_seq_id_2_id0_out        (ctrl_fram_seq_id[53:48]),
      // fram_seq_id_2.id1,
      .fram_seq_id_2_id1_out        (ctrl_fram_seq_id[59:54]),
      // fram_seq_id_2.id2,
      .fram_seq_id_2_id2_out        (ctrl_fram_seq_id[65:60]),
      // fram_seq_id_2.id3,
      .fram_seq_id_2_id3_out        (ctrl_fram_seq_id[71:66]),
      // fram_seq_id_3.id0,
      .fram_seq_id_3_id0_out        (ctrl_fram_seq_id[77:72]),
      // fram_seq_id_3.id1,
      .fram_seq_id_3_id1_out        (ctrl_fram_seq_id[83:78]),
      // fram_seq_id_3.id2,
      .fram_seq_id_3_id2_out        (ctrl_fram_seq_id[89:84]),
      // fram_seq_id_3.id3,
      .fram_seq_id_3_id3_out        (ctrl_fram_seq_id[95:90]),
      // fram_seq_cnt.val,
      .fram_seq_cnt_val_out         (ctrl_fram_seq_cnt),
      // odm_ctrl.en,
      .odm_ctrl_en_out              (ctrl_odm_en),
      // odm_meas_interval.val,
      .odm_meas_interval_val_out    (ctrl_odm_meas_interval),
      // ts_diff_ingress_ns.val,
      .ts_diff_ingress_ns_val_in    (stat_ts_diff_ingress_ns),
      // ts_diff_ingress_sec_l.val,
      .ts_diff_ingress_sec_l_val_in (stat_ts_diff_ingress_sec[31:0]),
      // ts_diff_ingress_sec_h.val,
      .ts_diff_ingress_sec_h_val_in (stat_ts_diff_ingress_sec[47:32]),
      // ts_diff_egress_ns.val,
      .ts_diff_egress_ns_val_in     (stat_ts_diff_egress_ns),
      // ts_diff_egress_sec_l.val,
      .ts_diff_egress_sec_l_val_in  (stat_ts_diff_egress_sec[31:0]),
      // ts_diff_egress_sec_h.val,
      .ts_diff_egress_sec_h_val_in  (stat_ts_diff_egress_sec[47:32]),
      // rx_resync_cnt.val,
      .rx_resync_cnt_val_in         (stat_rx_resync_cnt),
      // tx_resync_cnt.val,
      .tx_resync_cnt_val_in         (stat_tx_resync_cnt),
      // topology_id.val,
      .topology_id_val_in           (stat_topology_id),
      // lp_topology_id.val,
      .lp_topology_id_val_in        (stat_lp_topology_id)
  );

  cdc_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0)
  ) i_cdc_rx_status (
      .src_clk (1'b1),
      .src_in  (stat_rx_status),
      //
      .dest_clk(s_axi_aclk),
      .dest_out(stat_rx_status_cdc)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (16)
  ) i_cdc_ctrl_topology_id (
      .src_clk (1'b1),
      .src_in  (topology_id),
      //
      .dest_clk(s_axi_aclk),
      .dest_out(stat_topology_id)
  );

  ecpri_if #(
      .HAS_ODM_FUNCTION(1),
      .HAS_STATISTICS  (1)
  ) i_ecpri_if (
      // Ethernet I/F
      //-------------
      // Rx Ethernet ports
      .rx_eth_clk                (rx_eth_clk),
      .rx_eth_rst                (rx_eth_rst),
      //
      .s_eth_defm_tdata          (s_eth_rx_tdata),
      .s_eth_defm_tkeep          (s_eth_rx_tkeep),
      .s_eth_defm_tlast          (s_eth_rx_tlast),
      .s_eth_defm_tuser          (s_eth_rx_tuser),
      .s_eth_defm_tvalid         (s_eth_rx_tvalid),
      // Tx Ethernet ports
      .tx_eth_clk                (tx_eth_clk),
      .tx_eth_rst                (tx_eth_rst),
      //
      .m_eth_fram_tdata          (m_eth_tx_tdata),
      .m_eth_fram_tkeep          (m_eth_tx_tkeep),
      .m_eth_fram_tlast          (m_eth_tx_tlast),
      .m_eth_fram_tuser          (m_eth_tx_tuser),
      .m_eth_fram_tvalid         (m_eth_tx_tvalid),
      .m_eth_fram_tready         (m_eth_tx_tready),
      // PTP ports
      .rx_ptp_timestamp          (rx_ptp_timestamp),
      .rx_ptp_timestamp_valid    (rx_ptp_timestamp_valid),
      //
      .tx_ptp_1588op             (tx_ptp_1588op),
      .tx_ptp_tag_field          (tx_ptp_tag_field),
      .tx_ptp_timestamp          (tx_ptp_timestamp),
      .tx_ptp_timestamp_tag      (tx_ptp_timestamp_tag),
      .tx_ptp_timestamp_valid    (tx_ptp_timestamp_valid),
      // Internal interface
      //-------------------
      .clk                       (clk),
      .rst                       (rst),
      // Deframer ports !@rx_eth_clk
      .m_axis_tdata              (m0_axis_tdata),
      .m_axis_tkeep              (m0_axis_tkeep),
      .m_axis_tlast              (m0_axis_tlast),
      .m_axis_tvalid             (m0_axis_tvalid),
      //
      .m_mac_header_valid        (m0_mac_header_valid),
      .m_mac_dest_mac            (m0_mac_dest_mac),
      .m_mac_source_mac          (m0_mac_source_mac),
      .m_mac_with_vlan           (m0_mac_with_vlan),
      .m_mac_vlan_tag            (m0_mac_vlan_tag),
      .m_mac_ethertype           (m0_mac_ethertype),
      //
      .m_ecpri_header_valid      (m0_ecpri_header_valid),
      .m_ecpri_concat            (m0_ecpri_concat),
      .m_ecpri_messagetype       (m0_ecpri_messagetype),
      .m_ecpri_payloadsize       (m0_ecpri_payloadsize),
      //
      .m_trans_header_valid      (m0_trans_header_valid),
      .m_trans_rtc_pc_id         (m0_trans_rtc_pc_id),
      .m_trans_seqid             (m0_trans_seqid),
      .m_trans_ebit              (m0_trans_ebit),
      .m_trans_subseqid          (m0_trans_subseqid),
      //
      .m_odm_header_valid        (m0_odm_header_valid),
      .m_odm_measurementid       (m0_odm_measurementid),
      .m_odm_actiontype          (m0_odm_actiontype),
      .m_odm_timestamp           (m0_odm_timestamp),
      .m_odm_compensation        (m0_odm_compensation),
      .m_odm_timestamp2          (m0_odm_timestamp2),
      // PTP
      .m_ptp_tdata               (unused_ptp_tdata),
      .m_ptp_tkeep               (unused_ptp_tkeep),
      .m_ptp_tlast               (unused_ptp_tlast),
      .m_ptp_tuser               (unused_ptp_tuser),
      .m_ptp_tvalid              (unused_ptp_tvalid),
      .m_ptp_tready              (1'b1),
      // Message
      .m_message_tdata           (m_message_tdata),
      .m_message_tkeep           (m_message_tkeep),
      .m_message_tlast           (m_message_tlast),
      .m_message_tvalid          (m_message_tvalid),
      .m_message_tready          (m_message_tready),
      // Framer ports !@tx_eth_clk
      .s_axis_tdata              (s0_axis_tdata),
      .s_axis_tkeep              (s0_axis_tkeep),
      .s_axis_tlast              (s0_axis_tlast),
      .s_axis_tvalid             (s0_axis_tvalid),
      .s_axis_tready             (s0_axis_tready),
      //
      .s_trans_messagetype       (s0_trans_messagetype),
      .s_trans_payloadsize       (s0_trans_payloadsize),
      .s_trans_rtc_pc_id         (s0_trans_rtc_pc_id),
      // PTP
      .s_ptp_tdata               ('b0),
      .s_ptp_tkeep               ('b0),
      .s_ptp_tlast               ('b0),
      .s_ptp_tuser               ('b0),
      .s_ptp_tvalid              ('b0),
      .s_ptp_tready              (unused_s_ptp_tready),
      // Message
      .s_message_tdata           (s_message_tdata),
      .s_message_tkeep           (s_message_tkeep),
      .s_message_tlast           (s_message_tlast),
      .s_message_tvalid          (s_message_tvalid),
      .s_message_tready          (s_message_tready),
      // Control & Status
      //-----------------
      .ctrl_clk                  (s_axi_aclk),
      .ctrl_rst                  (~s_axi_aresetn),
      //
      .ctrl_defm_reset           (ctrl_defm_reset),
      .ctrl_fram_reset           (ctrl_fram_reset),
      //
      .ctrl_defm_en              (ctrl_defm_en),
      .ctrl_fram_en              (ctrl_fram_en),
      //
      .ctrl_tick_snap            (ctrl_tick_snap),
      .ctrl_tick_clear           (ctrl_tick_clear),
      //
      .ctrl_defm_dest_mac        (ctrl_defm_dest_mac),
      .ctrl_defm_src_mac         (ctrl_defm_src_mac),
      .ctrl_defm_has_vlan        (ctrl_defm_has_vlan),
      .ctrl_defm_vlan_tag        (ctrl_defm_vlan_tag),
      //
      .ctrl_topology_id          (topology_id),
      //
      .ctrl_defm_dest_mac_flt_en (ctrl_defm_dest_mac_flt_en),
      .ctrl_defm_src_mac_flt_en  (ctrl_defm_src_mac_flt_en),
      .ctrl_defm_src_mac_flt_mask(ctrl_defm_src_mac_flt_mask),
      .ctrl_defm_vlan_flt_en     (ctrl_defm_vlan_flt_en),
      .ctrl_defm_vlan_flt_mask   (ctrl_defm_vlan_flt_mask),
      //
      .ctrl_fram_dest_mac        (ctrl_fram_dest_mac),
      .ctrl_fram_src_mac         (ctrl_fram_src_mac),
      .ctrl_fram_has_vlan        (ctrl_fram_has_vlan),
      .ctrl_fram_vlan_tag        (ctrl_fram_vlan_tag),
      //
      .ctrl_odm_en               (ctrl_odm_en),
      .ctrl_odm_meas_interval    (ctrl_odm_meas_interval),
      //
      .stat_defm_total_pkt_cnt   (stat_defm_total_pkt_cnt),
      .stat_defm_ecpri_pkt_cnt   (stat_defm_ecpri_pkt_cnt),
      .stat_defm_trans_pkt_cnt   (stat_defm_trans_pkt_cnt),
      .stat_defm_odm_pkt_cnt     (stat_defm_odm_pkt_cnt),
      //
      .stat_fram_total_pkt_cnt   (stat_fram_total_pkt_cnt),
      .stat_fram_ecpri_pkt_cnt   (stat_fram_ecpri_pkt_cnt),
      .stat_fram_trans_pkt_cnt   (stat_fram_trans_pkt_cnt),
      .stat_fram_odm_pkt_cnt     (stat_fram_odm_pkt_cnt),
      //
      .stat_ts_diff_ingress_ns   (stat_ts_diff_ingress_ns),
      .stat_ts_diff_ingress_sec  (stat_ts_diff_ingress_sec),
      //
      .stat_ts_diff_egress_ns    (stat_ts_diff_egress_ns),
      .stat_ts_diff_egress_sec   (stat_ts_diff_egress_sec),
      //
      .stat_topology_id          (stat_lp_topology_id)
  );

  timer_syncer #(
      .FREQ_MODE  (1),
      .SIM_SPEEDUP(0)
  ) i_timer_syncer (
      .clk               (clk),
      .rst               (rst),
      //
      .pps_in            (pps_in),
      //
      .tod_sec           (tod_sec),
      .tod_ns            (tod_ns),
      //
      .rx_eth_clk        (rx_eth_clk),
      .rx_eth_rst        (rx_eth_rst),
      //
      .tx_eth_clk        (tx_eth_clk),
      .tx_eth_rst        (tx_eth_rst),
      //
      .ctrl_clk          (s_axi_aclk),
      .ctrl_rst          (~s_axi_aresetn),
      //
      .ctl_rx_systemtimer(ctl_rx_systemtimer),
      .ctl_tx_systemtimer(ctl_tx_systemtimer),
      //
      .stat_rx_resync_cnt(stat_rx_resync_cnt),
      .stat_tx_resync_cnt(stat_tx_resync_cnt)
  );

  coe_deframer i_deframer (
      .clk                 (clk),
      .rst                 (rst),
      //
      .sync                (pps_in),
      //
      .s_axis_tdata        (m0_axis_tdata),
      .s_axis_tkeep        (m0_axis_tkeep),
      .s_axis_tlast        (m0_axis_tlast),
      .s_axis_tvalid       (m0_axis_tvalid),
      //
      .s_trans_header_valid(m0_trans_header_valid),
      .s_trans_rtc_pc_id   (m0_trans_rtc_pc_id),
      .s_trans_seqid       (m0_trans_seqid),
      .s_trans_ebit        (m0_trans_ebit),
      .s_trans_subseqid    (m0_trans_subseqid),
      //
      .m_axis_rx_tdata     (m_axis_rx_tdata),
      .m_axis_rx_tuser     (m_axis_rx_tuser),
      .m_axis_rx_tlast     (m_axis_rx_tlast),
      .m_axis_rx_tvalid    (m_axis_rx_tvalid),
      .m_axis_rx_tready    (m_axis_rx_tready),
      //
      .ctrl_clk            (s_axi_aclk),
      .ctrl_rst            (~s_axi_aresetn),
      //
      .ctrl_en             (ctrl_defm_en),
      .ctrl_seq_en         (ctrl_defm_seq_en),
      .ctrl_seq_id         (ctrl_defm_seq_id),
      //
      .ctrl_ts_offset      (ctrl_defm_ts_offset),
      //
      .stat_conflict_cnt   (stat_defm_conflict_cnt)
  );

  coe_framer i_framer (
      .clk                (clk),
      .rst                (rst),
      //
      .sync               (pps_in),
      //
      .s_axis_tdata       (s_axis_tx_tdata),
      .s_axis_tuser       (s_axis_tx_tuser),
      .s_axis_tlast       (s_axis_tx_tlast),
      .s_axis_tvalid      (s_axis_tx_tvalid),
      .s_axis_tready      (s_axis_tx_tready),
      //
      .m_axis_tdata       (s0_axis_tdata),
      .m_axis_tkeep       (s0_axis_tkeep),
      .m_axis_tlast       (s0_axis_tlast),
      .m_axis_tvalid      (s0_axis_tvalid),
      .m_axis_tready      (s0_axis_tready),
      //
      .m_trans_messagetype(s0_trans_messagetype),
      .m_trans_payloadsize(s0_trans_payloadsize),
      .m_trans_rtc_pc_id  (s0_trans_rtc_pc_id),
      //
      .ctrl_en            (ctrl_fram_en),
      .ctrl_seq_en        (ctrl_fram_seq_en),
      .ctrl_seq_id        (ctrl_fram_seq_id),
      .ctrl_seq_cnt       (ctrl_fram_seq_cnt)
  );

endmodule

`default_nettype wire
