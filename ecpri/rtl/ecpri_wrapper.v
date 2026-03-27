`timescale 1 ns / 1 ps
//
`default_nettype none

// verilog_format: off
module ecpri_wrapper (
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
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET rx_eth_rst, ASSOCIATED_BUSIF S_ETH_DEFM, FREQ_HZ 312500000, FREQ_TOLERANCE_HZ 0" *)
    input  wire        rx_eth_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rx_eth_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input  wire        rx_eth_rst,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_ETH_DEFM TDATA" *)
    input  wire [31:0] s_eth_defm_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_ETH_DEFM TKEEP" *)
    input  wire [ 3:0] s_eth_defm_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_ETH_DEFM TLAST" *)
    input  wire        s_eth_defm_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_ETH_DEFM TUSER" *)
    input  wire        s_eth_defm_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_ETH_DEFM TVALID" *)
    input  wire        s_eth_defm_tvalid,
    // Tx Ethernet ports
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 tx_eth_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET tx_eth_rst, ASSOCIATED_BUSIF M_ETH_FRAM, FREQ_HZ 312500000, FREQ_TOLERANCE_HZ 0" *)
    input  wire        tx_eth_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 tx_eth_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input  wire        tx_eth_rst,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_FRAM TDATA" *)
    output wire [31:0] m_eth_fram_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_FRAM TKEEP" *)
    output wire [ 3:0] m_eth_fram_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_FRAM TLAST" *)
    output wire        m_eth_fram_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_FRAM TUSER" *)
    output wire        m_eth_fram_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_FRAM TVALID" *)
    output wire        m_eth_fram_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_ETH_FRAM TREADY" *)
    input  wire        m_eth_fram_tready,
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
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET rstn, ASSOCIATED_BUSIF M_AXIS:M_PTP:M_MESSAGE:S_AXIS:S_PTP:S_MESSAGE, FREQ_HZ 491520000, FREQ_TOLERANCE_HZ 0" *)
    input  wire        clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rstn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire        rstn,
    //
    input  wire        pps_in,
    //
    input  wire [47:0] tod_sec,
    input  wire [31:0] tod_ns,
    //
    input  wire [15:0] topology_id,
    // Deframer ports
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
    output wire [31:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TKEEP" *)
    output wire [ 3:0] m_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TLAST" *)
    output wire        m_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
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
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_PTP TDATA" *)
    output wire [31:0] m_ptp_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_PTP TKEEP" *)
    output wire [ 3:0] m_ptp_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_PTP TLAST" *)
    output wire        m_ptp_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_PTP TUSER" *)
    output wire [79:0] m_ptp_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_PTP TVALID" *)
    output wire        m_ptp_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_PTP TREADY" *)
    input  wire        m_ptp_tready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_MESSAGE TDATA" *)
    output wire [31:0] m_message_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_MESSAGE TKEEP" *)
    output wire [ 3:0] m_message_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_MESSAGE TLAST" *)
    output wire        m_message_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_MESSAGE TVALID" *)
    output wire        m_message_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_MESSAGE TREADY" *)
    input  wire        m_message_tready,
    // Framer ports
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
    input  wire [31:0] s_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TKEEP" *)
    input  wire [ 3:0] s_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TLAST" *)
    input  wire        s_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
    input  wire        s_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *)
    output wire        s_axis_tready,
    //
    input  wire [ 7:0] s_trans_messagetype,
    input  wire [15:0] s_trans_payloadsize,
    input  wire [15:0] s_trans_rtc_pc_id,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_PTP TDATA" *)
    input  wire [31:0] s_ptp_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_PTP TKEEP" *)
    input  wire [ 3:0] s_ptp_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_PTP TLAST" *)
    input  wire        s_ptp_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_PTP TUSER" *)
    input  wire [17:0] s_ptp_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_PTP TVALID" *)
    input  wire        s_ptp_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_PTP TREADY" *)
    output wire        s_ptp_tready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_MESSAGE TDATA" *)
    input  wire [31:0] s_message_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_MESSAGE TKEEP" *)
    input  wire [ 3:0] s_message_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_MESSAGE TLAST" *)
    input  wire        s_message_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_MESSAGE TVALID" *)
    input  wire        s_message_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_MESSAGE TREADY" *)
    output wire        s_message_tready
);
// verilog_format: on

  ecpri inst (
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
      .s_eth_defm_tdata      (s_eth_defm_tdata),
      .s_eth_defm_tkeep      (s_eth_defm_tkeep),
      .s_eth_defm_tlast      (s_eth_defm_tlast),
      .s_eth_defm_tuser      (s_eth_defm_tuser),
      .s_eth_defm_tvalid     (s_eth_defm_tvalid),
      // Tx Ethernet ports
      .tx_eth_clk            (tx_eth_clk),
      .tx_eth_rst            (tx_eth_rst),
      //
      .m_eth_fram_tdata      (m_eth_fram_tdata),
      .m_eth_fram_tkeep      (m_eth_fram_tkeep),
      .m_eth_fram_tlast      (m_eth_fram_tlast),
      .m_eth_fram_tuser      (m_eth_fram_tuser),
      .m_eth_fram_tvalid     (m_eth_fram_tvalid),
      .m_eth_fram_tready     (m_eth_fram_tready),
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
      .tod_ns                (tod_ns),
      //
      .topology_id           (topology_id),
      // Deframer ports
      .m_axis_tdata          (m_axis_tdata),
      .m_axis_tkeep          (m_axis_tkeep),
      .m_axis_tlast          (m_axis_tlast),
      .m_axis_tvalid         (m_axis_tvalid),
      //
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
      // Framer ports
      .s_axis_tdata          (s_axis_tdata),
      .s_axis_tkeep          (s_axis_tkeep),
      .s_axis_tlast          (s_axis_tlast),
      .s_axis_tvalid         (s_axis_tvalid),
      .s_axis_tready         (s_axis_tready),
      //
      .s_trans_messagetype   (s_trans_messagetype),
      .s_trans_payloadsize   (s_trans_payloadsize),
      .s_trans_rtc_pc_id     (s_trans_rtc_pc_id),
      //
      .s_ptp_tdata           (s_ptp_tdata),
      .s_ptp_tkeep           (s_ptp_tkeep),
      .s_ptp_tlast           (s_ptp_tlast),
      .s_ptp_tuser           (s_ptp_tuser),
      .s_ptp_tvalid          (s_ptp_tvalid),
      .s_ptp_tready          (s_ptp_tready),
      //
      .s_message_tdata       (s_message_tdata),
      .s_message_tkeep       (s_message_tkeep),
      .s_message_tlast       (s_message_tlast),
      .s_message_tvalid      (s_message_tvalid),
      .s_message_tready      (s_message_tready)
  );

endmodule

`default_nettype wire
