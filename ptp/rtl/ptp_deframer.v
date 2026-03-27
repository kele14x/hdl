`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_deframer (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [31:0] s_axis_tdata,
    input  wire [ 3:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire [79:0] s_axis_tuser,
    input  wire        s_axis_tvalid,
    output reg         s_axis_tready,
    //
    output reg         m_msg_valid,
    output wire [ 3:0] m_msg_message_type,
    output wire [15:0] m_msg_sequence_id,
    output wire [79:0] m_msg_timestamp,
    output wire [79:0] m_msg_origin_timestamp,
    output wire [79:0] m_msg_source_port_identity
);

  // Parameters

  `include "ptp_pkg.vh"

  localparam integer S_RST = 0;
  localparam integer S_PAD = 1;
  //
  localparam integer S_DMAC0 = 2;
  localparam integer S_DMAC1_SMAC0 = 3;
  localparam integer S_SMAC1 = 4;
  //
  localparam integer S_ETHERTYPE_HEADER0 = 5;
  localparam integer S_HEADER1 = 6;
  localparam integer S_HEADER2 = 7;
  localparam integer S_HEADER3 = 8;
  localparam integer S_HEADER4 = 9;
  localparam integer S_HEADER5 = 10;
  localparam integer S_HEADER6 = 11;
  localparam integer S_HEADER7 = 12;
  localparam integer S_HEADER8 = 13;
  //
  localparam integer S_SYNC0 = 14;
  localparam integer S_SYNC1 = 15;
  localparam integer S_SYNC2 = 16;
  //
  localparam integer S_DELAY_REQ0 = 17;
  localparam integer S_DELAY_REQ1 = 18;
  localparam integer S_DELAY_REQ2 = 19;
  //
  localparam integer S_FOLLOW_UP0 = 20;
  localparam integer S_FOLLOW_UP1 = 21;
  localparam integer S_FOLLOW_UP2 = 22;
  //
  localparam integer S_DELAY_RESP0 = 23;
  localparam integer S_DELAY_RESP1 = 24;
  localparam integer S_DELAY_RESP2 = 25;
  localparam integer S_DELAY_RESP3 = 26;
  localparam integer S_DELAY_RESP4 = 27;
  //
  localparam integer S_ANNOUNCE0 = 28;
  localparam integer S_ANNOUNCE1 = 29;
  localparam integer S_ANNOUNCE2 = 30;
  localparam integer S_ANNOUNCE3 = 31;
  localparam integer S_ANNOUNCE4 = 32;
  localparam integer S_ANNOUNCE5 = 33;
  localparam integer S_ANNOUNCE6 = 34;
  localparam integer S_ANNOUNCE7 = 35;

  // Signals

  integer state, state_next;

  wire [31:0] s_axis_tdata_rev;

  reg  [47:0] dest_mac;
  reg  [47:0] src_mac;
  reg  [15:0] ethertype;
  reg  [79:0] timestamp;

  reg  [ 3:0] transport_specific;
  reg  [ 3:0] message_type;
  reg  [ 3:0] reserved0;
  reg  [ 3:0] version_ptp;
  reg  [15:0] message_length;
  reg  [ 7:0] domain_number;
  reg  [ 7:0] reserved1;
  reg  [15:0] flag_field;
  reg  [63:0] correction_field;
  reg  [31:0] reserved2;
  reg  [79:0] source_port_identity;  // {clock_identity, port_number}
  reg  [15:0] sequence_id;
  reg  [ 7:0] control_field;
  reg  [ 7:0] log_message_interval;

  reg  [79:0] origin_timestamp;
  reg  [15:0] current_utc_offset;
  reg  [ 7:0] reserved3;
  reg  [ 7:0] grandmaster_priority1;
  reg  [31:0] grandmaster_clock_quality;
  reg  [ 7:0] grandmaster_priority2;
  reg  [63:0] grandmaster_identity;
  reg  [15:0] steps_removed;
  reg  [ 7:0] time_source;

  reg  [79:0] requesting_port_identity;

  // Main

  always @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always @(*) begin
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_DMAC0;
      end

      S_DMAC0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_DMAC1_SMAC0;
        end
      end

      S_DMAC1_SMAC0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_SMAC1;
        end
      end

      S_SMAC1: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_ETHERTYPE_HEADER0;
        end
      end

      // PTP Common Header

      S_ETHERTYPE_HEADER0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_HEADER1;
        end
      end

      S_HEADER1: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_HEADER2;
        end
      end

      S_HEADER2: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_HEADER3;
        end
      end

      S_HEADER3: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_HEADER4;
        end
      end

      S_HEADER4: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_HEADER5;
        end
      end

      S_HEADER5: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_HEADER6;
        end
      end

      S_HEADER6: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_HEADER7;
        end
      end

      S_HEADER7: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_HEADER8;
        end
      end

      S_HEADER8: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          if (message_type == PTP_MESSAGE_TYPE_SYNC) begin
            state_next = S_SYNC0;
          end else if (message_type == PTP_MESSAGE_TYPE_DELAY_REQ) begin
            state_next = S_DELAY_REQ0;
          end else if (message_type == PTP_MESSAGE_TYPE_FOLLOW_UP) begin
            state_next = S_FOLLOW_UP0;
          end else if (message_type == PTP_MESSAGE_TYPE_DELAY_RESP) begin
            state_next = S_DELAY_RESP0;
          end else if (message_type == PTP_MESSAGE_TYPE_ANNOUNCE) begin
            state_next = S_ANNOUNCE0;
          end else begin
            state_next = S_PAD;
          end
        end
      end

      // Sync

      S_SYNC0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_SYNC1;
        end
      end

      S_SYNC1: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_SYNC2;
        end
      end

      S_SYNC2: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_PAD;
        end
      end

      // Delay Request

      S_DELAY_REQ0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_DELAY_REQ1;
        end
      end

      S_DELAY_REQ1: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_DELAY_REQ2;
        end
      end

      S_DELAY_REQ2: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_PAD;
        end
      end

      // Follow Up

      S_FOLLOW_UP0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_FOLLOW_UP1;
        end
      end

      S_FOLLOW_UP1: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_FOLLOW_UP2;
        end
      end

      S_FOLLOW_UP2: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_PAD;
        end
      end

      // Delay Response

      S_DELAY_RESP0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_DELAY_RESP1;
        end
      end

      S_DELAY_RESP1: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_DELAY_RESP2;
        end
      end

      S_DELAY_RESP2: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_DELAY_RESP3;
        end
      end

      S_DELAY_RESP3: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_DELAY_RESP4;
        end
      end

      S_DELAY_RESP4: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_PAD;
        end
      end

      // Announce

      S_ANNOUNCE0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_ANNOUNCE1;
        end
      end

      S_ANNOUNCE1: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_ANNOUNCE2;
        end
      end

      S_ANNOUNCE2: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_ANNOUNCE3;
        end
      end

      S_ANNOUNCE3: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_ANNOUNCE4;
        end
      end

      S_ANNOUNCE4: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_ANNOUNCE5;
        end
      end

      S_ANNOUNCE5: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_ANNOUNCE6;
        end
      end

      S_ANNOUNCE6: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_ANNOUNCE7;
        end
      end

      S_ANNOUNCE7: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_PAD;
        end
      end

      S_PAD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // Parser

  assign s_axis_tdata_rev = byte_reverse(s_axis_tdata);

  always @(posedge clk) begin
    // Ethernet Header
    if (s_axis_tvalid && state == S_DMAC0) begin
      dest_mac[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_DMAC1_SMAC0) begin
      {dest_mac[15:0], src_mac[47:32]} <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_SMAC1) begin
      src_mac[31:0] <= s_axis_tdata_rev;
    end

    // PTP Common Header
    if (s_axis_tvalid && state == S_ETHERTYPE_HEADER0) begin
      {ethertype, transport_specific, message_type, reserved0, version_ptp} <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_HEADER1) begin
      {message_length, domain_number, reserved1} <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_HEADER2) begin
      {flag_field, correction_field[63:48]} <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_HEADER3) begin
      correction_field[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_HEADER4) begin
      {correction_field[15:0], reserved2[31:16]} <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_HEADER5) begin
      {reserved2[15:0], source_port_identity[79:64]} <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_HEADER6) begin
      source_port_identity[63:32] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_HEADER7) begin
      source_port_identity[31:0] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_HEADER8) begin
      {sequence_id, control_field, log_message_interval} <= s_axis_tdata_rev;
    end

    // Sync Message
    if (s_axis_tvalid && state == S_SYNC0) begin
      origin_timestamp[79:48] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_SYNC1) begin
      origin_timestamp[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_SYNC2) begin
      origin_timestamp[15:0] <= s_axis_tdata_rev[31:16];
    end

    // Delay Request Message
    if (s_axis_tvalid && state == S_DELAY_REQ0) begin
      origin_timestamp[79:48] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_DELAY_REQ1) begin
      origin_timestamp[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_DELAY_REQ2) begin
      origin_timestamp[15:0] <= s_axis_tdata_rev[31:16];
    end

    // Follow Up Message
    if (s_axis_tvalid && state == S_FOLLOW_UP0) begin
      origin_timestamp[79:48] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_FOLLOW_UP1) begin
      origin_timestamp[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_FOLLOW_UP2) begin
      origin_timestamp[15:0] <= s_axis_tdata_rev[31:16];
    end

    // Delay Response Message
    if (s_axis_tvalid && state == S_DELAY_RESP0) begin
      origin_timestamp[79:48] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_DELAY_RESP1) begin
      origin_timestamp[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_DELAY_RESP2) begin
      {origin_timestamp[15:0], requesting_port_identity[79:64]} <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_DELAY_RESP3) begin
      requesting_port_identity[63:32] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_DELAY_RESP4) begin
      requesting_port_identity[31:0] <= s_axis_tdata_rev;
    end

    // Announce Message
    if (s_axis_tvalid && state == S_ANNOUNCE0) begin
      origin_timestamp[79:48] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_ANNOUNCE1) begin
      origin_timestamp[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_ANNOUNCE2) begin
      {origin_timestamp[15:0], current_utc_offset} <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_ANNOUNCE3) begin
      {reserved3, grandmaster_priority1, grandmaster_clock_quality[31:16]} <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_ANNOUNCE4) begin
      {
        grandmaster_clock_quality[15:0], grandmaster_priority2, grandmaster_identity[63:56]
      } <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_ANNOUNCE5) begin
      grandmaster_identity[55:24] <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_ANNOUNCE6) begin
      {grandmaster_identity[23:0], steps_removed[15:8]} <= s_axis_tdata_rev;
    end

    if (s_axis_tvalid && state == S_ANNOUNCE7) begin
      {steps_removed[7:0], time_source} <= s_axis_tdata_rev[31:16];
    end
  end

  always @(posedge clk) begin
    if (s_axis_tvalid && state == S_DMAC0) begin
      timestamp <= s_axis_tuser;
    end
  end

  // Input

  always @(posedge clk) begin
    if (rst) begin
      s_axis_tready <= 1'b0;
    end else begin
      s_axis_tready <= 1'b1;
    end
  end

  // Output

  always @(posedge clk) begin
    m_msg_valid <= (s_axis_tvalid && ((state == S_SYNC2) || (state == S_DELAY_REQ2) ||
      (state == S_FOLLOW_UP2) || (state == S_DELAY_RESP4) || (state == S_ANNOUNCE7)));
  end

  assign m_msg_message_type         = message_type;
  assign m_msg_sequence_id          = sequence_id;
  assign m_msg_timestamp            = timestamp;
  assign m_msg_origin_timestamp     = origin_timestamp;
  assign m_msg_source_port_identity = source_port_identity;

endmodule

`default_nettype wire
