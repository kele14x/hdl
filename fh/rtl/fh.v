`timescale 1 ns / 1 ps
//
`default_nettype none

module fh (
    // AXI-Lite I/F
    //-------------
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [31:0] s_axi_awaddr,
    input  wire [ 2:0] s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    //
    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    //
    output wire [ 1:0] s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    //
    input  wire [31:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    // Ethernet I/F
    //-------------
    // Rx Ethernet ports
    input  wire        rx_eth_clk,
    input  wire        rx_eth_rst,
    //
    input  wire [63:0] s_axis_rx_tdata,
    input  wire [ 7:0] s_axis_rx_tkeep,
    input  wire        s_axis_rx_tvalid,
    input  wire        s_axis_rx_tlast,
    input  wire        s_axis_rx_tuser,
    // Tx Ethernet ports
    input  wire        tx_eth_clk,
    input  wire        tx_eth_rst,
    //
    output wire [63:0] m_axis_tx_tdata,
    output wire [ 7:0] m_axis_tx_tkeep,
    output wire        m_axis_tx_tlast,
    output wire        m_axis_tx_tuser,
    output wire        m_axis_tx_tvalid,
    input  wire        m_axis_tx_tready,
    // PTP ports
    input  wire [79:0] rx_ptp_timestamp,
    input  wire        rx_ptp_timestamp_valid,
    //
    output wire [ 1:0] tx_ptp_1588op,
    output wire [15:0] tx_ptp_tag_field,
    //
    input  wire [79:0] tx_ptp_timestamp,
    input  wire [15:0] tx_ptp_timestamp_tag,
    input  wire        tx_ptp_timestamp_valid,
    // PTP Control Interface
    output wire [79:0] ctl_rx_systemtimer,
    output wire [79:0] ctl_tx_systemtimer,
    // Time Interface
    //-------------------
    input  wire        timer_clk,
    input  wire        timer_rst,
    //
    input  wire        pps_in,
    //
    input  wire [47:0] tod_sec,
    input  wire [31:0] tod_ns,
    // Internal interface
    //-------------------
    input  wire        clk,
    input  wire        rst,
    // Receive interface
    output wire [63:0] m_axis_tdata,
    output wire [ 7:0] m_axis_tkeep,
    output wire        m_axis_tlast,
    output wire [79:0] m_axis_tuser,
    output wire        m_axis_tvalid,
    //
    output wire [31:0] m_message_tdata,
    output wire [ 3:0] m_message_tkeep,
    output wire        m_message_tlast,
    output wire        m_message_tvalid,
    input  wire        m_message_tready,
    // Transmit interface
    input  wire [63:0] s_axis_tdata,
    input  wire [ 7:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tvalid,
    //
    input  wire [31:0] s_message_tdata,
    input  wire [ 3:0] s_message_tkeep,
    input  wire        s_message_tlast,
    input  wire        s_message_tvalid,
    output wire        s_message_tready
);

  wire        ctrl_ptp_master_en;
  wire [47:0] ctrl_ptp_src_mac;
  wire [ 7:0] ctrl_ptp_domain_number;
  wire [15:0] ctrl_ptp_utc_offset;
  wire [ 7:0] ctrl_ptp_log_announce_interval;
  wire [ 7:0] ctrl_ptp_log_sync_interval;

  wire [79:0] tx_ptp_timestamp_s;
  wire [15:0] tx_ptp_timestamp_tag_s;
  wire        tx_ptp_timestamp_valid_s;

  wire [31:0] rx_ptp_tdata;
  wire [ 3:0] rx_ptp_tkeep;
  wire        rx_ptp_tlast;
  wire [79:0] rx_ptp_tuser;
  wire        rx_ptp_tvalid;
  wire        rx_ptp_tready;

  wire [31:0] tx_ptp_tdata;
  wire [ 3:0] tx_ptp_tkeep;
  wire        tx_ptp_tlast;
  wire [17:0] tx_ptp_tuser;
  wire        tx_ptp_tvalid;
  wire        tx_ptp_tready;

  wire [31:0] stat_rx_resync_cnt;
  wire [31:0] stat_tx_resync_cnt;

  fh_regs i_regs (
      .s_axi_aclk                       (s_axi_aclk),
      .s_axi_aresetn                    (s_axi_aresetn),
      //
      .s_axi_awaddr                     (s_axi_awaddr),
      .s_axi_awprot                     (s_axi_awprot),
      .s_axi_awvalid                    (s_axi_awvalid),
      .s_axi_awready                    (s_axi_awready),
      //
      .s_axi_wdata                      (s_axi_wdata),
      .s_axi_wstrb                      (s_axi_wstrb),
      .s_axi_wvalid                     (s_axi_wvalid),
      .s_axi_wready                     (s_axi_wready),
      //
      .s_axi_bresp                      (s_axi_bresp),
      .s_axi_bvalid                     (s_axi_bvalid),
      .s_axi_bready                     (s_axi_bready),
      //
      .s_axi_araddr                     (s_axi_araddr),
      .s_axi_arprot                     (s_axi_arprot),
      .s_axi_arvalid                    (s_axi_arvalid),
      .s_axi_arready                    (s_axi_arready),
      //
      .s_axi_rdata                      (s_axi_rdata),
      .s_axi_rresp                      (s_axi_rresp),
      .s_axi_rvalid                     (s_axi_rvalid),
      .s_axi_rready                     (s_axi_rready),
      // ptp_ctrl.master_en,
      .ptp_ctrl_master_en_out           (ctrl_ptp_master_en),
      // ptp_src_mac_l.val,
      .ptp_src_mac_l_val_out            (ctrl_ptp_src_mac[31:0]),
      // ptp_src_mac_h.val,
      .ptp_src_mac_h_val_out            (ctrl_ptp_src_mac[47:32]),
      // ptp_domain_number.val,
      .ptp_domain_number_val_out        (ctrl_ptp_domain_number),
      // ptp_utc_offset.val,
      .ptp_utc_offset_val_out           (ctrl_ptp_utc_offset),
      // ptp_log_announce_interval.val,
      .ptp_log_announce_interval_val_out(ctrl_ptp_log_announce_interval),
      // ptp_log_sync_interval.val,
      .ptp_log_sync_interval_val_out    (ctrl_ptp_log_sync_interval)
  );

  timer_syncer #(
      .FREQ_MODE  (0),
      .SIM_SPEEDUP(0)
  ) i_timer_syncer (
      .clk               (timer_clk),
      .rst               (timer_rst),
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
      .ctrl_clk          (clk),
      .ctrl_rst          (rst),
      //
      .ctl_rx_systemtimer(ctl_rx_systemtimer),
      .ctl_tx_systemtimer(ctl_tx_systemtimer),
      //
      .stat_rx_resync_cnt(stat_rx_resync_cnt),
      .stat_tx_resync_cnt(stat_tx_resync_cnt)
  );

  fh_deframer i_deframer (
      // Rx Ethernet ports
      .rx_eth_clk            (rx_eth_clk),
      .rx_eth_rst            (rx_eth_rst),
      //
      .s_axis_rx_tdata       (s_axis_rx_tdata),
      .s_axis_rx_tkeep       (s_axis_rx_tkeep),
      .s_axis_rx_tvalid      (s_axis_rx_tvalid),
      .s_axis_rx_tlast       (s_axis_rx_tlast),
      .s_axis_rx_tuser       (s_axis_rx_tuser),
      // PTP ports
      .rx_ptp_timestamp      (rx_ptp_timestamp),
      .rx_ptp_timestamp_valid(rx_ptp_timestamp_valid),
      //
      .clk                   (clk),
      .rst                   (rst),
      // Receive interface
      .m_axis_tdata          (m_axis_tdata),
      .m_axis_tkeep          (m_axis_tkeep),
      .m_axis_tlast          (m_axis_tlast),
      .m_axis_tuser          (m_axis_tuser),
      .m_axis_tvalid         (m_axis_tvalid),
      // PTP interface
      .m_ptp_tdata           (rx_ptp_tdata),
      .m_ptp_tkeep           (rx_ptp_tkeep),
      .m_ptp_tlast           (rx_ptp_tlast),
      .m_ptp_tuser           (rx_ptp_tuser),
      .m_ptp_tvalid          (rx_ptp_tvalid),
      .m_ptp_tready          (rx_ptp_tready),
      //
      .m_message_tdata       (m_message_tdata),
      .m_message_tkeep       (m_message_tkeep),
      .m_message_tlast       (m_message_tlast),
      .m_message_tvalid      (m_message_tvalid),
      .m_message_tready      (m_message_tready)
  );

  fh_framer i_framer (
      // Tx Ethernet ports
      .tx_eth_clk      (tx_eth_clk),
      .tx_eth_rst      (tx_eth_rst),
      //
      .m_axis_tx_tdata (m_axis_tx_tdata),
      .m_axis_tx_tkeep (m_axis_tx_tkeep),
      .m_axis_tx_tlast (m_axis_tx_tlast),
      .m_axis_tx_tuser (m_axis_tx_tuser),
      .m_axis_tx_tvalid(m_axis_tx_tvalid),
      .m_axis_tx_tready(m_axis_tx_tready),
      //
      .tx_ptp_1588op   (tx_ptp_1588op),
      .tx_ptp_tag_field(tx_ptp_tag_field),
      // Internal interface
      .clk             (clk),
      .rst             (rst),
      // Receive interface
      .s_axis_tdata    (s_axis_tdata),
      .s_axis_tkeep    (s_axis_tkeep),
      .s_axis_tlast    (s_axis_tlast),
      .s_axis_tvalid   (s_axis_tvalid),
      //
      .s_ptp_tdata     (tx_ptp_tdata),
      .s_ptp_tkeep     (tx_ptp_tkeep),
      .s_ptp_tlast     (tx_ptp_tlast),
      .s_ptp_tuser     (tx_ptp_tuser),
      .s_ptp_tvalid    (tx_ptp_tvalid),
      .s_ptp_tready    (tx_ptp_tready),
      //
      .s_message_tdata (s_message_tdata),
      .s_message_tkeep (s_message_tkeep),
      .s_message_tlast (s_message_tlast),
      .s_message_tvalid(s_message_tvalid),
      .s_message_tready(s_message_tready)
  );

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .SRC_SYNC_FF (4),
      .WIDTH       (96)  // 80 bits for timestamp + 16 bits for tag
  ) i_cdc_tx_ptp_timestamp (
      .src_clk   (tx_eth_clk),
      .src_in    ({tx_ptp_timestamp, tx_ptp_timestamp_tag}),
      .src_valid (tx_ptp_timestamp_valid),
      .src_ready (  /* assume always ready */),
      //
      .dest_clk  (clk),
      .dest_out  ({tx_ptp_timestamp_s, tx_ptp_timestamp_tag_s}),
      .dest_valid(tx_ptp_timestamp_valid_s),
      .dest_ready(1'b1)
  );

  ptp_lite #(
      .CLK_FREQ(300000000)
  ) i_ptp_lite (
      .clk                       (clk),
      .rst                       (rst),
      //
      .s_axis_tdata              (rx_ptp_tdata),
      .s_axis_tkeep              (rx_ptp_tkeep),
      .s_axis_tlast              (rx_ptp_tlast),
      .s_axis_tuser              (rx_ptp_tuser),
      .s_axis_tvalid             (rx_ptp_tvalid),
      .s_axis_tready             (rx_ptp_tready),
      //
      .m_axis_tdata              (tx_ptp_tdata),
      .m_axis_tkeep              (tx_ptp_tkeep),
      .m_axis_tlast              (tx_ptp_tlast),
      .m_axis_tuser              (tx_ptp_tuser),
      .m_axis_tvalid             (tx_ptp_tvalid),
      .m_axis_tready             (tx_ptp_tready),
      //
      .tx_ptp_timestamp          (tx_ptp_timestamp_s),
      .tx_ptp_timestamp_tag      (tx_ptp_timestamp_tag_s),
      .tx_ptp_timestamp_valid    (tx_ptp_timestamp_valid_s),
      //
      .ctrl_master_en            (ctrl_ptp_master_en),
      .ctrl_src_mac              (ctrl_ptp_src_mac),
      .ctrl_domain_number        (ctrl_ptp_domain_number),
      .ctrl_utc_offset           (ctrl_ptp_utc_offset),
      .ctrl_log_announce_interval(ctrl_ptp_log_announce_interval),
      .ctrl_log_sync_interval    (ctrl_ptp_log_sync_interval)
  );

endmodule

`default_nettype wire
