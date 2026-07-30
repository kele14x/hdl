// File: oran_if.sv
// Brief: O-RAN Interface Slave IP Core
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_statistics #(
    parameter int NUM_ETHERNET_PORT = 1,
    parameter int NUM_ANTENNA_PORT = 2,
    parameter int NUM_CC = 1
) (
    input var         rx_eth_clk            [NUM_ETHERNET_PORT],
    input var         rx_eth_rst            [NUM_ETHERNET_PORT],
    //
    input var         clk,
    input var         rst,
    // Timer
    input var         defm_radio_start_10ms,
    // O-RAN Parse Ports
    //------------------
    input var         m_mac_header_valid    [NUM_ETHERNET_PORT],
    input var  [47:0] m_mac_dest_mac        [NUM_ETHERNET_PORT],
    input var  [47:0] m_mac_source_mac      [NUM_ETHERNET_PORT],
    input var         m_mac_with_vlan       [NUM_ETHERNET_PORT],
    input var  [15:0] m_mac_vlan_tag        [NUM_ETHERNET_PORT],
    input var  [15:0] m_mac_ethertype       [NUM_ETHERNET_PORT],
    //
    input var         m_ecpri_header_valid  [NUM_ETHERNET_PORT],
    input var         m_ecpri_concat        [NUM_ETHERNET_PORT],
    input var  [ 7:0] m_ecpri_messagetype   [NUM_ETHERNET_PORT],
    input var  [15:0] m_ecpri_payloadsize   [NUM_ETHERNET_PORT],
    //
    input var         m_trans_header_valid  [NUM_ETHERNET_PORT],
    input var  [15:0] m_trans_rtc_pc_id     [NUM_ETHERNET_PORT],
    input var  [ 7:0] m_trans_seqid         [NUM_ETHERNET_PORT],
    input var         m_trans_ebit          [NUM_ETHERNET_PORT],
    input var  [ 6:0] m_trans_subseqid      [NUM_ETHERNET_PORT],
    //
    input var         m_app_header_valid    [ NUM_ANTENNA_PORT][NUM_CC],
    input var         m_app_datadirection   [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 3:0] m_app_filterindex     [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 7:0] m_app_frameid         [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 3:0] m_app_subframeid      [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 5:0] m_app_slotid          [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 5:0] m_app_symbolid        [ NUM_ANTENNA_PORT][NUM_CC],
    input var         m_app_packet_in_window[ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 8:0] m_app_offset_in_symbol[ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 7:0] m_app_numsections     [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 2:0] m_app_sectiontype     [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 7:0] m_app_udcomphdr       [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [15:0] m_app_timeoffset      [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 7:0] m_app_framestructure  [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [15:0] m_app_cplength        [ NUM_ANTENNA_PORT][NUM_CC],
    //
    input var         m_section_header_valid[ NUM_ANTENNA_PORT][NUM_CC],
    input var  [11:0] m_section_sectionid   [ NUM_ANTENNA_PORT][NUM_CC],
    input var         m_section_rb          [ NUM_ANTENNA_PORT][NUM_CC],
    input var         m_section_syminc      [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 9:0] m_section_startprb    [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 7:0] m_section_numprb      [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [11:0] m_section_remask      [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 3:0] m_section_numsymbol   [ NUM_ANTENNA_PORT][NUM_CC],
    input var         m_section_ef          [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [14:0] m_section_beamid      [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [23:0] m_section_freqoffset  [ NUM_ANTENNA_PORT][NUM_CC],
    // Control & Status
    //-----------------
    input var         ctrl_tick_snap,
    input var         ctrl_tick_clear,
    //
    output var [47:0] stat_total_pkt_cnt,
    output var [47:0] stat_oran_pkt_cnt,
    output var [47:0] stat_ontime_pkt_cnt,
    output var [47:0] stat_early_pkt_cnt,
    output var [47:0] stat_late_pkt_cnt,
    //
    output var [ 8:0] stat_earliest_u_pkt,
    output var [ 8:0] stat_latest_u_pkt
);

  logic [ 7:0] frame_cnt;
  logic        clear_int;

  logic [47:0] total_pkt_cnt_per [NUM_ETHERNET_PORT];
  logic [47:0] oran_pkt_cnt_per  [NUM_ETHERNET_PORT];

  logic [47:0] ontime_pkt_cnt_per[ NUM_ANTENNA_PORT] [NUM_CC];
  logic [47:0] early_pkt_cnt_per [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [47:0] late_pkt_cnt_per  [ NUM_ANTENNA_PORT] [NUM_CC];

  logic [ 8:0] earliest_u_pkt_per[ NUM_ANTENNA_PORT] [NUM_CC];
  logic [ 8:0] latest_u_pkt_per  [ NUM_ANTENNA_PORT] [NUM_CC];

  wire unused_statistics_inputs = &{
    1'b0,
    rx_eth_rst,
    rst,
    m_mac_dest_mac,
    m_mac_source_mac,
    m_mac_with_vlan,
    m_mac_vlan_tag,
    m_mac_ethertype,
    m_ecpri_header_valid,
    m_ecpri_concat,
    m_ecpri_messagetype,
    m_ecpri_payloadsize,
    m_trans_rtc_pc_id,
    m_trans_seqid,
    m_trans_ebit,
    m_trans_subseqid,
    m_app_datadirection,
    m_app_filterindex,
    m_app_frameid,
    m_app_subframeid,
    m_app_slotid,
    m_app_symbolid,
    m_app_numsections,
    m_app_sectiontype,
    m_app_udcomphdr,
    m_app_timeoffset,
    m_app_framestructure,
    m_app_cplength,
    m_section_header_valid,
    m_section_sectionid,
    m_section_rb,
    m_section_syminc,
    m_section_startprb,
    m_section_numprb,
    m_section_remask,
    m_section_numsymbol,
    m_section_ef,
    m_section_beamid,
    m_section_freqoffset,
    ctrl_tick_snap,
    ctrl_tick_clear
  };

  // Use a local version for timing
  always_ff @(posedge clk) begin
    if (defm_radio_start_10ms) begin
      if (frame_cnt >= 99) begin
        frame_cnt <= '0;
      end else begin
        frame_cnt <= frame_cnt + 8'd1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (frame_cnt >= 99 && defm_radio_start_10ms) begin
      clear_int <= 1'b1;
    end else begin
      clear_int <= 1'b0;
    end
  end

  // Total packet counter

  generate
    for (genvar e = 0; e < NUM_ETHERNET_PORT; e++) begin : g_total_pkt_cnt
      always_ff @(posedge rx_eth_clk[e]) begin
        if (clear_int) begin
          total_pkt_cnt_per[e] <= '0;
        end else if (m_mac_header_valid[e]) begin
          total_pkt_cnt_per[e] <= total_pkt_cnt_per[e] + 1;
        end
      end
    end
  endgenerate

  always @(posedge rx_eth_clk[0]) begin
    logic [47:0] stat_total_pkt_cnt_c;
    if (clear_int) begin
      stat_total_pkt_cnt_c = 0;
      for (int e = 0; e < NUM_ETHERNET_PORT; e++) begin
        stat_total_pkt_cnt_c = stat_total_pkt_cnt_c + total_pkt_cnt_per[e];
      end
      stat_total_pkt_cnt <= stat_total_pkt_cnt_c;
    end
  end

  // O-RAN packet counter

  generate
    for (genvar e = 0; e < NUM_ETHERNET_PORT; e++) begin : g_oran_pkt_cnt
      always_ff @(posedge rx_eth_clk[e]) begin
        if (clear_int) begin
          oran_pkt_cnt_per[e] <= '0;
        end else if (m_trans_header_valid[e]) begin
          oran_pkt_cnt_per[e] <= oran_pkt_cnt_per[e] + 1;
        end
      end
    end
  endgenerate

  always @(posedge rx_eth_clk[0]) begin
    logic [47:0] stat_oran_pkt_cnt_c;
    if (clear_int) begin
      stat_oran_pkt_cnt_c = '0;
      for (int e = 0; e < NUM_ETHERNET_PORT; e++) begin
        stat_oran_pkt_cnt_c = stat_oran_pkt_cnt_c + oran_pkt_cnt_per[e];
      end
      stat_oran_pkt_cnt <= stat_oran_pkt_cnt_c;
    end
  end

  // On-time packet counter

  generate
    for (genvar i = 0; i < NUM_ANTENNA_PORT; i++) begin : g_ontime_ant
      for (genvar cc = 0; cc < NUM_ETHERNET_PORT; cc++) begin : g_ontime_eth
        always_ff @(posedge clk) begin
          if (clear_int) begin
            ontime_pkt_cnt_per[i][cc] <= '0;
          end else if (m_app_header_valid[i][cc] && m_app_packet_in_window[i][cc]) begin
            ontime_pkt_cnt_per[i][cc] <= ontime_pkt_cnt_per[i][cc] + 1;
          end
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    logic [47:0] stat_ontime_pkt_cnt_c;
    if (clear_int) begin
      stat_ontime_pkt_cnt_c = '0;
      for (int i = 0; i < NUM_ANTENNA_PORT; i++) begin
        for (int cc = 0; cc < NUM_ETHERNET_PORT; cc++) begin
          stat_ontime_pkt_cnt_c = stat_ontime_pkt_cnt_c + ontime_pkt_cnt_per[i][cc];
        end
      end
      stat_ontime_pkt_cnt <= stat_ontime_pkt_cnt_c;
    end
  end

  // Early packet counter

  generate
    for (genvar i = 0; i < NUM_ANTENNA_PORT; i++) begin : g_early_ant
      for (genvar cc = 0; cc < NUM_ETHERNET_PORT; cc++) begin : g_early_eth
        always_ff @(posedge clk) begin
          if (clear_int) begin
            early_pkt_cnt_per[i][cc] <= '0;
          end else if (m_app_header_valid[i][cc] && !m_app_packet_in_window[i][cc] && m_app_offset_in_symbol[i][cc] < 140) begin
            early_pkt_cnt_per[i][cc] <= early_pkt_cnt_per[i][cc] + 1;
          end
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    logic [47:0] stat_early_pkt_cnt_c;
    if (clear_int) begin
      stat_early_pkt_cnt_c = '0;
      for (int i = 0; i < NUM_ANTENNA_PORT; i++) begin
        for (int cc = 0; cc < NUM_ETHERNET_PORT; cc++) begin
          stat_early_pkt_cnt_c = stat_early_pkt_cnt_c + early_pkt_cnt_per[i][cc];
        end
      end
      stat_early_pkt_cnt <= stat_early_pkt_cnt_c;
    end
  end

  // Late packet counter

  generate
    for (genvar i = 0; i < NUM_ANTENNA_PORT; i++) begin : g_late_ant
      for (genvar cc = 0; cc < NUM_ETHERNET_PORT; cc++) begin : g_late_eth
        always_ff @(posedge clk) begin
          if (clear_int) begin
            late_pkt_cnt_per[i][cc] <= '0;
          end else if (m_app_header_valid[i][cc] && !m_app_packet_in_window[i][cc] && m_app_offset_in_symbol[i][cc] >= 140) begin
            late_pkt_cnt_per[i][cc] <= late_pkt_cnt_per[i][cc] + 1;
          end
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    logic [47:0] stat_late_pkt_cnt_c;
    if (clear_int) begin
      stat_late_pkt_cnt_c = '0;
      for (int i = 0; i < NUM_ANTENNA_PORT; i++) begin
        for (int cc = 0; cc < NUM_ETHERNET_PORT; cc++) begin
          stat_late_pkt_cnt_c = stat_late_pkt_cnt_c + late_pkt_cnt_per[i][cc];
        end
      end
      stat_late_pkt_cnt <= stat_late_pkt_cnt_c;
    end
  end

  // Earliest packet

  generate
    for (genvar i = 0; i < NUM_ANTENNA_PORT; i++) begin : g_earliest_ant
      for (genvar cc = 0; cc < NUM_ETHERNET_PORT; cc++) begin : g_earliest_eth
        always_ff @(posedge clk) begin
          if (clear_int) begin
            earliest_u_pkt_per[i][cc] <= '0;
          end else if (m_app_header_valid[i][cc] &&
            m_app_offset_in_symbol[i][cc] < 140 &&
            m_app_offset_in_symbol[i][cc] > earliest_u_pkt_per[i][cc]) begin
            earliest_u_pkt_per[i][cc] <= m_app_offset_in_symbol[i][cc];
          end
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    logic [8:0] stat_earliest_u_pkt_c;
    if (clear_int) begin
      stat_earliest_u_pkt_c = '0;
      for (int i = 0; i < NUM_ANTENNA_PORT; i++) begin
        for (int cc = 0; cc < NUM_ETHERNET_PORT; cc++) begin
          if (earliest_u_pkt_per[i][cc] > stat_earliest_u_pkt_c) begin
            stat_earliest_u_pkt_c = earliest_u_pkt_per[i][cc];
          end
        end
      end
      stat_earliest_u_pkt <= stat_earliest_u_pkt_c;
    end
  end

  // Latest packet

  generate
    for (genvar i = 0; i < NUM_ANTENNA_PORT; i++) begin : g_latest_ant
      for (genvar cc = 0; cc < NUM_ETHERNET_PORT; cc++) begin : g_latest_eth
        always_ff @(posedge clk) begin
          if (clear_int) begin
            latest_u_pkt_per[i][cc] <= '1;
          end else if (m_app_header_valid[i][cc] &&
            m_app_offset_in_symbol[i][cc] >= 140 &&
            m_app_offset_in_symbol[i][cc] < latest_u_pkt_per[i][cc]) begin
            latest_u_pkt_per[i][cc] <= m_app_offset_in_symbol[i][cc];
          end
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    logic [8:0] stat_latest_u_pkt_c;
    if (clear_int) begin
      stat_latest_u_pkt_c = '0;
      for (int i = 0; i < NUM_ANTENNA_PORT; i++) begin
        for (int cc = 0; cc < NUM_ETHERNET_PORT; cc++) begin
          if (latest_u_pkt_per[i][cc] < stat_latest_u_pkt_c) begin
            stat_latest_u_pkt_c = latest_u_pkt_per[i][cc];
          end
        end
      end
      stat_latest_u_pkt <= stat_latest_u_pkt_c;
    end
  end

endmodule

`default_nettype wire
