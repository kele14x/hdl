`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_framer (
    input  wire        clk,
    input  wire        rst,
    //
    output wire [31:0] m_axis_tdata,
    output reg  [ 3:0] m_axis_tkeep,
    output reg         m_axis_tlast,
    output reg  [17:0] m_axis_tuser,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    //
    input  wire        ap_valid,
    output reg         ap_ready,
    input  wire [ 3:0] ap_message_type,
    input  wire [15:0] ap_sequence_id,
    input  wire [ 7:0] ap_log_message_interval,
    input  wire [79:0] ap_origin_timestamp,
    input  wire [79:0] ap_requesting_port_identity,
    input  wire [15:0] ap_tag_field,
    // CSR
    input  wire [47:0] ctrl_src_mac,
    input  wire [ 7:0] ctrl_domain_number,
    input  wire [15:0] ctrl_utc_offset
);

  // Parameters

  import ptp_pkg::*;

  wire unused_ptp_pkg_params = |{
    PTP_MESSAGE_TYPE_PDELAY_REQ,
    PTP_MESSAGE_TYPE_PDELAY_RESP,
    PTP_MESSAGE_TYPE_PDELAY_RESP_FUP,
    PTP_MESSAGE_TYPE_SIGNALING,
    PTP_MULTICAST_MAC_PDELAY
  };

  localparam integer S_RST = 0;
  localparam integer S_IDLE = 1;
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

  wire [47:0] ctrl_src_mac_s;
  wire [ 7:0] ctrl_domain_number_s;
  wire [15:0] ctrl_utc_offset_s;

  integer state, state_next;

  reg  [31:0] m_axis_tdata_rev;

  wire [ 3:0] transport_specific = 4'd0;
  reg  [ 3:0] message_type;
  wire [ 3:0] reserved0 = 4'd1;  // major_sdo_id
  wire [ 3:0] version_ptp = 4'd2;
  reg  [15:0] message_length;
  wire [ 7:0] domain_number;
  wire [ 7:0] reserved1 = 8'd0;  // minor_sdo_id
  wire [15:0] flag_field = 16'h0200;
  wire [63:0] correction_field = 64'd0;
  wire [31:0] reserved2 = 32'd0;  // message_type_specific
  wire [79:0] source_port_identity;  // {clock_identity, port_number}
  reg  [15:0] sequence_id;
  reg  [ 7:0] control_field;
  reg  [ 7:0] log_message_interval;

  reg  [79:0] origin_timestamp;
  wire [15:0] current_utc_offset;
  wire [ 7:0] reserved3 = 8'd0;
  wire [ 7:0] grandmaster_priority1 = 8'h80;
  wire [31:0] grandmaster_clock_quality = 32'h06FEFFFF;
  wire [ 7:0] grandmaster_priority2 = 8'h80;
  wire [63:0] grandmaster_identity;
  wire [15:0] steps_removed = 16'd0;
  wire [ 7:0] time_source = 8'hA0;

  reg  [79:0] requesting_port_identity;

  // Control CDC

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (48)
  ) i_cdc_ctrl_src_mac (
      .src_clk (1'b1),
      .src_in  (ctrl_src_mac),
      .dest_clk(clk),
      .dest_out(ctrl_src_mac_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (8)
  ) i_cdc_ctrl_domain_number (
      .src_clk (1'b1),
      .src_in  (ctrl_domain_number),
      .dest_clk(clk),
      .dest_out(ctrl_domain_number_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (16)
  ) i_cdc_ctrl_utc_offset (
      .src_clk (1'b1),
      .src_in  (ctrl_utc_offset),
      .dest_clk(clk),
      .dest_out(ctrl_utc_offset_s)
  );

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
        state_next = S_IDLE;
      end

      S_IDLE: begin
        if (ap_valid) begin
          // We only support E2E delay messages
          if (ap_message_type == PTP_MESSAGE_TYPE_SYNC) begin
            state_next = S_DMAC0;
          end else if (ap_message_type == PTP_MESSAGE_TYPE_DELAY_REQ) begin
            state_next = S_DMAC0;
          end else if (ap_message_type == PTP_MESSAGE_TYPE_FOLLOW_UP) begin
            state_next = S_DMAC0;
          end else if (ap_message_type == PTP_MESSAGE_TYPE_DELAY_RESP) begin
            state_next = S_DMAC0;
          end else if (ap_message_type == PTP_MESSAGE_TYPE_ANNOUNCE) begin
            state_next = S_DMAC0;
          end
        end
      end

      S_DMAC0: begin
        if (m_axis_tready) begin
          state_next = S_DMAC1_SMAC0;
        end
      end

      S_DMAC1_SMAC0: begin
        if (m_axis_tready) begin
          state_next = S_SMAC1;
        end
      end

      S_SMAC1: begin
        if (m_axis_tready) begin
          state_next = S_ETHERTYPE_HEADER0;
        end
      end

      // PTP Common Header

      S_ETHERTYPE_HEADER0: begin
        if (m_axis_tready) begin
          state_next = S_HEADER1;
        end
      end

      S_HEADER1: begin
        if (m_axis_tready) begin
          state_next = S_HEADER2;
        end
      end

      S_HEADER2: begin
        if (m_axis_tready) begin
          state_next = S_HEADER3;
        end
      end

      S_HEADER3: begin
        if (m_axis_tready) begin
          state_next = S_HEADER4;
        end
      end

      S_HEADER4: begin
        if (m_axis_tready) begin
          state_next = S_HEADER5;
        end
      end

      S_HEADER5: begin
        if (m_axis_tready) begin
          state_next = S_HEADER6;
        end
      end

      S_HEADER6: begin
        if (m_axis_tready) begin
          state_next = S_HEADER7;
        end
      end

      S_HEADER7: begin
        if (m_axis_tready) begin
          state_next = S_HEADER8;
        end
      end

      S_HEADER8: begin
        if (m_axis_tready) begin
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
            state_next = S_IDLE;
          end
        end
      end

      // Sync

      S_SYNC0: begin
        if (m_axis_tready) begin
          state_next = S_SYNC1;
        end
      end

      S_SYNC1: begin
        if (m_axis_tready) begin
          state_next = S_SYNC2;
        end
      end

      S_SYNC2: begin
        if (m_axis_tready) begin
          state_next = S_IDLE;
        end
      end

      // Delay Request

      S_DELAY_REQ0: begin
        if (m_axis_tready) begin
          state_next = S_DELAY_REQ1;
        end
      end

      S_DELAY_REQ1: begin
        if (m_axis_tready) begin
          state_next = S_DELAY_REQ2;
        end
      end

      S_DELAY_REQ2: begin
        if (m_axis_tready) begin
          state_next = S_IDLE;
        end
      end

      // Follow Up

      S_FOLLOW_UP0: begin
        if (m_axis_tready) begin
          state_next = S_FOLLOW_UP1;
        end
      end

      S_FOLLOW_UP1: begin
        if (m_axis_tready) begin
          state_next = S_FOLLOW_UP2;
        end
      end

      S_FOLLOW_UP2: begin
        if (m_axis_tready) begin
          state_next = S_IDLE;
        end
      end

      // Delay Response

      S_DELAY_RESP0: begin
        if (m_axis_tready) begin
          state_next = S_DELAY_RESP1;
        end
      end

      S_DELAY_RESP1: begin
        if (m_axis_tready) begin
          state_next = S_DELAY_RESP2;
        end
      end

      S_DELAY_RESP2: begin
        if (m_axis_tready) begin
          state_next = S_DELAY_RESP3;
        end
      end

      S_DELAY_RESP3: begin
        if (m_axis_tready) begin
          state_next = S_DELAY_RESP4;
        end
      end

      S_DELAY_RESP4: begin
        if (m_axis_tready) begin
          state_next = S_IDLE;
        end
      end

      // Announce

      S_ANNOUNCE0: begin
        if (m_axis_tready) begin
          state_next = S_ANNOUNCE1;
        end
      end

      S_ANNOUNCE1: begin
        if (m_axis_tready) begin
          state_next = S_ANNOUNCE2;
        end
      end

      S_ANNOUNCE2: begin
        if (m_axis_tready) begin
          state_next = S_ANNOUNCE3;
        end
      end

      S_ANNOUNCE3: begin
        if (m_axis_tready) begin
          state_next = S_ANNOUNCE4;
        end
      end

      S_ANNOUNCE4: begin
        if (m_axis_tready) begin
          state_next = S_ANNOUNCE5;
        end
      end

      S_ANNOUNCE5: begin
        if (m_axis_tready) begin
          state_next = S_ANNOUNCE6;
        end
      end

      S_ANNOUNCE6: begin
        if (m_axis_tready) begin
          state_next = S_ANNOUNCE7;
        end
      end

      S_ANNOUNCE7: begin
        if (m_axis_tready) begin
          state_next = S_IDLE;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // Input

  always @(posedge clk) begin
    if (rst) begin
      ap_ready <= 1'b0;
    end else begin
      ap_ready <= state_next == S_IDLE;
    end
  end

  always @(posedge clk) begin
    if (ap_ready && ap_valid) begin
      message_type <= ap_message_type;
    end
  end

  always @(posedge clk) begin
    if (ap_ready && ap_valid) begin
      if (ap_message_type == PTP_MESSAGE_TYPE_SYNC) begin
        message_length <= 'd44;
      end else if (ap_message_type == PTP_MESSAGE_TYPE_DELAY_REQ) begin
        message_length <= 'd44;
      end else if (ap_message_type == PTP_MESSAGE_TYPE_FOLLOW_UP) begin
        message_length <= 'd44;
      end else if (ap_message_type == PTP_MESSAGE_TYPE_DELAY_RESP) begin
        message_length <= 'd54;
      end else if (ap_message_type == PTP_MESSAGE_TYPE_ANNOUNCE) begin
        message_length <= 'd64;
      end else begin
        message_length <= 'd0;
      end
    end
  end

  assign domain_number = ctrl_domain_number_s;

  // Use EUI-48 (MAC address) as clock identity (EUI-64)
  // portNumber (port_number) is fixed to 0x0001
  assign source_port_identity = {ctrl_src_mac_s[47:24], 16'hFFFE, ctrl_src_mac_s[23:0], 16'h0001};

  always @(posedge clk) begin
    if (ap_ready && ap_valid) begin
      sequence_id <= ap_sequence_id;
    end
  end

  always @(posedge clk) begin
    if (ap_ready && ap_valid) begin
      if (ap_message_type == PTP_MESSAGE_TYPE_SYNC) begin
        control_field <= PTP_CONTROL_FIELD_SYNC;  // 0x00
      end else if (ap_message_type == PTP_MESSAGE_TYPE_DELAY_REQ) begin
        control_field <= PTP_CONTROL_FIELD_DELAY_REQ;  // 0x01
      end else if (ap_message_type == PTP_MESSAGE_TYPE_FOLLOW_UP) begin
        control_field <= PTP_CONTROL_FIELD_FOLLOW_UP;  // 0x02
      end else if (ap_message_type == PTP_MESSAGE_TYPE_DELAY_RESP) begin
        control_field <= PTP_CONTROL_FIELD_DELAY_RESP;  // 0x03
      end else if (ap_message_type == PTP_MESSAGE_TYPE_ANNOUNCE) begin
        // ptp4l maps Announce Mesage to 0x0
        control_field <= PTP_CONTROL_FIELD_SYNC;  // 0x00
      end else if (ap_message_type == PTP_MESSAGE_TYPE_MANAGEMENT) begin
        control_field <= PTP_CONTROL_FIELD_MANAGEMENT;  // 0x04
      end else begin
        control_field <= PTP_CONTROL_FIELD_OTHERS;  // 0x05
      end
    end
  end

  always @(posedge clk) begin
    if (ap_ready && ap_valid) begin
      log_message_interval <= ap_log_message_interval;
    end
  end

  always @(posedge clk) begin
    if (ap_ready && ap_valid) begin
      origin_timestamp <= ap_origin_timestamp;
    end
  end

  assign current_utc_offset   = ctrl_utc_offset_s;

  assign grandmaster_identity = {ctrl_src_mac_s[47:24], 16'hFFFE, ctrl_src_mac_s[23:0]};

  always @(posedge clk) begin
    if (ap_ready && ap_valid) begin
      requesting_port_identity <= ap_requesting_port_identity;
    end
  end

  // Output

  assign m_axis_tdata = byte_reverse(m_axis_tdata_rev);

  always @(posedge clk) begin
    // Ethernet Header
    if (state_next == S_DMAC0) begin
      m_axis_tdata_rev <= PTP_MULTICAST_MAC[47:16];
    end else if (state_next == S_DMAC1_SMAC0) begin
      m_axis_tdata_rev <= {PTP_MULTICAST_MAC[15:0], ctrl_src_mac_s[47:32]};
    end else if (state_next == S_SMAC1) begin
      m_axis_tdata_rev <= ctrl_src_mac_s[31:0];

      // PTP Common Header
    end else if (state_next == S_ETHERTYPE_HEADER0) begin
      m_axis_tdata_rev <= {PTP_ETHERTYPE, transport_specific, message_type, reserved0, version_ptp};
    end else if (state_next == S_HEADER1) begin
      m_axis_tdata_rev <= {message_length, domain_number, reserved1};
    end else if (state_next == S_HEADER2) begin
      m_axis_tdata_rev <= {flag_field, correction_field[63:48]};
    end else if (state_next == S_HEADER3) begin
      m_axis_tdata_rev <= correction_field[47:16];
    end else if (state_next == S_HEADER4) begin
      m_axis_tdata_rev <= {correction_field[15:0], reserved2[31:16]};
    end else if (state_next == S_HEADER5) begin
      m_axis_tdata_rev <= {reserved2[15:0], source_port_identity[79:64]};
    end else if (state_next == S_HEADER6) begin
      m_axis_tdata_rev <= source_port_identity[63:32];
    end else if (state_next == S_HEADER7) begin
      m_axis_tdata_rev <= source_port_identity[31:0];
    end else if (state_next == S_HEADER8) begin
      m_axis_tdata_rev <= {sequence_id, control_field, log_message_interval};

      // Sync Message
    end else if (state_next == S_SYNC0) begin
      m_axis_tdata_rev <= origin_timestamp[79:48];
    end else if (state_next == S_SYNC1) begin
      m_axis_tdata_rev <= origin_timestamp[47:16];
    end else if (state_next == S_SYNC2) begin
      m_axis_tdata_rev <= {origin_timestamp[15:0], 16'h0000};

      // Delay Request Message
    end else if (state_next == S_DELAY_REQ0) begin
      m_axis_tdata_rev <= origin_timestamp[79:48];
    end else if (state_next == S_DELAY_REQ1) begin
      m_axis_tdata_rev <= origin_timestamp[47:16];
    end else if (state_next == S_DELAY_REQ2) begin
      m_axis_tdata_rev <= {origin_timestamp[15:0], 16'h0000};

      // Follow Up Message
    end else if (state_next == S_FOLLOW_UP0) begin
      m_axis_tdata_rev <= origin_timestamp[79:48];
    end else if (state_next == S_FOLLOW_UP1) begin
      m_axis_tdata_rev <= origin_timestamp[47:16];
    end else if (state_next == S_FOLLOW_UP2) begin
      m_axis_tdata_rev <= {origin_timestamp[15:0], 16'h0000};

      // Delay Response Message
    end else if (state_next == S_DELAY_RESP0) begin
      m_axis_tdata_rev <= origin_timestamp[79:48];
    end else if (state_next == S_DELAY_RESP1) begin
      m_axis_tdata_rev <= origin_timestamp[47:16];
    end else if (state_next == S_DELAY_RESP2) begin
      m_axis_tdata_rev <= {origin_timestamp[15:0], requesting_port_identity[79:64]};
    end else if (state_next == S_DELAY_RESP3) begin
      m_axis_tdata_rev <= requesting_port_identity[63:32];
    end else if (state_next == S_DELAY_RESP4) begin
      m_axis_tdata_rev <= requesting_port_identity[31:0];

      // Announce Message
    end else if (state_next == S_ANNOUNCE0) begin
      m_axis_tdata_rev <= origin_timestamp[79:48];
    end else if (state_next == S_ANNOUNCE1) begin
      m_axis_tdata_rev <= origin_timestamp[47:16];
    end else if (state_next == S_ANNOUNCE2) begin
      m_axis_tdata_rev <= {origin_timestamp[15:0], current_utc_offset};
    end else if (state_next == S_ANNOUNCE3) begin
      m_axis_tdata_rev <= {reserved3, grandmaster_priority1, grandmaster_clock_quality[31:16]};
    end else if (state_next == S_ANNOUNCE4) begin
      m_axis_tdata_rev <= {
        grandmaster_clock_quality[15:0], grandmaster_priority2, grandmaster_identity[63:56]
      };
    end else if (state_next == S_ANNOUNCE5) begin
      m_axis_tdata_rev <= grandmaster_identity[55:24];
    end else if (state_next == S_ANNOUNCE6) begin
      m_axis_tdata_rev <= {grandmaster_identity[23:0], steps_removed[15:8]};
    end else if (state_next == S_ANNOUNCE7) begin
      m_axis_tdata_rev <= {steps_removed[7:0], time_source, 16'h0000};
    end
  end

  always @(posedge clk) begin
    if (state_next == S_DMAC0) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_DMAC1_SMAC0) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_SMAC1) begin
      m_axis_tkeep <= 4'b1111;

      // PTP Common Header
    end else if (state_next == S_ETHERTYPE_HEADER0) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_HEADER1) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_HEADER2) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_HEADER3) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_HEADER4) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_HEADER5) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_HEADER6) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_HEADER7) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_HEADER8) begin
      m_axis_tkeep <= 4'b1111;

      // Sync Message
    end else if (state_next == S_SYNC0) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_SYNC1) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_SYNC2) begin
      m_axis_tkeep <= 4'b0011;

      // Delay Request Message
    end else if (state_next == S_DELAY_REQ0) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_DELAY_REQ1) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_DELAY_REQ2) begin
      m_axis_tkeep <= 4'b0011;

      // Follow Up Message
    end else if (state_next == S_FOLLOW_UP0) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_FOLLOW_UP1) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_FOLLOW_UP2) begin
      m_axis_tkeep <= 4'b0011;

      // Delay Response Message
    end else if (state_next == S_DELAY_RESP0) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_DELAY_RESP1) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_DELAY_RESP2) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_DELAY_RESP3) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_DELAY_RESP4) begin
      m_axis_tkeep <= 4'b1111;

      // Announce Message
    end else if (state_next == S_ANNOUNCE0) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_ANNOUNCE1) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_ANNOUNCE2) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_ANNOUNCE3) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_ANNOUNCE4) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_ANNOUNCE5) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_ANNOUNCE6) begin
      m_axis_tkeep <= 4'b1111;
    end else if (state_next == S_ANNOUNCE7) begin
      m_axis_tkeep <= 4'b0011;
    end
  end

  always @(posedge clk) begin
    if (state_next == S_DMAC0) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_DMAC1_SMAC0) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_SMAC1) begin
      m_axis_tlast <= 1'b0;

      // PTP Common Header
    end else if (state_next == S_ETHERTYPE_HEADER0) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_HEADER1) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_HEADER2) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_HEADER3) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_HEADER4) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_HEADER5) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_HEADER6) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_HEADER7) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_HEADER8) begin
      m_axis_tlast <= 1'b0;

      // Sync Message
    end else if (state_next == S_SYNC0) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_SYNC1) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_SYNC2) begin
      m_axis_tlast <= 1'b1;

      // Delay Request Message
    end else if (state_next == S_DELAY_REQ0) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_DELAY_REQ1) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_DELAY_REQ2) begin
      m_axis_tlast <= 1'b1;

      // Follow Up Message
    end else if (state_next == S_FOLLOW_UP0) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_FOLLOW_UP1) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_FOLLOW_UP2) begin
      m_axis_tlast <= 1'b1;

      // Delay Response Message
    end else if (state_next == S_DELAY_RESP0) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_DELAY_RESP1) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_DELAY_RESP2) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_DELAY_RESP3) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_DELAY_RESP4) begin
      m_axis_tlast <= 1'b1;

      // Announce Message
    end else if (state_next == S_ANNOUNCE0) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_ANNOUNCE1) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_ANNOUNCE2) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_ANNOUNCE3) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_ANNOUNCE4) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_ANNOUNCE5) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_ANNOUNCE6) begin
      m_axis_tlast <= 1'b0;
    end else if (state_next == S_ANNOUNCE7) begin
      m_axis_tlast <= 1'b1;
    end
  end

  always @(posedge clk) begin
    if (state == S_IDLE) begin
      if (ap_valid) begin
        if (ap_message_type == PTP_MESSAGE_TYPE_SYNC) begin
          m_axis_tuser <= {2'h2, ap_tag_field};
        end else if (ap_message_type == PTP_MESSAGE_TYPE_DELAY_REQ) begin
          m_axis_tuser <= {2'h2, ap_tag_field};
        end else if (ap_message_type == PTP_MESSAGE_TYPE_FOLLOW_UP) begin
          m_axis_tuser <= 18'h00000;
        end else if (ap_message_type == PTP_MESSAGE_TYPE_DELAY_RESP) begin
          m_axis_tuser <= 18'h00000;
        end else if (ap_message_type == PTP_MESSAGE_TYPE_ANNOUNCE) begin
          m_axis_tuser <= 18'h00000;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (state_next == S_DMAC0) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_DMAC1_SMAC0) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_SMAC1) begin
      m_axis_tvalid <= 1'b1;

      // PTP Common Header
    end else if (state_next == S_ETHERTYPE_HEADER0) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_HEADER1) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_HEADER2) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_HEADER3) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_HEADER4) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_HEADER5) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_HEADER6) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_HEADER7) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_HEADER8) begin
      m_axis_tvalid <= 1'b1;

      // Sync Message
    end else if (state_next == S_SYNC0) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_SYNC1) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_SYNC2) begin
      m_axis_tvalid <= 1'b1;

      // Delay Request Message
    end else if (state_next == S_DELAY_REQ0) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_DELAY_REQ1) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_DELAY_REQ2) begin
      m_axis_tvalid <= 1'b1;

      // Follow Up Message
    end else if (state_next == S_FOLLOW_UP0) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_FOLLOW_UP1) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_FOLLOW_UP2) begin
      m_axis_tvalid <= 1'b1;

      // Delay Response Message
    end else if (state_next == S_DELAY_RESP0) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_DELAY_RESP1) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_DELAY_RESP2) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_DELAY_RESP3) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_DELAY_RESP4) begin
      m_axis_tvalid <= 1'b1;

      // Announce Message
    end else if (state_next == S_ANNOUNCE0) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_ANNOUNCE1) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_ANNOUNCE2) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_ANNOUNCE3) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_ANNOUNCE4) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_ANNOUNCE5) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_ANNOUNCE6) begin
      m_axis_tvalid <= 1'b1;
    end else if (state_next == S_ANNOUNCE7) begin
      m_axis_tvalid <= 1'b1;
    end else begin
      m_axis_tvalid <= 1'b0;
    end
  end

endmodule

`default_nettype wire
