// Insert transport (eCPRI) header at the beginning of Ethernet Packet
`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_odm (
    input  wire         clk,
    input  wire         rst,
    //
    input  wire  [79:0] tx_ptp_timestamp,
    input  wire  [15:0] tx_ptp_timestamp_tag,
    input  wire         tx_ptp_timestamp_valid,
    // Receive I/F
    input  wire         s_odm_header_valid,
    input  wire  [ 7:0] s_odm_measurementid,
    input  wire  [ 7:0] s_odm_actiontype,
    input  wire  [79:0] s_odm_timestamp,
    input  wire  [63:0] s_odm_compensation,
    input  wire  [79:0] s_odm_timestamp2,
    // Transmit I/F
    output logic        m_axis_tvalid,
    input  wire         m_axis_tready,
    //
    output logic [ 7:0] m_odm_measurementid,
    output logic [ 7:0] m_odm_actiontype,
    output logic [79:0] m_odm_timestamp,
    output logic [63:0] m_odm_compensation,
    //
    input  wire         ctrl_clk,
    input  wire         ctrl_rst,
    //
    input  wire         ctrl_en,
    input  wire  [31:0] ctrl_meas_interval,
    //
    output wire  [31:0] stat_ts_diff_ingress_ns,
    output wire  [47:0] stat_ts_diff_ingress_sec,
    //
    output wire  [31:0] stat_ts_diff_egress_ns,
    output wire  [47:0] stat_ts_diff_egress_sec
);

  wire unused_inputs = &{1'b0, s_odm_compensation, ctrl_rst};

  // Note

  // | Action Type | Description                     |
  // |-------------|---------------------------------|
  // |        0x00 | Request                         |
  // |        0x01 | Request with Follow Up          |
  // |        0x02 | Response                        |
  // |        0x03 | Remote Request                  |
  // |        0x04 | Remote Request with Follow Up   |
  // |        0x05 | Follow Up                       |
  // | 0x06...0xFF | Reserved                        |

  localparam logic [7:0] ODM_ACTION_TYPE_REQUEST = 8'h00;
  localparam logic [7:0] ODM_ACTION_TYPE_REQUEST_WITH_FOLLOW_UP = 8'h01;
  localparam logic [7:0] ODM_ACTION_TYPE_RESPONSE = 8'h02;
  localparam logic [7:0] ODM_ACTION_TYPE_REMOTE_REQUEST = 8'h03;
  localparam logic [7:0] ODM_ACTION_TYPE_REMOTE_REQUEST_WITH_FOLLOW_UP = 8'h04;
  localparam logic [7:0] ODM_ACTION_TYPE_FOLLOW_UP = 8'h05;

  function [79:0] ts_diff(input logic [79:0] ts1, input logic [79:0] ts2);
    logic [31:0] ns;
    logic [47:0] sec;
    begin
      ns = ts1[31:0] - ts2[31:0];
      sec = ts1[79:32] - ts2[79:32];
      ts_diff = {sec, ns};
    end
  endfunction

  function [79:0] ts_wrap(input logic [79:0] ts1);
    logic [31:0] ns;
    logic [47:0] sec;
    begin
      ns  = ts1[31:0];
      sec = ts1[79:32];
      if (ns[31] == 1'b1) begin
        ns  = ns + 32'd1000000000;
        sec = sec - 1'd1;
      end
      ts_wrap = {sec, ns};
    end
  endfunction

  // Signals

  wire         ctrl_en_s;
  wire  [31:0] ctrl_meas_interval_s;
  wire  [ 1:0] unused_stat_src_ready;
  wire  [ 1:0] unused_stat_dest_valid;

  logic [31:0] timer;
  logic        timer_tick;

  logic [ 7:0] id_int;

  logic [79:0] ts_ingress;
  logic [ 7:0] ts_ingress_measurementid;
  logic [79:0] ts_diff_ingress;
  logic [79:0] ts_diff_ingress_wrap;
  logic        ts_diff_ingress_valid;
  logic        ts_diff_ingress_wrap_valid;

  logic [79:0] ts_egress;
  logic [ 7:0] ts_egress_measurementid;
  logic [79:0] ts_diff_egress;
  logic [79:0] ts_diff_egress_wrap;
  logic        ts_diff_egress_valid;
  logic        ts_diff_egress_wrap_valid;

  // Main

  always_ff @(posedge clk) begin
    if (rst) begin
      timer <= 'd0;
    end else if (timer == ctrl_meas_interval_s) begin
      timer <= 'd0;
    end else if (ctrl_en_s) begin
      timer <= timer + 1'd1;
    end
  end

  always_ff @(posedge clk) begin
    timer_tick <= (timer == ctrl_meas_interval_s) && (timer != 0);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      id_int <= 'hFF;
    end else if (timer_tick) begin
      id_int <= {id_int[6:0], id_int[7] ^ id_int[5] ^ id_int[4] ^ id_int[3]};
    end
  end

  // Upon received a request (0x00) message, replay with a response (0x02) message
  //
  // Upon received a request with fu (0x01) message, wait a follow up (0x05) message,
  // then replay with a response (0x02 message)
  //
  // Send a remote request (0x3) or remote request with follow up (0x4) message, to
  // trigger a request from remote

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tvalid <= 1'b0;
    end else if (timer_tick) begin
      m_axis_tvalid <= 1'b1;
    end else if (s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_REQUEST)) begin
      m_axis_tvalid <= 1'b1;
    end else if (s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_REMOTE_REQUEST)) begin
      m_axis_tvalid <= 1'b1;
    end else if (s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_REMOTE_REQUEST_WITH_FOLLOW_UP)) begin
      m_axis_tvalid <= 1'b1;
    end else if (s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_FOLLOW_UP) && (s_odm_measurementid == m_odm_measurementid)) begin
      m_axis_tvalid <= 1'b1;
    end else if (tx_ptp_timestamp_valid && (tx_ptp_timestamp_tag == {m_odm_actiontype, m_odm_measurementid})) begin
      m_axis_tvalid <= 1'b1;
    end else if (m_axis_tready) begin
      m_axis_tvalid <= 1'b0;
    end  // else keep at current state
  end

  always_ff @(posedge clk) begin
    if (~m_axis_tvalid && timer_tick) begin
      // Send periodic request message
      m_odm_measurementid <= id_int;
      m_odm_actiontype    <= ODM_ACTION_TYPE_REQUEST_WITH_FOLLOW_UP;
      m_odm_timestamp     <= 0;
      m_odm_compensation  <= 0;
    end

    if (~m_axis_tvalid && s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_REQUEST)) begin
      // Send a response message
      m_odm_measurementid <= s_odm_measurementid;
      m_odm_actiontype    <= ODM_ACTION_TYPE_RESPONSE;
      m_odm_timestamp     <= s_odm_timestamp2;
      m_odm_compensation  <= 0;
    end

    if (~m_axis_tvalid && s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_REQUEST_WITH_FOLLOW_UP)) begin
      // Wait for a follow up message
      m_odm_measurementid <= s_odm_measurementid;
    end

    // There is no action needed for response message

    if (~m_axis_tvalid && s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_REMOTE_REQUEST)) begin
      // Send a request message
      m_odm_measurementid <= s_odm_measurementid;
      m_odm_actiontype    <= ODM_ACTION_TYPE_REQUEST;
      m_odm_timestamp     <= 0;
      m_odm_compensation  <= 0;
    end

    if (~m_axis_tvalid && s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_REMOTE_REQUEST_WITH_FOLLOW_UP)) begin
      // Send a request with follow up message
      m_odm_measurementid <= s_odm_measurementid;
      m_odm_actiontype    <= ODM_ACTION_TYPE_REQUEST_WITH_FOLLOW_UP;
      m_odm_timestamp     <= 0;
      m_odm_compensation  <= 0;
    end

    if (~m_axis_tvalid && s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_FOLLOW_UP)) begin
      // Send a response message
      if (s_odm_measurementid == m_odm_measurementid) begin
        m_odm_actiontype   <= ODM_ACTION_TYPE_RESPONSE;
        m_odm_timestamp    <= s_odm_timestamp2;
        m_odm_compensation <= 0;
      end
    end

    if (~m_axis_tvalid && tx_ptp_timestamp_valid) begin
      // Send a follow up message
      if (tx_ptp_timestamp_tag == {m_odm_actiontype, m_odm_measurementid}) begin
        m_odm_actiontype   <= ODM_ACTION_TYPE_FOLLOW_UP;
        m_odm_timestamp    <= tx_ptp_timestamp;
        m_odm_compensation <= 0;
      end
    end
  end

  // Ingress timestamp

  always_ff @(posedge clk) begin
    if (s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_REQUEST_WITH_FOLLOW_UP)) begin
      ts_ingress               <= s_odm_timestamp2;
      ts_ingress_measurementid <= s_odm_measurementid;
    end
  end

  always_ff @(posedge clk) begin
    if (s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_REQUEST)) begin
      // T12 = t2 - t1, t2 is Ethernet timestamped, t1 is in packet
      // Since the timestamp is 1 step mode, we does not need to check the measurement_id
      ts_diff_ingress <= ts_diff(s_odm_timestamp2, s_odm_timestamp);
    end else if (s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_FOLLOW_UP)) begin
      // T12 = T2 - T1, t2 is Ethernet timestamped previously, t1 is in packet
      // Check measurement_id to make sure the packets matches
      if (s_odm_measurementid == ts_ingress_measurementid) begin
        ts_diff_ingress <= ts_diff(ts_ingress, s_odm_timestamp);
      end
    end
  end

  always_ff @(posedge clk) begin
    ts_diff_ingress_wrap <= ts_wrap(ts_diff_ingress);
  end

  always_ff @(posedge clk) begin
    if (s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_REQUEST)) begin
      ts_diff_ingress_valid <= 1'b1;
    end else if (s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_FOLLOW_UP)) begin
      ts_diff_ingress_valid <= 1'b1;
    end else begin
      ts_diff_ingress_valid <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    ts_diff_ingress_wrap_valid <= ts_diff_ingress_valid;
  end

  // Egress timestamp

  always_ff @(posedge clk) begin
    if (tx_ptp_timestamp_valid && (tx_ptp_timestamp_tag == {m_odm_actiontype, m_odm_measurementid})) begin
      ts_egress               <= tx_ptp_timestamp;
      ts_egress_measurementid <= m_odm_measurementid;
    end
  end

  always_ff @(posedge clk) begin
    if (s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_RESPONSE)) begin
      // T34 = t4 - t3, t4 is in packet from remote, t3 is Ethernet timestamped previously
      // Check the measurement_id to make sure the packets matches
      if (s_odm_measurementid == ts_egress_measurementid) begin
        ts_diff_egress <= ts_diff(s_odm_timestamp, ts_egress);
      end
    end
  end

  always_ff @(posedge clk) begin
    ts_diff_egress_wrap <= ts_wrap(ts_diff_egress);
  end

  always_ff @(posedge clk) begin
    if (s_odm_header_valid && (s_odm_actiontype == ODM_ACTION_TYPE_RESPONSE)) begin
      ts_diff_egress_valid <= 1'b1;
    end else begin
      ts_diff_egress_valid <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    ts_diff_egress_wrap_valid <= ts_diff_egress_valid;
  end

  // Tx PTP timestamp & control CDC

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (1)
  ) i_cdc_ctrl_en (
      .src_clk (1'b1),
      .src_in  (ctrl_en),
      //
      .dest_clk(clk),
      .dest_out(ctrl_en_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (32)
  ) i_cdc_ctrl_meas_interval (
      .src_clk (1'b1),
      .src_in  (ctrl_meas_interval),
      //
      .dest_clk(clk),
      .dest_out(ctrl_meas_interval_s)
  );

  // Status CDC

  cdc_handshake_f #(
      .DEST_EXT_HSK(1),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .SRC_SYNC_FF (4),
      .WIDTH       (80)
  ) i_cdc_stat_ts_ingress (
      .src_clk   (clk),
      .src_in    (ts_diff_ingress_wrap),
      .src_valid (ts_diff_ingress_wrap_valid),
      .src_ready (unused_stat_src_ready[0]),
      //
      .dest_clk  (ctrl_clk),
      .dest_out  ({stat_ts_diff_ingress_sec, stat_ts_diff_ingress_ns}),
      .dest_valid(unused_stat_dest_valid[0]),
      .dest_ready(1'b1)
  );

  cdc_handshake_f #(
      .DEST_EXT_HSK(1),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .SRC_SYNC_FF (4),
      .WIDTH       (80)
  ) i_cdc_stat_ts_egress (
      .src_clk   (clk),
      .src_in    (ts_diff_egress_wrap),
      .src_valid (ts_diff_egress_wrap_valid),
      .src_ready (unused_stat_src_ready[1]),
      //
      .dest_clk  (ctrl_clk),
      .dest_out  ({stat_ts_diff_egress_sec, stat_ts_diff_egress_ns}),
      .dest_valid(unused_stat_dest_valid[1]),
      .dest_ready(1'b1)
  );

endmodule

`default_nettype wire
