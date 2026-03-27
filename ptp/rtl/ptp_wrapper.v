`timescale 1 ns / 1 ps
//
`default_nettype none

// verilog_format: off
module ptp_wrapper (
    // AXI-Lite I/F
    //-------------
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET s_axi_aresetn, ASSOCIATED_BUSIF S_AXI, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire        s_axi_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire        s_axi_aresetn,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input  wire [31:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
    input  wire [ 2:0] s_axi_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
    input  wire        s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
    output wire        s_axi_awready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input  wire [31:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
    input  wire [ 3:0] s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
    input  wire        s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
    output wire        s_axi_wready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
    output wire [ 1:0] s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
    output wire        s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
    input  wire        s_axi_bready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input  wire [31:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
    input  wire [ 2:0] s_axi_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input  wire        s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
    output wire        s_axi_arready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output wire [31:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output wire [ 1:0] s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output wire        s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input  wire        s_axi_rready,
    // Ethernet I/F
    //-------------
    // Rx Ethernet ports
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 rx_eth_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET rx_eth_rst, ASSOCIATED_BUSIF S_AXIS, FREQ_HZ 312500000, FREQ_TOLERANCE_HZ 0" *)
    input  wire        rx_eth_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rx_eth_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input  wire        rx_eth_rst,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
    input  wire [31:0] s_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TKEEP" *)
    input  wire [ 3:0] s_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TLAST" *)
    input  wire        s_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TUSER" *)
    input  wire        s_axis_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
    input  wire        s_axis_tvalid,
    // Tx Ethernet ports
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 tx_eth_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET tx_eth_rst, ASSOCIATED_BUSIF M_AXIS, FREQ_HZ 312500000, FREQ_TOLERANCE_HZ 0" *)
    input  wire        tx_eth_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 tx_eth_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input  wire        tx_eth_rst,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
    output wire [31:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TKEEP" *)
    output wire [ 3:0] m_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TLAST" *)
    output wire        m_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TUSER" *)
    output wire        m_axis_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
    output wire        m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)
    input  wire        m_axis_tready,
    // PTP User Interface
    input  wire [79:0] rx_ptp_timestamp,
    input  wire        rx_ptp_timestamp_valid,
    //
    output wire [ 1:0] tx_ptp_1588op,
    output wire [15:0] tx_ptp_tag_field,
    input  wire [79:0] tx_ptp_timestamp,
    input  wire [15:0] tx_ptp_timestamp_tag,
    input  wire        tx_ptp_timestamp_valid,
    // PTP Control Interface
    output wire [79:0] ctl_rx_systemtimer,
    output wire [79:0] ctl_tx_systemtimer,
    // Internal interface
    //-------------------
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET rstn, ASSOCIATED_BUSIF, FREQ_HZ 491520000, FREQ_TOLERANCE_HZ 0" *)
    input  wire        clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rstn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire        rstn,
    //
    input  wire        pps_in,
    //
    input  wire [47:0] tod_sec,
    input  wire [31:0] tod_ns
);
// verilog_format: on

  ptp inst (
      // AXI-Lite I/F
      //-------------
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
      // Ethernet I/F
      //-------------
      // Rx Ethernet ports
      .rx_eth_clk            (rx_eth_clk),
      .rx_eth_rst            (rx_eth_rst),
      //
      .s_axis_tdata          (s_axis_tdata),
      .s_axis_tkeep          (s_axis_tkeep),
      .s_axis_tlast          (s_axis_tlast),
      .s_axis_tuser          (s_axis_tuser),
      .s_axis_tvalid         (s_axis_tvalid),
      // Tx Ethernet ports
      .tx_eth_clk            (tx_eth_clk),
      .tx_eth_rst            (tx_eth_rst),
      //
      .m_axis_tdata          (m_axis_tdata),
      .m_axis_tkeep          (m_axis_tkeep),
      .m_axis_tlast          (m_axis_tlast),
      .m_axis_tuser          (m_axis_tuser),
      .m_axis_tvalid         (m_axis_tvalid),
      .m_axis_tready         (m_axis_tready),
      // PTP ports
      .rx_ptp_timestamp      (rx_ptp_timestamp),
      .rx_ptp_timestamp_valid(rx_ptp_timestamp_valid),
      //
      .tx_ptp_1588op         (tx_ptp_1588op),
      .tx_ptp_tag_field      (tx_ptp_tag_field),
      .tx_ptp_timestamp      (tx_ptp_timestamp),
      .tx_ptp_timestamp_tag  (tx_ptp_timestamp_tag),
      .tx_ptp_timestamp_valid(tx_ptp_timestamp_valid),
      // PTP Control Interface
      .ctl_rx_systemtimer    (ctl_rx_systemtimer),
      .ctl_tx_systemtimer    (ctl_tx_systemtimer),
      // Internal interface
      //-------------------
      .clk                   (clk),
      .rst                   (~rstn),
      //
      .pps_in                (pps_in),
      //
      .tod_sec               (tod_sec),
      .tod_ns                (tod_ns)
  );

endmodule

`default_nettype wire
