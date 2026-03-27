`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_ptp_lite;

  // Parameters

  localparam integer CLK_FREQ = 400000000;

  // Signals

  logic        clk;
  logic        rst;
  //
  logic [31:0] s_axis_tdata;
  logic [ 3:0] s_axis_tkeep;
  logic        s_axis_tlast;
  logic [79:0] s_axis_tuser;
  logic        s_axis_tvalid;
  logic        s_axis_tready;
  //
  logic [31:0] m_axis_tdata;
  logic [ 3:0] m_axis_tkeep;
  logic        m_axis_tlast;
  logic [17:0] m_axis_tuser;
  logic        m_axis_tvalid;
  logic        m_axis_tready;
  //
  logic [79:0] tx_ptp_timestamp;
  logic [15:0] tx_ptp_timestamp_tag;
  logic        tx_ptp_timestamp_valid;
  //
  logic        ctrl_master_en;
  logic [47:0] ctrl_src_mac;
  logic [ 7:0] ctrl_domain_number;
  logic [15:0] ctrl_utc_offset;
  logic [ 7:0] ctrl_log_announce_interval;
  logic [ 7:0] ctrl_log_sync_interval;

  logic [47:0] ts_s;
  logic [31:0] ts_ns;

  function void parse_packet(input bit [7:0] data[], input int len);
    int c;

    bit [47:0] dst_mac;
    bit [47:0] src_mac;
    bit [15:0] ether_type;

    bit [3:0] ptp_transport_specific;
    bit [3:0] ptp_message_type;
    bit [3:0] ptp_version_reserved0;
    bit [3:0] ptp_version_ptp;
    bit [15:0] ptp_message_length;
    bit [7:0] ptp_domain_number;
    bit [7:0] ptp_reserved1;
    bit [15:0] ptp_flag_field;
    bit [63:0] ptp_correction_field_length;
    bit [31:0] ptp_reserved2;
    bit [79:0] ptp_source_port_identity;
    bit [15:0] ptp_sequence_id;
    bit [7:0] ptp_control_field;
    bit [7:0] ptp_log_message_interval;

    c = 0;

    // Destination MAC address
    dst_mac = {data[c+0], data[c+1], data[c+2], data[c+3], data[c+4], data[c+5]};
    $display("Destination MAC address: %x", dst_mac);
    c += 6;

    // Source MAC address
    src_mac = {data[c+0], data[c+1], data[c+2], data[c+3], data[c+4], data[c+5]};
    $display("Source MAC address: %x", src_mac);
    c += 6;

    // EtherType
    forever begin
      ether_type = {data[c+0], data[c+1]};
      // Check if this is a VLAN tagged frame (0x8100)
      if (ether_type == 16'h8100) begin
        // VLAN tag is 4 bytes: 2 bytes for TPID (which is 0x8100) and 2 bytes for TCI
        $display("VLAN tagged frame");
        // Skip VLAN TCI (Tag Control Information)
        c += 4;
      end else begin
        break;
      end
    end
    $display("EtherType: %x", ether_type);
    c += 2;

    // Parse the PTP payload
    if (ether_type == 16'h88f7) begin
      $display("PTP frame");

      // transportSpecific/messageType
      ptp_transport_specific = data[c][7:4];
      ptp_message_type = data[c][3:0];
      case (ptp_message_type)
        4'h0: $display("Sync");
        4'h1: $display("Delay_Req");
        4'h2: $display("Pdelay_Req");
        4'h3: $display("Pdelay_Resp");
        4'h8: $display("Follow_Up");
        4'h9: $display("Delay_Resp");
        4'hA: $display("Pdelay_Resp_Follow_Up");
        4'hB: $display("Announce");
        4'hC: $display("Signaling");
        4'hD: $display("Management");
        default: $display("Unknown PTP message type: %x", ptp_message_type);
      endcase
      c += 1;

    end else begin
      $display("Non-PTP frame");
    end
  endfunction

  // DUT

  ptp_lite #(.CLK_FREQ(CLK_FREQ)) DUT (.*);

  // Clock & Reset

  initial begin
    clk = 0;
    forever #(1.25) clk = ~clk;
  end

  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst <= 0;
  end

  // Test

  initial begin
    $display("*** Simulation Start ***");
    //
    ctrl_master_en             = 1'b1;
    ctrl_src_mac               = 48'h00_15_5D_8F_5E_F0;
    ctrl_domain_number         = 8'd0;
    ctrl_utc_offset            = 16'd37;
    ctrl_log_announce_interval = -8'sd14;
    ctrl_log_sync_interval     = -8'sd15;
    //
    //
    #100000;
    //
    $finish;
  end

  final begin
    $display("*** Simulation End ***");
  end

  initial begin
    ts_s  = 0;
    ts_ns = 0;

    forever begin
      @(posedge clk);
      if (ts_ns >= 1_000_000_000 - 4) begin
        ts_s  <= ts_s + 1;
        ts_ns <= 0;
      end else begin
        ts_ns <= ts_ns + 4;
      end
    end
  end

  initial begin
    bit [ 7:0] data      [0:9999];
    int        i;

    bit        timestamp;
    bit [47:0] pts_s;
    bit [31:0] pts_ns;
    bit [15:0] tag;

    m_axis_tready = 1'b1;

    tx_ptp_timestamp = 0;
    tx_ptp_timestamp_tag = 0;
    tx_ptp_timestamp_valid = 0;

    // Receive and parse MI packet
    i = 0;
    forever begin
      @(posedge clk);
      if (m_axis_tvalid) begin

        // Check if the packet requires a timestamp at the first byte
        if (i == 0 && m_axis_tuser[17:16] == 2'b10) begin
          timestamp = 1'b1;
          pts_s     = ts_s;
          pts_ns    = ts_ns;
          tag       = m_axis_tuser[15:0];
        end else begin
          timestamp = 1'b0;
        end

        for (int b = 0; b < 4; b++) begin
          if (m_axis_tkeep[b]) begin
            data[i] = m_axis_tdata[b*8+7-:8];
            i++;
          end
        end

        if (m_axis_tlast) begin
          // This is end of the packet
          $display("MI packet received, length: %d", i);
          parse_packet(data, i);
          i = 0;

          // Set the timestamp if required
          if (timestamp) begin
            tx_ptp_timestamp       <= {pts_s, pts_ns};
            tx_ptp_timestamp_tag   <= tag;
            tx_ptp_timestamp_valid <= 1'b1;
            m_axis_tready          <= 1'b0;
            @(posedge clk);
            tx_ptp_timestamp_valid <= 1'b0;
            m_axis_tready          <= 1'b1;
          end
        end
      end
    end
  end

  initial begin
    bit sync_n;
    sync_n = 0;

    // Loopback the MI packet to SI interface
    forever begin
      @(posedge clk);

      // Sync with the first byte of the packet
      if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
        sync_n <= 0;
      end else if (m_axis_tvalid && m_axis_tready) begin
        sync_n <= 1;
      end

      s_axis_tdata <= m_axis_tdata;
      s_axis_tkeep <= m_axis_tkeep;
      s_axis_tlast <= m_axis_tlast;
      if (sync_n == 0) begin
        s_axis_tuser <= {ts_s, ts_ns};
      end
      s_axis_tvalid <= m_axis_tvalid;
    end
  end

endmodule

`default_nettype wire
