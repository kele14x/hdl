`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_ctrl #(
    parameter integer CLK_FREQ = 49152000
) (
    input  wire        clk,
    input  wire        rst,
    // Rx de-framer
    input  wire        s_msg_valid,
    input  wire [ 3:0] s_msg_message_type,
    input  wire [15:0] s_msg_sequence_id,
    input  wire [79:0] s_msg_timestamp,
    input  wire [79:0] s_msg_origin_timestamp,
    input  wire [79:0] s_msg_source_port_identity,
    // Tx framer
    output logic         ap_valid,
    input  wire        ap_ready,
    output logic  [ 3:0] ap_message_type,
    output logic  [15:0] ap_sequence_id,
    output logic  [ 7:0] ap_log_message_interval,
    output logic  [79:0] ap_origin_timestamp,
    output logic  [79:0] ap_requesting_port_identity,
    output logic  [15:0] ap_tag_field,
    // Tx Ethernet
    input  wire [79:0] tx_ptp_timestamp,
    input  wire [15:0] tx_ptp_timestamp_tag,
    input  wire        tx_ptp_timestamp_valid,
    // CSR
    input  wire        ctrl_master_en,
    input  wire [ 7:0] ctrl_log_announce_interval,
    input  wire [ 7:0] ctrl_log_sync_interval
);

  // Parameters

  localparam [3:0] PTP_MESSAGE_TYPE_SYNC = 4'h0;
  localparam [3:0] PTP_MESSAGE_TYPE_DELAY_REQ = 4'h1;
  localparam [3:0] PTP_MESSAGE_TYPE_FOLLOW_UP = 4'h8;
  localparam [3:0] PTP_MESSAGE_TYPE_DELAY_RESP = 4'h9;
  localparam [3:0] PTP_MESSAGE_TYPE_ANNOUNCE = 4'hB;

  localparam integer CounterWidth = $clog2(CLK_FREQ);
  localparam [CounterWidth-1:0] ClkFreq = CLK_FREQ[CounterWidth-1:0];
  localparam [CounterWidth-1:0] OneCount = {{(CounterWidth-1){1'b0}}, 1'b1};

  wire unused_origin_timestamp = |s_msg_origin_timestamp;

  // Signals

  wire                    ctrl_master_en_s;
  wire [             7:0] ctrl_log_announce_interval_s;
  wire [             7:0] ctrl_log_sync_interval_s;

  logic  [            15:0] tag_field;
  wire                    tag_field_fb;

  // Sync message

  wire [             6:0] sync_counter_shift;

  logic  [CounterWidth-1:0] sync_counter;
  logic  [CounterWidth-1:0] sync_counter_max;
  wire                    sync_counter_wrap;

  logic  [             7:0] sync_counter_s;
  logic  [             7:0] sync_counter_s_max;
  wire                    sync_counter_s_wrap;

  logic  [            15:0] sync_sequence_id;

  logic                     sync_req;
  wire                    sync_ack;

  // Delay Request Message

  logic  [            15:0] delay_req_sequence_id;

  logic                     delay_req_req;
  wire                    delay_req_ack;

  // Follow message

  logic  [            79:0] follow_up_origin_timestamp;
  logic  [            15:0] follow_up_sequence_id;
  logic  [            15:0] follow_up_tag_field;

  logic                     follow_up_req;
  wire                    follow_up_ack;

  // Delay Response Message

  logic  [            79:0] delay_resp_timestamp;
  logic  [            79:0] delay_resp_port_identity;
  logic  [            15:0] delay_resp_sequence_id;

  logic                     delay_resp_req;
  wire                    delay_resp_ack;

  // Announce message

  wire [             6:0] announce_counter_shift;

  logic  [CounterWidth-1:0] announce_counter;
  logic  [CounterWidth-1:0] announce_counter_max;
  wire                    announce_counter_wrap;

  logic  [             7:0] announce_counter_s;
  logic  [             7:0] announce_counter_s_max;
  wire                    announce_counter_s_wrap;

  logic  [            15:0] announce_sequence_id;

  logic                     announce_req;
  wire                    announce_ack;

  // Control CDC

  cdc_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0)
  ) i_cdc_ctrl_master_en (
      .src_clk (1'b1),
      .src_in  (ctrl_master_en),
      .dest_clk(clk),
      .dest_out(ctrl_master_en_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (8)
  ) i_cdc_ctrl_log_announce_interval (
      .src_clk (1'b1),
      .src_in  (ctrl_log_announce_interval),
      .dest_clk(clk),
      .dest_out(ctrl_log_announce_interval_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (8)
  ) i_cdc_ctrl_log_sync_interval (
      .src_clk (1'b1),
      .src_in  (ctrl_log_sync_interval),
      .dest_clk(clk),
      .dest_out(ctrl_log_sync_interval_s)
  );

  // Main

  always_ff @(posedge clk) begin
    if (rst) begin
      tag_field <= 'd0;
    end else if ((sync_req && sync_ack) || (delay_req_req && delay_req_ack)) begin
      tag_field <= {tag_field[14:0], tag_field_fb};
    end
  end

  // Feedback polynomial = x^16 + x^15 + x^13 + x^4 + 1
  assign tag_field_fb = ~(tag_field[15] ^ tag_field[13] ^ tag_field[4] ^ tag_field[0]);

  // Sync Message

  // The `ctrl_log_sync_interval` is the log2 of the number of seconds between sync messages
  // and it self is signed 8-bit integer
  // The counter is used to generate the sync message at the correct time

  assign sync_counter_shift = (~ctrl_log_sync_interval_s[6:0] + 1);

  always_ff @(posedge clk) begin
    if (ctrl_log_sync_interval_s[7]) begin
      // Interval is negative (less than 1s), so we need to count up to 1s / 2^ctrl_log_sync_interval
      sync_counter_max <= (ClkFreq >> sync_counter_shift) - OneCount;
    end else begin
      // Interval is positive (larger than 1s), so we need to count up to 1s
      sync_counter_max <= ClkFreq - OneCount;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      sync_counter <= 0;
    end else if (sync_counter_wrap) begin
      sync_counter <= 0;
    end else begin
      sync_counter <= sync_counter + 1'd1;
    end
  end

  assign sync_counter_wrap = (sync_counter == sync_counter_max);

  always_ff @(posedge clk) begin
    if (ctrl_log_sync_interval_s[7]) begin
      // Interval is negative (less than 1s), so we not need second counter
      sync_counter_s_max <= 0;
    end else begin
      // Interval is positive (larger than 1s), so we need to count up to 2s ^ ctrl_log_sync_interval
      // However, our second counter is only 8-bit, so we can only count up to 256s
      case (ctrl_log_sync_interval_s[6:0])
        7'h00:   sync_counter_s_max <= 0;  // 2^0
        7'h01:   sync_counter_s_max <= 1;  // 2^1
        7'h02:   sync_counter_s_max <= 3;  // 2^2
        7'h03:   sync_counter_s_max <= 7;  // 2^3
        7'h04:   sync_counter_s_max <= 15;  // 2^4
        7'h05:   sync_counter_s_max <= 31;  // 2^5
        7'h06:   sync_counter_s_max <= 63;  // 2^6
        7'h07:   sync_counter_s_max <= 127;  // 2^7
        default: sync_counter_s_max <= 255;  // 2^8
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      sync_counter_s <= 0;
    end else if (sync_counter_s_wrap) begin
      sync_counter_s <= 0;
    end else if (sync_counter_wrap) begin
      sync_counter_s <= sync_counter_s + 1'd1;
    end
  end

  assign sync_counter_s_wrap = (sync_counter_s == sync_counter_s_max);

  always_ff @(posedge clk) begin
    if (rst) begin
      sync_sequence_id <= 'd0;
    end else if (sync_req && sync_ack) begin
      sync_sequence_id <= sync_sequence_id + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      sync_req <= 1'b0;
    end else if (sync_counter_wrap && sync_counter_s_wrap && ctrl_master_en_s) begin
      sync_req <= 1'b1;
    end else if (sync_ack) begin
      sync_req <= 1'b0;
    end
  end

  // Delay Request Message

  always_ff @(posedge clk) begin
    if (rst) begin
      delay_req_sequence_id <= 'd0;
    end else if (delay_req_req && delay_req_ack) begin
      delay_req_sequence_id <= delay_req_sequence_id + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      delay_req_req <= 1'b0;
    end else if (s_msg_valid && (s_msg_message_type == PTP_MESSAGE_TYPE_SYNC)) begin
      delay_req_req <= 1'b1;
    end else if (delay_req_ack) begin
      delay_req_req <= 1'b0;
    end
  end

  // Follow Up Message

  always_ff @(posedge clk) begin
    if (tx_ptp_timestamp_valid && (tx_ptp_timestamp_tag == follow_up_tag_field)) begin
      follow_up_origin_timestamp <= tx_ptp_timestamp;
    end
  end

  // Register the sequenceID when send sync message, we should use same value
  // for Follow Up message
  always_ff @(posedge clk) begin
    if (sync_req && sync_ack) begin
      follow_up_sequence_id <= sync_sequence_id;
    end
  end

  // Register the tag field when send sync message, we should check it when
  // got TX timestamp
  always_ff @(posedge clk) begin
    if (sync_req && sync_ack) begin
      follow_up_tag_field <= tag_field;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      follow_up_req <= 1'b0;
    end else if (tx_ptp_timestamp_valid && (tx_ptp_timestamp_tag == follow_up_tag_field) && ctrl_master_en_s) begin
      follow_up_req <= 1'b1;
    end else if (follow_up_ack) begin
      follow_up_req <= 1'b0;
    end
  end

  // Delay Response Message

  always_ff @(posedge clk) begin
    if (s_msg_valid && (s_msg_message_type == PTP_MESSAGE_TYPE_DELAY_REQ)) begin
      delay_resp_timestamp <= s_msg_timestamp;
    end
  end

  always_ff @(posedge clk) begin
    if (s_msg_valid && (s_msg_message_type == PTP_MESSAGE_TYPE_DELAY_REQ)) begin
      delay_resp_port_identity <= s_msg_source_port_identity;
    end
  end

  always_ff @(posedge clk) begin
    if (s_msg_valid && (s_msg_message_type == PTP_MESSAGE_TYPE_DELAY_REQ)) begin
      delay_resp_sequence_id <= s_msg_sequence_id;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      delay_resp_req <= 1'b0;
    end else if (s_msg_valid && (s_msg_message_type == PTP_MESSAGE_TYPE_DELAY_REQ) && ctrl_master_en_s) begin
      delay_resp_req <= 1'b1;
    end else if (delay_resp_ack) begin
      delay_resp_req <= 1'b0;
    end
  end

  // Announce Message

  // The `ctrl_log_announce_interval` is the log2 of the number of seconds between announce messages
  // and it self is signed 8-bit integer
  // The counter is used to generate the announce message at the correct time

  assign announce_counter_shift = (~ctrl_log_announce_interval_s[6:0] + 1'b1);

  always_ff @(posedge clk) begin
    if (ctrl_log_announce_interval_s[7]) begin
      // Interval is negative (less than 1s), so we need to count up to 1s / 2^ctrl_log_announce_interval
      announce_counter_max <= (ClkFreq >> announce_counter_shift) - OneCount;
    end else begin
      // Interval is positive (larger than 1s), so we need to count up to 1s
      announce_counter_max <= ClkFreq - OneCount;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      announce_counter <= 0;
    end else if (announce_counter_wrap) begin
      announce_counter <= 0;
    end else begin
      announce_counter <= announce_counter + 1'd1;
    end
  end

  assign announce_counter_wrap = (announce_counter == announce_counter_max);

  always_ff @(posedge clk) begin
    if (ctrl_log_announce_interval_s[7]) begin
      // Interval is negative (less than 1s), so we not need second counter
      announce_counter_s_max <= 0;
    end else begin
      // Interval is positive (larger than 1s), so we need to count up to 2s ^ ctrl_log_announce_interval
      // However, our second counter is only 8-bit, so we can only count up to 256s
      case (ctrl_log_announce_interval_s[6:0])
        7'h00:   announce_counter_s_max <= 0;  // 2^0
        7'h01:   announce_counter_s_max <= 1;  // 2^1
        7'h02:   announce_counter_s_max <= 3;  // 2^2
        7'h03:   announce_counter_s_max <= 7;  // 2^3
        7'h04:   announce_counter_s_max <= 15;  // 2^4
        7'h05:   announce_counter_s_max <= 31;  // 2^5
        7'h06:   announce_counter_s_max <= 63;  // 2^6
        7'h07:   announce_counter_s_max <= 127;  // 2^7
        default: announce_counter_s_max <= 255;  // 2^8
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      announce_counter_s <= 0;
    end else if (announce_counter_s_wrap) begin
      announce_counter_s <= 0;
    end else if (announce_counter_wrap) begin
      announce_counter_s <= announce_counter_s + 1'd1;
    end
  end

  assign announce_counter_s_wrap = (announce_counter_s == announce_counter_s_max);

  always_ff @(posedge clk) begin
    if (rst) begin
      announce_sequence_id <= 'd0;
    end else if (announce_req && announce_ack) begin
      announce_sequence_id <= announce_sequence_id + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      announce_req <= 1'b0;
    end else if (announce_counter_wrap && announce_counter_s_wrap && ctrl_master_en_s) begin
      announce_req <= 1'b1;
    end else if (announce_ack) begin
      announce_req <= 1'b0;
    end
  end

  // Output

  always_ff @(posedge clk) begin
    if (rst) begin
      ap_valid <= 1'b0;
    end else if (ap_valid) begin
      // Some other message is already being sent, so we need to wait for it to be ready
      if (ap_ready) begin
        ap_valid <= 1'b0;
      end
    end else begin
      // No other message is being sent, so we can send the the required message
      if (announce_req || delay_resp_req || follow_up_req || delay_req_req || sync_req) begin
        ap_valid <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (sync_req && ~ap_valid) begin
      ap_message_type             <= PTP_MESSAGE_TYPE_SYNC;
      ap_sequence_id              <= sync_sequence_id;
      ap_log_message_interval     <= ctrl_log_sync_interval_s;
      ap_origin_timestamp         <= 80'd0;
      ap_requesting_port_identity <= 80'd0;
      ap_tag_field                <= tag_field;
    end else if (delay_req_req && ~ap_valid) begin
      ap_message_type             <= PTP_MESSAGE_TYPE_DELAY_REQ;
      ap_sequence_id              <= delay_req_sequence_id;
      ap_log_message_interval     <= 8'h7F;
      ap_origin_timestamp         <= 80'd0;
      ap_requesting_port_identity <= 80'd0;
      ap_tag_field                <= tag_field;
    end else if (follow_up_req && ~ap_valid) begin
      ap_message_type             <= PTP_MESSAGE_TYPE_FOLLOW_UP;
      ap_sequence_id              <= follow_up_sequence_id;
      ap_log_message_interval     <= 8'h7F;
      ap_origin_timestamp         <= follow_up_origin_timestamp;
      ap_requesting_port_identity <= 80'b0;
      ap_tag_field                <= 16'b0;
    end else if (delay_resp_req && ~ap_valid) begin
      ap_message_type             <= PTP_MESSAGE_TYPE_DELAY_RESP;
      ap_sequence_id              <= delay_resp_sequence_id;
      ap_log_message_interval     <= 8'h7F;
      ap_origin_timestamp         <= delay_resp_timestamp;
      ap_requesting_port_identity <= delay_resp_port_identity;
      ap_tag_field                <= 16'b0;
    end else if (announce_req && ~ap_valid) begin
      ap_message_type             <= PTP_MESSAGE_TYPE_ANNOUNCE;
      ap_sequence_id              <= announce_sequence_id;
      ap_log_message_interval     <= ctrl_log_announce_interval_s;
      ap_origin_timestamp         <= 80'b0;
      ap_requesting_port_identity <= 80'b0;
      ap_tag_field                <= 16'b0;
    end
  end

  assign sync_ack = sync_req && ~ap_valid;
  assign delay_req_ack = delay_req_req && ~sync_req && ~ap_valid;
  assign follow_up_ack = follow_up_req && ~delay_req_req && ~sync_req && ~ap_valid;
  assign delay_resp_ack = delay_resp_req && ~follow_up_req && ~delay_req_req && ~sync_req && ~ap_valid;
  assign announce_ack = announce_req && ~delay_resp_req && ~follow_up_req && ~delay_req_req && ~sync_req && ~ap_valid;

endmodule

`default_nettype wire
