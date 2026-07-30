`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_lite #(
    parameter integer CLK_FREQ = 49152000
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [31:0] s_axis_tdata,
    input  wire [ 3:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire [79:0] s_axis_tuser,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    //
    output wire [31:0] m_axis_tdata,
    output wire [ 3:0] m_axis_tkeep,
    output wire        m_axis_tlast,
    output wire [17:0] m_axis_tuser,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    //
    input  wire [79:0] tx_ptp_timestamp,
    input  wire [15:0] tx_ptp_timestamp_tag,
    input  wire        tx_ptp_timestamp_valid,
    //
    input  wire        ctrl_master_en,
    input  wire [47:0] ctrl_src_mac,
    input  wire [ 7:0] ctrl_domain_number,
    input  wire [15:0] ctrl_utc_offset,
    input  wire [ 7:0] ctrl_log_announce_interval,
    input  wire [ 7:0] ctrl_log_sync_interval
);

  // Signals

  wire        s0_msg_valid;
  wire [ 3:0] s0_msg_message_type;
  wire [15:0] s0_msg_sequence_id;
  wire [79:0] s0_msg_timestamp;
  wire [79:0] s0_msg_origin_timestamp;
  wire [79:0] s0_msg_source_port_identity;

  wire        ap_valid;
  wire        ap_ready;

  wire [ 3:0] ap_message_type;
  wire [15:0] ap_sequence_id;
  wire [ 7:0] ap_log_message_interval;
  wire [79:0] ap_origin_timestamp;
  wire [79:0] ap_requesting_port_identity;
  wire [15:0] ap_tag_field;

  // Modules

  ptp_deframer i_deframer (
      .clk                       (clk),
      .rst                       (rst),
      //
      .s_axis_tdata              (s_axis_tdata),
      .s_axis_tkeep              (s_axis_tkeep),
      .s_axis_tlast              (s_axis_tlast),
      .s_axis_tuser              (s_axis_tuser),
      .s_axis_tvalid             (s_axis_tvalid),
      .s_axis_tready             (s_axis_tready),
      //
      .m_msg_valid               (s0_msg_valid),
      .m_msg_message_type        (s0_msg_message_type),
      .m_msg_sequence_id         (s0_msg_sequence_id),
      .m_msg_timestamp           (s0_msg_timestamp),
      .m_msg_origin_timestamp    (s0_msg_origin_timestamp),
      .m_msg_source_port_identity(s0_msg_source_port_identity)
  );

  ptp_framer i_framer (
      .clk                        (clk),
      .rst                        (rst),
      //
      .m_axis_tdata               (m_axis_tdata),
      .m_axis_tkeep               (m_axis_tkeep),
      .m_axis_tlast               (m_axis_tlast),
      .m_axis_tuser               (m_axis_tuser),
      .m_axis_tvalid              (m_axis_tvalid),
      .m_axis_tready              (m_axis_tready),
      //
      .ap_valid                   (ap_valid),
      .ap_ready                   (ap_ready),
      .ap_message_type            (ap_message_type),
      .ap_sequence_id             (ap_sequence_id),
      .ap_log_message_interval    (ap_log_message_interval),
      .ap_origin_timestamp        (ap_origin_timestamp),
      .ap_requesting_port_identity(ap_requesting_port_identity),
      .ap_tag_field               (ap_tag_field),
      // CSR
      .ctrl_src_mac               (ctrl_src_mac),
      .ctrl_domain_number         (ctrl_domain_number),
      .ctrl_utc_offset            (ctrl_utc_offset)
  );

  ptp_ctrl #(
      .CLK_FREQ(CLK_FREQ)
  ) i_ctrl (
      .clk                        (clk),
      .rst                        (rst),
      //
      .s_msg_valid                (s0_msg_valid),
      .s_msg_message_type         (s0_msg_message_type),
      .s_msg_sequence_id          (s0_msg_sequence_id),
      .s_msg_timestamp            (s0_msg_timestamp),
      .s_msg_origin_timestamp     (s0_msg_origin_timestamp),
      .s_msg_source_port_identity (s0_msg_source_port_identity),
      //
      .ap_valid                   (ap_valid),
      .ap_ready                   (ap_ready),
      .ap_message_type            (ap_message_type),
      .ap_sequence_id             (ap_sequence_id),
      .ap_log_message_interval    (ap_log_message_interval),
      .ap_origin_timestamp        (ap_origin_timestamp),
      .ap_requesting_port_identity(ap_requesting_port_identity),
      .ap_tag_field               (ap_tag_field),
      //
      .tx_ptp_timestamp           (tx_ptp_timestamp),
      .tx_ptp_timestamp_tag       (tx_ptp_timestamp_tag),
      .tx_ptp_timestamp_valid     (tx_ptp_timestamp_valid),
      //
      .ctrl_master_en             (ctrl_master_en),
      .ctrl_log_announce_interval (ctrl_log_announce_interval),
      .ctrl_log_sync_interval     (ctrl_log_sync_interval)
  );

endmodule

`default_nettype wire
