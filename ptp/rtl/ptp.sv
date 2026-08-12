`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp #(
    parameter int CLK_FREQ = 49152000
) (
    // AXI-Lite I/F
    //-------------
    input var         s_axi_aclk,
    input var         s_axi_aresetn,
    //
    input var  [31:0] s_axi_awaddr,
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
    input var  [31:0] s_axi_araddr,
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
    input var  [31:0] s_axis_tdata,
    input var  [ 3:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var         s_axis_tuser,
    input var         s_axis_tvalid,
    // Tx Ethernet ports
    input var         tx_eth_clk,
    input var         tx_eth_rst,
    //
    output var [31:0] m_axis_tdata,
    output var [ 3:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var        m_axis_tuser,
    output var        m_axis_tvalid,
    input var         m_axis_tready,
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
    // Internal I/F
    //-------------
    input var         clk,
    input var         rst,
    //
    input var         pps_in,
    //
    input var  [47:0] tod_sec,
    input var  [31:0] tod_ns
);

  // Signals

  wire [79:0] s_axis_tuser_s;
  wire [17:0] m_axis_tuser_s;

  wire        ctrl_master_en;
  wire [47:0] ctrl_src_mac;
  wire [ 7:0] ctrl_domain_number;
  wire [15:0] ctrl_utc_offset;
  wire [ 7:0] ctrl_log_announce_interval;
  wire [ 7:0] ctrl_log_sync_interval;

  // Main

  ptp_regs i_ptp_regs (
      .s_axi_aclk                   (s_axi_aclk),
      .s_axi_aresetn                (s_axi_aresetn),
      //
      .s_axi_awaddr                 (s_axi_awaddr),
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
      .s_axi_araddr                 (s_axi_araddr),
      .s_axi_arprot                 (s_axi_arprot),
      .s_axi_arvalid                (s_axi_arvalid),
      .s_axi_arready                (s_axi_arready),
      //
      .s_axi_rdata                  (s_axi_rdata),
      .s_axi_rresp                  (s_axi_rresp),
      .s_axi_rvalid                 (s_axi_rvalid),
      .s_axi_rready                 (s_axi_rready),
      //
      .ctrl_master_en_out           (ctrl_master_en),
      .src_mac_l_val_out            (ctrl_src_mac[31:0]),
      .src_mac_h_val_out            (ctrl_src_mac[47:32]),
      .domain_number_val_out        (ctrl_domain_number),
      .utc_offset_val_out           (ctrl_utc_offset),
      .log_announce_interval_val_out(ctrl_log_announce_interval),
      .log_sync_interval_val_out    (ctrl_log_sync_interval)
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
      .stat_rx_resync_cnt(),
      .stat_tx_resync_cnt()
  );

  // TODO: TUSER signal from Ethernet IP is not used
  assign s_axis_tuser_s = rx_ptp_timestamp;

  assign {tx_ptp_1588op, tx_ptp_tag_field} = m_axis_tuser_s;
  assign m_axis_tuser = 1'b0;

  ptp_lite #(
      .CLK_FREQ(CLK_FREQ)
  ) i_ptp_lite (
      .rx_eth_clk                (rx_eth_clk),
      .rx_eth_rst                (rx_eth_rst),
      //
      .s_axis_tdata              (s_axis_tdata),
      .s_axis_tkeep              (s_axis_tkeep),
      .s_axis_tlast              (s_axis_tlast),
      .s_axis_tuser              (s_axis_tuser_s),
      .s_axis_tvalid             (s_axis_tvalid),
      //
      .tx_eth_clk                (tx_eth_clk),
      .tx_eth_rst                (tx_eth_rst),
      //
      .m_axis_tdata              (m_axis_tdata),
      .m_axis_tkeep              (m_axis_tkeep),
      .m_axis_tlast              (m_axis_tlast),
      .m_axis_tuser              (m_axis_tuser_s),
      .m_axis_tvalid             (m_axis_tvalid),
      .m_axis_tready             (m_axis_tready),
      //
      .tx_ptp_timestamp          (tx_ptp_timestamp),
      .tx_ptp_timestamp_tag      (tx_ptp_timestamp_tag),
      .tx_ptp_timestamp_valid    (tx_ptp_timestamp_valid),
      //
      .ctrl_master_en            (ctrl_master_en),
      .ctrl_src_mac              (ctrl_src_mac),
      .ctrl_domain_number        (ctrl_domain_number),
      .ctrl_utc_offset           (ctrl_utc_offset),
      .ctrl_log_announce_interval(ctrl_log_announce_interval),
      .ctrl_log_sync_interval    (ctrl_log_sync_interval)
  );

endmodule

`default_nettype wire
