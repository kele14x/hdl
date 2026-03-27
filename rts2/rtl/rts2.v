`timescale 1 ns / 1 ps
//
`default_nettype none

module rts2 (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [15:0] s_axi_awaddr,
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
    input  wire [15:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    // Timer interfaces
    //-----------------
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        rfs_in,
    // DataMover interface
    //--------------------
    input  wire        ddr4_clk,
    input  wire        ddr4_rst,
    // S2MM CMD
    output wire [79:0] m_axis_s2mm_cmd_tdata,
    output wire        m_axis_s2mm_cmd_tvalid,
    input  wire        m_axis_s2mm_cmd_tready,
    // MM2S CMD
    output wire [79:0] m_axis_mm2s_cmd_tdata,
    output wire        m_axis_mm2s_cmd_tvalid,
    input  wire        m_axis_mm2s_cmd_tready,
    // S2MM STS
    input  wire [31:0] s_axis_s2mm_sts_tdata,
    input  wire [ 3:0] s_axis_s2mm_sts_tkeep,
    input  wire        s_axis_s2mm_sts_tlast,
    input  wire        s_axis_s2mm_sts_tvalid,
    output wire        s_axis_s2mm_sts_tready,
    // MM2S STS
    input  wire [ 7:0] s_axis_mm2s_sts_tdata,
    input  wire [ 0:0] s_axis_mm2s_sts_tkeep,
    input  wire        s_axis_mm2s_sts_tlast,
    input  wire        s_axis_mm2s_sts_tvalid,
    output wire        s_axis_mm2s_sts_tready,
    //
    input  wire        mm2s_err,
    input  wire        s2mm_err,
    // MM2S AXIS
    output wire [63:0] m_axis_s2mm_tdata,
    output wire [ 7:0] m_axis_s2mm_tkeep,
    output wire        m_axis_s2mm_tlast,
    output wire        m_axis_s2mm_tvalid,
    input  wire        m_axis_s2mm_tready,
    // S2MM AXIS
    input  wire [63:0] s_axis_mm2s_tdata,
    input  wire [ 7:0] s_axis_mm2s_tkeep,
    input  wire        s_axis_mm2s_tlast,
    input  wire        s_axis_mm2s_tvalid,
    output wire        s_axis_mm2s_tready,
    // Ethernet ports
    //--------------
    output wire [63:0] m_tx_axis_tdata,
    output wire [ 7:0] m_tx_axis_tkeep,
    output wire        m_tx_axis_tlast,
    output wire        m_tx_axis_tvalid,
    //
    input  wire [63:0] s_rx_axis_tdata,
    input  wire [ 7:0] s_rx_axis_tkeep,
    input  wire        s_rx_axis_tlast,
    input  wire        s_rx_axis_tvalid
);

  localparam integer AddrWidth = 40;

  wire [ 0:0] ctrl_en;

  wire [31:0] ctrl_ram0_offset;
  wire [31:0] ctrl_ram1_offset;
  wire [31:0] ctrl_ram2_offset;

  wire [31:0] ctrl_ram0_size;
  wire [31:0] ctrl_ram1_size;
  wire [31:0] ctrl_ram2_size;

  // Main

  rts2_regs i_regs (
      .s_axi_aclk         (s_axi_aclk),
      .s_axi_aresetn      (s_axi_aresetn),
      //
      .s_axi_awaddr       (s_axi_awaddr),
      .s_axi_awprot       (s_axi_awprot),
      .s_axi_awvalid      (s_axi_awvalid),
      .s_axi_awready      (s_axi_awready),
      //
      .s_axi_wdata        (s_axi_wdata),
      .s_axi_wstrb        (s_axi_wstrb),
      .s_axi_wvalid       (s_axi_wvalid),
      .s_axi_wready       (s_axi_wready),
      //
      .s_axi_bresp        (s_axi_bresp),
      .s_axi_bvalid       (s_axi_bvalid),
      .s_axi_bready       (s_axi_bready),
      //
      .s_axi_araddr       (s_axi_araddr),
      .s_axi_arprot       (s_axi_arprot),
      .s_axi_arvalid      (s_axi_arvalid),
      .s_axi_arready      (s_axi_arready),
      //
      .s_axi_rdata        (s_axi_rdata),
      .s_axi_rresp        (s_axi_rresp),
      .s_axi_rvalid       (s_axi_rvalid),
      .s_axi_rready       (s_axi_rready),
      // ctrl.en,
      .ctrl_en_out        (ctrl_en),
      // ram0_offset.val,
      .ram0_offset_val_out(ctrl_ram0_offset),
      // ram1_offset.val,
      .ram1_offset_val_out(ctrl_ram1_offset),
      // ram2_offset.val,
      .ram2_offset_val_out(ctrl_ram2_offset),
      // ram0_size.val,
      .ram0_size_val_out  (ctrl_ram0_size),
      // ram1_size.val,
      .ram1_size_val_out  (ctrl_ram1_size),
      // ram2_size.val,
      .ram2_size_val_out  (ctrl_ram2_size)
  );

  rts2_playback #(
      .ADDR_WIDTH(AddrWidth)
  ) i_playback (
      .clk                   (clk),
      .rst                   (rst),
      //
      .sync_in               (rfs_in),
      //
      .ddr4_clk              (ddr4_clk),
      .ddr4_rst              (ddr4_rst),
      // CMD
      .m_axis_mm2s_cmd_tdata (m_axis_mm2s_cmd_tdata),
      .m_axis_mm2s_cmd_tvalid(m_axis_mm2s_cmd_tvalid),
      .m_axis_mm2s_cmd_tready(m_axis_mm2s_cmd_tready),
      // STS
      .s_axis_mm2s_sts_tdata (s_axis_mm2s_sts_tdata),
      .s_axis_mm2s_sts_tkeep (s_axis_mm2s_sts_tkeep),
      .s_axis_mm2s_sts_tlast (s_axis_mm2s_sts_tlast),
      .s_axis_mm2s_sts_tvalid(s_axis_mm2s_sts_tvalid),
      .s_axis_mm2s_sts_tready(s_axis_mm2s_sts_tready),
      //
      .mm2s_err              (mm2s_err),
      //
      .s_axis_tdata          (s_axis_mm2s_tdata),
      .s_axis_tkeep          (s_axis_mm2s_tkeep),
      .s_axis_tlast          (s_axis_mm2s_tlast),
      .s_axis_tvalid         (s_axis_mm2s_tvalid),
      .s_axis_tready         (s_axis_mm2s_tready),
      //
      .m_tx_axis_tdata       (m_tx_axis_tdata),
      .m_tx_axis_tkeep       (m_tx_axis_tkeep),
      .m_tx_axis_tlast       (m_tx_axis_tlast),
      .m_tx_axis_tvalid      (m_tx_axis_tvalid),
      //
      .ctrl_en               (ctrl_en),
      .ctrl_addr_offset      (ctrl_ram0_offset),
      .ctrl_addr_size        (ctrl_ram0_size)
  );

  rts2_capture #(
      .ADDR_WIDTH(AddrWidth)
  ) i_capture (
      .clk                   (clk),
      .rst                   (rst),
      //
      .sync_in               (rfs_in),
      //
      .ddr4_clk              (ddr4_clk),
      .ddr4_rst              (ddr4_rst),
      //
      .m_axis_s2mm_cmd_tdata (m_axis_s2mm_cmd_tdata),
      .m_axis_s2mm_cmd_tvalid(m_axis_s2mm_cmd_tvalid),
      .m_axis_s2mm_cmd_tready(m_axis_s2mm_cmd_tready),
      //
      .s_axis_s2mm_sts_tdata (s_axis_s2mm_sts_tdata),
      .s_axis_s2mm_sts_tkeep (s_axis_s2mm_sts_tkeep),
      .s_axis_s2mm_sts_tlast (s_axis_s2mm_sts_tlast),
      .s_axis_s2mm_sts_tvalid(s_axis_s2mm_sts_tvalid),
      .s_axis_s2mm_sts_tready(s_axis_s2mm_sts_tready),
      //
      .s2mm_err              (s2mm_err),
      //
      .m_axis_tdata          (m_axis_s2mm_tdata),
      .m_axis_tkeep          (m_axis_s2mm_tkeep),
      .m_axis_tlast          (m_axis_s2mm_tlast),
      .m_axis_tvalid         (m_axis_s2mm_tvalid),
      .m_axis_tready         (m_axis_s2mm_tready),
      //
      .s_rx_axis_tdata       (s_rx_axis_tdata),
      .s_rx_axis_tkeep       (s_rx_axis_tkeep),
      .s_rx_axis_tlast       (s_rx_axis_tlast),
      .s_rx_axis_tvalid      (s_rx_axis_tvalid)
  );

endmodule

`default_nettype wire
