`timescale 1 ns / 1 ps
//
`default_nettype none

// verilog_format: off
module rts2_wrapper (
    // AXI4-Lite
    //----------
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET s_axi_aresetn, ASSOCIATED_BUSIF S_AXI, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire        s_axi_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire        s_axi_aresetn,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input  wire [15:0] s_axi_awaddr,
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
    input  wire [15:0] s_axi_araddr,
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
    // Timer Interface
    //----------------
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET rstn, ASSOCIATED_BUSIF \"\", ASSOCIATED_PORT rfs_in, FREQ_HZ 400000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire        clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rstn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire        rstn,
    //
    input  wire        rfs_in,
    // DDR DataMover Interface
    //------------------------
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ddr4_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET ddr4_rstn, ASSOCIATED_BUSIF M_AXIS_S2MM_CMD:M_AXIS_MM2S_CMD:S_AXIS_S2MM_STS:S_AXIS_MM2S_STS:M_AXIS_S2MM:S_AXIS_MM2S:M_TX_AXIS:S_RX_AXIS, FREQ_HZ 300000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire        ddr4_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ddr4_rstn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire        ddr4_rstn,
    // S2MM CMD
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_S2MM_CMD TDATA" *)
    output wire [79:0] m_axis_s2mm_cmd_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_S2MM_CMD TVALID" *)
    output wire        m_axis_s2mm_cmd_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_S2MM_CMD TREADY" *)
    input  wire        m_axis_s2mm_cmd_tready,
    // MM2S CMD
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S_CMD TDATA" *)
    output wire [79:0] m_axis_mm2s_cmd_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S_CMD TVALID" *)
    output wire        m_axis_mm2s_cmd_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S_CMD TREADY" *)
    input  wire        m_axis_mm2s_cmd_tready,
    // S2MM STS
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_STS TDATA" *)
    input  wire [31:0] s_axis_s2mm_sts_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_STS TKEEP" *)
    input  wire [ 3:0] s_axis_s2mm_sts_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_STS TLAST" *)
    input  wire        s_axis_s2mm_sts_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_STS TVALID" *)
    input  wire        s_axis_s2mm_sts_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_STS TREADY" *)
    output wire        s_axis_s2mm_sts_tready,
    // MM2S STS
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_MM2S_STS TDATA" *)
    input  wire [ 7:0] s_axis_mm2s_sts_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_MM2S_STS TKEEP" *)
    input  wire [ 0:0] s_axis_mm2s_sts_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_MM2S_STS TLAST" *)
    input  wire        s_axis_mm2s_sts_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_MM2S_STS TVALID" *)
    input  wire        s_axis_mm2s_sts_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_MM2S_STS TREADY" *)
    output wire        s_axis_mm2s_sts_tready,
    //
    input  wire        mm2s_err,
    input  wire        s2mm_err,
    // S2MM AXIS
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_S2MM TDATA" *)
    output wire [63:0] m_axis_s2mm_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_S2MM TKEEP" *)
    output wire [ 7:0] m_axis_s2mm_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_S2MM TLAST" *)
    output wire        m_axis_s2mm_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_S2MM TVALID" *)
    output wire        m_axis_s2mm_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_S2MM TREADY" *)
    input  wire        m_axis_s2mm_tready,
    // MM2S AXIS
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_MM2S TDATA" *)
    input  wire [63:0] s_axis_mm2s_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_MM2S TKEEP" *)
    input  wire [ 7:0] s_axis_mm2s_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_MM2S TLAST" *)
    input  wire        s_axis_mm2s_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_MM2S TVALID" *)
    input  wire        s_axis_mm2s_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_MM2S TREADY" *)
    output wire        s_axis_mm2s_tready,
    // Ethernet Interface
    //-------------------
    // Ethernet Tx
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_TX_AXIS TDATA" *)
    output wire [63:0] m_tx_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_TX_AXIS TKEEP" *)
    output wire [ 7:0] m_tx_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_TX_AXIS TLAST" *)
    output wire        m_tx_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_TX_AXIS TVALID" *)
    output wire        m_tx_axis_tvalid,
    // Ethernet Rx
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_RX_AXIS TDATA" *)
    input  wire [63:0] s_rx_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_RX_AXIS TKEEP" *)
    input  wire [ 7:0] s_rx_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_RX_AXIS TLAST" *)
    input  wire        s_rx_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_RX_AXIS TVALID" *)
    input  wire        s_rx_axis_tvalid
);
// verilog_format: on

  reg rst;
  reg ddr4_rst;

  always @(posedge clk) begin
    rst <= ~rstn;
  end

  always @(posedge ddr4_clk) begin
    ddr4_rst <= ~ddr4_rstn;
  end

  rts2 inst (
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
      //
      .clk                   (clk),
      .rst                   (rst),
      //
      .rfs_in                (rfs_in),
      //
      .ddr4_clk              (ddr4_clk),
      .ddr4_rst              (ddr4_rst),
      // S2MM CMD
      .m_axis_s2mm_cmd_tdata (m_axis_s2mm_cmd_tdata),
      .m_axis_s2mm_cmd_tvalid(m_axis_s2mm_cmd_tvalid),
      .m_axis_s2mm_cmd_tready(m_axis_s2mm_cmd_tready),
      // MM2S CMD
      .m_axis_mm2s_cmd_tdata (m_axis_mm2s_cmd_tdata),
      .m_axis_mm2s_cmd_tvalid(m_axis_mm2s_cmd_tvalid),
      .m_axis_mm2s_cmd_tready(m_axis_mm2s_cmd_tready),
      // S2MM STS
      .s_axis_s2mm_sts_tdata (s_axis_s2mm_sts_tdata),
      .s_axis_s2mm_sts_tkeep (s_axis_s2mm_sts_tkeep),
      .s_axis_s2mm_sts_tlast (s_axis_s2mm_sts_tlast),
      .s_axis_s2mm_sts_tvalid(s_axis_s2mm_sts_tvalid),
      .s_axis_s2mm_sts_tready(s_axis_s2mm_sts_tready),
      // MM2S STS
      .s_axis_mm2s_sts_tdata (s_axis_mm2s_sts_tdata),
      .s_axis_mm2s_sts_tkeep (s_axis_mm2s_sts_tkeep),
      .s_axis_mm2s_sts_tlast (s_axis_mm2s_sts_tlast),
      .s_axis_mm2s_sts_tvalid(s_axis_mm2s_sts_tvalid),
      .s_axis_mm2s_sts_tready(s_axis_mm2s_sts_tready),
      //
      .mm2s_err              (mm2s_err),
      .s2mm_err              (s2mm_err),
      //
      .m_axis_s2mm_tdata     (m_axis_s2mm_tdata),
      .m_axis_s2mm_tkeep     (m_axis_s2mm_tkeep),
      .m_axis_s2mm_tlast     (m_axis_s2mm_tlast),
      .m_axis_s2mm_tvalid    (m_axis_s2mm_tvalid),
      .m_axis_s2mm_tready    (m_axis_s2mm_tready),
      //
      .s_axis_mm2s_tdata     (s_axis_mm2s_tdata),
      .s_axis_mm2s_tkeep     (s_axis_mm2s_tkeep),
      .s_axis_mm2s_tlast     (s_axis_mm2s_tlast),
      .s_axis_mm2s_tvalid    (s_axis_mm2s_tvalid),
      .s_axis_mm2s_tready    (s_axis_mm2s_tready),
      //
      .m_tx_axis_tdata       (m_tx_axis_tdata),
      .m_tx_axis_tkeep       (m_tx_axis_tkeep),
      .m_tx_axis_tlast       (m_tx_axis_tlast),
      .m_tx_axis_tvalid      (m_tx_axis_tvalid),
      //
      .s_rx_axis_tdata       (s_rx_axis_tdata),
      .s_rx_axis_tkeep       (s_rx_axis_tkeep),
      .s_rx_axis_tlast       (s_rx_axis_tlast),
      .s_rx_axis_tvalid      (s_rx_axis_tvalid)
  );

endmodule

`default_nettype wire
