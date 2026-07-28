/*
 * This module parse eCPRI packets (assume MAC header removed), write
 * parsed eCPRI common header filed to scalar ports, then forward the
 * payload to next stage.
 * - Multiple eCPRI message in one packet (concatenation) is supported.
 *   They are split into multiple packets.
 *   NOTE: If concatenation is used, eCPRI message witch C = 1 should
 *   be pad to 32-bit boundary.
 * - eCPRI common header (4-byte) is removed here.
 * - The latency is 1 clock cycles, (header input to payload output)
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_deframer_common (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [31:0] s_axis_tdata,
    input  wire [ 3:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire [79:0] s_axis_tuser,
    input  wire        s_axis_tvalid,
    //
    output reg  [31:0] m_axis_tdata,
    output reg  [ 3:0] m_axis_tkeep,
    output reg         m_axis_tlast,
    output reg  [79:0] m_axis_tuser,
    output reg         m_axis_tvalid,
    // Transport header (eCPRI header)
    output reg         m_ecpri_header_valid,
    output reg         m_ecpri_concat,
    output reg  [ 7:0] m_ecpri_messagetype,
    output reg  [15:0] m_ecpri_payloadsize
);

  import ecpri_pkg::*;

  // FSM states

  localparam integer S_RST = 0;  // Under reset
  localparam integer S_COMM = 1;  // Common header
  localparam integer S_PAYLOAD = 2;  // Payload

  // Input data

  wire [31:0] s_axis_tdata_reversed;

  // eCPRI Common Header & Payload

  wire [ 3:0] ecpri_version;  // !no output
  wire [ 2:0] ecpri_reserved;  // !no output
  wire        ecpri_concat;  // eCPRI concatenation indicator
  wire [ 7:0] ecpri_messagetype;  // 0 = IQ, 2 = IQC, 5 = Delay measure
  wire [15:0] ecpri_payloadsize;

  reg  [15:0] payload_counter;  // Received message bytes counter

  wire        payload_end;
  wire        unused_header_fields;

  assign unused_header_fields = &{1'b0, ecpri_version, ecpri_reserved};

  integer state, state_next;

  // Main

  always @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always @(*) begin
    // Stay at current state by default
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_COMM;
      end

      S_COMM: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_COMM;
        end else if (s_axis_tvalid && ecpri_payloadsize == 0) begin
          state_next = S_COMM;
        end else if (s_axis_tvalid) begin
          state_next = S_PAYLOAD;
        end
      end

      S_PAYLOAD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_COMM;
        end else if (s_axis_tvalid && payload_end) begin
          state_next = S_COMM;
        end else if (s_axis_tvalid) begin
          state_next = S_PAYLOAD;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // Byte reverse for easy handling
  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  // Header & payload mapping

  assign {
    ecpri_version,
    ecpri_reserved,
    ecpri_concat,
    ecpri_messagetype,
    ecpri_payloadsize
  } = s_axis_tdata_reversed;

  // Total received bytes, not including current bytes
  always @(posedge clk) begin
    if (rst) begin
      payload_counter <= 0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      payload_counter <= 0;
    end else if ((state == S_COMM) && s_axis_tvalid) begin
      payload_counter <= 0;
    end else if (s_axis_tvalid && (state == S_PAYLOAD)) begin
      payload_counter <= payload_counter + 4;
    end
  end

  assign payload_end = (payload_counter >= m_ecpri_payloadsize);

  // eCPRI common header parse ports output

  always @(posedge clk) begin
    m_ecpri_header_valid <= (state == S_COMM) && s_axis_tvalid;
  end

  always @(posedge clk) begin
    if ((state == S_COMM) && s_axis_tvalid) begin
      m_ecpri_concat      <= ecpri_concat;
      m_ecpri_messagetype <= ecpri_messagetype;
      m_ecpri_payloadsize <= ecpri_payloadsize;
    end
  end

  // Master AXIS

  always @(posedge clk) begin
    if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tdata <= s_axis_tdata;
    end
  end

  always @(posedge clk) begin
    if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tkeep <= s_axis_tkeep;
    end
  end

  always @(posedge clk) begin
    if (s_axis_tvalid) begin
      m_axis_tlast <= s_axis_tlast || payload_end;
    end
  end


  always @(posedge clk) begin
    if ((state == S_COMM) && s_axis_tvalid) begin
      m_axis_tuser <= s_axis_tuser;
    end
  end

  always @(posedge clk) begin
    m_axis_tvalid <= (state == S_PAYLOAD) && s_axis_tvalid;
  end

endmodule

`default_nettype wire
