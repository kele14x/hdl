// File: ptp_master.sv
// Brief: PTP Master implemented by FPGA.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp #(
    parameter int NUM_CH = 1
) (
    // AXI I/F
    //--------
    input var         s_axi_aclk,
    input var         s_axi_arestn,
    //
    input var  [31:0] s_axi_awaddr,
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
    input var         s_axi_arvalid,
    output var        s_axi_arready,
    //
    output var [31:0] s_axi_rdata,
    output var [ 1:0] s_axi_rresp,
    output var        s_axi_rvalid,
    input var         s_axi_rready,
    // Data I/F
    //---------
    input var         clk,
    input var         rst,
    //
    output var [63:0] m_axis_tdata      [NUM_CH],
    output var [ 7:0] m_axis_tkeep      [NUM_CH],
    output var        m_axis_tvalid     [NUM_CH],
    output var        m_axis_tlast      [NUM_CH],
    output var [55:0] m_axis_tuser      [NUM_CH],
    input var         m_axis_tready     [NUM_CH],
    //
    input var  [95:0] s_axis_txts_tdata [NUM_CH],
    input var         s_axis_txts_tvalid[NUM_CH],
    //
    input var  [63:0] s_axis_tdata      [NUM_CH],
    input var  [ 7:0] s_axis_tkeep      [NUM_CH],
    input var         s_axis_tvalid     [NUM_CH],
    input var         s_axis_tlast      [NUM_CH],
    input var  [79:0] s_axis_tuser      [NUM_CH],
    // Timer I/F
    //----------
    input var         eth_tx_clk,
    input var         eth_tx_rst,
    output var [79:0] eth_tx_systemtimer[NUM_CH],
    //
    input var         eth_rx_clk,
    input var         eth_rx_rst,
    output var [79:0] eth_tx_systemtimer[NUM_CH]
);

  ptp_regs i_regs (
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
      // ctrl.rst,
      .ctrl_rst_out          (ctrl_rst_out),
      // ctrl.enable,
      .ctrl_enable_out       (ctrl_enable_out),
      // mode.slave,
      .mode_slave_out        (mode_slave_out),
      // rtc_offset_set.set,
      .rtc_offset_set_set_out(rtc_offset_set_set_out),
      // rtc_offset_ns.val,
      .rtc_offset_ns_val_out (rtc_offset_ns_val_out),
      // rtc_offset_s_l.val,
      .rtc_offset_s_l_val_out(rtc_offset_s_l_val_out),
      // rtc_offset_s_h.val,
      .rtc_offset_s_h_val_out(rtc_offset_s_h_val_out),
      // rtc_offset_get.get,
      .rtc_offset_get_get_out(rtc_offset_get_get_out),
      // rtc_ns.val,
      .rtc_ns_val_in         (rtc_ns_val_in),
      // rtc_s_l.val,
      .rtc_s_l_val_in        (rtc_s_l_val_in),
      // rtc_s_h.val,
      .rtc_s_h_val_in        (rtc_s_h_val_in)
  );

  generate
    for (genvar i = 0; i < NUM_CH; i++) begin

      ptp_channel i_channel (
          // TX
          //---
          .eth_tx_clk             (eth_tx_clk),
          .eth_tx_rst             (eth_tx_rst),
          //
          .m_axis_tdata           (m_axis_tdata[i]),
          .m_axis_tkeep           (m_axis_tkeep[i]),
          .m_axis_tvalid          (m_axis_tvalid[i]),
          .m_axis_tlast           (m_axis_tlast[i]),
          .m_axis_tready          (m_axis_tready[i]),
          .m_axis_tuser           (m_axis_tuser[i]),
          // Timestamp
          .s_axis_txts_tdata      (s_axis_txts_tdata[i]),
          .s_axis_txts_tvalid     (s_axis_txts_tvalid[i]),
          // RX
          //---
          .eth_rx_clk             (eth_rx_clk),
          .eth_rx_rst             (eth_rx_rst),
          //
          .s_axis_tdata           (s_axis_tdata[i]),
          .s_axis_tkeep           (s_axis_tkeep[i]),
          .s_axis_tvalid          (s_axis_tvalid[i]),
          .s_axis_tlast           (s_axis_tlast[i]),
          .s_axis_tuser           (s_axis_tuser[i]),
          // Internal domain
          //----------------
          .clk                    (clk),
          .rst                    (rst),
          //
          .ctrl_enable            (ctrl_enable),
          .ctrl_soft_reset        (ctrl_soft_reset),
          .ctrl_force_slave       (ctrl_force_slave),
          .ctrl_sync_interval     (ctrl_sync_interval),
          .ctrl_delay_req_internal(ctrl_delay_req_internal)
      );

    end
  endgenerate

endmodule

`default_nettype wire
