`timescale 1ns / 1ps
//
`default_nettype none

module rts2_playback #(
    parameter integer ADDR_WIDTH = 40
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        sync_in,
    //
    input  wire        ddr4_clk,
    input  wire        ddr4_rst,
    // CMD
    output wire [79:0] m_axis_mm2s_cmd_tdata,
    output wire        m_axis_mm2s_cmd_tvalid,
    input  wire        m_axis_mm2s_cmd_tready,
    // STS
    input  wire [ 7:0] s_axis_mm2s_sts_tdata,
    input  wire [ 0:0] s_axis_mm2s_sts_tkeep,
    input  wire        s_axis_mm2s_sts_tlast,
    input  wire        s_axis_mm2s_sts_tvalid,
    output wire        s_axis_mm2s_sts_tready,
    //
    input  wire        mm2s_err,
    //
    input  wire [63:0] s_axis_tdata,
    input  wire [ 7:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    //
    output wire [63:0] m_tx_axis_tdata,
    output wire [ 7:0] m_tx_axis_tkeep,
    output wire        m_tx_axis_tlast,
    output wire        m_tx_axis_tvalid,
    //
    input  wire        ctrl_en,
    input  wire [31:0] ctrl_addr_offset,
    input  wire [31:0] ctrl_addr_size
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
