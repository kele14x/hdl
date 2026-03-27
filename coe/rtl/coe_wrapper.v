`timescale 1 ns / 1 ps
//
`default_nettype none

// verilog_format: off
module coe_wrapper (
    // AXI4-Lite
    //----------
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET s_axi_aresetn, ASSOCIATED_BUSIF S_AXI, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire         s_axi_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire         s_axi_aresetn,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input  wire [ 31:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
    input  wire [  2:0] s_axi_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
    input  wire         s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
    output wire         s_axi_awready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input  wire [ 31:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
    input  wire [  3:0] s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
    input  wire         s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
    output wire         s_axi_wready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
    output wire [  1:0] s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
    output wire         s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
    input  wire         s_axi_bready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input  wire [ 31:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
    input  wire [  2:0] s_axi_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input  wire         s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
    output wire         s_axi_arready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output wire [ 31:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output wire [  1:0] s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output wire         s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input  wire         s_axi_rready,
    // Ethernet
    //---------
    // Ethernet Rx
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 rx_eth_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET rx_eth_rst, ASSOCIATED_BUSIF S_ETH_RX, FREQ_HZ 312500000, FREQ_TOLERANCE_HZ 0" *)
    input  wire         rx_eth_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rx_eth_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input  wire         rx_eth_rst,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_ETH_RX TDATA" *)
    input  wire [ 31:0] s_eth_rx_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_ETH_RX TKEEP" *)
    input  wire [  3:0] s_eth_rx_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_ETH_RX TLAST" *)
    input  wire         s_eth_rx_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_ETH_RX TUSER" *)
    input  wire         s_eth_rx_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_ETH_RX TVALID" *)
    input  wire         s_eth_rx_tvalid,
    // Ethernet Tx
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 tx_eth_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET tx_eth_rst, ASSOCIATED_BUSIF M_ETH_TX, FREQ_HZ 312500000, FREQ_TOLERANCE_HZ 0" *)
    input  wire         tx_eth_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 tx_eth_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input  wire         tx_eth_rst,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_TX TDATA" *)
    output wire [ 31:0] m_eth_tx_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_TX TKEEP" *)
    output wire [  3:0] m_eth_tx_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_TX TLAST" *)
    output wire         m_eth_tx_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_TX TUSER" *)
    output wire         m_eth_tx_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_TX TVALID" *)
    output wire         m_eth_tx_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_TX TREADY" *)
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
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET rstn, ASSOCIATED_BUSIF M_MESSAGE:S_MESSAGE:M_AXIS_RX:S_AXIS_TX, FREQ_HZ 400000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire         clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rstn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire         rstn,
    //
    input  wire         pps_in,
    //
    input wire  [ 47:0] tod_sec,
    input wire  [ 31:0] tod_ns,
    //
    input wire  [ 15:0] topology_id,
    // Message I/F
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_MESSAGE TDATA" *)
    output wire [ 31:0] m_message_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_MESSAGE TKEEP" *)
    output wire [  3:0] m_message_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_MESSAGE TLAST" *)
    output wire         m_message_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_MESSAGE TVALID" *)
    output wire         m_message_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_MESSAGE TREADY" *)
    input  wire         m_message_tready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_MESSAGE TDATA" *)
    input  wire [ 31:0] s_message_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_MESSAGE TKEEP" *)
    input  wire [  3:0] s_message_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_MESSAGE TLAST" *)
    input  wire         s_message_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_MESSAGE TVALID" *)
    input  wire         s_message_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_MESSAGE TREADY" *)
    output wire         s_message_tready,
    // Radio I/F
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_RX TDATA" *)
    output wire [767:0] m_axis_rx_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_RX TUSER" *)
    output wire [  7:0] m_axis_rx_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_RX TLAST" *)
    output wire         m_axis_rx_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_RX TVALID" *)
    output wire         m_axis_rx_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_RX TREADY" *)
    input  wire         m_axis_rx_tready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_TX TDATA" *)
    input  wire [767:0] s_axis_tx_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_TX TUSER" *)
    input  wire [  7:0] s_axis_tx_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_TX TLAST" *)
    input  wire         s_axis_tx_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_TX TVALID" *)
    input  wire         s_axis_tx_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_TX TREADY" *)
    output wire         s_axis_tx_tready
);
// verilog_format: on

  reg rst;

  always @(posedge clk) begin
    rst <= ~rstn;
  end

  coe inst (
      // AXI4-Lite
      //----------
      .s_axi_aclk            (s_axi_aclk),
      .s_axi_aresetn         (s_axi_aresetn),
      //
      .s_axi_awaddr          (s_axi_awaddr),
      .s_axi_awprot          (s_axi_awprot),
      .s_axi_awvalid         (s_axi_awvalid),
      .s_axi_awready         (s_axi_awready),
      //
      .s_axi_wdata           (s_axi_wdata),
      .s_axi_wstrb           (s_axi_wstrb),
      .s_axi_wvalid          (s_axi_wvalid),
      .s_axi_wready          (s_axi_wready),
      //
      .s_axi_bresp           (s_axi_bresp),
      .s_axi_bvalid          (s_axi_bvalid),
      .s_axi_bready          (s_axi_bready),
      //
      .s_axi_araddr          (s_axi_araddr),
      .s_axi_arprot          (s_axi_arprot),
      .s_axi_arvalid         (s_axi_arvalid),
      .s_axi_arready         (s_axi_arready),
      //
      .s_axi_rdata           (s_axi_rdata),
      .s_axi_rresp           (s_axi_rresp),
      .s_axi_rvalid          (s_axi_rvalid),
      .s_axi_rready          (s_axi_rready),
      // Ethernet
      //---------
      // Ethernet Rx
      .rx_eth_clk            (rx_eth_clk),
      .rx_eth_rst            (rx_eth_rst),
      //
      .s_eth_rx_tdata        (s_eth_rx_tdata),
      .s_eth_rx_tkeep        (s_eth_rx_tkeep),
      .s_eth_rx_tlast        (s_eth_rx_tlast),
      .s_eth_rx_tuser        (s_eth_rx_tuser),
      .s_eth_rx_tvalid       (s_eth_rx_tvalid),
      // Ethernet Tx
      .tx_eth_clk            (tx_eth_clk),
      .tx_eth_rst            (tx_eth_rst),
      //
      .m_eth_tx_tdata        (m_eth_tx_tdata),
      .m_eth_tx_tkeep        (m_eth_tx_tkeep),
      .m_eth_tx_tlast        (m_eth_tx_tlast),
      .m_eth_tx_tuser        (m_eth_tx_tuser),
      .m_eth_tx_tvalid       (m_eth_tx_tvalid),
      .m_eth_tx_tready       (m_eth_tx_tready),
      // PTP interface
      .rx_ptp_timestamp      (rx_ptp_timestamp),
      .rx_ptp_timestamp_valid(rx_ptp_timestamp_valid),
      //
      .tx_ptp_1588op         (tx_ptp_1588op),
      .tx_ptp_tag_field      (tx_ptp_tag_field),
      .tx_ptp_timestamp      (tx_ptp_timestamp),
      .tx_ptp_timestamp_tag  (tx_ptp_timestamp_tag),
      .tx_ptp_timestamp_valid(tx_ptp_timestamp_valid),
      // Timer ports
      .ctl_rx_systemtimer    (ctl_rx_systemtimer),
      .ctl_tx_systemtimer    (ctl_tx_systemtimer),
      // GPTIO
      .stat_rx_status        (stat_rx_status),
      // Internal Clock Domain
      //----------------------
      .clk                   (clk),
      .rst                   (rst),
      //
      .pps_in                (pps_in),
      //
      .tod_sec               (tod_sec),
      .tod_ns                (tod_ns),
      //
      .topology_id           (topology_id),
      // Message I/F
      .m_message_tdata       (m_message_tdata),
      .m_message_tkeep       (m_message_tkeep),
      .m_message_tlast       (m_message_tlast),
      .m_message_tvalid      (m_message_tvalid),
      .m_message_tready      (m_message_tready),
      //
      .s_message_tdata       (s_message_tdata),
      .s_message_tkeep       (s_message_tkeep),
      .s_message_tlast       (s_message_tlast),
      .s_message_tvalid      (s_message_tvalid),
      .s_message_tready      (s_message_tready),
      // Radio I/F
      .m_axis_rx_tdata       (m_axis_rx_tdata),
      .m_axis_rx_tuser       (m_axis_rx_tuser),
      .m_axis_rx_tlast       (m_axis_rx_tlast),
      .m_axis_rx_tvalid      (m_axis_rx_tvalid),
      .m_axis_rx_tready      (m_axis_rx_tready),
      //
      .s_axis_tx_tdata       (s_axis_tx_tdata),
      .s_axis_tx_tuser       (s_axis_tx_tuser),
      .s_axis_tx_tlast       (s_axis_tx_tlast),
      .s_axis_tx_tvalid      (s_axis_tx_tvalid),
      .s_axis_tx_tready      (s_axis_tx_tready)
  );

endmodule

`default_nettype wire
