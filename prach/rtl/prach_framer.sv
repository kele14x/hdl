`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_framer #(
    parameter int CC_ID   = 0,
    parameter int ANT_ID  = 0,
    parameter int NUM_ANT = 4
) (
    input var         clk,
    input var         rst,
    //
    input var  [15:0] din_dr,
    input var  [15:0] din_di,
    input var         din_sf,
    input var         din_sl,
    input var         din_sy,
    input var  [ 1:0] din_chn,
    input var         din_dv,
    input var         din_last,
    //
    input var  [11:0] rd_section_id,
    // ORAN I/F
    //---------
    input var         clk_eth_xran,
    input var         rst_eth_xran,
    // U-Plane
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var [31:0] m_axis_tuser,
    output var        m_axis_tvalid,
    input var         m_axis_tready,
    // CSR
    //----
    input var  [ 3:0] ctrl_fs_offset
);

  // Signals

  logic [63:0] s0_axis_tdata;
  logic [ 7:0] s0_axis_tkeep;
  logic        s0_axis_tlast;
  logic [31:0] s0_axis_tuser;
  logic        s0_axis_tvalid;

  logic        fifo_err_discard;

  // Main

  prach_framer_buffer #(
      .CC_ID  (CC_ID),
      .ANT_ID (ANT_ID),
      .NUM_ANT(NUM_ANT)
  ) u_buffer (
      .clk           (clk),
      .rst           (rst),
      //
      .din_dr        (din_dr),
      .din_di        (din_di),
      .din_sf        (din_sf),
      .din_sl        (din_sl),
      .din_sy        (din_sy),
      .din_chn       (din_chn),
      .din_dv        (din_dv),
      .din_last      (din_last),
      //
      .rd_section_id (rd_section_id),
      .ctrl_fs_offset(ctrl_fs_offset),
      //
      .m_axis_tdata  (s0_axis_tdata),
      .m_axis_tkeep  (s0_axis_tkeep),
      .m_axis_tlast  (s0_axis_tlast),
      .m_axis_tuser  (s0_axis_tuser),
      .m_axis_tvalid (s0_axis_tvalid)
  );

  axis_fifo_alt #(
      .ASYNC_MODE  (1'b1),
      .FIFO_DEPTH  (1024),
      .FIFO_LATENCY(3),
      .DATA_WIDTH  (64),
      .USER_WIDTH  (32)
  ) u_fifo (
      .s_axis_aclk   (clk),
      .s_axis_aresetn(~rst),
      //
      .s_axis_tdata  (s0_axis_tdata),
      .s_axis_tkeep  (s0_axis_tkeep),
      .s_axis_tlast  (s0_axis_tlast),
      .s_axis_tuser  (s0_axis_tuser),
      .s_axis_tvalid (s0_axis_tvalid),
      //
      .m_axis_aclk   (clk_eth_xran),
      //
      .m_axis_tdata  (m_axis_tdata),
      .m_axis_tkeep  (m_axis_tkeep),
      .m_axis_tlast  (m_axis_tlast),
      .m_axis_tuser  (m_axis_tuser),
      .m_axis_tvalid (m_axis_tvalid),
      .m_axis_tready (m_axis_tready),
      .err_discard   (fifo_err_discard)
      //
  );

  wire unused_framer = &{1'b0, rst_eth_xran, fifo_err_discard};

endmodule

`default_nettype wire
