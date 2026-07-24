/*
 * eCPRI Deframer Demultiplexer
 *
 * This module filters out Precision Time Protocol (PTP) packets, non-eCPRI packets,
 * and eCPRI packets to their respective endpoints for further processing.
 *
 * TODO: TUSER marks the corrupted packet, we need to discard it
 *
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_deframer_demux (
    // Ethernet clock domain
    //----------------------
    input  wire        rx_eth_clk,
    input  wire        rx_eth_rst,
    //
    input  wire [31:0] s_axis_tdata,
    input  wire [ 3:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tuser,
    input  wire        s_axis_tvalid,
    //
    input  wire [79:0] rx_ptp_timestamp,
    input  wire        rx_ptp_timestamp_valid,
    // Internal clock domain
    //----------------------
    input  wire        clk,
    input  wire        rst,
    // eCPRI message
    output wire [31:0] m_axis_tdata,
    output wire [ 3:0] m_axis_tkeep,
    output wire        m_axis_tlast,
    output wire [79:0] m_axis_tuser,
    output wire        m_axis_tvalid,
    // PTP message
    output wire [31:0] m_ptp_tdata,
    output wire [ 3:0] m_ptp_tkeep,
    output wire        m_ptp_tlast,
    output wire [79:0] m_ptp_tuser,
    output wire        m_ptp_tvalid,
    // none-eCPRI message
    output wire [31:0] m_message_tdata,
    output wire [ 3:0] m_message_tkeep,
    output wire        m_message_tlast,
    output wire        m_message_tvalid,
    // Control & Status
    //-----------------
    output wire        stat_corrupt_pkt
);

  `include "ecpri_pkg.vh"

  // Parameters

  localparam integer AddrWidth = 12;
  localparam integer DataWidth = 37;

  localparam integer FiFoDepth = 2 ** (AddrWidth - 4);
  localparam integer FiFoDataWidth = 108;

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
  localparam integer S_DISCARD = 6;  // Discard the packet

  // Signals

  wire [             31:0] s_axis_tdata_reversed;

  wire [             15:0] mac_ethertype;

  wire                     wr_en;
  reg  [    AddrWidth-1:0] wr_addr;
  reg  [    AddrWidth-1:0] wr_addr_last;
  reg  [    AddrWidth-1:0] wr_addr_next;
  wire [    DataWidth-1:0] wr_data;

  wire                     rd_en;
  reg                      rd_en_d;
  reg                      rd_en_dd;
  reg  [    AddrWidth-1:0] rd_addr;
  wire [    AddrWidth-1:0] rd_addr_next;
  wire [    DataWidth-1:0] rd_data;
  reg  [    DataWidth-1:0] rd_data_r;

  reg                      packet_valid;
  reg  [             15:0] packet_ethertype;
  reg  [             79:0] packet_timestamp;

  wire                     fifo_wr_en;
  wire [FiFoDataWidth-1:0] fifo_wr_din;

  wire                     fifo_rd_en;
  wire [FiFoDataWidth-1:0] fifo_rd_dout;
  wire                     fifo_rd_empty;

  wire                     packet_valid_s;
  wire [             15:0] packet_ethertype_s;
  wire [             79:0] packet_timestamp_s;

  reg                      corrupt_pkt_pulse;

  integer state, state_next;

  // Main

  // Byte reverse AXIS data, this looks more clear
  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  assign mac_ethertype = s_axis_tdata_reversed[31:16];

  // Packet parser FSM
  // The state is sync with input data stream and parse to get the EtherType
  // field

  always @(posedge rx_eth_clk) begin
    if (rx_eth_rst) begin
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
        state_next = S_DMACH;
      end

      S_DMACH: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMACH;
        end else if (s_axis_tvalid && s_axis_tuser) begin
          state_next = S_DISCARD;
        end else if (s_axis_tvalid) begin
          state_next = S_DMACL_SMACH;
        end
      end

      S_DMACL_SMACH: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMACH;
        end else if (s_axis_tvalid && s_axis_tuser) begin
          state_next = S_DISCARD;
        end else if (s_axis_tvalid) begin
          state_next = S_SMACL;
        end
      end

      S_SMACL: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMACH;
        end else if (s_axis_tvalid && s_axis_tuser) begin
          state_next = S_DISCARD;
        end else if (s_axis_tvalid) begin
          state_next = S_ETYPE;
        end
      end

      S_ETYPE: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMACH;
        end else if (s_axis_tvalid && s_axis_tuser) begin
          state_next = S_DISCARD;
        end else if (s_axis_tvalid) begin
          // Check EtherType field, if it's VLAN, we need to skip it and check
          // again.
          if (mac_ethertype == EtherTypeVlan) begin
            state_next = S_ETYPE;
          end else begin
            state_next = S_PAYLOAD;
          end
        end
      end

      S_PAYLOAD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_DMACH;
        end else if (s_axis_tvalid && s_axis_tuser) begin
          state_next = S_DISCARD;
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

  // Write to RAM

  assign wr_en = s_axis_tvalid;

  always @(posedge rx_eth_clk) begin
    if (rx_eth_rst) begin
      wr_addr <= 0;
    end else if ((state == S_DMACH) && s_axis_tvalid && s_axis_tuser) begin
      // We received TUSER at first tick of the packet, we already marked the
      // packet as corrupted to discard it
      wr_addr <= wr_addr;
    end else if ((state == S_DISCARD) && s_axis_tvalid) begin
      wr_addr <= wr_addr;
    end else if (s_axis_tvalid && s_axis_tuser) begin
      // We received TUSER, revert to last address
      wr_addr <= wr_addr_last;
    end else if (s_axis_tvalid) begin
      wr_addr <= wr_addr + 1'b1;
    end
  end

  // Register the address at the first tick of the packet, in the case of we need to
  // discard the packet
  always @(posedge rx_eth_clk) begin
    if (rx_eth_rst) begin
      wr_addr_last <= 0;
    end else if ((state == S_DMACH) && s_axis_tvalid) begin
      wr_addr_last <= wr_addr;
    end
  end

  always @(posedge rx_eth_clk) begin
    if ((state == S_PAYLOAD) && s_axis_tvalid && s_axis_tlast && ~s_axis_tuser) begin
      wr_addr_next <= wr_addr;
    end
  end

  assign wr_data = {s_axis_tlast, s_axis_tkeep, s_axis_tdata};

  // Packet done

  // We successfully received the last byte of the packet, so we can use the current
  // address as the next address
  always @(posedge rx_eth_clk) begin
    packet_valid <= ((state == S_PAYLOAD) && s_axis_tvalid && s_axis_tlast && ~s_axis_tuser);
  end

  // Assume the timestamp is valid at first clock tick of the packet, so we
  // can ignore the `rx_ptp_timestamp_valid` signal
  always @(posedge rx_eth_clk) begin
    if ((state == S_DMACH) && s_axis_tvalid) begin
      packet_timestamp <= rx_ptp_timestamp;
    end
  end

  always @(posedge rx_eth_clk) begin
    if ((state == S_ETYPE) && (mac_ethertype != EtherTypeVlan) && s_axis_tvalid) begin
      packet_ethertype <= mac_ethertype;
    end
  end

  // Status output

  always @(posedge rx_eth_clk) begin
    corrupt_pkt_pulse <= ((state == S_DMACH) || (state == S_DMACL_SMACH) ||
      (state == S_SMACL) || (state == S_ETYPE) || (state == S_PAYLOAD)) &&
      s_axis_tvalid && s_axis_tuser;
  end

  // FIFO

  assign fifo_wr_en = packet_valid;
  assign fifo_wr_din = {packet_ethertype, packet_timestamp, wr_addr_next};

  assign packet_valid_s = ~fifo_rd_empty;
  assign {packet_ethertype_s, packet_timestamp_s, rd_addr_next} = fifo_rd_dout;
  assign fifo_rd_en = (rd_addr == rd_addr_next);

  // Read side

  assign rd_en = packet_valid_s;

  always @(posedge clk) begin
    rd_en_d  <= rd_en;
    rd_en_dd <= rd_en_d;
  end

  always @(posedge clk) begin
    if (rst) begin
      rd_addr <= 0;
    end else if (rd_en) begin
      rd_addr <= rd_addr + 1'b1;
    end
  end

  always @(posedge clk) begin
    if (rd_en_dd) begin
      rd_data_r <= rd_data;
    end
  end

  // AXI Output

  assign {m_axis_tlast, m_axis_tkeep, m_axis_tdata} = rd_data_r;
  assign m_axis_tuser = packet_timestamp_s;

  assign {m_ptp_tlast, m_ptp_tkeep, m_ptp_tdata} = rd_data_r;
  assign m_ptp_tuser = packet_timestamp_s;

  assign {m_message_tlast, m_message_tkeep, m_message_tdata} = rd_data_r;

  // Buffer

  ram_sdp #(
      .ADDR_WIDTH  (AddrWidth),
      .DATA_WIDTH  (DataWidth),
      .READ_LATENCY(2),
      .INIT_WORD   (0),
      .INIT_FILE   ("")
  ) i_ram (
      .clka (rx_eth_clk),
      .ena  (wr_en),
      .wea  (wr_en),
      .addra(wr_addr),
      .dina (wr_data),
      //
      .clkb (clk),
      .rstb ({rst, rst}),
      .enb  ({rd_en_d, rd_en}),
      .addrb(rd_addr),
      .doutb(rd_data)
  );

  fifo_async #(
      .FIFO_DEPTH  (FiFoDepth),
      .FIFO_LATENCY(2),
      .DATA_WIDTH  (FiFoDataWidth)
  ) i_fifo_async (
      .rst     (rx_eth_rst),
      //
      .wr_clk  (rx_eth_clk),
      .wr_en   (fifo_wr_en),
      .wr_din  (fifo_wr_din),
      .wr_full (),
      //
      .rd_clk  (clk),
      .rd_en   (fifo_rd_en),
      .rd_dout (fifo_rd_dout),
      .rd_empty(fifo_rd_empty)
  );

  delay #(
      .WIDTH(1),
      .DEPTH(3)
  ) i_delay_axis_tvalid (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (packet_valid_s && (packet_ethertype_s == EtherTypeEcpri)),
      //
      .dout(m_axis_tvalid)
  );

  delay #(
      .WIDTH(1),
      .DEPTH(3)
  ) i_delay_ptp_tvalid (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .din (packet_valid_s && (packet_ethertype_s == EtherTypePtp)),
      .dout(m_ptp_tvalid)
  );

  delay #(
      .WIDTH(1),
      .DEPTH(3)
  ) i_delay_message_tvalid (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .din (packet_valid_s && (packet_ethertype_s != EtherTypeEcpri) &&
        (packet_ethertype_s != EtherTypePtp)),
      .dout(m_message_tvalid)
  );

  cdc_pulse #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .REG_OUTPUT  (0),
      .RST_USED    (1)
  ) i_cdc_pulse_corrupt_pkt (
      .src_clk   (rx_eth_clk),
      .src_rst   (rx_eth_rst),
      .src_pulse (corrupt_pkt_pulse),
      //
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(stat_corrupt_pkt)
  );

endmodule

`default_nettype wire
