`timescale 1 ns / 1 ps
//
`default_nettype none

module fh_deframer (
    // Ethernet I/F
    //-------------
    // Rx Ethernet ports
    input  wire        rx_eth_clk,
    input  wire        rx_eth_rst,
    //
    input  wire [63:0] s_axis_rx_tdata,
    input  wire [ 7:0] s_axis_rx_tkeep,
    input  wire        s_axis_rx_tlast,
    input  wire        s_axis_rx_tuser,
    input  wire        s_axis_rx_tvalid,
    // PTP ports
    input  wire [79:0] rx_ptp_timestamp,
    input  wire        rx_ptp_timestamp_valid,
    // Internal Interface
    //-------------------
    input  wire        clk,
    input  wire        rst,
    // Receive interface
    output wire [63:0] m_axis_tdata,
    output wire [ 7:0] m_axis_tkeep,
    output wire        m_axis_tlast,
    output wire [79:0] m_axis_tuser,
    output wire        m_axis_tvalid,
    // PTP interface
    output wire [31:0] m_ptp_tdata,
    output wire [ 3:0] m_ptp_tkeep,
    output wire        m_ptp_tlast,
    output wire [79:0] m_ptp_tuser,
    output wire        m_ptp_tvalid,
    input  wire        m_ptp_tready,
    //
    output wire [31:0] m_message_tdata,
    output wire [ 3:0] m_message_tkeep,
    output wire        m_message_tlast,
    output wire        m_message_tvalid,
    input  wire        m_message_tready
);

  wire [63:0] s0_axis_tdata;
  wire [ 7:0] s0_axis_tkeep;
  wire        s0_axis_tlast;
  wire [79:0] s0_axis_tuser;
  wire        s0_axis_tvalid;

  wire [63:0] s0_ptp_tdata;
  wire [ 7:0] s0_ptp_tkeep;
  wire        s0_ptp_tlast;
  wire [79:0] s0_ptp_tuser;
  wire        s0_ptp_tvalid;

  wire [63:0] s0_message_tdata;
  wire [ 7:0] s0_message_tkeep;
  wire        s0_message_tlast;
  wire        s0_message_tvalid;

  wire        stat_corrupt_pkt;
  wire        message_tuser_unused;
  wire        unused_outputs = &{1'b0, stat_corrupt_pkt, message_tuser_unused};

  fh_deframer_demux i_demux (
      // Ethernet clock domain
      //----------------------
      .rx_eth_clk            (rx_eth_clk),
      .rx_eth_rst            (rx_eth_rst),
      //
      .s_axis_tdata          (s_axis_rx_tdata),
      .s_axis_tkeep          (s_axis_rx_tkeep),
      .s_axis_tlast          (s_axis_rx_tlast),
      .s_axis_tuser          (s_axis_rx_tuser),
      .s_axis_tvalid         (s_axis_rx_tvalid),
      //
      .rx_ptp_timestamp      (rx_ptp_timestamp),
      .rx_ptp_timestamp_valid(rx_ptp_timestamp_valid),
      // Internal clock domain
      //----------------------
      .clk                   (clk),
      .rst                   (rst),
      // eCPRI message
      .m_axis_tdata          (s0_axis_tdata),
      .m_axis_tkeep          (s0_axis_tkeep),
      .m_axis_tlast          (s0_axis_tlast),
      .m_axis_tuser          (s0_axis_tuser),
      .m_axis_tvalid         (s0_axis_tvalid),
      // PTP message
      .m_ptp_tdata           (s0_ptp_tdata),
      .m_ptp_tkeep           (s0_ptp_tkeep),
      .m_ptp_tlast           (s0_ptp_tlast),
      .m_ptp_tuser           (s0_ptp_tuser),
      .m_ptp_tvalid          (s0_ptp_tvalid),
      // none-eCPRI message
      .m_message_tdata       (s0_message_tdata),
      .m_message_tkeep       (s0_message_tkeep),
      .m_message_tlast       (s0_message_tlast),
      .m_message_tvalid      (s0_message_tvalid),
      // Control & Status
      //-----------------
      .stat_corrupt_pkt      (stat_corrupt_pkt)
  );

  fh_deframer_buffer #(
      .FIFO_DEPTH  (4096),
      .FIFO_LATENCY(3),
      .USER_WIDTH  (80)
  ) i_fh_fifo (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s0_axis_tdata),
      .s_axis_tkeep (s0_axis_tkeep),
      .s_axis_tlast (s0_axis_tlast),
      .s_axis_tuser (s0_axis_tuser),
      .s_axis_tvalid(s0_axis_tvalid),
      //
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tuser (m_axis_tuser),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tready(1'b1)
  );

  fh_deframer_64to32 #(
      .FIFO_DEPTH  (4096),
      .FIFO_LATENCY(3),
      .USER_WIDTH  (80)
  ) i_ptp_fifo (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s0_ptp_tdata),
      .s_axis_tkeep (s0_ptp_tkeep),
      .s_axis_tlast (s0_ptp_tlast),
      .s_axis_tuser (s0_ptp_tuser),
      .s_axis_tvalid(s0_ptp_tvalid),
      //
      .m_axis_tdata (m_ptp_tdata),
      .m_axis_tkeep (m_ptp_tkeep),
      .m_axis_tlast (m_ptp_tlast),
      .m_axis_tuser (m_ptp_tuser),
      .m_axis_tvalid(m_ptp_tvalid),
      .m_axis_tready(m_ptp_tready)
  );

  fh_deframer_64to32 #(
      .FIFO_DEPTH  (4096),
      .FIFO_LATENCY(3),
      .USER_WIDTH  (1)
  ) i_message_fifo (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s0_message_tdata),
      .s_axis_tkeep (s0_message_tkeep),
      .s_axis_tlast (s0_message_tlast),
      .s_axis_tuser ('b0),
      .s_axis_tvalid(s0_message_tvalid),
      //
      .m_axis_tdata (m_message_tdata),
      .m_axis_tkeep (m_message_tkeep),
      .m_axis_tlast (m_message_tlast),
      .m_axis_tuser (message_tuser_unused),
      .m_axis_tvalid(m_message_tvalid),
      .m_axis_tready(m_message_tready)
  );

endmodule

`default_nettype wire
