`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy1 (
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
    //
    input  wire [ 11:0] s1_axi_awaddr,
    input  wire [  2:0] s1_axi_awprot,
    input  wire         s1_axi_awvalid,
    output wire         s1_axi_awready,
    //
    input  wire [ 31:0] s1_axi_wdata,
    input  wire [  3:0] s1_axi_wstrb,
    input  wire         s1_axi_wvalid,
    output wire         s1_axi_wready,
    //
    output wire [  1:0] s1_axi_bresp,
    output wire         s1_axi_bvalid,
    input  wire         s1_axi_bready,
    //
    input  wire [ 11:0] s1_axi_araddr,
    input  wire [  2:0] s1_axi_arprot,
    input  wire         s1_axi_arvalid,
    output wire         s1_axi_arready,
    //
    output wire [ 31:0] s1_axi_rdata,
    output wire [  1:0] s1_axi_rresp,
    output wire         s1_axi_rvalid,
    input  wire         s1_axi_rready,
    //
    input  wire [ 11:0] s2_axi_awaddr,
    input  wire [  2:0] s2_axi_awprot,
    input  wire         s2_axi_awvalid,
    output wire         s2_axi_awready,
    //
    input  wire [ 31:0] s2_axi_wdata,
    input  wire [  3:0] s2_axi_wstrb,
    input  wire         s2_axi_wvalid,
    output wire         s2_axi_wready,
    //
    output wire [  1:0] s2_axi_bresp,
    output wire         s2_axi_bvalid,
    input  wire         s2_axi_bready,
    //
    input  wire [ 11:0] s2_axi_araddr,
    input  wire [  2:0] s2_axi_arprot,
    input  wire         s2_axi_arvalid,
    output wire         s2_axi_arready,
    //
    output wire [ 31:0] s2_axi_rdata,
    output wire [  1:0] s2_axi_rresp,
    output wire         s2_axi_rvalid,
    input  wire         s2_axi_rready,
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
    //
    input  wire [ 11:0] s3_ul_sym_num,
    input  wire [ 11:0] s3_ul_cta_sym_num,
    input  wire         s3_ul_update,
    input  wire         s3_ul_slot_update,
    input  wire [ 11:0] s3_dl_sym_num,
    input  wire [ 11:0] s3_dl_cta_sym_num,
    input  wire         s3_dl_update,
    input  wire         s3_dl_slot_update,
    input  wire         s3_ul_toggle,
    input  wire         s3_dl_toggle,
    // input  wire         s3_ul_symbol_inc,
    // input  wire         s3_dl_symbol_inc,
    input  wire         s3_cc_enable,
    input  wire         s3_cc_reload,
    //
    input  wire [ 11:0] s4_ul_sym_num,
    input  wire [ 11:0] s4_ul_cta_sym_num,
    input  wire         s4_ul_update,
    input  wire         s4_ul_slot_update,
    input  wire [ 11:0] s4_dl_sym_num,
    input  wire [ 11:0] s4_dl_cta_sym_num,
    input  wire         s4_dl_update,
    input  wire         s4_dl_slot_update,
    input  wire         s4_ul_toggle,
    input  wire         s4_dl_toggle,
    // input  wire         s4_ul_symbol_inc,
    // input  wire         s4_dl_symbol_inc,
    input  wire         s4_cc_enable,
    input  wire         s4_cc_reload,
    //
    input  wire [ 11:0] s5_ul_sym_num,
    input  wire [ 11:0] s5_ul_cta_sym_num,
    input  wire         s5_ul_update,
    input  wire         s5_ul_slot_update,
    input  wire [ 11:0] s5_dl_sym_num,
    input  wire [ 11:0] s5_dl_cta_sym_num,
    input  wire         s5_dl_update,
    input  wire         s5_dl_slot_update,
    input  wire         s5_ul_toggle,
    input  wire         s5_dl_toggle,
    // input  wire         s5_ul_symbol_inc,
    // input  wire         s5_dl_symbol_inc,
    input  wire         s5_cc_enable,
    input  wire         s5_cc_reload,
    //
    input  wire [ 11:0] s6_ul_sym_num,
    input  wire [ 11:0] s6_ul_cta_sym_num,
    input  wire         s6_ul_update,
    input  wire         s6_ul_slot_update,
    input  wire [ 11:0] s6_dl_sym_num,
    input  wire [ 11:0] s6_dl_cta_sym_num,
    input  wire         s6_dl_update,
    input  wire         s6_dl_slot_update,
    input  wire         s6_ul_toggle,
    input  wire         s6_dl_toggle,
    // input  wire         s6_ul_symbol_inc,
    // input  wire         s6_dl_symbol_inc,
    input  wire         s6_cc_enable,
    input  wire         s6_cc_reload,
    //
    input  wire [ 11:0] s7_ul_sym_num,
    input  wire [ 11:0] s7_ul_cta_sym_num,
    input  wire         s7_ul_update,
    input  wire         s7_ul_slot_update,
    input  wire [ 11:0] s7_dl_sym_num,
    input  wire [ 11:0] s7_dl_cta_sym_num,
    input  wire         s7_dl_update,
    input  wire         s7_dl_slot_update,
    input  wire         s7_ul_toggle,
    input  wire         s7_dl_toggle,
    // input  wire         s7_ul_symbol_inc,
    // input  wire         s7_dl_symbol_inc,
    input  wire         s7_cc_enable,
    input  wire         s7_cc_reload,
    //
    input  wire [ 11:0] s8_ul_sym_num,
    input  wire [ 11:0] s8_ul_cta_sym_num,
    input  wire         s8_ul_update,
    input  wire         s8_ul_slot_update,
    input  wire [ 11:0] s8_dl_sym_num,
    input  wire [ 11:0] s8_dl_cta_sym_num,
    input  wire         s8_dl_update,
    input  wire         s8_dl_slot_update,
    input  wire         s8_ul_toggle,
    input  wire         s8_dl_toggle,
    // input  wire         s8_ul_symbol_inc,
    // input  wire         s8_dl_symbol_inc,
    input  wire         s8_cc_enable,
    input  wire         s8_cc_reload,
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
    output wire [ 63:0] m004_fram_data_tdata,
    output wire [  7:0] m004_fram_data_tkeep,
    output wire         m004_fram_data_tvalid,
    output wire         m004_fram_data_tlast,
    input  wire         m004_fram_data_tready,
    input  wire [ 32:0] m004_fram_data_req,
    //
    input  wire [107:0] s004_fram_bid_debug,
    input  wire         s004_fram_bid_valid,
    input  wire         s004_fram_bid_tlast,
    output wire         s004_fram_bid_ready,
    input  wire         s004_fram_bid_off,
    input  wire [ 14:0] s004_fram_bid_beamid15,
    input  wire [ 11:0] s004_fram_bid_remask,
    input  wire         s004_fram_bid_rb,
    input  wire [  9:0] s004_fram_bid_start_prbc,
    input  wire [  7:0] s004_fram_bid_num_prbc,
    input  wire [  3:0] s004_fram_bid_num_symbol,
    input  wire [  7:0] s004_fram_bid_cc_id,
    input  wire [ 23:0] s004_fram_bid_frequency_offset,
    input  wire [ 15:0] s004_fram_bid_time_offset,
    input  wire [  7:0] s004_fram_bid_frame_structure,
    input  wire [ 15:0] s004_fram_bid_cp_length,
    //
    output wire [ 63:0] m005_fram_data_tdata,
    output wire [  7:0] m005_fram_data_tkeep,
    output wire         m005_fram_data_tvalid,
    output wire         m005_fram_data_tlast,
    input  wire         m005_fram_data_tready,
    input  wire [ 32:0] m005_fram_data_req,
    //
    input  wire [107:0] s005_fram_bid_debug,
    input  wire         s005_fram_bid_valid,
    input  wire         s005_fram_bid_tlast,
    output wire         s005_fram_bid_ready,
    input  wire         s005_fram_bid_off,
    input  wire [ 14:0] s005_fram_bid_beamid15,
    input  wire [ 11:0] s005_fram_bid_remask,
    input  wire         s005_fram_bid_rb,
    input  wire [  9:0] s005_fram_bid_start_prbc,
    input  wire [  7:0] s005_fram_bid_num_prbc,
    input  wire [  3:0] s005_fram_bid_num_symbol,
    input  wire [  7:0] s005_fram_bid_cc_id,
    input  wire [ 23:0] s005_fram_bid_frequency_offset,
    input  wire [ 15:0] s005_fram_bid_time_offset,
    input  wire [  7:0] s005_fram_bid_frame_structure,
    input  wire [ 15:0] s005_fram_bid_cp_length,
    //
    output wire [ 63:0] m006_fram_data_tdata,
    output wire [  7:0] m006_fram_data_tkeep,
    output wire         m006_fram_data_tvalid,
    output wire         m006_fram_data_tlast,
    input  wire         m006_fram_data_tready,
    input  wire [ 32:0] m006_fram_data_req,
    //
    input  wire [107:0] s006_fram_bid_debug,
    input  wire         s006_fram_bid_valid,
    input  wire         s006_fram_bid_tlast,
    output wire         s006_fram_bid_ready,
    input  wire         s006_fram_bid_off,
    input  wire [ 14:0] s006_fram_bid_beamid15,
    input  wire [ 11:0] s006_fram_bid_remask,
    input  wire         s006_fram_bid_rb,
    input  wire [  9:0] s006_fram_bid_start_prbc,
    input  wire [  7:0] s006_fram_bid_num_prbc,
    input  wire [  3:0] s006_fram_bid_num_symbol,
    input  wire [  7:0] s006_fram_bid_cc_id,
    input  wire [ 23:0] s006_fram_bid_frequency_offset,
    input  wire [ 15:0] s006_fram_bid_time_offset,
    input  wire [  7:0] s006_fram_bid_frame_structure,
    input  wire [ 15:0] s006_fram_bid_cp_length,
    //
    output wire [ 63:0] m007_fram_data_tdata,
    output wire [  7:0] m007_fram_data_tkeep,
    output wire         m007_fram_data_tvalid,
    output wire         m007_fram_data_tlast,
    input  wire         m007_fram_data_tready,
    input  wire [ 32:0] m007_fram_data_req,
    //
    input  wire [107:0] s007_fram_bid_debug,
    input  wire         s007_fram_bid_valid,
    input  wire         s007_fram_bid_tlast,
    output wire         s007_fram_bid_ready,
    input  wire         s007_fram_bid_off,
    input  wire [ 14:0] s007_fram_bid_beamid15,
    input  wire [ 11:0] s007_fram_bid_remask,
    input  wire         s007_fram_bid_rb,
    input  wire [  9:0] s007_fram_bid_start_prbc,
    input  wire [  7:0] s007_fram_bid_num_prbc,
    input  wire [  3:0] s007_fram_bid_num_symbol,
    input  wire [  7:0] s007_fram_bid_cc_id,
    input  wire [ 23:0] s007_fram_bid_frequency_offset,
    input  wire [ 15:0] s007_fram_bid_time_offset,
    input  wire [  7:0] s007_fram_bid_frame_structure,
    input  wire [ 15:0] s007_fram_bid_cp_length,
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
    //
    input  wire [ 63:0] s004_defm_data_tdata,
    input  wire [  7:0] s004_defm_data_tkeep,
    input  wire         s004_defm_data_tvalid,
    input  wire         s004_defm_data_tlast,
    output wire         s004_defm_data_tready,
    input  wire [ 90:0] s004_defm_data_tuser,
    input  wire [  4:0] s004_defm_data_tdest,
    //
    input  wire         s004_defm_bid_valid,
    input  wire         s004_defm_bid_tlast,
    output wire         s004_defm_bid_ready,
    input  wire         s004_defm_bid_off,
    input  wire [ 14:0] s004_defm_bid_beamid15,
    input  wire [ 11:0] s004_defm_bid_remask,
    input  wire         s004_defm_bid_rb,
    input  wire [  9:0] s004_defm_bid_start_prbc,
    input  wire [  7:0] s004_defm_bid_num_prbc,
    input  wire [  3:0] s004_defm_bid_num_symbol,
    input  wire [  7:0] s004_defm_bid_cc_id,
    input  wire [ 23:0] s004_defm_bid_frequency_offset,
    input  wire [ 15:0] s004_defm_bid_time_offset,
    input  wire [  7:0] s004_defm_bid_frame_structure,
    input  wire [ 15:0] s004_defm_bid_cp_length,
    //
    input  wire [ 63:0] s005_defm_data_tdata,
    input  wire [  7:0] s005_defm_data_tkeep,
    input  wire         s005_defm_data_tvalid,
    input  wire         s005_defm_data_tlast,
    output wire         s005_defm_data_tready,
    input  wire [ 90:0] s005_defm_data_tuser,
    input  wire [  4:0] s005_defm_data_tdest,
    //
    input  wire         s005_defm_bid_valid,
    input  wire         s005_defm_bid_tlast,
    output wire         s005_defm_bid_ready,
    input  wire         s005_defm_bid_off,
    input  wire [ 14:0] s005_defm_bid_beamid15,
    input  wire [ 11:0] s005_defm_bid_remask,
    input  wire         s005_defm_bid_rb,
    input  wire [  9:0] s005_defm_bid_start_prbc,
    input  wire [  7:0] s005_defm_bid_num_prbc,
    input  wire [  3:0] s005_defm_bid_num_symbol,
    input  wire [  7:0] s005_defm_bid_cc_id,
    input  wire [ 23:0] s005_defm_bid_frequency_offset,
    input  wire [ 15:0] s005_defm_bid_time_offset,
    input  wire [  7:0] s005_defm_bid_frame_structure,
    input  wire [ 15:0] s005_defm_bid_cp_length,
    //
    input  wire [ 63:0] s006_defm_data_tdata,
    input  wire [  7:0] s006_defm_data_tkeep,
    input  wire         s006_defm_data_tvalid,
    input  wire         s006_defm_data_tlast,
    output wire         s006_defm_data_tready,
    input  wire [ 90:0] s006_defm_data_tuser,
    input  wire [  4:0] s006_defm_data_tdest,
    //
    input  wire         s006_defm_bid_valid,
    input  wire         s006_defm_bid_tlast,
    output wire         s006_defm_bid_ready,
    input  wire         s006_defm_bid_off,
    input  wire [ 14:0] s006_defm_bid_beamid15,
    input  wire [ 11:0] s006_defm_bid_remask,
    input  wire         s006_defm_bid_rb,
    input  wire [  9:0] s006_defm_bid_start_prbc,
    input  wire [  7:0] s006_defm_bid_num_prbc,
    input  wire [  3:0] s006_defm_bid_num_symbol,
    input  wire [  7:0] s006_defm_bid_cc_id,
    input  wire [ 23:0] s006_defm_bid_frequency_offset,
    input  wire [ 15:0] s006_defm_bid_time_offset,
    input  wire [  7:0] s006_defm_bid_frame_structure,
    input  wire [ 15:0] s006_defm_bid_cp_length,
    //
    input  wire [ 63:0] s007_defm_data_tdata,
    input  wire [  7:0] s007_defm_data_tkeep,
    input  wire         s007_defm_data_tvalid,
    input  wire         s007_defm_data_tlast,
    output wire         s007_defm_data_tready,
    input  wire [ 90:0] s007_defm_data_tuser,
    input  wire [  4:0] s007_defm_data_tdest,
    //
    input  wire         s007_defm_bid_valid,
    input  wire         s007_defm_bid_tlast,
    output wire         s007_defm_bid_ready,
    input  wire         s007_defm_bid_off,
    input  wire [ 14:0] s007_defm_bid_beamid15,
    input  wire [ 11:0] s007_defm_bid_remask,
    input  wire         s007_defm_bid_rb,
    input  wire [  9:0] s007_defm_bid_start_prbc,
    input  wire [  7:0] s007_defm_bid_num_prbc,
    input  wire [  3:0] s007_defm_bid_num_symbol,
    input  wire [  7:0] s007_defm_bid_cc_id,
    input  wire [ 23:0] s007_defm_bid_frequency_offset,
    input  wire [ 15:0] s007_defm_bid_time_offset,
    input  wire [  7:0] s007_defm_bid_frame_structure,
    input  wire [ 15:0] s007_defm_bid_cp_length,
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
    output wire         fram_radio_start_10ms_cc3,
    output wire         defm_radio_start_10ms_cc3,
    output wire         fram_radio_start_10ms_cc4,
    output wire         defm_radio_start_10ms_cc4,
    output wire         fram_radio_start_10ms_cc5,
    output wire         defm_radio_start_10ms_cc5,
    output wire         fram_radio_start_10ms_cc6,
    output wire         defm_radio_start_10ms_cc6,
    output wire         fram_radio_start_10ms_cc7,
    output wire         defm_radio_start_10ms_cc7,
    output wire         fram_radio_start_10ms_cc8,
    output wire         defm_radio_start_10ms_cc8,
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
    output wire [767:0] m_dl_axis_tdata,
    output wire [  7:0] m_dl_axis_tuser,
    output wire         m_dl_axis_tlast,
    output wire         m_dl_axis_tvalid,
    input  wire         m_dl_axis_tready,
    //
    input  wire [767:0] s_ul_axis_tdata,
    input  wire [  7:0] s_ul_axis_tuser,
    input  wire         s_ul_axis_tlast,
    input  wire         s_ul_axis_tvalid,
    output wire         s_ul_axis_tready
);

  // Parameters

  localparam int NumCc = 3;
  localparam int NumAnt = 8;
  localparam bit HalfBlock = 1'b1;

  // Signals

  logic [31:0] m0_axis_tdata [NumCc][4];
  logic [ 7:0] m0_axis_tuser [NumCc][4];
  logic        m0_axis_tlast [NumCc][4];
  logic        m0_axis_tvalid[NumCc][4];
  logic        m0_axis_tready[NumCc][4];

  logic [31:0] s0_axis_tdata [NumCc][4];
  logic [ 7:0] s0_axis_tuser [NumCc][4];
  logic        s0_axis_tlast [NumCc][4];
  logic        s0_axis_tvalid[NumCc][4];
  logic        s0_axis_tready[NumCc][4];


  logic [31:0] m1_axis_tdata [NumCc][2];
  logic [ 7:0] m1_axis_tuser [NumCc][2];
  logic        m1_axis_tlast [NumCc][2];
  logic        m1_axis_tvalid[NumCc][2];
  logic        m1_axis_tready[NumCc][2];

  logic [31:0] s1_axis_tdata [NumCc][2];
  logic [ 7:0] s1_axis_tuser [NumCc][2];
  logic        s1_axis_tlast [NumCc][2];
  logic        s1_axis_tvalid[NumCc][2];
  logic        s1_axis_tready[NumCc][2];

  logic [31:0] m2_axis_tdata [NumCc][2];
  logic [ 7:0] m2_axis_tuser [NumCc][2];
  logic        m2_axis_tlast [NumCc][2];
  logic        m2_axis_tvalid[NumCc][2];
  logic        m2_axis_tready[NumCc][2];

  logic [31:0] s2_axis_tdata [NumCc][2];
  logic [ 7:0] s2_axis_tuser [NumCc][2];
  logic        s2_axis_tlast [NumCc][2];
  logic        s2_axis_tvalid[NumCc][2];
  logic        s2_axis_tready[NumCc][2];

  generate
    for (genvar unused_cc = 0; unused_cc < NumCc; unused_cc++) begin : gen_unused_cc
      for (genvar unused_ant0 = 0; unused_ant0 < 4; unused_ant0++) begin : gen_unused_ant0
        wire unused_s0_ready;

        assign unused_s0_ready = &{1'b0, s0_axis_tready[unused_cc][unused_ant0]};
      end

      for (genvar unused_ant = 0; unused_ant < 2; unused_ant++) begin : gen_unused_ant12
        wire unused_secondary_axis;

        assign unused_secondary_axis = &{
            1'b0,
            m1_axis_tuser[unused_cc][unused_ant],
            m1_axis_tlast[unused_cc][unused_ant],
            m1_axis_tvalid[unused_cc][unused_ant],
            s1_axis_tready[unused_cc][unused_ant],
            m2_axis_tuser[unused_cc][unused_ant],
            m2_axis_tlast[unused_cc][unused_ant],
            m2_axis_tvalid[unused_cc][unused_ant],
            s2_axis_tready[unused_cc][unused_ant]
        };
      end
    end
  endgenerate

  // Unsol

  wire [63:0] s0_fram_unsol_tdata;
  wire [ 7:0] s0_fram_unsol_tkeep;
  wire        s0_fram_unsol_tvalid;
  wire        s0_fram_unsol_tlast;
  wire        s0_fram_unsol_tready;
  wire [31:0] s0_fram_unsol_tuser;

  wire [63:0] s1_fram_unsol_tdata;
  wire [ 7:0] s1_fram_unsol_tkeep;
  wire        s1_fram_unsol_tvalid;
  wire        s1_fram_unsol_tlast;
  wire        s1_fram_unsol_tready;
  wire [31:0] s1_fram_unsol_tuser;

  wire [63:0] s2_fram_unsol_tdata;
  wire [ 7:0] s2_fram_unsol_tkeep;
  wire        s2_fram_unsol_tvalid;
  wire        s2_fram_unsol_tlast;
  wire        s2_fram_unsol_tready;
  wire [31:0] s2_fram_unsol_tuser;

  // PRACH

  wire [63:0] s0_fram_prach_tdata;
  wire [ 7:0] s0_fram_prach_tkeep;
  wire        s0_fram_prach_tvalid;
  wire        s0_fram_prach_tlast;
  wire        s0_fram_prach_tready;
  wire [31:0] s0_fram_prach_tuser;

  wire [63:0] s1_fram_prach_tdata;
  wire [ 7:0] s1_fram_prach_tkeep;
  wire        s1_fram_prach_tvalid;
  wire        s1_fram_prach_tlast;
  wire        s1_fram_prach_tready;
  wire [31:0] s1_fram_prach_tuser;

  wire [63:0] s2_fram_prach_tdata;
  wire [ 7:0] s2_fram_prach_tkeep;
  wire        s2_fram_prach_tvalid;
  wire        s2_fram_prach_tlast;
  wire        s2_fram_prach_tready;
  wire [31:0] s2_fram_prach_tuser;

  // Main

  lowphy_band #(
      .NUM_CC    (NumCc),
      .NUM_ANT   (NumAnt / 2),
      .HALF_BLOCK(HalfBlock)
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
      .m_fram_unsol_tdata            (s0_fram_unsol_tdata),
      .m_fram_unsol_tkeep            (s0_fram_unsol_tkeep),
      .m_fram_unsol_tvalid           (s0_fram_unsol_tvalid),
      .m_fram_unsol_tlast            (s0_fram_unsol_tlast),
      .m_fram_unsol_tready           (s0_fram_unsol_tready),
      .m_fram_unsol_tuser            (s0_fram_unsol_tuser),
      //
      .m_fram_prach_tdata            (s0_fram_prach_tdata),
      .m_fram_prach_tkeep            (s0_fram_prach_tkeep),
      .m_fram_prach_tvalid           (s0_fram_prach_tvalid),
      .m_fram_prach_tlast            (s0_fram_prach_tlast),
      .m_fram_prach_tready           (s0_fram_prach_tready),
      .m_fram_prach_tuser            (s0_fram_prach_tuser),
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
      .m_axis_tdata                  (m0_axis_tdata),
      .m_axis_tuser                  (m0_axis_tuser),
      .m_axis_tlast                  (m0_axis_tlast),
      .m_axis_tvalid                 (m0_axis_tvalid),
      .m_axis_tready                 (m0_axis_tready),
      //
      .s_axis_tdata                  (s0_axis_tdata),
      .s_axis_tuser                  (s0_axis_tuser),
      .s_axis_tlast                  (s0_axis_tlast),
      .s_axis_tvalid                 (s0_axis_tvalid),
      .s_axis_tready                 (s0_axis_tready)
  );

  lowphy_band #(
      .NUM_CC    (NumCc),
      .NUM_ANT   (NumAnt / 4),
      .CC_ID     (0),
      .ANT_ID    (0),
      .HALF_BLOCK(HalfBlock)
  ) u_b1 (
      // AXI
      //----
      .s_axi_aclk                    (s_axi_aclk),
      .s_axi_aresetn                 (s_axi_aresetn),
      //
      .s_axi_awaddr                  (s1_axi_awaddr),
      .s_axi_awprot                  (s1_axi_awprot),
      .s_axi_awvalid                 (s1_axi_awvalid),
      .s_axi_awready                 (s1_axi_awready),
      //
      .s_axi_wdata                   (s1_axi_wdata),
      .s_axi_wstrb                   (s1_axi_wstrb),
      .s_axi_wvalid                  (s1_axi_wvalid),
      .s_axi_wready                  (s1_axi_wready),
      //
      .s_axi_bresp                   (s1_axi_bresp),
      .s_axi_bvalid                  (s1_axi_bvalid),
      .s_axi_bready                  (s1_axi_bready),
      //
      .s_axi_araddr                  (s1_axi_araddr),
      .s_axi_arprot                  (s1_axi_arprot),
      .s_axi_arvalid                 (s1_axi_arvalid),
      .s_axi_arready                 (s1_axi_arready),
      //
      .s_axi_rdata                   (s1_axi_rdata),
      .s_axi_rresp                   (s1_axi_rresp),
      .s_axi_rvalid                  (s1_axi_rvalid),
      .s_axi_rready                  (s1_axi_rready),
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
      .s_ul_sym_num                  ('{s3_ul_sym_num,     s4_ul_sym_num,     s5_ul_sym_num}),
      .s_ul_cta_sym_num              ('{s3_ul_cta_sym_num, s4_ul_cta_sym_num, s5_ul_cta_sym_num}),
      .s_ul_update                   ('{s3_ul_update,      s4_ul_update,      s5_ul_update}),
      .s_ul_slot_update              ('{s3_ul_slot_update, s4_ul_slot_update, s5_ul_slot_update}),
      .s_dl_sym_num                  ('{s3_dl_sym_num,     s4_dl_sym_num,     s5_dl_sym_num}),
      .s_dl_cta_sym_num              ('{s3_dl_cta_sym_num, s4_dl_cta_sym_num, s5_dl_cta_sym_num}),
      .s_dl_update                   ('{s3_dl_update,      s4_dl_update,      s5_dl_update}),
      .s_dl_slot_update              ('{s3_dl_slot_update, s4_dl_slot_update, s5_dl_slot_update}),
      .s_ul_toggle                   ('{s3_ul_toggle,      s4_ul_toggle,      s5_ul_toggle}),
      .s_dl_toggle                   ('{s3_dl_toggle,      s4_dl_toggle,      s5_dl_toggle}),
      // .s_ul_symbol_inc               ('{s3_ul_symbol_inc,  s4_ul_symbol_inc,  s5_ul_symbol_inc}),
      // .s_dl_symbol_inc               ('{s3_dl_symbol_inc,  s4_dl_symbol_inc,  s5_dl_symbol_inc}),
      .s_cc_enable                   ('{s3_cc_enable,      s4_cc_enable,      s5_cc_enable}),
      .s_cc_reload                   ('{s3_cc_reload,      s4_cc_reload,      s5_cc_reload}),
      // CARRIER ports for the Framer, the datapath to the ethernet
      .m_fram_data_tdata             ('{m004_fram_data_tdata,  m005_fram_data_tdata}),
      .m_fram_data_tkeep             ('{m004_fram_data_tkeep,  m005_fram_data_tkeep}),
      .m_fram_data_tvalid            ('{m004_fram_data_tvalid, m005_fram_data_tvalid}),
      .m_fram_data_tlast             ('{m004_fram_data_tlast,  m005_fram_data_tlast}),
      .m_fram_data_tready            ('{m004_fram_data_tready, m005_fram_data_tready}),
      .m_fram_data_req               ('{m004_fram_data_req,    m005_fram_data_req}),
      //
      .s_fram_bid_debug              ('{s004_fram_bid_debug,            s005_fram_bid_debug}),
      .s_fram_bid_valid              ('{s004_fram_bid_valid,            s005_fram_bid_valid}),
      .s_fram_bid_tlast              ('{s004_fram_bid_tlast,            s005_fram_bid_tlast}),
      .s_fram_bid_ready              ('{s004_fram_bid_ready,            s005_fram_bid_ready}),
      .s_fram_bid_off                ('{s004_fram_bid_off,              s005_fram_bid_off}),
      .s_fram_bid_beamid15           ('{s004_fram_bid_beamid15,         s005_fram_bid_beamid15}),
      .s_fram_bid_remask             ('{s004_fram_bid_remask,           s005_fram_bid_remask}),
      .s_fram_bid_rb                 ('{s004_fram_bid_rb,               s005_fram_bid_rb}),
      .s_fram_bid_start_prbc         ('{s004_fram_bid_start_prbc,       s005_fram_bid_start_prbc}),
      .s_fram_bid_num_prbc           ('{s004_fram_bid_num_prbc,         s005_fram_bid_num_prbc}),
      .s_fram_bid_num_symbol         ('{s004_fram_bid_num_symbol,       s005_fram_bid_num_symbol}),
      .s_fram_bid_cc_id              ('{s004_fram_bid_cc_id,            s005_fram_bid_cc_id}),
      .s_fram_bid_frequency_offset   ('{s004_fram_bid_frequency_offset, s005_fram_bid_frequency_offset}),
      .s_fram_bid_time_offset        ('{s004_fram_bid_time_offset,      s005_fram_bid_time_offset}),
      .s_fram_bid_frame_structure    ('{s004_fram_bid_frame_structure,  s005_fram_bid_frame_structure}),
      .s_fram_bid_cp_length          ('{s004_fram_bid_cp_length,        s005_fram_bid_cp_length}),
      // verilog_format: on
      .m_fram_unsol_tdata            (s1_fram_unsol_tdata),
      .m_fram_unsol_tkeep            (s1_fram_unsol_tkeep),
      .m_fram_unsol_tvalid           (s1_fram_unsol_tvalid),
      .m_fram_unsol_tlast            (s1_fram_unsol_tlast),
      .m_fram_unsol_tready           (s1_fram_unsol_tready),
      .m_fram_unsol_tuser            (s1_fram_unsol_tuser),
      //
      .m_fram_prach_tdata            (s1_fram_prach_tdata),
      .m_fram_prach_tkeep            (s1_fram_prach_tkeep),
      .m_fram_prach_tvalid           (s1_fram_prach_tvalid),
      .m_fram_prach_tlast            (s1_fram_prach_tlast),
      .m_fram_prach_tready           (s1_fram_prach_tready),
      .m_fram_prach_tuser            (s1_fram_prach_tuser),
      // CARRIER ports from the Framer, the datapath from the ethernet
      // verilog_format: off
      .s_defm_data_tdata             ('{s004_defm_data_tdata,  s005_defm_data_tdata}),
      .s_defm_data_tkeep             ('{s004_defm_data_tkeep,  s005_defm_data_tkeep}),
      .s_defm_data_tvalid            ('{s004_defm_data_tvalid, s005_defm_data_tvalid}),
      .s_defm_data_tlast             ('{s004_defm_data_tlast,  s005_defm_data_tlast}),
      .s_defm_data_tready            ('{s004_defm_data_tready, s005_defm_data_tready}),
      .s_defm_data_tuser             ('{s004_defm_data_tuser,  s005_defm_data_tuser}),
      .s_defm_data_tdest             ('{s004_defm_data_tdest,  s005_defm_data_tdest}),
      //
      .s_defm_bid_valid              ('{s004_defm_bid_valid,            s005_defm_bid_valid}),
      .s_defm_bid_tlast              ('{s004_defm_bid_tlast,            s005_defm_bid_tlast}),
      .s_defm_bid_ready              ('{s004_defm_bid_ready,            s005_defm_bid_ready}),
      .s_defm_bid_off                ('{s004_defm_bid_off,              s005_defm_bid_off}),
      .s_defm_bid_beamid15           ('{s004_defm_bid_beamid15,         s005_defm_bid_beamid15}),
      .s_defm_bid_remask             ('{s004_defm_bid_remask,           s005_defm_bid_remask}),
      .s_defm_bid_rb                 ('{s004_defm_bid_rb,               s005_defm_bid_rb}),
      .s_defm_bid_start_prbc         ('{s004_defm_bid_start_prbc,       s005_defm_bid_start_prbc}),
      .s_defm_bid_num_prbc           ('{s004_defm_bid_num_prbc,         s005_defm_bid_num_prbc}),
      .s_defm_bid_num_symbol         ('{s004_defm_bid_num_symbol,       s005_defm_bid_num_symbol}),
      .s_defm_bid_cc_id              ('{s004_defm_bid_cc_id,            s005_defm_bid_cc_id}),
      .s_defm_bid_frequency_offset   ('{s004_defm_bid_frequency_offset, s005_defm_bid_frequency_offset}),
      .s_defm_bid_time_offset        ('{s004_defm_bid_time_offset,      s005_defm_bid_time_offset}),
      .s_defm_bid_frame_structure    ('{s004_defm_bid_frame_structure,  s005_defm_bid_frame_structure}),
      .s_defm_bid_cp_length          ('{s004_defm_bid_cp_length,        s005_defm_bid_cp_length}),
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
      .fram_radio_start_10ms         ('{fram_radio_start_10ms_cc3, fram_radio_start_10ms_cc4, fram_radio_start_10ms_cc5}),
      .defm_radio_start_10ms         ('{defm_radio_start_10ms_cc3, defm_radio_start_10ms_cc4, defm_radio_start_10ms_cc5}),
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
      .m_axis_tdata                  (m1_axis_tdata),
      .m_axis_tuser                  (m1_axis_tuser),
      .m_axis_tlast                  (m1_axis_tlast),
      .m_axis_tvalid                 (m1_axis_tvalid),
      .m_axis_tready                 (m1_axis_tready),
      //
      .s_axis_tdata                  (s1_axis_tdata),
      .s_axis_tuser                  (s1_axis_tuser),
      .s_axis_tlast                  (s1_axis_tlast),
      .s_axis_tvalid                 (s1_axis_tvalid),
      .s_axis_tready                 (s1_axis_tready)
  );

  lowphy_band #(
      .NUM_CC    (NumCc),
      .NUM_ANT   (NumAnt / 4),
      .CC_ID     (0),
      .ANT_ID    (2),
      .HALF_BLOCK(HalfBlock)
  ) u_b2 (
      // AXI
      //----
      .s_axi_aclk                    (s_axi_aclk),
      .s_axi_aresetn                 (s_axi_aresetn),
      //
      .s_axi_awaddr                  (s2_axi_awaddr),
      .s_axi_awprot                  (s2_axi_awprot),
      .s_axi_awvalid                 (s2_axi_awvalid),
      .s_axi_awready                 (s2_axi_awready),
      //
      .s_axi_wdata                   (s2_axi_wdata),
      .s_axi_wstrb                   (s2_axi_wstrb),
      .s_axi_wvalid                  (s2_axi_wvalid),
      .s_axi_wready                  (s2_axi_wready),
      //
      .s_axi_bresp                   (s2_axi_bresp),
      .s_axi_bvalid                  (s2_axi_bvalid),
      .s_axi_bready                  (s2_axi_bready),
      //
      .s_axi_araddr                  (s2_axi_araddr),
      .s_axi_arprot                  (s2_axi_arprot),
      .s_axi_arvalid                 (s2_axi_arvalid),
      .s_axi_arready                 (s2_axi_arready),
      //
      .s_axi_rdata                   (s2_axi_rdata),
      .s_axi_rresp                   (s2_axi_rresp),
      .s_axi_rvalid                  (s2_axi_rvalid),
      .s_axi_rready                  (s2_axi_rready),
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
      .s_ul_sym_num                  ('{s6_ul_sym_num,     s7_ul_sym_num,     s8_ul_sym_num}),
      .s_ul_cta_sym_num              ('{s6_ul_cta_sym_num, s7_ul_cta_sym_num, s8_ul_cta_sym_num}),
      .s_ul_update                   ('{s6_ul_update,      s7_ul_update,      s8_ul_update}),
      .s_ul_slot_update              ('{s6_ul_slot_update, s7_ul_slot_update, s8_ul_slot_update}),
      .s_dl_sym_num                  ('{s6_dl_sym_num,     s7_dl_sym_num,     s8_dl_sym_num}),
      .s_dl_cta_sym_num              ('{s6_dl_cta_sym_num, s7_dl_cta_sym_num, s8_dl_cta_sym_num}),
      .s_dl_update                   ('{s6_dl_update,      s7_dl_update,      s8_dl_update}),
      .s_dl_slot_update              ('{s6_dl_slot_update, s7_dl_slot_update, s8_dl_slot_update}),
      .s_ul_toggle                   ('{s6_ul_toggle,      s7_ul_toggle,      s8_ul_toggle}),
      .s_dl_toggle                   ('{s6_dl_toggle,      s7_dl_toggle,      s8_dl_toggle}),
      // .s_ul_symbol_inc               ('{s6_ul_symbol_inc,  s7_ul_symbol_inc,  s8_ul_symbol_inc}),
      // .s_dl_symbol_inc               ('{s6_dl_symbol_inc,  s7_dl_symbol_inc,  s8_dl_symbol_inc}),
      .s_cc_enable                   ('{s6_cc_enable,      s7_cc_enable,      s8_cc_enable}),
      .s_cc_reload                   ('{s6_cc_reload,      s7_cc_reload,      s8_cc_reload}),
      // CARRIER ports for the Framer, the datapath to the ethernet
      .m_fram_data_tdata             ('{m006_fram_data_tdata,  m007_fram_data_tdata}),
      .m_fram_data_tkeep             ('{m006_fram_data_tkeep,  m007_fram_data_tkeep}),
      .m_fram_data_tvalid            ('{m006_fram_data_tvalid, m007_fram_data_tvalid}),
      .m_fram_data_tlast             ('{m006_fram_data_tlast,  m007_fram_data_tlast}),
      .m_fram_data_tready            ('{m006_fram_data_tready, m007_fram_data_tready}),
      .m_fram_data_req               ('{m006_fram_data_req,    m007_fram_data_req}),
      //
      .s_fram_bid_debug              ('{s006_fram_bid_debug,            s007_fram_bid_debug}),
      .s_fram_bid_valid              ('{s006_fram_bid_valid,            s007_fram_bid_valid}),
      .s_fram_bid_tlast              ('{s006_fram_bid_tlast,            s007_fram_bid_tlast}),
      .s_fram_bid_ready              ('{s006_fram_bid_ready,            s007_fram_bid_ready}),
      .s_fram_bid_off                ('{s006_fram_bid_off,              s007_fram_bid_off}),
      .s_fram_bid_beamid15           ('{s006_fram_bid_beamid15,         s007_fram_bid_beamid15}),
      .s_fram_bid_remask             ('{s006_fram_bid_remask,           s007_fram_bid_remask}),
      .s_fram_bid_rb                 ('{s006_fram_bid_rb,               s007_fram_bid_rb}),
      .s_fram_bid_start_prbc         ('{s006_fram_bid_start_prbc,       s007_fram_bid_start_prbc}),
      .s_fram_bid_num_prbc           ('{s006_fram_bid_num_prbc,         s007_fram_bid_num_prbc}),
      .s_fram_bid_num_symbol         ('{s006_fram_bid_num_symbol,       s007_fram_bid_num_symbol}),
      .s_fram_bid_cc_id              ('{s006_fram_bid_cc_id,            s007_fram_bid_cc_id}),
      .s_fram_bid_frequency_offset   ('{s006_fram_bid_frequency_offset, s007_fram_bid_frequency_offset}),
      .s_fram_bid_time_offset        ('{s006_fram_bid_time_offset,      s007_fram_bid_time_offset}),
      .s_fram_bid_frame_structure    ('{s006_fram_bid_frame_structure,  s007_fram_bid_frame_structure}),
      .s_fram_bid_cp_length          ('{s006_fram_bid_cp_length,        s007_fram_bid_cp_length}),
      // verilog_format: on
      .m_fram_unsol_tdata            (s2_fram_unsol_tdata),
      .m_fram_unsol_tkeep            (s2_fram_unsol_tkeep),
      .m_fram_unsol_tvalid           (s2_fram_unsol_tvalid),
      .m_fram_unsol_tlast            (s2_fram_unsol_tlast),
      .m_fram_unsol_tready           (s2_fram_unsol_tready),
      .m_fram_unsol_tuser            (s2_fram_unsol_tuser),
      //
      .m_fram_prach_tdata            (s2_fram_prach_tdata),
      .m_fram_prach_tkeep            (s2_fram_prach_tkeep),
      .m_fram_prach_tvalid           (s2_fram_prach_tvalid),
      .m_fram_prach_tlast            (s2_fram_prach_tlast),
      .m_fram_prach_tready           (s2_fram_prach_tready),
      .m_fram_prach_tuser            (s2_fram_prach_tuser),
      // CARRIER ports from the Framer, the datapath from the ethernet
      // verilog_format: off
      .s_defm_data_tdata             ('{s006_defm_data_tdata,  s007_defm_data_tdata}),
      .s_defm_data_tkeep             ('{s006_defm_data_tkeep,  s007_defm_data_tkeep}),
      .s_defm_data_tvalid            ('{s006_defm_data_tvalid, s007_defm_data_tvalid}),
      .s_defm_data_tlast             ('{s006_defm_data_tlast,  s007_defm_data_tlast}),
      .s_defm_data_tready            ('{s006_defm_data_tready, s007_defm_data_tready}),
      .s_defm_data_tuser             ('{s006_defm_data_tuser,  s007_defm_data_tuser}),
      .s_defm_data_tdest             ('{s006_defm_data_tdest,  s007_defm_data_tdest}),
      //
      .s_defm_bid_valid              ('{s006_defm_bid_valid,            s007_defm_bid_valid}),
      .s_defm_bid_tlast              ('{s006_defm_bid_tlast,            s007_defm_bid_tlast}),
      .s_defm_bid_ready              ('{s006_defm_bid_ready,            s007_defm_bid_ready}),
      .s_defm_bid_off                ('{s006_defm_bid_off,              s007_defm_bid_off}),
      .s_defm_bid_beamid15           ('{s006_defm_bid_beamid15,         s007_defm_bid_beamid15}),
      .s_defm_bid_remask             ('{s006_defm_bid_remask,           s007_defm_bid_remask}),
      .s_defm_bid_rb                 ('{s006_defm_bid_rb,               s007_defm_bid_rb}),
      .s_defm_bid_start_prbc         ('{s006_defm_bid_start_prbc,       s007_defm_bid_start_prbc}),
      .s_defm_bid_num_prbc           ('{s006_defm_bid_num_prbc,         s007_defm_bid_num_prbc}),
      .s_defm_bid_num_symbol         ('{s006_defm_bid_num_symbol,       s007_defm_bid_num_symbol}),
      .s_defm_bid_cc_id              ('{s006_defm_bid_cc_id,            s007_defm_bid_cc_id}),
      .s_defm_bid_frequency_offset   ('{s006_defm_bid_frequency_offset, s007_defm_bid_frequency_offset}),
      .s_defm_bid_time_offset        ('{s006_defm_bid_time_offset,      s007_defm_bid_time_offset}),
      .s_defm_bid_frame_structure    ('{s006_defm_bid_frame_structure,  s007_defm_bid_frame_structure}),
      .s_defm_bid_cp_length          ('{s006_defm_bid_cp_length,        s007_defm_bid_cp_length}),
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
      .fram_radio_start_10ms         ('{fram_radio_start_10ms_cc6, fram_radio_start_10ms_cc7, fram_radio_start_10ms_cc8}),
      .defm_radio_start_10ms         ('{defm_radio_start_10ms_cc6, defm_radio_start_10ms_cc7, defm_radio_start_10ms_cc8}),
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
      .m_axis_tdata                  (m2_axis_tdata),
      .m_axis_tuser                  (m2_axis_tuser),
      .m_axis_tlast                  (m2_axis_tlast),
      .m_axis_tvalid                 (m2_axis_tvalid),
      .m_axis_tready                 (m2_axis_tready),
      //
      .s_axis_tdata                  (s2_axis_tdata),
      .s_axis_tuser                  (s2_axis_tuser),
      .s_axis_tlast                  (s2_axis_tlast),
      .s_axis_tvalid                 (s2_axis_tvalid),
      .s_axis_tready                 (s2_axis_tready)
  );

  generate
    for (genvar cc = 0; cc < NumCc; cc++) begin : gen_cc
      for (genvar ant = 0; ant < NumAnt; ant++) begin : gen_ant
        if (ant < 4) begin : gen_band0_ant

          assign m_dl_axis_tdata[(cc*NumAnt+ant)*32+31-:32] = m0_axis_tdata[cc][ant];
          assign m0_axis_tready[cc][ant] = m_dl_axis_tready;
          assign s0_axis_tdata[cc][ant] = s_ul_axis_tdata[(cc*NumAnt+ant)*32+31-:32];
          assign s0_axis_tuser[cc][ant] = s_ul_axis_tuser;
          assign s0_axis_tlast[cc][ant] = s_ul_axis_tlast;
          assign s0_axis_tvalid[cc][ant] = s_ul_axis_tvalid;

        end else if (ant < 6) begin : gen_band1_ant

          assign m_dl_axis_tdata[(cc*NumAnt+ant)*32+31-:32] = m1_axis_tdata[cc][ant-4];
          assign m1_axis_tready[cc][ant-4] = m_dl_axis_tready;
          assign s1_axis_tdata[cc][ant-4] = s_ul_axis_tdata[(cc*NumAnt+ant)*32+31-:32];
          assign s1_axis_tuser[cc][ant-4] = s_ul_axis_tuser;
          assign s1_axis_tlast[cc][ant-4] = s_ul_axis_tlast;
          assign s1_axis_tvalid[cc][ant-4] = s_ul_axis_tvalid;

        end else if (ant < 8) begin : gen_band2_ant

          assign m_dl_axis_tdata[(cc*NumAnt+ant)*32+31-:32] = m2_axis_tdata[cc][ant-6];
          assign m2_axis_tready[cc][ant-6] = m_dl_axis_tready;
          assign s2_axis_tdata[cc][ant-6] = s_ul_axis_tdata[(cc*NumAnt+ant)*32+31-:32];
          assign s2_axis_tuser[cc][ant-6] = s_ul_axis_tuser;
          assign s2_axis_tlast[cc][ant-6] = s_ul_axis_tlast;
          assign s2_axis_tvalid[cc][ant-6] = s_ul_axis_tvalid;

        end
      end
    end

  endgenerate

  assign m_dl_axis_tuser  = m0_axis_tuser[0][0];
  assign m_dl_axis_tlast  = m0_axis_tlast[0][0];
  assign m_dl_axis_tvalid = m0_axis_tvalid[0][0];

  assign s_ul_axis_tready = s0_axis_tready[0][0] & s1_axis_tready[0][0] & s2_axis_tready[0][0];

  // Unsol AXIS Switch

  axis_switch #(
      .NUM_SRC   (3),
      .NUM_DEST  (1),
      .DATA_WIDTH(64),
      .USER_WIDTH(32)
  ) i_unsol_switch (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata ({s2_fram_unsol_tdata, s1_fram_unsol_tdata, s0_fram_unsol_tdata}),
      .s_axis_tkeep ({s2_fram_unsol_tkeep, s1_fram_unsol_tkeep, s0_fram_unsol_tkeep}),
      .s_axis_tlast ({s2_fram_unsol_tlast, s1_fram_unsol_tlast, s0_fram_unsol_tlast}),
      .s_axis_tdest ({1'b1, 1'b1, 1'b1}),
      .s_axis_tuser ({s2_fram_unsol_tuser, s1_fram_unsol_tuser, s0_fram_unsol_tuser}),
      .s_axis_tvalid({s2_fram_unsol_tvalid, s1_fram_unsol_tvalid, s0_fram_unsol_tvalid}),
      .s_axis_tready({s2_fram_unsol_tready, s1_fram_unsol_tready, s0_fram_unsol_tready}),
      //
      .m_axis_tdata (m00_fram_unsol_tdata),
      .m_axis_tkeep (m00_fram_unsol_tkeep),
      .m_axis_tlast (m00_fram_unsol_tlast),
      .m_axis_tuser (m00_fram_unsol_tuser),
      .m_axis_tvalid(m00_fram_unsol_tvalid),
      .m_axis_tready(m00_fram_unsol_tready)
  );

  // PRACH AXIS Switch

  axis_switch #(
      .NUM_SRC   (3),
      .NUM_DEST  (1),
      .DATA_WIDTH(64),
      .USER_WIDTH(32)
  ) i_prach_switch (
      .clk          (internal_bus_clk),
      .rst          (fram_reset),
      //
      .s_axis_tdata ({s2_fram_prach_tdata, s1_fram_prach_tdata, s0_fram_prach_tdata}),
      .s_axis_tkeep ({s2_fram_prach_tkeep, s1_fram_prach_tkeep, s0_fram_prach_tkeep}),
      .s_axis_tlast ({s2_fram_prach_tlast, s1_fram_prach_tlast, s0_fram_prach_tlast}),
      .s_axis_tdest ({1'b1, 1'b1, 1'b1}),
      .s_axis_tuser ({s2_fram_prach_tuser, s1_fram_prach_tuser, s0_fram_prach_tuser}),
      .s_axis_tvalid({s2_fram_prach_tvalid, s1_fram_prach_tvalid, s0_fram_prach_tvalid}),
      .s_axis_tready({s2_fram_prach_tready, s1_fram_prach_tready, s0_fram_prach_tready}),
      //
      .m_axis_tdata (m00_fram_prach_tdata),
      .m_axis_tkeep (m00_fram_prach_tkeep),
      .m_axis_tlast (m00_fram_prach_tlast),
      .m_axis_tuser (m00_fram_prach_tuser),
      .m_axis_tvalid(m00_fram_prach_tvalid),
      .m_axis_tready(m00_fram_prach_tready)
  );

endmodule

`default_nettype wire
