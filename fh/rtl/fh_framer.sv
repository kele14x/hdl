`timescale 1 ns / 1 ps
//
`default_nettype none

module fh_framer (
    // Ethernet I/F
    //-------------
    // Tx Ethernet ports
    input var         tx_eth_clk,
    input var         tx_eth_rst,
    //
    output var [63:0] m_axis_tx_tdata,
    output var [ 7:0] m_axis_tx_tkeep,
    output var        m_axis_tx_tlast,
    output var        m_axis_tx_tuser,
    output var        m_axis_tx_tvalid,
    input var         m_axis_tx_tready,
    //
    output var [ 1:0] tx_ptp_1588op,
    output var [15:0] tx_ptp_tag_field,
    // Internal interface
    //-------------------
    input var         clk,
    input var         rst,
    // Receive interface
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var         s_axis_tvalid,
    //
    input var  [31:0] s_ptp_tdata,
    input var  [ 3:0] s_ptp_tkeep,
    input var         s_ptp_tlast,
    input var  [17:0] s_ptp_tuser,
    input var         s_ptp_tvalid,
    output var        s_ptp_tready,
    //
    input var  [31:0] s_message_tdata,
    input var  [ 3:0] s_message_tkeep,
    input var         s_message_tlast,
    input var         s_message_tvalid,
    output var        s_message_tready
);

  wire [63:0] s0_axis_tdata;
  wire [ 7:0] s0_axis_tkeep;
  wire        s0_axis_tlast;
  wire        s0_axis_tvalid;
  wire        s0_axis_tready;

  wire [63:0] s1_axis_tdata;
  wire [ 7:0] s1_axis_tkeep;
  wire        s1_axis_tlast;
  wire [17:0] s1_axis_tuser;
  wire        s1_axis_tvalid;
  wire        s1_axis_tready;

  wire [63:0] s2_axis_tdata;
  wire [ 7:0] s2_axis_tkeep;
  wire        s2_axis_tlast;
  wire        s2_axis_tvalid;
  wire        s2_axis_tready;

  wire [63:0] s3_axis_tdata;
  wire [ 7:0] s3_axis_tkeep;
  wire        s3_axis_tlast;
  wire [17:0] s3_axis_tuser;
  wire        s3_axis_tvalid;
  wire        s3_axis_tready;

  wire        fh_fifo_tuser;
  wire        fh_fifo_err_discard;
  wire [17:0] message_tuser_unused;
  wire        unused_outputs = &{1'b0, fh_fifo_tuser, fh_fifo_err_discard, message_tuser_unused};

  axis_fifo_alt #(
      .ASYNC_MODE  (1'b1),
      .FIFO_DEPTH  (4096),
      .FIFO_LATENCY(3),
      .DATA_WIDTH  (64),
      .USER_WIDTH  (1)
  ) i_fh_fifo (
      .s_axis_aclk   (clk),
      .s_axis_aresetn(!rst),
      //
      .s_axis_tdata  (s_axis_tdata),
      .s_axis_tkeep  (s_axis_tkeep),
      .s_axis_tlast  (s_axis_tlast),
      .s_axis_tuser  (1'b0),
      .s_axis_tvalid (s_axis_tvalid),
      //
      .m_axis_aclk   (tx_eth_clk),
      //
      .m_axis_tdata  (s0_axis_tdata),
      .m_axis_tkeep  (s0_axis_tkeep),
      .m_axis_tlast  (s0_axis_tlast),
      .m_axis_tuser  (fh_fifo_tuser),
      .m_axis_tvalid (s0_axis_tvalid),
      .m_axis_tready (s0_axis_tready),
      //
      .err_discard   (fh_fifo_err_discard)
  );

  fh_framer_32to64 i_ptp (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s_ptp_tdata),
      .s_axis_tkeep (s_ptp_tkeep),
      .s_axis_tlast (s_ptp_tlast),
      .s_axis_tuser (s_ptp_tuser),
      .s_axis_tvalid(s_ptp_tvalid),
      .s_axis_tready(s_ptp_tready),
      //
      .tx_eth_clk   (tx_eth_clk),
      .tx_eth_rst   (tx_eth_rst),
      //
      .m_axis_tdata (s1_axis_tdata),
      .m_axis_tkeep (s1_axis_tkeep),
      .m_axis_tlast (s1_axis_tlast),
      .m_axis_tuser (s1_axis_tuser),
      .m_axis_tvalid(s1_axis_tvalid),
      .m_axis_tready(s1_axis_tready)
  );

  fh_framer_32to64 i_message (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s_message_tdata),
      .s_axis_tkeep (s_message_tkeep),
      .s_axis_tlast (s_message_tlast),
      .s_axis_tuser ('b0),
      .s_axis_tvalid(s_message_tvalid),
      .s_axis_tready(s_message_tready),
      //
      .tx_eth_clk   (tx_eth_clk),
      .tx_eth_rst   (tx_eth_rst),
      //
      .m_axis_tdata (s2_axis_tdata),
      .m_axis_tkeep (s2_axis_tkeep),
      .m_axis_tlast (s2_axis_tlast),
      .m_axis_tuser (message_tuser_unused),
      .m_axis_tvalid(s2_axis_tvalid),
      .m_axis_tready(s2_axis_tready)
  );

  fh_switch #(
      .NUM_SRC   (3),
      .NUM_DEST  (1),
      .DATA_WIDTH(64),
      .USER_WIDTH(18)
  ) i_switch (
      .clk          (tx_eth_clk),
      .rst          (tx_eth_rst),
      //
      .s_axis_tdata ({s2_axis_tdata, s1_axis_tdata, s0_axis_tdata}),
      .s_axis_tkeep ({s2_axis_tkeep, s1_axis_tkeep, s0_axis_tkeep}),
      .s_axis_tlast ({s2_axis_tlast, s1_axis_tlast, s0_axis_tlast}),
      .s_axis_tuser ({18'b0, s1_axis_tuser, 18'b0}),
      .s_axis_tdest ({1'b1, 1'b1, 1'b1}),
      .s_axis_tvalid({s2_axis_tvalid, s1_axis_tvalid, s0_axis_tvalid}),
      .s_axis_tready({s2_axis_tready, s1_axis_tready, s0_axis_tready}),
      //
      .m_axis_tdata (s3_axis_tdata),
      .m_axis_tkeep (s3_axis_tkeep),
      .m_axis_tlast (s3_axis_tlast),
      .m_axis_tuser (s3_axis_tuser),
      .m_axis_tvalid(s3_axis_tvalid),
      .m_axis_tready(s3_axis_tready)
  );

  fh_framer_padding i_padding (
      .clk             (tx_eth_clk),
      .rst             (tx_eth_rst),
      //
      .s_axis_tdata    (s3_axis_tdata),
      .s_axis_tkeep    (s3_axis_tkeep),
      .s_axis_tlast    (s3_axis_tlast),
      .s_axis_tuser    (s3_axis_tuser),
      .s_axis_tvalid   (s3_axis_tvalid),
      .s_axis_tready   (s3_axis_tready),
      //
      .m_axis_tdata    (m_axis_tx_tdata),
      .m_axis_tkeep    (m_axis_tx_tkeep),
      .m_axis_tlast    (m_axis_tx_tlast),
      .m_axis_tuser    (m_axis_tx_tuser),
      .m_axis_tvalid   (m_axis_tx_tvalid),
      .m_axis_tready   (m_axis_tx_tready),
      //
      .tx_ptp_1588op   (tx_ptp_1588op),
      .tx_ptp_tag_field(tx_ptp_tag_field)
  );

endmodule

`default_nettype wire
