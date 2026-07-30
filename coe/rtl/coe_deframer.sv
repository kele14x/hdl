`timescale 1 ns / 1 ps
//
`default_nettype none

module coe_deframer (
    // Ethernet
    input  wire         clk,
    input  wire         rst,
    //
    input  wire         sync,
    //
    input  wire [ 31:0] s_axis_tdata,
    input  wire [  3:0] s_axis_tkeep,
    input  wire         s_axis_tlast,
    input  wire         s_axis_tvalid,
    //
    input  wire         s_trans_header_valid,
    input  wire [ 15:0] s_trans_rtc_pc_id,
    input  wire [  7:0] s_trans_seqid,
    input  wire         s_trans_ebit,
    input  wire [  6:0] s_trans_subseqid,
    // Radio I/F
    output wire [767:0] m_axis_rx_tdata,
    output wire [  7:0] m_axis_rx_tuser,
    output wire         m_axis_rx_tlast,
    output wire         m_axis_rx_tvalid,
    input  wire         m_axis_rx_tready,
    // CSR
    //----
    input  wire         ctrl_clk,
    input  wire         ctrl_rst,
    //
    input  wire         ctrl_en,
    input  wire [ 15:0] ctrl_seq_en,
    input  wire [ 95:0] ctrl_seq_id,
    //
    input  wire [  8:0] ctrl_ts_offset,
    //
    output wire [ 31:0] stat_conflict_cnt
);

  wire [31:0] s0_axis_tdata;
  wire [ 3:0] s0_axis_tkeep;
  wire        s0_axis_tlast;
  wire        s0_axis_tvalid;

  wire        s0_app_valid;
  wire [18:0] s0_app_ts;

  coe_deframer_hdr i_hdr (
      // Ethernet
      .clk          (clk),
      .rst          (rst),
      //
      .sync         (sync),
      //
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tkeep (s_axis_tkeep),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tvalid(s_axis_tvalid),
      // Radio I/F
      .m_axis_tdata (s0_axis_tdata),
      .m_axis_tkeep (s0_axis_tkeep),
      .m_axis_tlast (s0_axis_tlast),
      .m_axis_tvalid(s0_axis_tvalid),
      //
      .m_app_valid  (s0_app_valid),
      .m_app_ts     (s0_app_ts)
  );

  coe_deframer_data i_data (
      // Ethernet
      .clk                 (clk),
      .rst                 (rst),
      //
      .sync                (sync),
      //
      .s_axis_tdata        (s0_axis_tdata),
      .s_axis_tkeep        (s0_axis_tkeep),
      .s_axis_tlast        (s0_axis_tlast),
      .s_axis_tvalid       (s0_axis_tvalid),
      //
      .s_trans_header_valid(s_trans_header_valid),
      .s_trans_rtc_pc_id   (s_trans_rtc_pc_id),
      .s_trans_seqid       (s_trans_seqid),
      .s_trans_ebit        (s_trans_ebit),
      .s_trans_subseqid    (s_trans_subseqid),
      //
      .s_app_valid         (s0_app_valid),
      .s_app_ts            (s0_app_ts),
      // Radio I/F
      .m_axis_rx_tdata     (m_axis_rx_tdata),
      .m_axis_rx_tuser     (m_axis_rx_tuser),
      .m_axis_rx_tlast     (m_axis_rx_tlast),
      .m_axis_rx_tvalid    (m_axis_rx_tvalid),
      .m_axis_rx_tready    (m_axis_rx_tready),
      // CSR
      .ctrl_clk            (ctrl_clk),
      .ctrl_rst            (ctrl_rst),
      //
      .ctrl_en             (ctrl_en),
      .ctrl_seq_en         (ctrl_seq_en),
      .ctrl_seq_id         (ctrl_seq_id),
      //
      .ctrl_ts_offset      (ctrl_ts_offset),
      //
      .stat_conflict_cnt   (stat_conflict_cnt)
  );

endmodule

`default_nettype wire
