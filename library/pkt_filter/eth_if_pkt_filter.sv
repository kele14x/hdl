//-----------------------------------------------------------------------------
// File: eth_if_pkt_filter.sv
// Brief: Ethernet packet ingress filter. This module filters the incoming
//        packets from Ethernet MAC and ensures that eCPRI packets are not
//        forwarded to next module, which will floods DMA interface and cause
//        packet loss.
//
//        eCPRI packets are identified as:
//          - Raw Ethernet Type II packets with EtherType = 0xAEFE
//          - Raw Ethernet Type II packets with VLAN tag and EtherType = 0xAEFE
//
//        Currently, this module does not support:
//          -  IPv4/IPv6 over Ethernet with or without VLAN Tag
//-----------------------------------------------------------------------------
`timescale 1 ns / 1 ps `default_nettype none

module eth_if_pkt_filter #(
    parameter int ADDR_WIDTH = 12
) (
    input var         aclk,
    input var         aresetn,
    // Input
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    output var        s_axis_tready,
    // Sideband signal
    input var         s_mac_tuser,
    input var         s_mac_bad_fcs,
    input var  [79:0] s_mac_tstamp_out,
    input var         s_mac_tstamp_valid,
    // Output
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    input var         m_axis_tready,
    //
    output var [79:0] m_mac_tstamp_out,
    output var        m_mac_tstamp_valid
);

  // tdata + tkeep + tlast + tstamp + tstamp_valid
  localparam int DATA_WIDTH = (64 + 8 + 1 + 80 + 1);

  localparam logic [15:0] C_VLAN_TAG = 16'h8100;
  localparam logic [15:0] C_ECPRI_TAG = 16'hAEFE;

  typedef enum int {
    S_WR_RST,  // Under reset
    S_WR_WORD0,  // Wait word 0: {DEST_MAC[47:0], SRC_MAC[47:32]}
    S_WR_WORD1,   // Wait word 1: {SRC_MAC[31:0], ({ETH_TYPE_LENGTH[15:0], PAYLOAD[15:0]} | {VLAN_TPID[15:0], VLAN_TCI[15:0]})}
    S_WR_WORD2,  // Wait word 2: {ETH_TYPE_LENGTH[15:0], PAYLOAD[47:0]} if VLAN
    S_WR_PASS,  // Keep writing
    S_WR_DISCARD  // Discarded packet
  } wr_state_t;

  wr_state_t wr_state, wr_state_next;

  typedef enum int {
    S_RD_RST,    // Under reset
    S_RD_WAIT,   //
    S_RD_READ    //
  } rd_state_t;

  rd_state_t rd_state, rd_state_next;

  logic [63:0] tdata_reversed;

  // Writer
  logic [ADDR_WIDTH-1:0] wr_addr, wr_addr_next, wr_addr_last;
  logic                  wr_we;
  logic [DATA_WIDTH-1:0] wr_data;

  logic                  wr_full;

  // Reader
  logic [ADDR_WIDTH-1:0] rd_addr;
  logic [           2:0] rd_en, rd_vld;
  logic [DATA_WIDTH-1:0] rd_data;

  logic                  rd_empty;

  // Read/Writ shared
  logic [ADDR_WIDTH-1:0] tail_addr;

  // This function reverse the byte order of AXIS data, as required by the difference
  // between the AXI4-Stream and Ethernet stream interfaces.
  function automatic [63:0] byte_reverse(input [63:0] data);
    begin
      return {
        data[7:0],
        data[15:8],
        data[23:16],
        data[31:24],
        data[39:32],
        data[47:40],
        data[55:48],
        data[63:56]
      };
    end
  endfunction

  assign tdata_reversed = byte_reverse(s_axis_tdata);


  // Writer FSM
  //===========

  // wr_state Machine
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      wr_state <= S_WR_RST;
    end else begin
      wr_state <= wr_state_next;
    end
  end

  always_comb begin
    // by default stay at current state
    wr_state_next = wr_state;

    // state transfer
    case (wr_state)
      S_WR_RST: begin
        wr_state_next = S_WR_WORD0;
      end

      S_WR_WORD0: begin
        if (s_axis_tvalid) begin
          if (s_axis_tlast) begin
            wr_state_next = S_WR_WORD0;
          end else if (wr_full) begin
            wr_state_next = S_WR_DISCARD;
          end else begin
            wr_state_next = S_WR_WORD1;
          end
        end
      end

      S_WR_WORD1: begin
        if (s_axis_tvalid) begin
          if (s_axis_tlast) begin
            wr_state_next = S_WR_WORD0;
          end else if (wr_full || tdata_reversed[31:16] == C_ECPRI_TAG) begin
            wr_state_next = S_WR_DISCARD;
          end else if (tdata_reversed[31:16] == C_VLAN_TAG) begin
            wr_state_next = S_WR_WORD2;
          end else begin
            wr_state_next = S_WR_PASS;
          end
        end
      end

      S_WR_WORD2: begin
        if (s_axis_tvalid) begin
          if (s_axis_tlast) begin
            wr_state_next = S_WR_WORD0;
          end else if (wr_full || tdata_reversed[63:48] == C_ECPRI_TAG) begin
            wr_state_next = S_WR_DISCARD;
          end else begin
            wr_state_next = S_WR_PASS;
          end
        end
      end

      S_WR_PASS: begin
        if (s_axis_tvalid) begin
          if (s_axis_tlast) begin
            wr_state_next = S_WR_WORD0;
          end else if (wr_full) begin
            wr_state_next = S_WR_DISCARD;
          end
        end
      end

      S_WR_DISCARD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          wr_state_next = S_WR_WORD0;
        end
      end

      default: begin
        wr_state_next = S_WR_RST;
      end
    endcase
  end

  // This buffer will mostly be ready
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      s_axis_tready <= 1'b0;
    end else begin
      s_axis_tready <= (wr_state_next == S_WR_WORD0 || wr_state_next == S_WR_WORD1 ||
        wr_state_next == S_WR_WORD2 || wr_state_next == S_WR_PASS || wr_state_next == S_WR_DISCARD);
    end
  end

  // When first word of packet is received, temporarily save current writing
  // address to `wr_addr_last`. We may fall back to this address if the packet
  // looks not good or the buffer is full.
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      wr_addr_last <= '0;
    end else if (wr_state == S_WR_WORD0 && s_axis_tvalid) begin
      wr_addr_last <= wr_addr;
    end
  end

  // Writing address increases based on whether the packet is good, and whether
  // the buffer is full
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      wr_addr <= '0;
    end else begin
      wr_addr <= wr_addr_next;
    end
  end

  always_comb begin
    // by default `wr_addr` is not changed
    wr_addr_next = wr_addr;

    // wr_addr change
    case (wr_state)
      S_WR_WORD0: begin
        if (s_axis_tvalid && !s_axis_tlast && !wr_full) begin
          wr_addr_next = wr_addr + 1;
        end
      end

      S_WR_WORD1: begin
        if (s_axis_tvalid) begin
          if (s_axis_tlast) begin
            wr_addr_next = wr_addr_last;
          end else if (wr_full || tdata_reversed[31:16] == C_ECPRI_TAG) begin
            wr_addr_next = wr_addr_last;
          end else begin
            wr_addr_next = wr_addr + 1;
          end
        end
      end

      S_WR_WORD2: begin
        if (s_axis_tvalid) begin
          if (s_axis_tlast) begin
            wr_addr_next = wr_addr_last;
          end else if (wr_full || tdata_reversed[63:48] == C_ECPRI_TAG) begin
            wr_addr_next = wr_addr_last;
          end else begin
            wr_addr_next = wr_addr + 1;
          end
        end
      end

      S_WR_PASS: begin
        if (s_axis_tvalid) begin
          if (wr_full) begin
            wr_addr_next = wr_addr_last;
          end else begin
            wr_addr_next = wr_addr + 1;
          end
        end
      end

      default: begin
        wr_addr_next = wr_addr;
      end
    endcase
  end

  assign wr_we = s_axis_tvalid && (wr_state == S_WR_WORD0 || wr_state == S_WR_WORD1 ||
      wr_state == S_WR_WORD2 || wr_state == S_WR_PASS) && !wr_full;

  // We does not need to write tvalid and tready, tuser and bad_fcs flag
  assign wr_data = {s_mac_tstamp_valid, s_mac_tstamp_out, s_axis_tlast, s_axis_tkeep, s_axis_tdata};

  assign wr_full = (wr_addr == rd_addr - 1);


  // Shared
  //=======

  // tail_addr points to the end address of last received packet
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      tail_addr <= '0;
    end else if (wr_state == S_WR_PASS && s_axis_tvalid && s_axis_tlast && !wr_full) begin
      tail_addr <= wr_addr + 1;
    end
  end


  // Reader FSM
  //===========

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      rd_state <= S_RD_RST;
    end else begin
      rd_state <= rd_state_next;
    end
  end

  always_comb begin
    // By default stays at current state
    rd_state_next = rd_state;

    // State transfer
    case (rd_state)
      S_RD_RST: begin
        rd_state_next = S_RD_WAIT;
      end

      S_RD_WAIT: begin
        if (!rd_empty) begin
          rd_state_next = S_RD_READ;
        end
      end

      S_RD_READ: begin
        if (rd_empty) begin
          rd_state_next = S_RD_WAIT;
        end
      end

      default: begin
        rd_state_next = S_RD_RST;
      end
    endcase
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      rd_addr <= '0;
    end else if (rd_state == S_RD_READ && (!rd_vld[1] || m_axis_tready) && !rd_empty) begin
      rd_addr <= rd_addr + 1;
    end else begin
      rd_addr <= rd_addr;
    end
  end

  assign rd_en[0] = (rd_state == S_RD_READ) && (!rd_vld[1] || m_axis_tready) && !rd_empty;

  assign rd_en[1] = rd_vld[0] && (!rd_vld[2] || m_axis_tready);

  assign rd_en[2] = rd_vld[1] && m_axis_tready;

  assign rd_empty = (rd_addr == tail_addr);

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      rd_vld <= '0;
    end else begin
      rd_vld <= rd_en;
    end
  end

  // Output AXIS interface

  assign {m_mac_tstamp_valid, m_mac_tstamp_out, m_axis_tlast, m_axis_tkeep, m_axis_tdata} = rd_data;

  assign m_axis_tvalid = rd_vld[2];


  // The Buffer
  //===========

  bram_sdp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(3),
      .INIT_WORD   ('0),
      .INIT_FILE   ("")
  ) i_buffer (
      // Port A
      .clka (aclk),
      .ena  (wr_we),
      .wea  (wr_we),
      .addra(wr_addr),
      .dina (wr_data),
      // Port B
      .clkb (aclk),
      .rstb (1'b0),
      .enb  (rd_en),
      .addrb(rd_addr),
      .doutb(rd_data)
  );

endmodule

`default_nettype none
