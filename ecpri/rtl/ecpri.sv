`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri (
    // AXI-Lite I/F
    //-------------
    input var         s_axi_aclk,
    input var         s_axi_aresetn,
    //
    /* verilator lint_off UNUSED */
    input var  [31:0] s_axi_awaddr,
    /* verilator lint_on UNUSED */
    input var  [ 2:0] s_axi_awprot,
    input var         s_axi_awvalid,
    output var        s_axi_awready,
    //
    input var  [31:0] s_axi_wdata,
    input var  [ 3:0] s_axi_wstrb,
    input var         s_axi_wvalid,
    output var        s_axi_wready,
    //
    output var [ 1:0] s_axi_bresp,
    output var        s_axi_bvalid,
    input var         s_axi_bready,
    //
    /* verilator lint_off UNUSED */
    input var  [31:0] s_axi_araddr,
    /* verilator lint_on UNUSED */
    input var  [ 2:0] s_axi_arprot,
    input var         s_axi_arvalid,
    output var        s_axi_arready,
    //
    output var [31:0] s_axi_rdata,
    output var [ 1:0] s_axi_rresp,
    output var        s_axi_rvalid,
    input var         s_axi_rready,
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
    // PTP Control Interface
    output var [79:0] ctl_rx_systemtimer,
    output var [79:0] ctl_tx_systemtimer,
    // Internal interface
    //-------------------
    input var         clk,
    input var         rst,
    //
    input var         pps_in,
    //
    input var  [47:0] tod_sec,
    input var  [31:0] tod_ns,
    //
    input var  [15:0] topology_id,
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
    //
    input var  [31:0] s_ptp_tdata,
    input var  [ 3:0] s_ptp_tkeep,
    input var         s_ptp_tlast,
    input var  [17:0] s_ptp_tuser,
    input var         s_ptp_tvalid,
    output var        s_ptp_tready,
    //
    input var  [31:0] s_message_tdata,
    input var  [ 3:0] s_message_tkeep,
    input var         s_message_tlast,
    input var         s_message_tvalid,
    output var        s_message_tready
);

  // Signals

  wire        ctrl_tick_snap;
  wire        ctrl_tick_clear;

  wire        ctrl_defm_en;
  wire        ctrl_defm_reset;

  wire [47:0] ctrl_defm_src_mac;
  wire [47:0] ctrl_defm_dest_mac;
  wire        ctrl_defm_has_vlan;
  wire [15:0] ctrl_defm_vlan_tag;

  wire        ctrl_defm_dest_mac_flt_en;
  wire        ctrl_defm_src_mac_flt_en;
  wire [47:0] ctrl_defm_src_mac_flt_mask;
  wire        ctrl_defm_vlan_flt_en;
  wire [15:0] ctrl_defm_vlan_flt_mask;

  wire        ctrl_fram_en;
  wire        ctrl_fram_reset;

  wire [47:0] ctrl_fram_dest_mac;
  wire [47:0] ctrl_fram_src_mac;
  wire [15:0] ctrl_fram_vlan_tag;
  wire        ctrl_fram_has_vlan;

  wire        ctrl_odm_en;
  wire [31:0] ctrl_odm_meas_interval;

  wire [31:0] stat_defm_total_pkt_cnt;
  wire [31:0] stat_defm_ecpri_pkt_cnt;
  wire [31:0] stat_defm_trans_pkt_cnt;
  wire [31:0] stat_defm_odm_pkt_cnt;

  /* verilator lint_off UNUSED */
  wire [31:0] stat_fram_total_pkt_cnt;
  wire [31:0] stat_fram_ecpri_pkt_cnt;
  wire [31:0] stat_fram_trans_pkt_cnt;
  wire [31:0] stat_fram_odm_pkt_cnt;
  /* verilator lint_on UNUSED */

  wire [31:0] stat_ts_diff_ingress_ns;
  wire [47:0] stat_ts_diff_ingress_sec;

  wire [31:0] stat_ts_diff_egress_ns;
  wire [47:0] stat_ts_diff_egress_sec;

  wire [15:0] stat_topology_id;
  wire [15:0] stat_lp_topology_id;
  /* verilator lint_off UNUSED */
  wire [31:0] unused_stat_rx_resync_cnt;
  wire [31:0] unused_stat_tx_resync_cnt;
  wire        unused_m_odm_header_valid;
  wire [ 7:0] unused_m_odm_measurementid;
  wire [ 7:0] unused_m_odm_actiontype;
  wire [79:0] unused_m_odm_timestamp;
  wire [63:0] unused_m_odm_compensation;
  wire [79:0] unused_m_odm_timestamp2;
  /* verilator lint_on UNUSED */

  assign ctrl_defm_has_vlan = 1'b0;
  assign ctrl_defm_vlan_tag = 16'd0;
  assign ctrl_defm_src_mac_flt_mask = 48'd0;
  assign ctrl_defm_vlan_flt_en = 1'b0;
  assign ctrl_defm_vlan_flt_mask = 16'd0;

  // Main

  ecpri_regs i_regs (
      .s_axi_aclk                  (s_axi_aclk),
      .s_axi_aresetn               (s_axi_aresetn),
      //
      .s_axi_awaddr                (s_axi_awaddr[9:0]),
      .s_axi_awprot                (s_axi_awprot),
      .s_axi_awvalid               (s_axi_awvalid),
      .s_axi_awready               (s_axi_awready),
      //
      .s_axi_wdata                 (s_axi_wdata),
      .s_axi_wstrb                 (s_axi_wstrb),
      .s_axi_wvalid                (s_axi_wvalid),
      .s_axi_wready                (s_axi_wready),
      //
      .s_axi_bresp                 (s_axi_bresp),
      .s_axi_bvalid                (s_axi_bvalid),
      .s_axi_bready                (s_axi_bready),
      //
      .s_axi_araddr                (s_axi_araddr[9:0]),
      .s_axi_arprot                (s_axi_arprot),
      .s_axi_arvalid               (s_axi_arvalid),
      .s_axi_arready               (s_axi_arready),
      //
      .s_axi_rdata                 (s_axi_rdata),
      .s_axi_rresp                 (s_axi_rresp),
      .s_axi_rvalid                (s_axi_rvalid),
      .s_axi_rready                (s_axi_rready),
      // tick.snap,
      .tick_snap_out               (ctrl_tick_snap),
      // tick.clear,
      .tick_clear_out              (ctrl_tick_clear),
      // defm_ctrl.en,
      .defm_ctrl_en_out            (ctrl_defm_en),
      // defm_ctrl.rst,
      .defm_ctrl_rst_out           (ctrl_defm_reset),
      // defm_cfg.src_mac_flt_en,
      .defm_cfg_src_mac_flt_en_out (ctrl_defm_src_mac_flt_en),
      // defm_cfg.dest_mac_flt_en,
      .defm_cfg_dest_mac_flt_en_out(ctrl_defm_dest_mac_flt_en),
      // defm_src_mac_l.val,
      .defm_src_mac_l_val_out      (ctrl_defm_src_mac[31:0]),
      // defm_src_mac_h.val,
      .defm_src_mac_h_val_out      (ctrl_defm_src_mac[47:32]),
      // defm_dest_mac_l.val,
      .defm_dest_mac_l_val_out     (ctrl_defm_dest_mac[31:0]),
      // defm_dest_mac_h.val,
      .defm_dest_mac_h_val_out     (ctrl_defm_dest_mac[47:32]),
      // defm_total_pkt_cnt.val,
      .defm_total_pkt_cnt_val_in   (stat_defm_total_pkt_cnt),
      // defm_ecpri_pkt_cnt.val,
      .defm_ecpri_pkt_cnt_val_in   (stat_defm_ecpri_pkt_cnt),
      // defm_trans_pkt_cnt.val,
      .defm_trans_pkt_cnt_val_in   (stat_defm_trans_pkt_cnt),
      // defm_odm_pkt_cnt.val,
      .defm_odm_pkt_cnt_val_in     (stat_defm_odm_pkt_cnt),
      // fram_ctrl.en,
      .fram_ctrl_en_out            (ctrl_fram_en),
      // fram_ctrl.rst,
      .fram_ctrl_rst_out           (ctrl_fram_reset),
      // fram_dest_mac_l.val,
      .fram_dest_mac_l_val_out     (ctrl_fram_dest_mac[31:0]),
      // fram_dest_mac_h.val,
      .fram_dest_mac_h_val_out     (ctrl_fram_dest_mac[47:32]),
      // fram_src_mac_l.val,
      .fram_src_mac_l_val_out      (ctrl_fram_src_mac[31:0]),
      // fram_src_mac_h.val,
      .fram_src_mac_h_val_out      (ctrl_fram_src_mac[47:32]),
      // fram_vlan_ctrl.vlan_tag,
      .fram_vlan_ctrl_vlan_tag_out (ctrl_fram_vlan_tag),
      // fram_vlan_ctrl.has_vlan,
      .fram_vlan_ctrl_has_vlan_out (ctrl_fram_has_vlan),
      // odm_ctrl.en,
      .odm_ctrl_en_out             (ctrl_odm_en),
      // odm_meas_interval.val,
      .odm_meas_interval_val_out   (ctrl_odm_meas_interval),
      // ts_diff_ingress_ns.val,
      .ts_diff_ingress_ns_val_in   (stat_ts_diff_ingress_ns),
      // ts_diff_ingress_sec_l.val,
      .ts_diff_ingress_sec_l_val_in(stat_ts_diff_ingress_sec[31:0]),
      // ts_diff_ingress_sec_h.val,
      .ts_diff_ingress_sec_h_val_in(stat_ts_diff_ingress_sec[47:32]),
      // ts_diff_egress_ns.val,
      .ts_diff_egress_ns_val_in    (stat_ts_diff_egress_ns),
      // ts_diff_egress_sec_l.val,
      .ts_diff_egress_sec_l_val_in (stat_ts_diff_egress_sec[31:0]),
      // ts_diff_egress_sec_h.val,
      .ts_diff_egress_sec_h_val_in (stat_ts_diff_egress_sec[47:32]),
      // topology_id.val,
      .topology_id_val_in          (stat_topology_id),
      // lp_topology_id.val,
      .lp_topology_id_val_in       (stat_lp_topology_id)
  );

  timer_syncer i_timer_syncer (
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
      .stat_rx_resync_cnt(unused_stat_rx_resync_cnt),
      .stat_tx_resync_cnt(unused_stat_tx_resync_cnt)
  );

  ecpri_if #(
      .HAS_ODM_FUNCTION(1),
      .HAS_STATISTICS  (1)
  ) i_if (
      // Rx Ethernet ports
      .rx_eth_clk                (rx_eth_clk),
      .rx_eth_rst                (rx_eth_rst),
      //
      .s_eth_defm_tdata          (s_eth_defm_tdata),
      .s_eth_defm_tkeep          (s_eth_defm_tkeep),
      .s_eth_defm_tlast          (s_eth_defm_tlast),
      .s_eth_defm_tuser          (s_eth_defm_tuser),
      .s_eth_defm_tvalid         (s_eth_defm_tvalid),
      // Tx Ethernet ports
      .tx_eth_clk                (tx_eth_clk),
      .tx_eth_rst                (tx_eth_rst),
      //
      .m_eth_fram_tdata          (m_eth_fram_tdata),
      .m_eth_fram_tkeep          (m_eth_fram_tkeep),
      .m_eth_fram_tlast          (m_eth_fram_tlast),
      .m_eth_fram_tuser          (m_eth_fram_tuser),
      .m_eth_fram_tvalid         (m_eth_fram_tvalid),
      .m_eth_fram_tready         (m_eth_fram_tready),
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
      .clk                       (clk),
      .rst                       (rst),
      // Deframer ports
      .m_axis_tdata              (m_axis_tdata),
      .m_axis_tkeep              (m_axis_tkeep),
      .m_axis_tlast              (m_axis_tlast),
      .m_axis_tvalid             (m_axis_tvalid),
      //
      .m_mac_header_valid        (m_mac_header_valid),
      .m_mac_dest_mac            (m_mac_dest_mac),
      .m_mac_source_mac          (m_mac_source_mac),
      .m_mac_with_vlan           (m_mac_with_vlan),
      .m_mac_vlan_tag            (m_mac_vlan_tag),
      .m_mac_ethertype           (m_mac_ethertype),
      //
      .m_ecpri_header_valid      (m_ecpri_header_valid),
      .m_ecpri_concat            (m_ecpri_concat),
      .m_ecpri_messagetype       (m_ecpri_messagetype),
      .m_ecpri_payloadsize       (m_ecpri_payloadsize),
      //
      .m_trans_header_valid      (m_trans_header_valid),
      .m_trans_rtc_pc_id         (m_trans_rtc_pc_id),
      .m_trans_seqid             (m_trans_seqid),
      .m_trans_ebit              (m_trans_ebit),
      .m_trans_subseqid          (m_trans_subseqid),
      //
      .m_odm_header_valid        (unused_m_odm_header_valid),
      .m_odm_measurementid       (unused_m_odm_measurementid),
      .m_odm_actiontype          (unused_m_odm_actiontype),
      .m_odm_timestamp           (unused_m_odm_timestamp),
      .m_odm_compensation        (unused_m_odm_compensation),
      .m_odm_timestamp2          (unused_m_odm_timestamp2),
      //
      .m_ptp_tdata               (m_ptp_tdata),
      .m_ptp_tkeep               (m_ptp_tkeep),
      .m_ptp_tlast               (m_ptp_tlast),
      .m_ptp_tuser               (m_ptp_tuser),
      .m_ptp_tvalid              (m_ptp_tvalid),
      .m_ptp_tready              (m_ptp_tready),
      //
      .m_message_tdata           (m_message_tdata),
      .m_message_tkeep           (m_message_tkeep),
      .m_message_tlast           (m_message_tlast),
      .m_message_tvalid          (m_message_tvalid),
      .m_message_tready          (m_message_tready),
      // Framer ports
      .s_axis_tdata              (s_axis_tdata),
      .s_axis_tkeep              (s_axis_tkeep),
      .s_axis_tlast              (s_axis_tlast),
      .s_axis_tvalid             (s_axis_tvalid),
      .s_axis_tready             (s_axis_tready),
      //
      .s_trans_messagetype       (s_trans_messagetype),
      .s_trans_payloadsize       (s_trans_payloadsize),
      .s_trans_rtc_pc_id         (s_trans_rtc_pc_id),
      //
      .s_ptp_tdata               (s_ptp_tdata),
      .s_ptp_tkeep               (s_ptp_tkeep),
      .s_ptp_tlast               (s_ptp_tlast),
      .s_ptp_tuser               (s_ptp_tuser),
      .s_ptp_tvalid              (s_ptp_tvalid),
      .s_ptp_tready              (s_ptp_tready),
      //
      .s_message_tdata           (s_message_tdata),
      .s_message_tkeep           (s_message_tkeep),
      .s_message_tlast           (s_message_tlast),
      .s_message_tvalid          (s_message_tvalid),
      .s_message_tready          (s_message_tready),
      // Control & Status
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
      .ctrl_topology_id          (topology_id),
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

endmodule

`default_nettype wire
