`timescale 1 ns / 1 ps
//
`default_nettype none

module rts2 (
    input var         s_axi_aclk,
    input var         s_axi_aresetn,
    //
    input var  [15:0] s_axi_awaddr,
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
    input var  [15:0] s_axi_araddr,
    input var  [ 2:0] s_axi_arprot,
    input var         s_axi_arvalid,
    output var        s_axi_arready,
    //
    output var [31:0] s_axi_rdata,
    output var [ 1:0] s_axi_rresp,
    output var        s_axi_rvalid,
    input var         s_axi_rready,
    // Timer interfaces
    //-----------------
    input var         clk,
    input var         rst,
    //
    input var         rfs_in,
    // DataMover interface
    //--------------------
    input var         ddr4_clk,
    input var         ddr4_rst,
    // S2MM CMD
    output var [79:0] m_axis_s2mm_cmd_tdata,
    output var        m_axis_s2mm_cmd_tvalid,
    input var         m_axis_s2mm_cmd_tready,
    // MM2S CMD
    output var [79:0] m_axis_mm2s_cmd_tdata,
    output var        m_axis_mm2s_cmd_tvalid,
    input var         m_axis_mm2s_cmd_tready,
    // S2MM STS
    input var  [31:0] s_axis_s2mm_sts_tdata,
    input var  [ 3:0] s_axis_s2mm_sts_tkeep,
    input var         s_axis_s2mm_sts_tlast,
    input var         s_axis_s2mm_sts_tvalid,
    output var        s_axis_s2mm_sts_tready,
    // MM2S STS
    input var  [ 7:0] s_axis_mm2s_sts_tdata,
    input var  [ 0:0] s_axis_mm2s_sts_tkeep,
    input var         s_axis_mm2s_sts_tlast,
    input var         s_axis_mm2s_sts_tvalid,
    output var        s_axis_mm2s_sts_tready,
    //
    input var         mm2s_err,
    input var         s2mm_err,
    // MM2S AXIS
    output var [63:0] m_axis_s2mm_tdata,
    output var [ 7:0] m_axis_s2mm_tkeep,
    output var        m_axis_s2mm_tlast,
    output var        m_axis_s2mm_tvalid,
    input var         m_axis_s2mm_tready,
    // S2MM AXIS
    input var  [63:0] s_axis_mm2s_tdata,
    input var  [ 7:0] s_axis_mm2s_tkeep,
    input var         s_axis_mm2s_tlast,
    input var         s_axis_mm2s_tvalid,
    output var        s_axis_mm2s_tready,
    // Ethernet ports
    //--------------
    output var [63:0] m_tx_axis_tdata,
    output var [ 7:0] m_tx_axis_tkeep,
    output var        m_tx_axis_tlast,
    output var        m_tx_axis_tvalid,
    //
    input var  [63:0] s_rx_axis_tdata,
    input var  [ 7:0] s_rx_axis_tkeep,
    input var         s_rx_axis_tlast,
    input var         s_rx_axis_tvalid
);

  localparam int AddrWidth = 40;

  wire [0:0] ctrl_en;

  wire [31:0] ctrl_ram0_offset;
  wire [31:0] ctrl_ram1_offset;
  wire [31:0] ctrl_ram2_offset;

  wire [31:0] ctrl_ram0_size;
  wire [31:0] ctrl_ram1_size;
  wire [31:0] ctrl_ram2_size;

  wire unused_ctrl_outputs = &{1'b0, s_axi_awaddr[15:9], s_axi_araddr[15:9], ctrl_ram1_offset, ctrl_ram2_offset, ctrl_ram1_size, ctrl_ram2_size, 1'b0};

  // Main

  rts2_regs i_regs (
      .s_axi_aclk         (s_axi_aclk),
      .s_axi_aresetn      (s_axi_aresetn),
      //
      .s_axi_awaddr       (s_axi_awaddr[8:0]),
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
      .s_axi_araddr       (s_axi_araddr[8:0]),
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
