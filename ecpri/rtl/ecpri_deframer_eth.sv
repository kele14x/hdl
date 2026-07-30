/*
 * eCPRI Deframer Ethernet
 *
 * This module does the following:
 * - Filter out none eCPRI packets
 * - Remove MAC header, which is not useful for following processing
 * - Handles VLAN packets
 *
 * Latency is 4 clocks for VLAN packet, and 3 for none-VLAN packet
 * Payload latency is 2 clocks
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_deframer_eth (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [31:0] s_axis_tdata,
    input  wire [ 3:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tvalid,
    input  wire [79:0] s_axis_tuser,
    //
    output logic  [31:0] m_axis_tdata,
    output logic  [ 3:0] m_axis_tkeep,
    output logic         m_axis_tlast,
    output logic         m_axis_tvalid,
    output logic  [79:0] m_axis_tuser,
    //
    output logic         m_mac_header_valid,
    output logic  [47:0] m_mac_dest_mac,
    output logic  [47:0] m_mac_source_mac,
    output logic         m_mac_with_vlan,
    output logic  [15:0] m_mac_vlan_tag,
    output logic  [15:0] m_mac_ethertype
);

  import ecpri_pkg::*;

  // FSM states

  // MAC Header has 112 (14) or 144 (18) bits (bytes) including:
  // - Destination MAC:  48 (6)
  // - Source MAC:       48 (6)
  // - EtherType/Length: 16 (2)
  // - VLAN Tag:         16 (2), if previous EtherType is VLAN
  // - EtherType:        16 (2), if previous EtherType is VLAN

  localparam integer S_RST = 0;  // Under reset
  localparam integer S_DMACH = 1;  // Destination MAC [47:16]
  localparam integer S_DMACL_SMACH = 2;  // Destination MAC [15:0] and Source MAC [47:32]
  localparam integer S_SMACL = 3;  // Source MAC [31:0]
  localparam integer S_ETYPE = 4;  // EtherType (2) and Payload (2)
  localparam integer S_PAYLOAD = 5;  // Actually eCPRI Payload
  localparam integer S_DISCARD = 6;  // Not eCPRI Payload

  // Signals

  wire [31:0] s_axis_tdata_reversed;
  logic  [15:0] s_axis_tdata_d;  // also byte reversed

  logic  [ 3:0] s_axis_tkeep_d;

  wire        unused_tkeep_d = &{1'b0, s_axis_tkeep_d[1:0]};

  wire [47:0] mac_dest_mac;
  wire [47:0] mac_source_mac;
  wire        mac_with_vlan;
  wire [15:0] mac_vlan_tag;
  wire [15:0] mac_ethertype;

  logic         additional_tlast;

  integer state, state_next;

  // Main

  // Byte reverse AXIS data, this looks more clear
  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  // Register TDATA & TKEEP for later use

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      s_axis_tdata_d <= s_axis_tdata_reversed[15:0];
    end
  end

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      s_axis_tkeep_d <= s_axis_tkeep;
    end
  end

  // MAC Header Parse

  assign mac_dest_mac[47:16] = s_axis_tdata_reversed;

  assign {mac_dest_mac[15:0], mac_source_mac[47:32]} = s_axis_tdata_reversed;

  assign mac_source_mac[31:0] = s_axis_tdata_reversed;

  assign mac_ethertype = s_axis_tdata_reversed[31:16];

  assign mac_vlan_tag = s_axis_tdata_reversed[15:0];

  assign mac_with_vlan = (mac_ethertype == ECPRI_ETHERTYPE_VLAN);

  // Packet filter FSM
  // Ethernet packets are filtered by Ethertype field. If it's Ethertype field
  // is VLAN, we need to skip the 32-bit VLAN type & tag and check again.

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    // Stay at current state by default
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_DMACH;
      end

      S_DMACH: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMACH;
        end else if (s_axis_tvalid) begin
          state_next = S_DMACL_SMACH;
        end
      end

      S_DMACL_SMACH: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMACH;
        end else if (s_axis_tvalid) begin
          state_next = S_SMACL;
        end
      end

      S_SMACL: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMACH;
        end else if (s_axis_tvalid) begin
          state_next = S_ETYPE;
        end
      end

      S_ETYPE: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMACH;
        end else if (s_axis_tvalid) begin
          // Check EtherType field, if it's VLAN, we need to skip it and check
          // again. If it's eCPRI message, we goes to S_PAYLOAD. Other type
          // means we need to discard the entire packet.
          if (mac_ethertype == ECPRI_ETHERTYPE_VLAN) begin
            state_next = S_ETYPE;
          end else if (mac_ethertype == ECPRI_ETHERTYPE_ECPRI) begin
            state_next = S_PAYLOAD;
          end else begin
            state_next = S_DISCARD;
          end
        end
      end

      S_PAYLOAD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMACH;
        end
      end

      S_DISCARD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMACH;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // When we are waiting for payload and a valid TLAST received we need
  // to know if we still need an additional tick to write remained data
  // This happens at:
  //    We received 3 or more bytes when TLAST is assert
  always_ff @(posedge clk) begin
    additional_tlast <= 1'b0;
    if (state == S_PAYLOAD && s_axis_tvalid && s_axis_tlast) begin
      if (s_axis_tkeep[2]) begin
        additional_tlast <= 1'b1;
      end
    end
  end

  // Parse ports

  always_ff @(posedge clk) begin
    if (state == S_ETYPE && s_axis_tvalid && ~mac_with_vlan) begin
      m_mac_header_valid <= 1'b1;
    end else begin
      m_mac_header_valid <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_DMACH) && s_axis_tvalid) begin
      m_mac_dest_mac[47:16] <= mac_dest_mac[47:16];
    end
    if ((state == S_DMACL_SMACH) && s_axis_tvalid) begin
      m_mac_dest_mac[15:0] <= mac_dest_mac[15:0];
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_DMACL_SMACH) && s_axis_tvalid) begin
      m_mac_source_mac[47:32] <= mac_source_mac[47:32];
    end
    if ((state == S_SMACL) && s_axis_tvalid) begin
      m_mac_source_mac[31:0] <= mac_source_mac[31:0];
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_ETYPE) && s_axis_tvalid) begin
      m_mac_with_vlan <= mac_with_vlan;
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_ETYPE) && s_axis_tvalid && mac_with_vlan) begin
      m_mac_vlan_tag <= mac_vlan_tag;
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_ETYPE) && s_axis_tvalid && ~mac_with_vlan) begin
      m_mac_ethertype <= mac_ethertype;
    end
  end

  // Output

  // If `m_mac_with_vlan`, 6 bytes from previous TDATA and 2 bytes from current TDATA
  // if not, 2 bytes from previous TDATA and 6 bytes from current TDATA

  always_ff @(posedge clk) begin
    if (((state == S_PAYLOAD) && s_axis_tvalid) || additional_tlast) begin
      m_axis_tdata <= byte_reverse({s_axis_tdata_d, s_axis_tdata_reversed[31:16]});
    end
  end

  always_ff @(posedge clk) begin
    if (additional_tlast) begin
      m_axis_tkeep <= {2'b00, s_axis_tkeep_d[3:2]};
    end else if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tkeep <= {s_axis_tkeep[1:0], 2'b11};
    end
  end

  always_ff @(posedge clk) begin
    if (((state == S_PAYLOAD) && s_axis_tvalid) || additional_tlast) begin
      m_axis_tlast <= 1'b0;
      if (additional_tlast) begin
        m_axis_tlast <= 1'b1;
      end else if ((state == S_PAYLOAD) && s_axis_tvalid && s_axis_tlast) begin
        if (!s_axis_tkeep[2]) begin
          m_axis_tlast <= 1'b1;
        end
      end
    end
  end

  // Assume the timestamp is valid at first clock tick of the packet
  always_ff @(posedge clk) begin
    if ((state == S_DMACH) && s_axis_tvalid) begin
      m_axis_tuser <= s_axis_tuser;
    end
  end

  always_ff @(posedge clk) begin
    m_axis_tvalid <= ((state == S_PAYLOAD) && s_axis_tvalid) || additional_tlast;
  end

endmodule

`default_nettype wire
