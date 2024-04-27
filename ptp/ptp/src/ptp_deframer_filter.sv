// File: ptp_deframer_filter.sv
// Brief: This module does the following:
//        - Filter out none PTP packets
//        - Remove MAC header, which is not useful for following processing
//        - Handles VLAN packets
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_deframer_filter (
    input var         clk,
    input var         rst,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    input var  [79:0] s_axis_tuser,        // Rx TS
    // DL Carrier ports
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    output var [79:0] m_axis_tuser,
    //
    output var        m_mac_header_valid,
    output var [47:0] m_mac_dest_mac,
    output var [47:0] m_mac_source_mac,
    output var        m_mac_with_vlan,
    output var [15:0] m_mac_vlan_tag,
    output var [15:0] m_mac_ethertype
);

  import ptp_pkg::*;

  logic [63:0] s_axis_tdata_reversed;
  logic [63:0] s_axis_tdata_d;  // also byte reversed

  logic [ 7:0] s_axis_tkeep_d;

  logic [47:0] mac_dest_mac;
  logic [47:0] mac_source_mac;
  logic        mac_with_vlan;
  logic [15:0] mac_vlan_tag;
  logic [15:0] mac_ethertype0;
  logic [15:0] mac_ethertype1;

  // MAC Header has 112 (14) or 144 (18) bits (1.75 or 2.25 words) including:
  // Destination MAC, 48-bit (6)
  // Source MAC, 48-bit (6)
  // EtherType/Length, 16-bit (2)
  // VLAN Tag, 16-bit (2), if previous EtherType is VLAN
  // EtherType, 16-bit (2), if previous EtherType is VLAN

  typedef enum int {
    S_RST,          // Under reset
    S_DMAC_SMAC0,   // Wait for Destination MAC [47:0] (6) and Source MAC [47:32] (2)
    S_SMAC1_ETYPE,  // Waif for Source MAC [31:0] (4) and EtherType [15:0] (2)
                    //   and possible Payload (2) or VLAN Tag (2)
    S_ETYPE,        // We see VLAN Type, so this is EtherType (2) and Payload (6)
    S_PAYLOAD,      // Actually eCPRI Payload
    S_LAST,         // Remained word of payload, this assume there always be
                    //   at least 1 clock gap between packets. This should be valid
                    //   for Xilinx Ethernet MAC IP
    S_DISCARD       // Not eCPRI Payload
  } state_t;

  state_t state, state_next;


  // Main
  //-----

  // Byte reverse AXIS data, this looks more clear

  always_comb begin
    s_axis_tdata_reversed = byte_reverse(s_axis_tdata);
  end

  // Register TDATA & TKEEP for later use

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      s_axis_tdata_d <= s_axis_tdata_reversed;
    end
  end

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      s_axis_tkeep_d <= s_axis_tkeep;
    end
  end


  // MAC Header Parse

  assign {mac_dest_mac, mac_source_mac[47:32]} = s_axis_tdata_reversed;

  assign {mac_source_mac[31:0], mac_ethertype0, mac_vlan_tag} = s_axis_tdata_reversed;

  assign mac_with_vlan = (mac_ethertype0 == EthertypeVlan);

  assign mac_ethertype1 = s_axis_tdata_reversed[63:48];

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
        state_next = S_DMAC_SMAC0;
      end

      S_DMAC_SMAC0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC_SMAC0;
        end else if (s_axis_tvalid) begin
          state_next = S_SMAC1_ETYPE;
        end
      end

      S_SMAC1_ETYPE: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC_SMAC0;
        end else if (s_axis_tvalid) begin
          // Check EtherType field, if it's VLAN, we need to skip it and check
          // again. If it's eCPRI message, we goes to S_PAYLOAD. Other type
          // means we need to discard the entire packet.
          if (mac_ethertype0 == EthertypeVlan) begin
            state_next = S_ETYPE;
          end else if (mac_ethertype0 == EthertypePtp) begin
            state_next = S_PAYLOAD;
          end else begin
            state_next = S_DISCARD;
          end
        end
      end

      S_ETYPE: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC_SMAC0;
        end else if (s_axis_tvalid) begin
          if (mac_ethertype1 == EthertypePtp) begin
            state_next = S_PAYLOAD;
          end else begin
            state_next = S_DISCARD;
          end
        end
      end

      S_PAYLOAD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          // When we are waiting for payload and a valid TLAST received we need
          // to know if we still need an additional tick to write remained data
          // This happens at:
          //    We received 3 or more bytes when with VLAN
          //    We received 7 or more bytes when w/o VLAN
          if (s_axis_tkeep[2] && m_mac_with_vlan) begin
            state_next = S_LAST;
          end else if (s_axis_tkeep[6] && !m_mac_with_vlan) begin
            state_next = S_LAST;
          end else begin
            state_next = S_DMAC_SMAC0;
          end
        end else begin
          state_next = S_PAYLOAD;
        end
      end

      S_LAST: begin
        state_next = S_DMAC_SMAC0;
      end

      S_DISCARD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMAC_SMAC0;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end


  // Parse ports

  always_ff @(posedge clk) begin
    if (state == S_DMAC_SMAC0 && s_axis_tvalid) begin
      m_mac_dest_mac <= mac_dest_mac;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_SMAC1_ETYPE && s_axis_tvalid && mac_ethertype0 != EthertypeVlan) begin
      m_mac_header_valid <= 1'b1;
    end else if (state == S_ETYPE && s_axis_tvalid) begin
      m_mac_header_valid <= 1'b1;
    end else begin
      m_mac_header_valid <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_DMAC_SMAC0) begin
      m_mac_source_mac[47:32] <= mac_source_mac[47:32];
    end
    if (state == S_SMAC1_ETYPE && s_axis_tvalid) begin
      m_mac_source_mac[31:0] <= mac_source_mac[31:0];
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_SMAC1_ETYPE && s_axis_tvalid) begin
      m_mac_with_vlan <= mac_with_vlan;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_SMAC1_ETYPE && s_axis_tvalid && mac_with_vlan) begin
      m_mac_vlan_tag <= mac_vlan_tag;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_SMAC1_ETYPE && s_axis_tvalid && !mac_with_vlan) begin
      m_mac_ethertype <= mac_ethertype0;
    end else if (state == S_ETYPE && s_axis_tvalid) begin
      m_mac_ethertype <= mac_ethertype1;
    end
  end


  // Output
  //

  // If `m_mac_with_vlan`, 6 bytes from previous TDATA and 2 bytes from current TDATA
  // if not, 2 bytes from previous TDATA and 6 bytes from current TDATA

  always_ff @(posedge clk) begin
    if ((state == S_PAYLOAD && s_axis_tvalid) || (state == S_LAST)) begin
      if (m_mac_with_vlan) begin
        m_axis_tdata <= byte_reverse({s_axis_tdata_d[47:0], s_axis_tdata_reversed[63:48]});
      end else begin
        m_axis_tdata <= byte_reverse({s_axis_tdata_d[15:0], s_axis_tdata_reversed[63:16]});
      end
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_PAYLOAD && s_axis_tvalid) || (state == S_LAST)) begin
      if (m_mac_with_vlan) begin
        m_axis_tkeep <= {s_axis_tkeep[1:0], s_axis_tkeep_d[7:2]};
      end else begin
        m_axis_tkeep <= {s_axis_tkeep[5:0], s_axis_tkeep_d[7:6]};
      end
    end
  end

  always_ff @(posedge clk) begin
    m_axis_tvalid <= (state == S_PAYLOAD && s_axis_tvalid) || (state == S_LAST);
  end

  always_ff @(posedge clk) begin
    if ((state == S_PAYLOAD && s_axis_tvalid) || (state == S_LAST)) begin
      m_axis_tlast <= 1'b0;
      if (state == S_LAST) begin
        m_axis_tlast <= 1'b1;
      end else if (state == S_PAYLOAD && s_axis_tvalid && s_axis_tlast) begin
        if (m_mac_with_vlan && !s_axis_tkeep[2]) begin
          m_axis_tlast <= 1'b1;
        end else if (!m_mac_with_vlan && !s_axis_tkeep[6]) begin
          m_axis_tlast <= 1'b1;
        end
      end
    end
  end

  // TUSER is marked by Ethernet MAC IP for corrupt packet
  always_ff @(posedge clk) begin
    if ((state == S_PAYLOAD && s_axis_tvalid) || (state == S_LAST)) begin
      m_axis_tuser <= s_axis_tuser;
    end
  end

endmodule

`default_nettype wire
