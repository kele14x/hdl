`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_deframer (
    input var         clk,
    input var         rst,
    //
    input var  [31:0] s_axis_tdata,
    input var  [ 3:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var  [79:0] s_axis_tuser,
    input var         s_axis_tvalid,
    output var        s_axis_tready,
    //
    output var        m_msg_valid,
    output var [ 3:0] m_msg_message_type,
    output var [15:0] m_msg_sequence_id,
    output var [79:0] m_msg_timestamp,
    output var [79:0] m_msg_origin_timestamp,
    output var [79:0] m_msg_source_port_identity
);

  // Parameters

  localparam [3:0] PTP_MESSAGE_TYPE_SYNC = 4'h0;
  localparam [3:0] PTP_MESSAGE_TYPE_DELAY_REQ = 4'h1;
  localparam [3:0] PTP_MESSAGE_TYPE_FOLLOW_UP = 4'h8;
  localparam [3:0] PTP_MESSAGE_TYPE_DELAY_RESP = 4'h9;
  localparam [3:0] PTP_MESSAGE_TYPE_ANNOUNCE = 4'hB;

  function [31:0] byte_reverse;
    input [31:0] in;
    integer i;
    begin
      for (i = 0; i < 4; i = i + 1) begin
        byte_reverse[i*8+7-:8] = in[31-i*8-:8];
      end
    end
  endfunction

  localparam int S_RST = 0;
  localparam int S_PAD = 1;
  //
  localparam int S_DMAC0 = 2;
  localparam int S_DMAC1_SMAC0 = 3;
  localparam int S_SMAC1 = 4;
  //
  localparam int S_ETHERTYPE_HEADER0 = 5;
  localparam int S_HEADER1 = 6;
  localparam int S_HEADER2 = 7;
  localparam int S_HEADER3 = 8;
  localparam int S_HEADER4 = 9;
  localparam int S_HEADER5 = 10;
  localparam int S_HEADER6 = 11;
  localparam int S_HEADER7 = 12;
  localparam int S_HEADER8 = 13;
  //
  localparam int S_SYNC0 = 14;
  localparam int S_SYNC1 = 15;
  localparam int S_SYNC2 = 16;
  //
  localparam int S_DELAY_REQ0 = 17;
  localparam int S_DELAY_REQ1 = 18;
  localparam int S_DELAY_REQ2 = 19;
  //
  localparam int S_FOLLOW_UP0 = 20;
  localparam int S_FOLLOW_UP1 = 21;
  localparam int S_FOLLOW_UP2 = 22;
  //
  localparam int S_DELAY_RESP0 = 23;
  localparam int S_DELAY_RESP1 = 24;
  localparam int S_DELAY_RESP2 = 25;
  localparam int S_DELAY_RESP3 = 26;
  localparam int S_DELAY_RESP4 = 27;
  //
  localparam int S_ANNOUNCE0 = 28;
  localparam int S_ANNOUNCE1 = 29;
  localparam int S_ANNOUNCE2 = 30;
  localparam int S_ANNOUNCE3 = 31;
  localparam int S_ANNOUNCE4 = 32;
  localparam int S_ANNOUNCE5 = 33;
  localparam int S_ANNOUNCE6 = 34;
  localparam int S_ANNOUNCE7 = 35;

  // Signals

  integer state, state_next;

  wire  [31:0] s_axis_tdata_rev;
  wire         s_axis_word_valid;

  logic [79:0] timestamp;

  logic [ 3:0] message_type;
  logic [79:0] source_port_identity;  // {clock_identity, port_number}
  logic [15:0] sequence_id;

  logic [79:0] origin_timestamp;


  // Main

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_DMAC0;
      end

      S_DMAC0: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_DMAC1_SMAC0;
        end
      end

      S_DMAC1_SMAC0: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_SMAC1;
        end
      end

      S_SMAC1: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_ETHERTYPE_HEADER0;
        end
      end

      // PTP Common Header

      S_ETHERTYPE_HEADER0: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_HEADER1;
        end
      end

      S_HEADER1: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_HEADER2;
        end
      end

      S_HEADER2: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_HEADER3;
        end
      end

      S_HEADER3: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_HEADER4;
        end
      end

      S_HEADER4: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_HEADER5;
        end
      end

      S_HEADER5: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_HEADER6;
        end
      end

      S_HEADER6: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_HEADER7;
        end
      end

      S_HEADER7: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_HEADER8;
        end
      end

      S_HEADER8: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
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
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_SYNC1;
        end
      end

      S_SYNC1: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_SYNC2;
        end
      end

      S_SYNC2: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_PAD;
        end
      end

      // Delay Request

      S_DELAY_REQ0: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_DELAY_REQ1;
        end
      end

      S_DELAY_REQ1: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_DELAY_REQ2;
        end
      end

      S_DELAY_REQ2: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_PAD;
        end
      end

      // Follow Up

      S_FOLLOW_UP0: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_FOLLOW_UP1;
        end
      end

      S_FOLLOW_UP1: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_FOLLOW_UP2;
        end
      end

      S_FOLLOW_UP2: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_PAD;
        end
      end

      // Delay Response

      S_DELAY_RESP0: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_DELAY_RESP1;
        end
      end

      S_DELAY_RESP1: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_DELAY_RESP2;
        end
      end

      S_DELAY_RESP2: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_DELAY_RESP3;
        end
      end

      S_DELAY_RESP3: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_DELAY_RESP4;
        end
      end

      S_DELAY_RESP4: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_PAD;
        end
      end

      // Announce

      S_ANNOUNCE0: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_ANNOUNCE1;
        end
      end

      S_ANNOUNCE1: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_ANNOUNCE2;
        end
      end

      S_ANNOUNCE2: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_ANNOUNCE3;
        end
      end

      S_ANNOUNCE3: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_ANNOUNCE4;
        end
      end

      S_ANNOUNCE4: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_ANNOUNCE5;
        end
      end

      S_ANNOUNCE5: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_ANNOUNCE6;
        end
      end

      S_ANNOUNCE6: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_ANNOUNCE7;
        end
      end

      S_ANNOUNCE7: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end else if (s_axis_word_valid) begin
          state_next = S_PAD;
        end
      end

      S_PAD: begin
        if (s_axis_word_valid && s_axis_tlast) begin
          state_next = S_DMAC0;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // Parser

  assign s_axis_tdata_rev  = byte_reverse(s_axis_tdata);
  assign s_axis_word_valid = s_axis_tvalid && (|s_axis_tkeep);

  always_ff @(posedge clk) begin
    // PTP Common Header
    if (s_axis_word_valid && state == S_ETHERTYPE_HEADER0) begin
      message_type <= s_axis_tdata_rev[11:8];
    end

    if (s_axis_word_valid && state == S_HEADER5) begin
      source_port_identity[79:64] <= s_axis_tdata_rev[15:0];
    end

    if (s_axis_word_valid && state == S_HEADER6) begin
      source_port_identity[63:32] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_HEADER7) begin
      source_port_identity[31:0] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_HEADER8) begin
      sequence_id <= s_axis_tdata_rev[31:16];
    end

    // Sync Message
    if (s_axis_word_valid && state == S_SYNC0) begin
      origin_timestamp[79:48] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_SYNC1) begin
      origin_timestamp[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_SYNC2) begin
      origin_timestamp[15:0] <= s_axis_tdata_rev[31:16];
    end

    // Delay Request Message
    if (s_axis_word_valid && state == S_DELAY_REQ0) begin
      origin_timestamp[79:48] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_DELAY_REQ1) begin
      origin_timestamp[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_DELAY_REQ2) begin
      origin_timestamp[15:0] <= s_axis_tdata_rev[31:16];
    end

    // Follow Up Message
    if (s_axis_word_valid && state == S_FOLLOW_UP0) begin
      origin_timestamp[79:48] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_FOLLOW_UP1) begin
      origin_timestamp[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_FOLLOW_UP2) begin
      origin_timestamp[15:0] <= s_axis_tdata_rev[31:16];
    end

    // Delay Response Message
    if (s_axis_word_valid && state == S_DELAY_RESP0) begin
      origin_timestamp[79:48] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_DELAY_RESP1) begin
      origin_timestamp[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_DELAY_RESP2) begin
      origin_timestamp[15:0] <= s_axis_tdata_rev[31:16];
    end

    // Announce Message
    if (s_axis_word_valid && state == S_ANNOUNCE0) begin
      origin_timestamp[79:48] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_ANNOUNCE1) begin
      origin_timestamp[47:16] <= s_axis_tdata_rev;
    end

    if (s_axis_word_valid && state == S_ANNOUNCE2) begin
      origin_timestamp[15:0] <= s_axis_tdata_rev[31:16];
    end
  end

  always_ff @(posedge clk) begin
    if (s_axis_word_valid && state == S_DMAC0) begin
      timestamp <= s_axis_tuser;
    end
  end

  // Input

  always_ff @(posedge clk) begin
    if (rst) begin
      s_axis_tready <= 1'b0;
    end else begin
      s_axis_tready <= 1'b1;
    end
  end

  // Output

  always_ff @(posedge clk) begin
    m_msg_valid <= (s_axis_word_valid && ((state == S_SYNC2) || (state == S_DELAY_REQ2) ||
      (state == S_FOLLOW_UP2) || (state == S_DELAY_RESP4) || (state == S_ANNOUNCE7)));
  end

  assign m_msg_message_type         = message_type;
  assign m_msg_sequence_id          = sequence_id;
  assign m_msg_timestamp            = timestamp;
  assign m_msg_origin_timestamp     = origin_timestamp;
  assign m_msg_source_port_identity = source_port_identity;

endmodule

`default_nettype wire
