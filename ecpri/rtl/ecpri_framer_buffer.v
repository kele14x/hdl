/*
 * eCPRI Framer Buffer
 *   1. Padding the packet to the minimum length
 *   2. Clock domain crossing
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_framer_buffer #(
    parameter integer FIFO_DEPTH = 4096,
    parameter integer USER_WIDTH = 1
) (
    input  wire                                         clk,
    input  wire                                         rst,
    //
    input  wire [                                 31:0] s_axis_tdata,
    input  wire [                                  3:0] s_axis_tkeep,
    input  wire                                         s_axis_tlast,
    input  wire [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] s_axis_tuser,
    input  wire                                         s_axis_tvalid,
    output wire                                         s_axis_tready,
    // Ethernet clock domain
    input  wire                                         tx_eth_clk,
    input  wire                                         tx_eth_rst,
    //
    output wire [                                 31:0] m_axis_tdata,
    output wire [                                  3:0] m_axis_tkeep,
    output wire                                         m_axis_tlast,
    output wire [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] m_axis_tuser,
    output wire                                         m_axis_tvalid,
    input  wire                                         m_axis_tready
);

  // The FIFO

  axis_fifo #(
      .ASYNC_MODE  (1),
      .PACKET_MODE (1),
      .FIFO_DEPTH  (FIFO_DEPTH),
      .FIFO_LATENCY(3),
      .DATA_WIDTH  (32),
      .USER_WIDTH  (USER_WIDTH)
  ) i_fifo (
      .s_axis_aclk   (clk),
      .s_axis_aresetn(!rst),
      //
      .s_axis_tdata  (s_axis_tdata),
      .s_axis_tkeep  (s_axis_tkeep),
      .s_axis_tlast  (s_axis_tlast),
      .s_axis_tuser  (s_axis_tuser),
      .s_axis_tvalid (s_axis_tvalid),
      .s_axis_tready (s_axis_tready),
      //
      .m_axis_aclk   (tx_eth_clk),
      //
      .m_axis_tdata  (m_axis_tdata),
      .m_axis_tkeep  (m_axis_tkeep),
      .m_axis_tlast  (m_axis_tlast),
      .m_axis_tuser  (m_axis_tuser),
      .m_axis_tvalid (m_axis_tvalid),
      .m_axis_tready (m_axis_tready)
  );

endmodule

`default_nettype wire
