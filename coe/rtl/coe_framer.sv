`timescale 1 ns / 1 ps
//
`default_nettype none

module coe_framer (
    input var          clk,
    input var          rst,
    //
    input var          sync,
    //
    input var  [767:0] s_axis_tdata,
    input var  [  7:0] s_axis_tuser,
    input var          s_axis_tlast,
    input var          s_axis_tvalid,
    output var         s_axis_tready,
    //
    output var [ 31:0] m_axis_tdata,
    output var [  3:0] m_axis_tkeep,
    output var         m_axis_tlast,
    output var         m_axis_tvalid,
    input var          m_axis_tready,
    //
    output var [  7:0] m_trans_messagetype,
    output var [ 15:0] m_trans_payloadsize,
    output var [ 15:0] m_trans_rtc_pc_id,
    //
    input var          ctrl_en,
    input var  [ 15:0] ctrl_seq_en,
    input var  [ 95:0] ctrl_seq_id,
    input var  [  7:0] ctrl_seq_cnt
);

  wire [31:0] s0_axis_tdata;
  wire [ 3:0] s0_axis_tkeep;
  wire        s0_axis_tlast;
  wire        s0_axis_tvalid;
  wire        s0_axis_tready;

  wire [18:0] s0_app_ts;

  wire [ 7:0] s0_trans_messagetype;
  wire [15:0] s0_trans_payloadsize;
  wire [15:0] s0_trans_rtc_pc_id;

  coe_framer_data i_data (
      .clk                (clk),
      .rst                (rst),
      //
      .sync               (sync),
      //
      .s_axis_tdata       (s_axis_tdata),
      .s_axis_tuser       (s_axis_tuser),
      .s_axis_tlast       (s_axis_tlast),
      .s_axis_tvalid      (s_axis_tvalid),
      .s_axis_tready      (s_axis_tready),
      //
      .m_axis_tdata       (s0_axis_tdata),
      .m_axis_tkeep       (s0_axis_tkeep),
      .m_axis_tlast       (s0_axis_tlast),
      .m_axis_tvalid      (s0_axis_tvalid),
      .m_axis_tready      (s0_axis_tready),
      //
      .m_app_ts           (s0_app_ts),
      //
      .m_trans_messagetype(s0_trans_messagetype),
      .m_trans_payloadsize(s0_trans_payloadsize),
      .m_trans_rtc_pc_id  (s0_trans_rtc_pc_id),
      //
      .ctrl_en            (ctrl_en),
      .ctrl_seq_en        (ctrl_seq_en),
      .ctrl_seq_id        (ctrl_seq_id),
      .ctrl_seq_cnt       (ctrl_seq_cnt)
  );

  coe_framer_hdr i_hdr (
      .clk                (clk),
      .rst                (rst),
      //
      .s_axis_tdata       (s0_axis_tdata),
      .s_axis_tkeep       (s0_axis_tkeep),
      .s_axis_tlast       (s0_axis_tlast),
      .s_axis_tvalid      (s0_axis_tvalid),
      .s_axis_tready      (s0_axis_tready),
      //
      .s_app_ts           (s0_app_ts),
      //
      .s_trans_messagetype(s0_trans_messagetype),
      .s_trans_payloadsize(s0_trans_payloadsize),
      .s_trans_rtc_pc_id  (s0_trans_rtc_pc_id),
      //
      .m_axis_tdata       (m_axis_tdata),
      .m_axis_tkeep       (m_axis_tkeep),
      .m_axis_tlast       (m_axis_tlast),
      .m_axis_tvalid      (m_axis_tvalid),
      .m_axis_tready      (m_axis_tready),
      //
      .m_trans_messagetype(m_trans_messagetype),
      .m_trans_payloadsize(m_trans_payloadsize),
      .m_trans_rtc_pc_id  (m_trans_rtc_pc_id)
  );

endmodule

`default_nettype wire
