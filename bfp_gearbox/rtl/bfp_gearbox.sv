`timescale 1 ns / 1 ps
//
`default_nettype none

// Convert the 64-bit O-RAN BFP9 byte stream into two-IQ (36-bit) words.
//
// The BFP9 wire format used by bfp_comp is, for every PRB:
//
//   4'b0, 4-bit exponent, 24 x 9-bit IQ values
//
// Consequently one PRB produces six 36-bit words.  The exponent is repeated
// on each of those six output words so that the IQ and exponent memories can
// be written in lockstep.
//
// BYTE_REVERSE follows the convention used by bfp_comp/bfp_decomp: when set,
// the lowest byte of s_axis_tdata is the first byte on the AXI-Stream and the
// internal bit stream is assembled MSB first after reversing the byte lanes.
module bfp_gearbox #(
    parameter bit BYTE_REVERSE = 1'b1,
    parameter int USER_WIDTH   = 91
) (
    input  wire                   clk,
    input  wire                   rst,
    //
    input  wire [          63:0] s_axis_tdata,
    input  wire [           7:0] s_axis_tkeep,
    input  wire                   s_axis_tlast,
    input  wire [USER_WIDTH-1:0] s_axis_tuser,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    //
    output wire [          35:0] m_axis_tdata,
    output wire [           3:0] m_axis_exp,
    output wire                   m_axis_tlast,
    output wire [USER_WIDTH-1:0] m_axis_tuser,
    output wire                   m_axis_tvalid
);

  localparam int BUFFER_WIDTH = 128;

  typedef enum logic {
    ST_HEADER,
    ST_IQ
  } state_t;

  logic [BUFFER_WIDTH-1:0] bit_buffer;
  logic [           7:0] bit_count;
  logic [           3:0] exponent;
  logic [           2:0] iq_count;
  logic                  packet_started;
  logic                  packet_end_pending;
  logic [USER_WIDTH-1:0] packet_user;
  state_t                state;

  logic [           3:0] keep_bytes;
  logic [           6:0] input_bits;
  logic [          63:0] input_data_ordered;
  logic [          63:0] input_payload;
  logic [         127:0] input_payload_ext;

  logic                  header_consume;
  logic                  output_fire;
  logic                  input_fire;
  logic [           7:0] consume_bits;
  logic [           7:0] count_after_consume;
  logic [         127:0] buffer_after_consume;
  logic [         127:0] buffer_after_update;
  logic [           7:0] count_after_update;
  logic [         127:0] header_shifted;

  initial begin : drc_check
    assert (USER_WIDTH >= 1)
    else $error("[%m]: USER_WIDTH (%0d) must be at least 1.", USER_WIDTH);
  end

  function automatic logic [63:0] byte_reverse64(input logic [63:0] din);
    for (int i = 0; i < 8; i++) begin
      byte_reverse64[63-8*i-:8] = din[8*i+7-:8];
    end
  endfunction

  // AXI4-Stream TKEEP is expected to be a contiguous mask from bit 0.
  // Counting the set bits also keeps the gearbox well-defined for a shorter
  // final beat (BFP9 packets with an odd PRB count use 4 valid bytes).
  function automatic logic [3:0] tkeep_to_bytes(input logic [7:0] tkeep);
    tkeep_to_bytes = '0;
    for (int i = 0; i < 8; i++) begin
      tkeep_to_bytes = tkeep_to_bytes + tkeep[i];
    end
  endfunction

  assign keep_bytes = tkeep_to_bytes(s_axis_tkeep);
  assign input_bits = {keep_bytes, 3'b000};

  assign input_data_ordered = BYTE_REVERSE ? byte_reverse64(s_axis_tdata) : s_axis_tdata;

  // Place the first valid input bit at input_payload[input_bits-1].  The
  // conditional avoids a 64-bit variable shift when TKEEP is zero.
  always_comb begin
    input_payload = '0;
    if (input_bits != 0) begin
      input_payload = input_data_ordered >> (7'd64 - input_bits);
    end
  end

  assign m_axis_tvalid = (state == ST_IQ) && (bit_count >= 8'd36);
  assign m_axis_tdata  = m_axis_tvalid ? bit_buffer >> (bit_count - 8'd36) : '0;
  assign m_axis_exp    = exponent;
  assign m_axis_tlast = m_axis_tvalid && packet_end_pending &&
      (iq_count == 3'd5);
  assign m_axis_tuser = packet_user;

  // The FDV buffer is the guaranteed consumer of this stream, so a valid
  // output is consumed every cycle.  Backpressure is only needed on the
  // 64-bit input side because one input beat carries more bits than one
  // 36-bit output word.
  assign output_fire = m_axis_tvalid;
  assign header_consume = (state == ST_HEADER) && (bit_count >= 8'd8);

  // Only one kind of item is consumed in a cycle: a PRB header or an IQ
  // output word.  The input beat may be accepted in the same cycle and is
  // appended after that consumption.
  assign consume_bits = header_consume ? 8'd8 : (output_fire ? 8'd36 : 8'd0);
  assign count_after_consume = bit_count - consume_bits;
  // Valid bits occupy the low bit_count bits and the oldest bit is the most
  // significant bit of that valid region.  Consuming from the front
  // therefore only reduces bit_count; the remaining bits are already in the
  // low part of the register.  New bits are appended by shifting the
  // remaining stream toward the MSB and placing the new stream at the LSB.
  assign buffer_after_consume = bit_buffer;

  assign input_payload_ext = {64'b0, input_payload};
  assign buffer_after_update = (buffer_after_consume <<
      (input_fire ? input_bits : 7'd0)) | (input_fire ? input_payload_ext : 128'b0);
  assign count_after_update = count_after_consume + (input_fire ? input_bits : 7'd0);

  // Reserve space for a worst-case 64-bit input beat.  This deliberately
  // does not depend on TKEEP, whose value is not required to be meaningful
  // while TVALID is low.  A 128-bit buffer is enough for one input beat plus
  // one output word of overlap, while still allowing one-cycle backpressure.
  assign s_axis_tready = !packet_end_pending && (count_after_consume <= 8'd64);
  assign input_fire = s_axis_tvalid && s_axis_tready;

  assign header_shifted = bit_buffer >> (bit_count - 8'd8);

  always_ff @(posedge clk) begin
    if (rst) begin
      bit_buffer         <= '0;
      bit_count          <= '0;
      exponent           <= '0;
      iq_count           <= '0;
      packet_started     <= 1'b0;
      packet_end_pending <= 1'b0;
      packet_user        <= '0;
      state              <= ST_HEADER;
    end else begin
      bit_buffer <= buffer_after_update;
      bit_count  <= count_after_update;

      if (header_consume) begin
        // header_shifted[7:4] is the reserved zero nibble and
        // header_shifted[3:0] is the BFP9 exponent.
        exponent <= header_shifted[3:0];
        iq_count <= '0;
        state    <= ST_IQ;
      end else if (output_fire) begin
        if (iq_count == 3'd5) begin
          iq_count <= '0;
          state    <= ST_HEADER;
        end else begin
          iq_count <= iq_count + 1'b1;
        end
      end

      if (input_fire) begin
        if (!packet_started) begin
          packet_started <= 1'b1;
          packet_user    <= s_axis_tuser;
        end
        if (s_axis_tlast) begin
          packet_end_pending <= 1'b1;
        end
      end

      if (output_fire && m_axis_tlast) begin
        packet_started     <= 1'b0;
        packet_end_pending <= 1'b0;
      end
    end
  end

endmodule

`default_nettype wire
