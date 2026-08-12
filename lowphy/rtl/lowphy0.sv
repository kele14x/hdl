`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy0 (
    // AXI
    //----
    input var          s_axi_aclk,
    input var          s_axi_aresetn,
    //
    input var  [ 11:0] s0_axi_awaddr,
    input var  [  2:0] s0_axi_awprot,
    input var          s0_axi_awvalid,
    output var         s0_axi_awready,
    //
    input var  [ 31:0] s0_axi_wdata,
    input var  [  3:0] s0_axi_wstrb,
    input var          s0_axi_wvalid,
    output var         s0_axi_wready,
    //
    output var [  1:0] s0_axi_bresp,
    output var         s0_axi_bvalid,
    input var          s0_axi_bready,
    //
    input var  [ 11:0] s0_axi_araddr,
    input var  [  2:0] s0_axi_arprot,
    input var          s0_axi_arvalid,
    output var         s0_axi_arready,
    //
    output var [ 31:0] s0_axi_rdata,
    output var [  1:0] s0_axi_rresp,
    output var         s0_axi_rvalid,
    input var          s0_axi_rready,
    // ORAN-IF Interfaces
    //-------------------
    // Early BID ports
    input var  [ 47:0] s00_defm_ebid_tdata,
    input var          s00_defm_ebid_tvalid,
    input var          s00_defm_ebid_tlast,
    output var         s00_defm_ebid_tready,
    //
    input var  [ 47:0] s00_fram_ebid_tdata,
    input var          s00_fram_ebid_tvalid,
    input var          s00_fram_ebid_tlast,
    output var         s00_fram_ebid_tready,
    // PRACH C plane messages
    input var          s0_prach_tvalid,
    output var         s0_prach_tready,
    input var  [ 15:0] s0_prach_rtc_pc_id,
    input var  [  3:0] s0_prach_cc,
    input var  [  7:0] s0_prach_ss,
    input var  [ 11:0] s0_prach_section_id,
    input var  [  3:0] s0_prach_return_port,
    input var  [  3:0] s0_prach_filter_index,
    input var  [  7:0] s0_prach_f,
    input var  [  3:0] s0_prach_sf,
    input var  [  5:0] s0_prach_sl,
    input var  [  5:0] s0_prach_sy,
    input var  [ 15:0] s0_prach_time_offset,
    input var  [  7:0] s0_prach_frame_structure,
    input var  [ 15:0] s0_prach_cp_length,
    input var  [  7:0] s0_prach_udcomphdr,
    input var          s0_prach_rb,
    input var          s0_prach_syminc,
    input var  [  9:0] s0_prach_start_prbc,
    input var  [  7:0] s0_prach_num_prbc,
    input var  [ 11:0] s0_prach_remask,
    input var  [  3:0] s0_prach_num_symbol,
    input var  [ 14:0] s0_prach_beamid,
    input var  [ 23:0] s0_prach_freqoffset,
    // Timer ports
    input var  [ 11:0] s0_ul_sym_num,
    input var  [ 11:0] s0_ul_cta_sym_num,
    input var          s0_ul_update,
    input var          s0_ul_slot_update,
    input var  [ 11:0] s0_dl_sym_num,
    input var  [ 11:0] s0_dl_cta_sym_num,
    input var          s0_dl_update,
    input var          s0_dl_slot_update,
    input var          s0_ul_toggle,
    input var          s0_dl_toggle,
    // input  wire         s0_ul_symbol_inc,
    // input  wire         s0_dl_symbol_inc,
    input var          s0_cc_enable,
    input var          s0_cc_reload,
    //
    input var  [ 11:0] s1_ul_sym_num,
    input var  [ 11:0] s1_ul_cta_sym_num,
    input var          s1_ul_update,
    input var          s1_ul_slot_update,
    input var  [ 11:0] s1_dl_sym_num,
    input var  [ 11:0] s1_dl_cta_sym_num,
    input var          s1_dl_update,
    input var          s1_dl_slot_update,
    input var          s1_ul_toggle,
    input var          s1_dl_toggle,
    // input  wire         s1_ul_symbol_inc,
    // input  wire         s1_dl_symbol_inc,
    input var          s1_cc_enable,
    input var          s1_cc_reload,
    //
    input var  [ 11:0] s2_ul_sym_num,
    input var  [ 11:0] s2_ul_cta_sym_num,
    input var          s2_ul_update,
    input var          s2_ul_slot_update,
    input var  [ 11:0] s2_dl_sym_num,
    input var  [ 11:0] s2_dl_cta_sym_num,
    input var          s2_dl_update,
    input var          s2_dl_slot_update,
    input var          s2_ul_toggle,
    input var          s2_dl_toggle,
    // input  wire         s2_ul_symbol_inc,
    // input  wire         s2_dl_symbol_inc,
    input var          s2_cc_enable,
    input var          s2_cc_reload,
    // CARRIER ports for the Framer, the datapath to the ethernet
    output var [ 63:0] m000_fram_data_tdata,
    output var [  7:0] m000_fram_data_tkeep,
    output var         m000_fram_data_tvalid,
    output var         m000_fram_data_tlast,
    input var          m000_fram_data_tready,
    input var  [ 32:0] m000_fram_data_req,
    //
    input var  [107:0] s000_fram_bid_debug,
    input var          s000_fram_bid_valid,
    input var          s000_fram_bid_tlast,
    output var         s000_fram_bid_ready,
    input var          s000_fram_bid_off,
    input var  [ 14:0] s000_fram_bid_beamid15,
    input var  [ 11:0] s000_fram_bid_remask,
    input var          s000_fram_bid_rb,
    input var  [  9:0] s000_fram_bid_start_prbc,
    input var  [  7:0] s000_fram_bid_num_prbc,
    input var  [  3:0] s000_fram_bid_num_symbol,
    input var  [  7:0] s000_fram_bid_cc_id,
    input var  [ 23:0] s000_fram_bid_frequency_offset,
    input var  [ 15:0] s000_fram_bid_time_offset,
    input var  [  7:0] s000_fram_bid_frame_structure,
    input var  [ 15:0] s000_fram_bid_cp_length,
    //
    output var [ 63:0] m001_fram_data_tdata,
    output var [  7:0] m001_fram_data_tkeep,
    output var         m001_fram_data_tvalid,
    output var         m001_fram_data_tlast,
    input var          m001_fram_data_tready,
    input var  [ 32:0] m001_fram_data_req,
    //
    input var  [107:0] s001_fram_bid_debug,
    input var          s001_fram_bid_valid,
    input var          s001_fram_bid_tlast,
    output var         s001_fram_bid_ready,
    input var          s001_fram_bid_off,
    input var  [ 14:0] s001_fram_bid_beamid15,
    input var  [ 11:0] s001_fram_bid_remask,
    input var          s001_fram_bid_rb,
    input var  [  9:0] s001_fram_bid_start_prbc,
    input var  [  7:0] s001_fram_bid_num_prbc,
    input var  [  3:0] s001_fram_bid_num_symbol,
    input var  [  7:0] s001_fram_bid_cc_id,
    input var  [ 23:0] s001_fram_bid_frequency_offset,
    input var  [ 15:0] s001_fram_bid_time_offset,
    input var  [  7:0] s001_fram_bid_frame_structure,
    input var  [ 15:0] s001_fram_bid_cp_length,
    //
    output var [ 63:0] m002_fram_data_tdata,
    output var [  7:0] m002_fram_data_tkeep,
    output var         m002_fram_data_tvalid,
    output var         m002_fram_data_tlast,
    input var          m002_fram_data_tready,
    input var  [ 32:0] m002_fram_data_req,
    //
    input var  [107:0] s002_fram_bid_debug,
    input var          s002_fram_bid_valid,
    input var          s002_fram_bid_tlast,
    output var         s002_fram_bid_ready,
    input var          s002_fram_bid_off,
    input var  [ 14:0] s002_fram_bid_beamid15,
    input var  [ 11:0] s002_fram_bid_remask,
    input var          s002_fram_bid_rb,
    input var  [  9:0] s002_fram_bid_start_prbc,
    input var  [  7:0] s002_fram_bid_num_prbc,
    input var  [  3:0] s002_fram_bid_num_symbol,
    input var  [  7:0] s002_fram_bid_cc_id,
    input var  [ 23:0] s002_fram_bid_frequency_offset,
    input var  [ 15:0] s002_fram_bid_time_offset,
    input var  [  7:0] s002_fram_bid_frame_structure,
    input var  [ 15:0] s002_fram_bid_cp_length,
    //
    output var [ 63:0] m003_fram_data_tdata,
    output var [  7:0] m003_fram_data_tkeep,
    output var         m003_fram_data_tvalid,
    output var         m003_fram_data_tlast,
    input var          m003_fram_data_tready,
    input var  [ 32:0] m003_fram_data_req,
    //
    input var  [107:0] s003_fram_bid_debug,
    input var          s003_fram_bid_valid,
    input var          s003_fram_bid_tlast,
    output var         s003_fram_bid_ready,
    input var          s003_fram_bid_off,
    input var  [ 14:0] s003_fram_bid_beamid15,
    input var  [ 11:0] s003_fram_bid_remask,
    input var          s003_fram_bid_rb,
    input var  [  9:0] s003_fram_bid_start_prbc,
    input var  [  7:0] s003_fram_bid_num_prbc,
    input var  [  3:0] s003_fram_bid_num_symbol,
    input var  [  7:0] s003_fram_bid_cc_id,
    input var  [ 23:0] s003_fram_bid_frequency_offset,
    input var  [ 15:0] s003_fram_bid_time_offset,
    input var  [  7:0] s003_fram_bid_frame_structure,
    input var  [ 15:0] s003_fram_bid_cp_length,
    //
    output var [ 63:0] m00_fram_unsol_tdata,
    output var [  7:0] m00_fram_unsol_tkeep,
    output var         m00_fram_unsol_tvalid,
    output var         m00_fram_unsol_tlast,
    input var          m00_fram_unsol_tready,
    output var [ 31:0] m00_fram_unsol_tuser,
    //
    output var [ 63:0] m00_fram_prach_tdata,
    output var [  7:0] m00_fram_prach_tkeep,
    output var         m00_fram_prach_tvalid,
    output var         m00_fram_prach_tlast,
    input var          m00_fram_prach_tready,
    output var [ 31:0] m00_fram_prach_tuser,
    // CARRIER ports from the De-framer, the datapath from the ethernet
    input var  [ 63:0] s000_defm_data_tdata,
    input var  [  7:0] s000_defm_data_tkeep,
    input var          s000_defm_data_tvalid,
    input var          s000_defm_data_tlast,
    output var         s000_defm_data_tready,
    input var  [ 90:0] s000_defm_data_tuser,
    input var  [  4:0] s000_defm_data_tdest,
    //
    input var          s000_defm_bid_valid,
    input var          s000_defm_bid_tlast,
    output var         s000_defm_bid_ready,
    input var          s000_defm_bid_off,
    input var  [ 14:0] s000_defm_bid_beamid15,
    input var  [ 11:0] s000_defm_bid_remask,
    input var          s000_defm_bid_rb,
    input var  [  9:0] s000_defm_bid_start_prbc,
    input var  [  7:0] s000_defm_bid_num_prbc,
    input var  [  3:0] s000_defm_bid_num_symbol,
    input var  [  7:0] s000_defm_bid_cc_id,
    input var  [ 23:0] s000_defm_bid_frequency_offset,
    input var  [ 15:0] s000_defm_bid_time_offset,
    input var  [  7:0] s000_defm_bid_frame_structure,
    input var  [ 15:0] s000_defm_bid_cp_length,
    //
    input var  [ 63:0] s001_defm_data_tdata,
    input var  [  7:0] s001_defm_data_tkeep,
    input var          s001_defm_data_tvalid,
    input var          s001_defm_data_tlast,
    output var         s001_defm_data_tready,
    input var  [ 90:0] s001_defm_data_tuser,
    input var  [  4:0] s001_defm_data_tdest,
    //
    input var          s001_defm_bid_valid,
    input var          s001_defm_bid_tlast,
    output var         s001_defm_bid_ready,
    input var          s001_defm_bid_off,
    input var  [ 14:0] s001_defm_bid_beamid15,
    input var  [ 11:0] s001_defm_bid_remask,
    input var          s001_defm_bid_rb,
    input var  [  9:0] s001_defm_bid_start_prbc,
    input var  [  7:0] s001_defm_bid_num_prbc,
    input var  [  3:0] s001_defm_bid_num_symbol,
    input var  [  7:0] s001_defm_bid_cc_id,
    input var  [ 23:0] s001_defm_bid_frequency_offset,
    input var  [ 15:0] s001_defm_bid_time_offset,
    input var  [  7:0] s001_defm_bid_frame_structure,
    input var  [ 15:0] s001_defm_bid_cp_length,
    //
    input var  [ 63:0] s002_defm_data_tdata,
    input var  [  7:0] s002_defm_data_tkeep,
    input var          s002_defm_data_tvalid,
    input var          s002_defm_data_tlast,
    output var         s002_defm_data_tready,
    input var  [ 90:0] s002_defm_data_tuser,
    input var  [  4:0] s002_defm_data_tdest,
    //
    input var          s002_defm_bid_valid,
    input var          s002_defm_bid_tlast,
    output var         s002_defm_bid_ready,
    input var          s002_defm_bid_off,
    input var  [ 14:0] s002_defm_bid_beamid15,
    input var  [ 11:0] s002_defm_bid_remask,
    input var          s002_defm_bid_rb,
    input var  [  9:0] s002_defm_bid_start_prbc,
    input var  [  7:0] s002_defm_bid_num_prbc,
    input var  [  3:0] s002_defm_bid_num_symbol,
    input var  [  7:0] s002_defm_bid_cc_id,
    input var  [ 23:0] s002_defm_bid_frequency_offset,
    input var  [ 15:0] s002_defm_bid_time_offset,
    input var  [  7:0] s002_defm_bid_frame_structure,
    input var  [ 15:0] s002_defm_bid_cp_length,
    //
    input var  [ 63:0] s003_defm_data_tdata,
    input var  [  7:0] s003_defm_data_tkeep,
    input var          s003_defm_data_tvalid,
    input var          s003_defm_data_tlast,
    output var         s003_defm_data_tready,
    input var  [ 90:0] s003_defm_data_tuser,
    input var  [  4:0] s003_defm_data_tdest,
    //
    input var          s003_defm_bid_valid,
    input var          s003_defm_bid_tlast,
    output var         s003_defm_bid_ready,
    input var          s003_defm_bid_off,
    input var  [ 14:0] s003_defm_bid_beamid15,
    input var  [ 11:0] s003_defm_bid_remask,
    input var          s003_defm_bid_rb,
    input var  [  9:0] s003_defm_bid_start_prbc,
    input var  [  7:0] s003_defm_bid_num_prbc,
    input var  [  3:0] s003_defm_bid_num_symbol,
    input var  [  7:0] s003_defm_bid_cc_id,
    input var  [ 23:0] s003_defm_bid_frequency_offset,
    input var  [ 15:0] s003_defm_bid_time_offset,
    input var  [  7:0] s003_defm_bid_frame_structure,
    input var  [ 15:0] s003_defm_bid_cp_length,
    // ORAN prase ports
    input var  [127:0] s0_ep_debug,
    input var          s0_t_header_offset_valid,
    input var          s0_runt_packet_len,
    input var  [ 15:0] s0_rtc_pc_id,
    input var          s0_concat,
    input var  [  2:0] s0_messagetype,
    input var  [  7:0] s0_seqid,
    input var  [  6:0] s0_subseqid,
    input var          s0_ebit,
    input var  [ 15:0] s0_payloadsize,
    input var          s0_packet_in_window,
    input var  [ 11:0] s0_offset_in_symbol,
    //
    input var          s0_radio_app_head_valid,
    input var          s0_datadirection,
    input var  [  7:0] s0_numsections,
    input var  [  2:0] s0_sectiontype,
    input var  [  3:0] s0_filterindex,
    input var  [  7:0] s0_frameid,
    input var  [  3:0] s0_subframeid,
    input var  [  5:0] s0_slotid,
    input var  [  5:0] s0_symbolid,
    input var  [  7:0] s0_udcomphdr,
    input var  [ 15:0] s0_timeoffset,
    input var  [  7:0] s0_framestructure,
    input var  [ 15:0] s0_cplength,
    //
    input var          s0_section_header_valid,
    input var  [  3:0] s0_numsymbol,
    input var  [  7:0] s0_numprbc,
    input var  [  9:0] s0_startprbc,
    input var  [ 11:0] s0_sectionid,
    input var          s0_rb,
    input var  [ 11:0] s0_remask,
    input var  [ 14:0] s0_beamid15,
    input var  [ 23:0] s0_freqoffset,
    //
    input var  [ 63:0] s0_beamweights_tdata,
    input var          s0_beamweights_tvalid,
    input var          s0_beamweights_tlast,
    input var  [  3:0] s0_beamweights_tuser,
    //
    input var  [ 63:0] s0_raw_cplane_tdata,
    input var          s0_raw_cplane_tvalid,
    input var          s0_raw_cplane_tuser,
    input var          s0_raw_cplane_tlast,
    input var  [  7:0] s0_raw_cplane_tkeep,
    //
    input var  [ 26:0] s0_unsupport_ext_tuser,
    input var  [ 63:0] s0_unsupport_ext_tdata,
    input var          s0_unsupport_ext_tvalid,
    input var  [  7:0] s0_unsupport_ext_tkeep,
    input var          s0_unsupport_ext_tlast,
    // Clocks
    input var          internal_bus_clk,
    //
    input var          defm_reset,
    input var          fram_reset,
    //
    input var          defm_reset_active,
    input var          fram0_reset_active,
    // Timer ports
    output var         fram_radio_start_10ms,
    output var         defm_radio_start_10ms,
    output var         fram_radio_start_10ms_cc1,
    output var         defm_radio_start_10ms_cc1,
    output var         fram_radio_start_10ms_cc2,
    output var         defm_radio_start_10ms_cc2,
    // SSB ports
    input var  [ 63:0] s_ssb_data_tdata,
    input var  [  7:0] s_ssb_data_tkeep,
    input var          s_ssb_data_tvalid,
    input var          s_ssb_data_tlast,
    output var         s_ssb_data_tready,
    input var  [ 90:0] s_ssb_data_tuser,
    // Early BeamID generation
    input var  [ 47:0] s_ssb_ebid_tdata,
    input var          s_ssb_ebid_tvalid,
    input var          s_ssb_ebid_tlast,
    output var         s_ssb_ebid_tready,
    // Outputs to beamid fwd interface
    input var          s_ssb_bid_tvalid,
    input var          s_ssb_bid_tlast,
    output var         s_ssb_bid_tready,
    input var          s_ssb_bid_off,
    input var  [ 14:0] s_ssb_bid_beamid15,
    input var  [ 11:0] s_ssb_bid_remask,
    input var          s_ssb_bid_rb,
    input var  [  9:0] s_ssb_bid_start_prbc,
    input var  [  7:0] s_ssb_bid_num_prbc,
    input var  [  3:0] s_ssb_bid_num_symbol,
    input var  [  7:0] s_ssb_bid_cc_id,
    input var  [ 23:0] s_ssb_bid_frequency_offset,
    input var  [ 15:0] s_ssb_bid_time_offset,
    input var  [  7:0] s_ssb_bid_frame_structure,
    input var  [ 15:0] s_ssb_bid_cp_length,
    // Ready status
    input var          fram_ready,
    input var          defm_ready,
    // Mandatory 10 ms strobe
    input var          fram_rfs_in,
    input var          defm_rfs_in,
    // Radio I/F
    //----------
    input var          clk,
    input var          rst,
    //
    output var [383:0] m_dl_axis_tdata,
    output var [  7:0] m_dl_axis_tuser,
    output var         m_dl_axis_tlast,
    output var         m_dl_axis_tvalid,
    input var          m_dl_axis_tready,
    //
    input var  [383:0] s_ul_axis_tdata,
    input var  [  7:0] s_ul_axis_tuser,
    input var          s_ul_axis_tlast,
    input var          s_ul_axis_tvalid,
    output var         s_ul_axis_tready
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
