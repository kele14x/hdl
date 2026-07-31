// File: oran_deframer_eth_common.sv
// Brief: This module parse eCPRI packets (assume MAC header removed), write
//        parsed eCPRI common header filed to scalar ports, then forward the
//        payload to next stage.
//        - Multiple eCPRI message in one packet (concatenation) is supported.
//          They are splitted into multiple packets.
//          NOTE: If concatenation is used, eCPRI message witch C = 1 should
//          be pad to 32-bit boundary.
//        - eCPRI common header (4-byte) is removed here.
//        - The latency is 2 clock cycles, (header input to payload output)
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer_eth_common (
    input var         clk,
    input var         rst,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    input var  [79:0] s_axis_tuser,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    output var [79:0] m_axis_tuser,
    output var [ 1:0] m_axis_tdest,
    // O-RAN parse ports
    //------------------
    // Transport header (eCPRI header)
    output var        m_ecpri_header_valid,
    output var        m_ecpri_concat,
    output var [ 7:0] m_ecpri_messagetype,
    output var [15:0] m_ecpri_payloadsize
);

  import oran_pkg::*;


  // Input data

  logic [ 63:0] s_axis_tdata_reversed;
  logic [ 63:0] s_axis_tdata_d;
  logic [127:0] s_axis_tdata_c;

  logic [  7:0] s_axis_tkeep_d;

  // eCPRI Common Header & Payload

  logic [  3:0] ecpri_version;  // !no output
  logic [  2:0] ecpri_reserved;  // !no output
  logic         ecpri_concat;  // eCPRI concatenation indicator
  logic [  7:0] ecpri_messagetype;  // 0 = IQ, 2 = IQC, 5 = Delay measure
  logic [ 15:0] ecpri_payloadsize;

  logic [ 31:0] ecpri_header;
  logic         ecpri_header_valid;

  logic [ 63:0] ecpri_payload;
  logic         ecpri_payload_valid;

  logic [  1:0] tdest;
  logic [ 79:0] tuser;

  // Parse FSM

  logic [ 15:0] stat_counter;  // Received message bytes counter
  logic [ 15:0] stat_counter_next;  // Message
  logic [ 15:0] stat_counter_c;  // Message end position
  logic [ 15:0] stat_counter_h;  // Message start postion

  logic [  2:0] stat_payload_shift;
  logic [  2:0] stat_header_shift;

  logic         stat_last;  // in-phase last word
  logic         extra_last;

  wire          unused_common_fields = &{1'b0, s_axis_tkeep_d, ecpri_version, ecpri_reserved};


  // Get the TKEEP pattern based on the byte ending position
  function static bit [7:0] get_tkeep(input logic [2:0] cnt);
    case (cnt)
      3'b000:  return 8'b11111111;
      3'b001:  return 8'b00000001;
      3'b010:  return 8'b00000011;
      3'b011:  return 8'b00000111;
      3'b100:  return 8'b00001111;
      3'b101:  return 8'b00011111;
      3'b110:  return 8'b00111111;
      3'b111:  return 8'b01111111;
      default: return 8'b00000000;
    endcase
  endfunction


  // Main
  //-----

  // Register data for later use

  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      s_axis_tdata_d <= s_axis_tdata_reversed;
      s_axis_tkeep_d <= s_axis_tkeep;
    end
  end

  assign s_axis_tdata_c = {s_axis_tdata_d, s_axis_tdata_reversed};

  // Header & payload mapping

  assign {
    ecpri_version,
    ecpri_reserved,
    ecpri_concat,
    ecpri_messagetype,
    ecpri_payloadsize
  } = ecpri_header;

  // There is more than 4-byte so header presents
  always_comb begin
    ecpri_header_valid = 1'b0;
    if (stat_counter_next >= stat_counter_c + 4) begin
      ecpri_header_valid = 1'b1;
    end
  end

  always_comb begin
    ecpri_header = s_axis_tdata_c[8*stat_header_shift+31-:32];
  end

  always_comb begin
    ecpri_payload_valid = 1'b0;
    if (stat_counter_next >= stat_counter_h + 8) begin
      ecpri_payload_valid = 1'b1;
    end
  end

  always_comb begin
    ecpri_payload = s_axis_tdata_c[8*stat_payload_shift+63-:64];
  end


  // Packet Parser FSM

  // Total received bytes, not inculding current bytes
  always_ff @(posedge clk) begin
    if (rst) begin
      stat_counter <= '0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      stat_counter <= '0;
    end else if (s_axis_tvalid) begin
      stat_counter <= stat_counter + 8;
    end
  end

  // Received bytes at current tick
  always_comb begin
    stat_counter_next = stat_counter + 16'd8;
    if (s_axis_tvalid && s_axis_tlast) begin
      stat_counter_next = stat_counter + 16'(tkeep_size(s_axis_tkeep));
    end
  end

  // Message end postion
  always_ff @(posedge clk) begin
    if (rst) begin
      stat_counter_c <= '0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      stat_counter_c <= '0;
    end else if (s_axis_tvalid && ecpri_header_valid) begin
      stat_counter_c <= stat_counter_c + ecpri_payloadsize + 16'd4;
    end
  end

  // Message start postion
  always_ff @(posedge clk) begin
    if (rst) begin
      stat_counter_h <= 'd4;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      stat_counter_h <= 'd4;
    end else if (s_axis_tvalid && ecpri_header_valid) begin
      stat_counter_h <= stat_counter_c + 16'd4;
    end
  end

  always_comb begin
    stat_payload_shift = 3'(4'd8 - {1'b0, stat_counter_h[2:0]});
  end

  always_comb begin
    stat_header_shift = 3'(4'd4 - {1'b0, stat_counter_c[2:0]});
  end

  // In-phase last, marks last word of message
  always_comb begin
    if (s_axis_tvalid && s_axis_tlast) begin
      stat_last = 1'b1;
      // `stat_counter_c` indicates the end position of the section
      // This tick is last tick in section when we receive more bytes than `stat_counter_c`
      // but it should be only 0~7 bytes more. 8+ indicate the last is already generated
    end else if (s_axis_tvalid && (stat_counter_next >= stat_counter_c) &&
      (stat_counter_next - stat_counter_c < 16'd8)) begin
      stat_last = 1'b1;
    end else begin
      stat_last = 1'b0;
    end
  end

  // eCPRI common header parse ports output

  always_ff @(posedge clk) begin
    if (ecpri_header_valid && s_axis_tvalid) begin
      m_ecpri_concat      <= ecpri_concat;
      m_ecpri_messagetype <= ecpri_messagetype;
      m_ecpri_payloadsize <= ecpri_payloadsize;
    end
  end

  always_ff @(posedge clk) begin
    m_ecpri_header_valid <= ecpri_header_valid && s_axis_tvalid;
  end


  // Output

  // Extra TLAST for next clock tick
  always_ff @(posedge clk) begin
    extra_last <= 1'b0;
    if (s_axis_tvalid && stat_last && ((stat_counter_c[2:0] - 1) > (stat_counter_h[2:0] - 1))) begin
      extra_last <= 1'b1;
    end
  end

  // TDATA

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tdata <= byte_reverse(ecpri_payload);
    end else if (s_axis_tvalid && ecpri_payload_valid) begin
      m_axis_tdata <= byte_reverse(ecpri_payload);
    end
  end

  // TKEEP

  logic [7:0] stat_keep;
  logic [7:0] stat_keep_d;

  always_comb begin
    stat_keep = get_tkeep(3'(stat_counter_c - stat_counter_h));
  end

  always_ff @(posedge clk) begin
    stat_keep_d <= stat_keep;
  end

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tkeep <= stat_keep_d;
    end else if (ecpri_payload_valid && s_axis_tvalid && stat_last &&
      ((stat_counter_c[2:0] - 1) > (stat_counter_h[2:0] - 1))) begin
      m_axis_tkeep <= '1;
    end else if (ecpri_payload_valid && s_axis_tvalid && stat_last) begin
      m_axis_tkeep <= stat_keep;
    end else if (ecpri_payload_valid && s_axis_tvalid) begin
      m_axis_tkeep <= '1;
    end
  end

  // TVALID

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tvalid <= 1'b1;
    end else if (ecpri_payload_valid && s_axis_tvalid) begin
      m_axis_tvalid <= 1'b1;
    end else begin
      m_axis_tvalid <= 1'b0;
    end
  end

  // TLAST

  always_ff @(posedge clk) begin
    if (extra_last) begin
      m_axis_tlast <= 1'b1;
    end else if (ecpri_payload_valid) begin
      m_axis_tlast <= stat_last && !((stat_counter_c[2:0] - 1) > (stat_counter_h[2:0] - 1));
    end
  end

  // TDEST

  always_ff @(posedge clk) begin
    if (ecpri_header_valid && s_axis_tvalid) begin
      if (ecpri_messagetype == 0) begin
        tdest <= 2'b00;
      end else if (ecpri_messagetype == 2) begin
        tdest <= 2'b01;
      end else if (ecpri_messagetype == 5) begin
        tdest <= 2'b10;
      end else begin
        tdest <= 2'b11;
      end
    end
  end

  always_ff @(posedge clk) begin
    m_axis_tdest <= tdest;
  end

  // TUSER

  always_ff @(posedge clk) begin
    tuser <= s_axis_tuser;
  end

  always_ff @(posedge clk) begin
    m_axis_tuser <= tuser;
  end

endmodule

`default_nettype wire
