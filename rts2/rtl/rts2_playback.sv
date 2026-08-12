`timescale 1ns / 1ps
//
`default_nettype none

module rts2_playback #(
    parameter int ADDR_WIDTH = 40
) (
    input var         clk,
    input var         rst,
    //
    input var         sync_in,
    //
    input var         ddr4_clk,
    input var         ddr4_rst,
    // CMD
    output var [79:0] m_axis_mm2s_cmd_tdata,
    output var        m_axis_mm2s_cmd_tvalid,
    input var         m_axis_mm2s_cmd_tready,
    // STS
    input var  [ 7:0] s_axis_mm2s_sts_tdata,
    input var  [ 0:0] s_axis_mm2s_sts_tkeep,
    input var         s_axis_mm2s_sts_tlast,
    input var         s_axis_mm2s_sts_tvalid,
    output var        s_axis_mm2s_sts_tready,
    //
    input var         mm2s_err,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var         s_axis_tvalid,
    output var        s_axis_tready,
    //
    output var [63:0] m_tx_axis_tdata,
    output var [ 7:0] m_tx_axis_tkeep,
    output var        m_tx_axis_tlast,
    output var        m_tx_axis_tvalid,
    //
    input var         ctrl_en,
    input var  [31:0] ctrl_addr_offset,
    input var  [31:0] ctrl_addr_size
);

  rts2_playback_ctrl #(
      .ADDR_WIDTH(ADDR_WIDTH)
  ) i_ctrl (
      .ddr4_clk              (ddr4_clk),
      .ddr4_rst              (ddr4_rst),
      // DataMover I/F
      //--------------
      .m_axis_mm2s_cmd_tdata (m_axis_mm2s_cmd_tdata),
      .m_axis_mm2s_cmd_tvalid(m_axis_mm2s_cmd_tvalid),
      .m_axis_mm2s_cmd_tready(m_axis_mm2s_cmd_tready),
      //
      .s_axis_mm2s_sts_tdata (s_axis_mm2s_sts_tdata),
      .s_axis_mm2s_sts_tkeep (s_axis_mm2s_sts_tkeep),
      .s_axis_mm2s_sts_tlast (s_axis_mm2s_sts_tlast),
      .s_axis_mm2s_sts_tvalid(s_axis_mm2s_sts_tvalid),
      .s_axis_mm2s_sts_tready(s_axis_mm2s_sts_tready),
      //
      .mm2s_err              (mm2s_err),
      //
      .ctrl_en               (ctrl_en),
      .ctrl_addr_offset      (ctrl_addr_offset),
      .ctrl_addr_size        (ctrl_addr_size)
  );

  rts2_playback_parser i_parser (
      .clk          (clk),
      .rst          (rst),
      //
      .sync_in      (sync_in),
      //
      .ddr4_clk     (ddr4_clk),
      .ddr4_rst     (ddr4_rst),
      //
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tkeep (s_axis_tkeep),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tvalid(s_axis_tvalid),
      .s_axis_tready(s_axis_tready),
      //
      .m_axis_tdata (m_tx_axis_tdata),
      .m_axis_tkeep (m_tx_axis_tkeep),
      .m_axis_tlast (m_tx_axis_tlast),
      .m_axis_tvalid(m_tx_axis_tvalid),
      //
      .ctrl_en      (ctrl_en)
  );

endmodule

`default_nettype wire
