`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy0 (
    // AXI
    //----
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,
    //
    input  wire [ 11:0] s0_axi_awaddr,
    input  wire [  2:0] s0_axi_awprot,
    input  wire         s0_axi_awvalid,
    output wire         s0_axi_awready,
    //
    input  wire [ 31:0] s0_axi_wdata,
    input  wire [  3:0] s0_axi_wstrb,
    input  wire         s0_axi_wvalid,
    output wire         s0_axi_wready,
    //
    output wire [  1:0] s0_axi_bresp,
    output wire         s0_axi_bvalid,
    input  wire         s0_axi_bready,
    //
    input  wire [ 11:0] s0_axi_araddr,
    input  wire [  2:0] s0_axi_arprot,
    input  wire         s0_axi_arvalid,
    output wire         s0_axi_arready,
    //
    output wire [ 31:0] s0_axi_rdata,
    output wire [  1:0] s0_axi_rresp,
    output wire         s0_axi_rvalid,
    input  wire         s0_axi_rready,
    // ORAN-IF Interfaces
    //-------------------
    // Early BID ports
    input  wire [ 47:0] s00_defm_ebid_tdata,
    input  wire         s00_defm_ebid_tvalid,
    input  wire         s00_defm_ebid_tlast,
    output wire         s00_defm_ebid_tready,
    //
    input  wire [ 47:0] s00_fram_ebid_tdata,
    input  wire         s00_fram_ebid_tvalid,
    input  wire         s00_fram_ebid_tlast,
    output wire         s00_fram_ebid_tready,
    // PRACH C plane messages
    input  wire         s0_prach_tvalid,
    output wire         s0_prach_tready,
    input  wire [ 15:0] s0_prach_rtc_pc_id,
    input  wire [  3:0] s0_prach_cc,
    input  wire [  7:0] s0_prach_ss,
    input  wire [ 11:0] s0_prach_section_id,
    input  wire [  3:0] s0_prach_return_port,
    input  wire [  3:0] s0_prach_filter_index,
    input  wire [  7:0] s0_prach_f,
    input  wire [  3:0] s0_prach_sf,
    input  wire [  5:0] s0_prach_sl,
    input  wire [  5:0] s0_prach_sy,
    input  wire [ 15:0] s0_prach_time_offset,
    input  wire [  7:0] s0_prach_frame_structure,
    input  wire [ 15:0] s0_prach_cp_length,
    input  wire [  7:0] s0_prach_udcomphdr,
    input  wire         s0_prach_rb,
    input  wire         s0_prach_syminc,
    input  wire [  9:0] s0_prach_start_prbc,
    input  wire [  7:0] s0_prach_num_prbc,
    input  wire [ 11:0] s0_prach_remask,
    input  wire [  3:0] s0_prach_num_symbol,
    input  wire [ 14:0] s0_prach_beamid,
    input  wire [ 23:0] s0_prach_freqoffset,
    // Timer ports
    input  wire [ 11:0] s0_ul_sym_num,
    input  wire [ 11:0] s0_ul_cta_sym_num,
    input  wire         s0_ul_update,
    input  wire         s0_ul_slot_update,
    input  wire [ 11:0] s0_dl_sym_num,
    input  wire [ 11:0] s0_dl_cta_sym_num,
    input  wire         s0_dl_update,
    input  wire         s0_dl_slot_update,
    input  wire         s0_ul_toggle,
    input  wire         s0_dl_toggle,
    // input  wire         s0_ul_symbol_inc,
    // input  wire         s0_dl_symbol_inc,
    input  wire         s0_cc_enable,
    input  wire         s0_cc_reload,
    //
    input  wire [ 11:0] s1_ul_sym_num,
    input  wire [ 11:0] s1_ul_cta_sym_num,
    input  wire         s1_ul_update,
    input  wire         s1_ul_slot_update,
    input  wire [ 11:0] s1_dl_sym_num,
    input  wire [ 11:0] s1_dl_cta_sym_num,
    input  wire         s1_dl_update,
    input  wire         s1_dl_slot_update,
    input  wire         s1_ul_toggle,
    input  wire         s1_dl_toggle,
    // input  wire         s1_ul_symbol_inc,
    // input  wire         s1_dl_symbol_inc,
    input  wire         s1_cc_enable,
    input  wire         s1_cc_reload,
    //
    input  wire [ 11:0] s2_ul_sym_num,
    input  wire [ 11:0] s2_ul_cta_sym_num,
    input  wire         s2_ul_update,
    input  wire         s2_ul_slot_update,
    input  wire [ 11:0] s2_dl_sym_num,
    input  wire [ 11:0] s2_dl_cta_sym_num,
    input  wire         s2_dl_update,
    input  wire         s2_dl_slot_update,
    input  wire         s2_ul_toggle,
    input  wire         s2_dl_toggle,
    // input  wire         s2_ul_symbol_inc,
    // input  wire         s2_dl_symbol_inc,
    input  wire         s2_cc_enable,
    input  wire         s2_cc_reload,
    // CARRIER ports for the Framer, the datapath to the ethernet
    output wire [ 63:0] m000_fram_data_tdata,
    output wire [  7:0] m000_fram_data_tkeep,
    output wire         m000_fram_data_tvalid,
    output wire         m000_fram_data_tlast,
    input  wire         m000_fram_data_tready,
    input  wire [ 32:0] m000_fram_data_req,
    //
    input  wire [107:0] s000_fram_bid_debug,
    input  wire         s000_fram_bid_valid,
    input  wire         s000_fram_bid_tlast,
    output wire         s000_fram_bid_ready,
    input  wire         s000_fram_bid_off,
    input  wire [ 14:0] s000_fram_bid_beamid15,
    input  wire [ 11:0] s000_fram_bid_remask,
    input  wire         s000_fram_bid_rb,
    input  wire [  9:0] s000_fram_bid_start_prbc,
    input  wire [  7:0] s000_fram_bid_num_prbc,
    input  wire [  3:0] s000_fram_bid_num_symbol,
    input  wire [  7:0] s000_fram_bid_cc_id,
    input  wire [ 23:0] s000_fram_bid_frequency_offset,
    input  wire [ 15:0] s000_fram_bid_time_offset,
    input  wire [  7:0] s000_fram_bid_frame_structure,
    input  wire [ 15:0] s000_fram_bid_cp_length,
    //
    output wire [ 63:0] m001_fram_data_tdata,
    output wire [  7:0] m001_fram_data_tkeep,
    output wire         m001_fram_data_tvalid,
    output wire         m001_fram_data_tlast,
    input  wire         m001_fram_data_tready,
    input  wire [ 32:0] m001_fram_data_req,
    //
    input  wire [107:0] s001_fram_bid_debug,
    input  wire         s001_fram_bid_valid,
    input  wire         s001_fram_bid_tlast,
    output wire         s001_fram_bid_ready,
    input  wire         s001_fram_bid_off,
    input  wire [ 14:0] s001_fram_bid_beamid15,
    input  wire [ 11:0] s001_fram_bid_remask,
    input  wire         s001_fram_bid_rb,
    input  wire [  9:0] s001_fram_bid_start_prbc,
    input  wire [  7:0] s001_fram_bid_num_prbc,
    input  wire [  3:0] s001_fram_bid_num_symbol,
    input  wire [  7:0] s001_fram_bid_cc_id,
    input  wire [ 23:0] s001_fram_bid_frequency_offset,
    input  wire [ 15:0] s001_fram_bid_time_offset,
    input  wire [  7:0] s001_fram_bid_frame_structure,
    input  wire [ 15:0] s001_fram_bid_cp_length,
    //
    output wire [ 63:0] m002_fram_data_tdata,
    output wire [  7:0] m002_fram_data_tkeep,
    output wire         m002_fram_data_tvalid,
    output wire         m002_fram_data_tlast,
    input  wire         m002_fram_data_tready,
    input  wire [ 32:0] m002_fram_data_req,
    //
    input  wire [107:0] s002_fram_bid_debug,
    input  wire         s002_fram_bid_valid,
    input  wire         s002_fram_bid_tlast,
    output wire         s002_fram_bid_ready,
    input  wire         s002_fram_bid_off,
    input  wire [ 14:0] s002_fram_bid_beamid15,
    input  wire [ 11:0] s002_fram_bid_remask,
    input  wire         s002_fram_bid_rb,
    input  wire [  9:0] s002_fram_bid_start_prbc,
    input  wire [  7:0] s002_fram_bid_num_prbc,
    input  wire [  3:0] s002_fram_bid_num_symbol,
    input  wire [  7:0] s002_fram_bid_cc_id,
    input  wire [ 23:0] s002_fram_bid_frequency_offset,
    input  wire [ 15:0] s002_fram_bid_time_offset,
    input  wire [  7:0] s002_fram_bid_frame_structure,
    input  wire [ 15:0] s002_fram_bid_cp_length,
    //
    output wire [ 63:0] m003_fram_data_tdata,
    output wire [  7:0] m003_fram_data_tkeep,
    output wire         m003_fram_data_tvalid,
    output wire         m003_fram_data_tlast,
    input  wire         m003_fram_data_tready,
    input  wire [ 32:0] m003_fram_data_req,
    //
    input  wire [107:0] s003_fram_bid_debug,
    input  wire         s003_fram_bid_valid,
    input  wire         s003_fram_bid_tlast,
    output wire         s003_fram_bid_ready,
    input  wire         s003_fram_bid_off,
    input  wire [ 14:0] s003_fram_bid_beamid15,
    input  wire [ 11:0] s003_fram_bid_remask,
    input  wire         s003_fram_bid_rb,
    input  wire [  9:0] s003_fram_bid_start_prbc,
    input  wire [  7:0] s003_fram_bid_num_prbc,
    input  wire [  3:0] s003_fram_bid_num_symbol,
    input  wire [  7:0] s003_fram_bid_cc_id,
    input  wire [ 23:0] s003_fram_bid_frequency_offset,
    input  wire [ 15:0] s003_fram_bid_time_offset,
    input  wire [  7:0] s003_fram_bid_frame_structure,
    input  wire [ 15:0] s003_fram_bid_cp_length,
    //
    output wire [ 63:0] m00_fram_unsol_tdata,
    output wire [  7:0] m00_fram_unsol_tkeep,
    output wire         m00_fram_unsol_tvalid,
    output wire         m00_fram_unsol_tlast,
    input  wire         m00_fram_unsol_tready,
    output wire [ 31:0] m00_fram_unsol_tuser,
    //
    output wire [ 63:0] m00_fram_prach_tdata,
    output wire [  7:0] m00_fram_prach_tkeep,
    output wire         m00_fram_prach_tvalid,
    output wire         m00_fram_prach_tlast,
    input  wire         m00_fram_prach_tready,
    output wire [ 31:0] m00_fram_prach_tuser,
    // CARRIER ports from the De-framer, the datapath from the ethernet
    input  wire [ 63:0] s000_defm_data_tdata,
    input  wire [  7:0] s000_defm_data_tkeep,
    input  wire         s000_defm_data_tvalid,
    input  wire         s000_defm_data_tlast,
    output wire         s000_defm_data_tready,
    input  wire [ 90:0] s000_defm_data_tuser,
    input  wire [  4:0] s000_defm_data_tdest,
    //
    input  wire         s000_defm_bid_valid,
    input  wire         s000_defm_bid_tlast,
    output wire         s000_defm_bid_ready,
    input  wire         s000_defm_bid_off,
    input  wire [ 14:0] s000_defm_bid_beamid15,
    input  wire [ 11:0] s000_defm_bid_remask,
    input  wire         s000_defm_bid_rb,
    input  wire [  9:0] s000_defm_bid_start_prbc,
    input  wire [  7:0] s000_defm_bid_num_prbc,
    input  wire [  3:0] s000_defm_bid_num_symbol,
    input  wire [  7:0] s000_defm_bid_cc_id,
    input  wire [ 23:0] s000_defm_bid_frequency_offset,
    input  wire [ 15:0] s000_defm_bid_time_offset,
    input  wire [  7:0] s000_defm_bid_frame_structure,
    input  wire [ 15:0] s000_defm_bid_cp_length,
    //
    input  wire [ 63:0] s001_defm_data_tdata,
    input  wire [  7:0] s001_defm_data_tkeep,
    input  wire         s001_defm_data_tvalid,
    input  wire         s001_defm_data_tlast,
    output wire         s001_defm_data_tready,
    input  wire [ 90:0] s001_defm_data_tuser,
    input  wire [  4:0] s001_defm_data_tdest,
    //
    input  wire         s001_defm_bid_valid,
    input  wire         s001_defm_bid_tlast,
    output wire         s001_defm_bid_ready,
    input  wire         s001_defm_bid_off,
    input  wire [ 14:0] s001_defm_bid_beamid15,
    input  wire [ 11:0] s001_defm_bid_remask,
    input  wire         s001_defm_bid_rb,
    input  wire [  9:0] s001_defm_bid_start_prbc,
    input  wire [  7:0] s001_defm_bid_num_prbc,
    input  wire [  3:0] s001_defm_bid_num_symbol,
    input  wire [  7:0] s001_defm_bid_cc_id,
    input  wire [ 23:0] s001_defm_bid_frequency_offset,
    input  wire [ 15:0] s001_defm_bid_time_offset,
    input  wire [  7:0] s001_defm_bid_frame_structure,
    input  wire [ 15:0] s001_defm_bid_cp_length,
    //
    input  wire [ 63:0] s002_defm_data_tdata,
    input  wire [  7:0] s002_defm_data_tkeep,
    input  wire         s002_defm_data_tvalid,
    input  wire         s002_defm_data_tlast,
    output wire         s002_defm_data_tready,
    input  wire [ 90:0] s002_defm_data_tuser,
    input  wire [  4:0] s002_defm_data_tdest,
    //
    input  wire         s002_defm_bid_valid,
    input  wire         s002_defm_bid_tlast,
    output wire         s002_defm_bid_ready,
    input  wire         s002_defm_bid_off,
    input  wire [ 14:0] s002_defm_bid_beamid15,
    input  wire [ 11:0] s002_defm_bid_remask,
    input  wire         s002_defm_bid_rb,
    input  wire [  9:0] s002_defm_bid_start_prbc,
    input  wire [  7:0] s002_defm_bid_num_prbc,
    input  wire [  3:0] s002_defm_bid_num_symbol,
    input  wire [  7:0] s002_defm_bid_cc_id,
    input  wire [ 23:0] s002_defm_bid_frequency_offset,
    input  wire [ 15:0] s002_defm_bid_time_offset,
    input  wire [  7:0] s002_defm_bid_frame_structure,
    input  wire [ 15:0] s002_defm_bid_cp_length,
    //
    input  wire [ 63:0] s003_defm_data_tdata,
    input  wire [  7:0] s003_defm_data_tkeep,
    input  wire         s003_defm_data_tvalid,
    input  wire         s003_defm_data_tlast,
    output wire         s003_defm_data_tready,
    input  wire [ 90:0] s003_defm_data_tuser,
    input  wire [  4:0] s003_defm_data_tdest,
    //
    input  wire         s003_defm_bid_valid,
    input  wire         s003_defm_bid_tlast,
    output wire         s003_defm_bid_ready,
    input  wire         s003_defm_bid_off,
    input  wire [ 14:0] s003_defm_bid_beamid15,
    input  wire [ 11:0] s003_defm_bid_remask,
    input  wire         s003_defm_bid_rb,
    input  wire [  9:0] s003_defm_bid_start_prbc,
    input  wire [  7:0] s003_defm_bid_num_prbc,
    input  wire [  3:0] s003_defm_bid_num_symbol,
    input  wire [  7:0] s003_defm_bid_cc_id,
    input  wire [ 23:0] s003_defm_bid_frequency_offset,
    input  wire [ 15:0] s003_defm_bid_time_offset,
    input  wire [  7:0] s003_defm_bid_frame_structure,
    input  wire [ 15:0] s003_defm_bid_cp_length,
    // ORAN prase ports
    input  wire [127:0] s0_ep_debug,
    input  wire         s0_t_header_offset_valid,
    input  wire         s0_runt_packet_len,
    input  wire [ 15:0] s0_rtc_pc_id,
    input  wire         s0_concat,
    input  wire [  2:0] s0_messagetype,
    input  wire [  7:0] s0_seqid,
    input  wire [  6:0] s0_subseqid,
    input  wire         s0_ebit,
    input  wire [ 15:0] s0_payloadsize,
    input  wire         s0_packet_in_window,
    input  wire [ 11:0] s0_offset_in_symbol,
    //
    input  wire         s0_radio_app_head_valid,
    input  wire         s0_datadirection,
    input  wire [  7:0] s0_numsections,
    input  wire [  2:0] s0_sectiontype,
    input  wire [  3:0] s0_filterindex,
    input  wire [  7:0] s0_frameid,
    input  wire [  3:0] s0_subframeid,
    input  wire [  5:0] s0_slotid,
    input  wire [  5:0] s0_symbolid,
    input  wire [  7:0] s0_udcomphdr,
    input  wire [ 15:0] s0_timeoffset,
    input  wire [  7:0] s0_framestructure,
    input  wire [ 15:0] s0_cplength,
    //
    input  wire         s0_section_header_valid,
    input  wire [  3:0] s0_numsymbol,
    input  wire [  7:0] s0_numprbc,
    input  wire [  9:0] s0_startprbc,
    input  wire [ 11:0] s0_sectionid,
    input  wire         s0_rb,
    input  wire [ 11:0] s0_remask,
    input  wire [ 14:0] s0_beamid15,
    input  wire [ 23:0] s0_freqoffset,
    //
    input  wire [ 63:0] s0_beamweights_tdata,
    input  wire         s0_beamweights_tvalid,
    input  wire         s0_beamweights_tlast,
    input  wire [  3:0] s0_beamweights_tuser,
    //
    input  wire [ 63:0] s0_raw_cplane_tdata,
    input  wire         s0_raw_cplane_tvalid,
    input  wire         s0_raw_cplane_tuser,
    input  wire         s0_raw_cplane_tlast,
    input  wire [  7:0] s0_raw_cplane_tkeep,
    //
    input  wire [ 26:0] s0_unsupport_ext_tuser,
    input  wire [ 63:0] s0_unsupport_ext_tdata,
    input  wire         s0_unsupport_ext_tvalid,
    input  wire [  7:0] s0_unsupport_ext_tkeep,
    input  wire         s0_unsupport_ext_tlast,
    // Clocks
    input  wire         internal_bus_clk,
    //
    input  wire         defm_reset,
    input  wire         fram_reset,
    //
    input  wire         defm_reset_active,
    input  wire         fram0_reset_active,
    // Timer ports
    output wire         fram_radio_start_10ms,
    output wire         defm_radio_start_10ms,
    output wire         fram_radio_start_10ms_cc1,
    output wire         defm_radio_start_10ms_cc1,
    output wire         fram_radio_start_10ms_cc2,
    output wire         defm_radio_start_10ms_cc2,
    // SSB ports
    input  wire [ 63:0] s_ssb_data_tdata,
    input  wire [  7:0] s_ssb_data_tkeep,
    input  wire         s_ssb_data_tvalid,
    input  wire         s_ssb_data_tlast,
    output wire         s_ssb_data_tready,
    input  wire [ 90:0] s_ssb_data_tuser,
    // Early BeamID generation
    input  wire [ 47:0] s_ssb_ebid_tdata,
    input  wire         s_ssb_ebid_tvalid,
    input  wire         s_ssb_ebid_tlast,
    output wire         s_ssb_ebid_tready,
    // Outputs to beamid fwd interface
    input  wire         s_ssb_bid_tvalid,
    input  wire         s_ssb_bid_tlast,
    output wire         s_ssb_bid_tready,
    input  wire         s_ssb_bid_off,
    input  wire [ 14:0] s_ssb_bid_beamid15,
    input  wire [ 11:0] s_ssb_bid_remask,
    input  wire         s_ssb_bid_rb,
    input  wire [  9:0] s_ssb_bid_start_prbc,
    input  wire [  7:0] s_ssb_bid_num_prbc,
    input  wire [  3:0] s_ssb_bid_num_symbol,
    input  wire [  7:0] s_ssb_bid_cc_id,
    input  wire [ 23:0] s_ssb_bid_frequency_offset,
    input  wire [ 15:0] s_ssb_bid_time_offset,
    input  wire [  7:0] s_ssb_bid_frame_structure,
    input  wire [ 15:0] s_ssb_bid_cp_length,
    // Ready status
    input  wire         fram_ready,
    input  wire         defm_ready,
    // Mandatory 10 ms strobe
    input  wire         fram_rfs_in,
    input  wire         defm_rfs_in,
    // Radio I/F
    //----------
    input  wire         clk,
    input  wire         rst,
    //
    output wire [383:0] m_dl_axis_tdata,
    output wire [  7:0] m_dl_axis_tuser,
    output wire         m_dl_axis_tlast,
    output wire         m_dl_axis_tvalid,
    input  wire         m_dl_axis_tready,
    //
    input  wire [383:0] s_ul_axis_tdata,
    input  wire [  7:0] s_ul_axis_tuser,
    input  wire         s_ul_axis_tlast,
    input  wire         s_ul_axis_tvalid,
    output wire         s_ul_axis_tready
);

  // Parameters

  localparam int NumCc = 3;
  localparam int NumAnt = 4;
  localparam bit HalfBlock = 1'b0;

  // Signals

  logic [31:0] m_axis_tdata [NumCc][NumAnt];
  logic [ 7:0] m_axis_tuser [NumCc][NumAnt];
  logic        m_axis_tlast [NumCc][NumAnt];
  logic        m_axis_tvalid[NumCc][NumAnt];
  logic        m_axis_tready[NumCc][NumAnt];

  logic [31:0] s_axis_tdata [NumCc][NumAnt];
  logic [ 7:0] s_axis_tuser [NumCc][NumAnt];
  logic        s_axis_tlast [NumCc][NumAnt];
  logic        s_axis_tvalid[NumCc][NumAnt];
  logic        s_axis_tready[NumCc][NumAnt];

  // Main

  lowphy_band #(
      .NUM_CC    (NumCc),
      .NUM_ANT   (NumAnt),
      .HALF_BLOCK(HalfBlock),
      .HALF_FFT  (1'b0)
  ) u_b0 (
      // AXI
      //----
      .s_axi_aclk                    (s_axi_aclk),
      .s_axi_aresetn                 (s_axi_aresetn),
      //
      .s_axi_awaddr                  (s0_axi_awaddr),
      .s_axi_awprot                  (s0_axi_awprot),
      .s_axi_awvalid                 (s0_axi_awvalid),
      .s_axi_awready                 (s0_axi_awready),
      //
      .s_axi_wdata                   (s0_axi_wdata),
      .s_axi_wstrb                   (s0_axi_wstrb),
      .s_axi_wvalid                  (s0_axi_wvalid),
      .s_axi_wready                  (s0_axi_wready),
      //
      .s_axi_bresp                   (s0_axi_bresp),
      .s_axi_bvalid                  (s0_axi_bvalid),
      .s_axi_bready                  (s0_axi_bready),
      //
      .s_axi_araddr                  (s0_axi_araddr),
      .s_axi_arprot                  (s0_axi_arprot),
      .s_axi_arvalid                 (s0_axi_arvalid),
      .s_axi_arready                 (s0_axi_arready),
      //
      .s_axi_rdata                   (s0_axi_rdata),
      .s_axi_rresp                   (s0_axi_rresp),
      .s_axi_rvalid                  (s0_axi_rvalid),
      .s_axi_rready                  (s0_axi_rready),
      // ORAN-IF Interfaces
      //-------------------
      // Early BID ports
      .s_defm_ebid_tdata             (s00_defm_ebid_tdata),
      .s_defm_ebid_tvalid            (s00_defm_ebid_tvalid),
      .s_defm_ebid_tlast             (s00_defm_ebid_tlast),
      .s_defm_ebid_tready            (s00_defm_ebid_tready),
      //
      .s_fram_ebid_tdata             (s00_fram_ebid_tdata),
      .s_fram_ebid_tvalid            (s00_fram_ebid_tvalid),
      .s_fram_ebid_tlast             (s00_fram_ebid_tlast),
      .s_fram_ebid_tready            (s00_fram_ebid_tready),
      // PRACH C plane messages
      .s_prach_tvalid                (s0_prach_tvalid),
      .s_prach_tready                (s0_prach_tready),
      .s_prach_rtc_pc_id             (s0_prach_rtc_pc_id),
      .s_prach_cc                    (s0_prach_cc),
      .s_prach_ss                    (s0_prach_ss),
      .s_prach_section_id            (s0_prach_section_id),
      .s_prach_return_port           (s0_prach_return_port),
      .s_prach_filter_index          (s0_prach_filter_index),
      .s_prach_f                     (s0_prach_f),
      .s_prach_sf                    (s0_prach_sf),
      .s_prach_sl                    (s0_prach_sl),
      .s_prach_sy                    (s0_prach_sy),
      .s_prach_time_offset           (s0_prach_time_offset),
      .s_prach_frame_structure       (s0_prach_frame_structure),
      .s_prach_cp_length             (s0_prach_cp_length),
      .s_prach_udcomphdr             (s0_prach_udcomphdr),
      .s_prach_rb                    (s0_prach_rb),
      .s_prach_syminc                (s0_prach_syminc),
      .s_prach_start_prbc            (s0_prach_start_prbc),
      .s_prach_num_prbc              (s0_prach_num_prbc),
      .s_prach_remask                (s0_prach_remask),
      .s_prach_num_symbol            (s0_prach_num_symbol),
      .s_prach_beamid                (s0_prach_beamid),
      .s_prach_freqoffset            (s0_prach_freqoffset),
      // verilog_format: off
      // Timer ports
      .s_ul_sym_num                  ('{s0_ul_sym_num,     s1_ul_sym_num,     s2_ul_sym_num}),
      .s_ul_cta_sym_num              ('{s0_ul_cta_sym_num, s1_ul_cta_sym_num, s2_ul_cta_sym_num}),
      .s_ul_update                   ('{s0_ul_update,      s1_ul_update,      s2_ul_update}),
      .s_ul_slot_update              ('{s0_ul_slot_update, s1_ul_slot_update, s2_ul_slot_update}),
      .s_dl_sym_num                  ('{s0_dl_sym_num,     s1_dl_sym_num,     s2_dl_sym_num}),
      .s_dl_cta_sym_num              ('{s0_dl_cta_sym_num, s1_dl_cta_sym_num, s2_dl_cta_sym_num}),
      .s_dl_update                   ('{s0_dl_update,      s1_dl_update,      s2_dl_update}),
      .s_dl_slot_update              ('{s0_dl_slot_update, s1_dl_slot_update, s2_dl_slot_update}),
      .s_ul_toggle                   ('{s0_ul_toggle,      s1_ul_toggle,      s2_ul_toggle}),
      .s_dl_toggle                   ('{s0_dl_toggle,      s1_dl_toggle,      s2_dl_toggle}),
      // .s_ul_symbol_inc               ('{s0_ul_symbol_inc,  s1_ul_symbol_inc,  s2_ul_symbol_inc}),
      // .s_dl_symbol_inc               ('{s0_dl_symbol_inc,  s1_dl_symbol_inc,  s2_dl_symbol_inc}),
      .s_cc_enable                   ('{s0_cc_enable,      s1_cc_enable,      s2_cc_enable}),
      .s_cc_reload                   ('{s0_cc_reload,      s1_cc_reload,      s2_cc_reload}),
      // CARRIER ports for the Framer, the datapath to the ethernet
      .m_fram_data_tdata             ('{m000_fram_data_tdata,  m001_fram_data_tdata,  m002_fram_data_tdata,  m003_fram_data_tdata}),
      .m_fram_data_tkeep             ('{m000_fram_data_tkeep,  m001_fram_data_tkeep,  m002_fram_data_tkeep,  m003_fram_data_tkeep}),
      .m_fram_data_tvalid            ('{m000_fram_data_tvalid, m001_fram_data_tvalid, m002_fram_data_tvalid, m003_fram_data_tvalid}),
      .m_fram_data_tlast             ('{m000_fram_data_tlast,  m001_fram_data_tlast,  m002_fram_data_tlast,  m003_fram_data_tlast}),
      .m_fram_data_tready            ('{m000_fram_data_tready, m001_fram_data_tready, m002_fram_data_tready, m003_fram_data_tready}),
      .m_fram_data_req               ('{m000_fram_data_req,    m001_fram_data_req,    m002_fram_data_req,    m003_fram_data_req}),
      //
      .s_fram_bid_debug              ('{s000_fram_bid_debug,            s001_fram_bid_debug,            s002_fram_bid_debug,             s003_fram_bid_debug}),
      .s_fram_bid_valid              ('{s000_fram_bid_valid,            s001_fram_bid_valid,            s002_fram_bid_valid,             s003_fram_bid_valid}),
      .s_fram_bid_tlast              ('{s000_fram_bid_tlast,            s001_fram_bid_tlast,            s002_fram_bid_tlast,             s003_fram_bid_tlast}),
      .s_fram_bid_ready              ('{s000_fram_bid_ready,            s001_fram_bid_ready,            s002_fram_bid_ready,             s003_fram_bid_ready}),
      .s_fram_bid_off                ('{s000_fram_bid_off,              s001_fram_bid_off,              s002_fram_bid_off,               s003_fram_bid_off}),
      .s_fram_bid_beamid15           ('{s000_fram_bid_beamid15,         s001_fram_bid_beamid15,         s002_fram_bid_beamid15,          s003_fram_bid_beamid15}),
      .s_fram_bid_remask             ('{s000_fram_bid_remask,           s001_fram_bid_remask,           s002_fram_bid_remask,            s003_fram_bid_remask}),
      .s_fram_bid_rb                 ('{s000_fram_bid_rb,               s001_fram_bid_rb,               s002_fram_bid_rb,                s003_fram_bid_rb}),
      .s_fram_bid_start_prbc         ('{s000_fram_bid_start_prbc,       s001_fram_bid_start_prbc,       s002_fram_bid_start_prbc,        s003_fram_bid_start_prbc}),
      .s_fram_bid_num_prbc           ('{s000_fram_bid_num_prbc,         s001_fram_bid_num_prbc,         s002_fram_bid_num_prbc,          s003_fram_bid_num_prbc}),
      .s_fram_bid_num_symbol         ('{s000_fram_bid_num_symbol,       s001_fram_bid_num_symbol,       s002_fram_bid_num_symbol,        s003_fram_bid_num_symbol}),
      .s_fram_bid_cc_id              ('{s000_fram_bid_cc_id,            s001_fram_bid_cc_id,            s002_fram_bid_cc_id,             s003_fram_bid_cc_id}),
      .s_fram_bid_frequency_offset   ('{s000_fram_bid_frequency_offset, s001_fram_bid_frequency_offset, s002_fram_bid_frequency_offset,  s003_fram_bid_frequency_offset}),
      .s_fram_bid_time_offset        ('{s000_fram_bid_time_offset,      s001_fram_bid_time_offset,      s002_fram_bid_time_offset,       s003_fram_bid_time_offset}),
      .s_fram_bid_frame_structure    ('{s000_fram_bid_frame_structure,  s001_fram_bid_frame_structure,  s002_fram_bid_frame_structure,   s003_fram_bid_frame_structure}),
      .s_fram_bid_cp_length          ('{s000_fram_bid_cp_length,        s001_fram_bid_cp_length,        s002_fram_bid_cp_length,         s003_fram_bid_cp_length}),
      // verilog_format: on
      .m_fram_unsol_tdata            (m00_fram_unsol_tdata),
      .m_fram_unsol_tkeep            (m00_fram_unsol_tkeep),
      .m_fram_unsol_tvalid           (m00_fram_unsol_tvalid),
      .m_fram_unsol_tlast            (m00_fram_unsol_tlast),
      .m_fram_unsol_tready           (m00_fram_unsol_tready),
      .m_fram_unsol_tuser            (m00_fram_unsol_tuser),
      //
      .m_fram_prach_tdata            (m00_fram_prach_tdata),
      .m_fram_prach_tkeep            (m00_fram_prach_tkeep),
      .m_fram_prach_tvalid           (m00_fram_prach_tvalid),
      .m_fram_prach_tlast            (m00_fram_prach_tlast),
      .m_fram_prach_tready           (m00_fram_prach_tready),
      .m_fram_prach_tuser            (m00_fram_prach_tuser),
      // CARRIER ports from the Framer, the datapath from the ethernet
      // verilog_format: off
      .s_defm_data_tdata             ('{s000_defm_data_tdata,  s001_defm_data_tdata,  s002_defm_data_tdata,  s003_defm_data_tdata}),
      .s_defm_data_tkeep             ('{s000_defm_data_tkeep,  s001_defm_data_tkeep,  s002_defm_data_tkeep,  s003_defm_data_tkeep}),
      .s_defm_data_tvalid            ('{s000_defm_data_tvalid, s001_defm_data_tvalid, s002_defm_data_tvalid, s003_defm_data_tvalid}),
      .s_defm_data_tlast             ('{s000_defm_data_tlast,  s001_defm_data_tlast,  s002_defm_data_tlast,  s003_defm_data_tlast}),
      .s_defm_data_tready            ('{s000_defm_data_tready, s001_defm_data_tready, s002_defm_data_tready, s003_defm_data_tready}),
      .s_defm_data_tuser             ('{s000_defm_data_tuser,  s001_defm_data_tuser,  s002_defm_data_tuser,  s003_defm_data_tuser}),
      .s_defm_data_tdest             ('{s000_defm_data_tdest,  s001_defm_data_tdest,  s002_defm_data_tdest,  s003_defm_data_tdest}),
      //
      .s_defm_bid_valid              ('{s000_defm_bid_valid,            s001_defm_bid_valid,            s002_defm_bid_valid,            s003_defm_bid_valid}),
      .s_defm_bid_tlast              ('{s000_defm_bid_tlast,            s001_defm_bid_tlast,            s002_defm_bid_tlast,            s003_defm_bid_tlast}),
      .s_defm_bid_ready              ('{s000_defm_bid_ready,            s001_defm_bid_ready,            s002_defm_bid_ready,            s003_defm_bid_ready}),
      .s_defm_bid_off                ('{s000_defm_bid_off,              s001_defm_bid_off,              s002_defm_bid_off,              s003_defm_bid_off}),
      .s_defm_bid_beamid15           ('{s000_defm_bid_beamid15,         s001_defm_bid_beamid15,         s002_defm_bid_beamid15,         s003_defm_bid_beamid15}),
      .s_defm_bid_remask             ('{s000_defm_bid_remask,           s001_defm_bid_remask,           s002_defm_bid_remask,           s003_defm_bid_remask}),
      .s_defm_bid_rb                 ('{s000_defm_bid_rb,               s001_defm_bid_rb,               s002_defm_bid_rb,               s003_defm_bid_rb}),
      .s_defm_bid_start_prbc         ('{s000_defm_bid_start_prbc,       s001_defm_bid_start_prbc,       s002_defm_bid_start_prbc,       s003_defm_bid_start_prbc}),
      .s_defm_bid_num_prbc           ('{s000_defm_bid_num_prbc,         s001_defm_bid_num_prbc,         s002_defm_bid_num_prbc,         s003_defm_bid_num_prbc}),
      .s_defm_bid_num_symbol         ('{s000_defm_bid_num_symbol,       s001_defm_bid_num_symbol,       s002_defm_bid_num_symbol,       s003_defm_bid_num_symbol}),
      .s_defm_bid_cc_id              ('{s000_defm_bid_cc_id,            s001_defm_bid_cc_id,            s002_defm_bid_cc_id,            s003_defm_bid_cc_id}),
      .s_defm_bid_frequency_offset   ('{s000_defm_bid_frequency_offset, s001_defm_bid_frequency_offset, s002_defm_bid_frequency_offset, s003_defm_bid_frequency_offset}),
      .s_defm_bid_time_offset        ('{s000_defm_bid_time_offset,      s001_defm_bid_time_offset,      s002_defm_bid_time_offset,      s003_defm_bid_time_offset}),
      .s_defm_bid_frame_structure    ('{s000_defm_bid_frame_structure,  s001_defm_bid_frame_structure,  s002_defm_bid_frame_structure,  s003_defm_bid_frame_structure}),
      .s_defm_bid_cp_length          ('{s000_defm_bid_cp_length,        s001_defm_bid_cp_length,        s002_defm_bid_cp_length,        s003_defm_bid_cp_length}),
      // verilog_format: on
      // ORAN prase ports
      .s_ep_debug                    (s0_ep_debug),
      .s_t_header_offset_valid       (s0_t_header_offset_valid),
      .s_runt_packet_len             (s0_runt_packet_len),
      .s_rtc_pc_id                   (s0_rtc_pc_id),
      .s_concat                      (s0_concat),
      .s_messagetype                 (s0_messagetype),
      .s_seqid                       (s0_seqid),
      .s_subseqid                    (s0_subseqid),
      .s_ebit                        (s0_ebit),
      .s_payloadsize                 (s0_payloadsize),
      .s_packet_in_window            (s0_packet_in_window),
      .s_offset_in_symbol            (s0_offset_in_symbol),
      //
      .s_radio_app_head_valid        (s0_radio_app_head_valid),
      .s_datadirection               (s0_datadirection),
      .s_numsections                 (s0_numsections),
      .s_sectiontype                 (s0_sectiontype),
      .s_filterindex                 (s0_filterindex),
      .s_frameid                     (s0_frameid),
      .s_subframeid                  (s0_subframeid),
      .s_slotid                      (s0_slotid),
      .s_symbolid                    (s0_symbolid),
      .s_udcomphdr                   (s0_udcomphdr),
      .s_timeoffset                  (s0_timeoffset),
      .s_framestructure              (s0_framestructure),
      .s_cplength                    (s0_cplength),
      //
      .s_section_header_valid        (s0_section_header_valid),
      .s_numsymbol                   (s0_numsymbol),
      .s_numprbc                     (s0_numprbc),
      .s_startprbc                   (s0_startprbc),
      .s_sectionid                   (s0_sectionid),
      .s_rb                          (s0_rb),
      .s_remask                      (s0_remask),
      .s_beamid15                    (s0_beamid15),
      .s_freqoffset                  (s0_freqoffset),
      //
      .s_beamweights_tdata           (s0_beamweights_tdata),
      .s_beamweights_tvalid          (s0_beamweights_tvalid),
      .s_beamweights_tlast           (s0_beamweights_tlast),
      .s_beamweights_tuser           (s0_beamweights_tuser),
      //
      .s_raw_cplane_tdata            (s0_raw_cplane_tdata),
      .s_raw_cplane_tvalid           (s0_raw_cplane_tvalid),
      .s_raw_cplane_tuser            (s0_raw_cplane_tuser),
      .s_raw_cplane_tlast            (s0_raw_cplane_tlast),
      .s_raw_cplane_tkeep            (s0_raw_cplane_tkeep),
      //
      .s_unsupport_ext_tuser         (s0_unsupport_ext_tuser),
      .s_unsupport_ext_tdata         (s0_unsupport_ext_tdata),
      .s_unsupport_ext_tvalid        (s0_unsupport_ext_tvalid),
      .s_unsupport_ext_tkeep         (s0_unsupport_ext_tkeep),
      .s_unsupport_ext_tlast         (s0_unsupport_ext_tlast),
      // Clocks
      .internal_bus_clk              (internal_bus_clk),
      //
      .defm_reset                    (defm_reset),
      .fram_reset                    (fram_reset),
      //
      .defm_reset_active             (defm_reset_active),
      .fram0_reset_active            (fram0_reset_active),
      // Timer ports
      .fram_radio_start_10ms         ('{fram_radio_start_10ms, fram_radio_start_10ms_cc1, fram_radio_start_10ms_cc2}),
      .defm_radio_start_10ms         ('{defm_radio_start_10ms, defm_radio_start_10ms_cc1, defm_radio_start_10ms_cc2}),
      // SSB ports
      .s_ssb_data_tdata              (s_ssb_data_tdata),
      .s_ssb_data_tkeep              (s_ssb_data_tkeep),
      .s_ssb_data_tvalid             (s_ssb_data_tvalid),
      .s_ssb_data_tlast              (s_ssb_data_tlast),
      .s_ssb_data_tready             (s_ssb_data_tready),
      .s_ssb_data_tuser              (s_ssb_data_tuser),
      // Early BeamID generation
      .s_ssb_ebid_tdata              (s_ssb_ebid_tdata),
      .s_ssb_ebid_tvalid             (s_ssb_ebid_tvalid),
      .s_ssb_ebid_tlast              (s_ssb_ebid_tlast),
      .s_ssb_ebid_tready             (s_ssb_ebid_tready),
      // Outputs to beamid fwd interface
      .s_ssb_bid_tvalid              (s_ssb_bid_tvalid),
      .s_ssb_bid_tlast               (s_ssb_bid_tlast),
      .s_ssb_bid_tready              (s_ssb_bid_tready),
      .s_ssb_bid_off                 (s_ssb_bid_off),
      .s_ssb_bid_beamid15            (s_ssb_bid_beamid15),
      .s_ssb_bid_remask              (s_ssb_bid_remask),
      .s_ssb_bid_rb                  (s_ssb_bid_rb),
      .s_ssb_bid_start_prbc          (s_ssb_bid_start_prbc),
      .s_ssb_bid_num_prbc            (s_ssb_bid_num_prbc),
      .s_ssb_bid_num_symbol          (s_ssb_bid_num_symbol),
      .s_ssb_bid_cc_id               (s_ssb_bid_cc_id),
      .s_ssb_bid_frequency_offset    (s_ssb_bid_frequency_offset),
      .s_ssb_bid_time_offset         (s_ssb_bid_time_offset),
      .s_ssb_bid_frame_structure     (s_ssb_bid_frame_structure),
      .s_ssb_bid_cp_length           (s_ssb_bid_cp_length),
      // Ready status
      .fram_ready                    (fram_ready),
      .defm_ready                    (defm_ready),
      // Mandatory 10 ms strobe
      .fram_rfs_in                   (fram_rfs_in),
      .defm_rfs_in                   (defm_rfs_in),
      // Radio I/F
      //----------
      .clk                           (clk),
      .rst                           (rst),
      //
      .m_axis_tdata                  (m_axis_tdata),
      .m_axis_tuser                  (m_axis_tuser),
      .m_axis_tlast                  (m_axis_tlast),
      .m_axis_tvalid                 (m_axis_tvalid),
      .m_axis_tready                 (m_axis_tready),
      //
      .s_axis_tdata                  (s_axis_tdata),
      .s_axis_tuser                  (s_axis_tuser),
      .s_axis_tlast                  (s_axis_tlast),
      .s_axis_tvalid                 (s_axis_tvalid),
      .s_axis_tready                 (s_axis_tready)
  );

  generate
    for (genvar cc = 0; cc < NumCc; cc++) begin : gen_cc
      for (genvar ant = 0; ant < NumAnt; ant++) begin : gen_ant

        assign m_dl_axis_tdata[(cc*NumAnt+ant)*32+31-:32] = m_axis_tdata[cc][ant];

        assign m_axis_tready[cc][ant] = m_dl_axis_tready;

        assign s_axis_tdata[cc][ant] = s_ul_axis_tdata[(cc*NumAnt+ant)*32+31-:32];
        assign s_axis_tuser[cc][ant] = s_ul_axis_tuser;
        assign s_axis_tlast[cc][ant] = s_ul_axis_tlast;
        assign s_axis_tvalid[cc][ant] = s_ul_axis_tvalid;

      end
    end

  endgenerate

  assign m_dl_axis_tuser  = m_axis_tuser[0][0];
  assign m_dl_axis_tlast  = m_axis_tlast[0][0];
  assign m_dl_axis_tvalid = m_axis_tvalid[0][0];

  assign s_ul_axis_tready = s_axis_tready[0][0];

endmodule

`default_nettype wire
