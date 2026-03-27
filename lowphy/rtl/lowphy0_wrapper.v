`timescale 1 ns / 1 ps
//
`default_nettype none

// verilog_format: off
module lowphy0_wrapper (
    // AXI
    //----
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET s_axi_aresetn, ASSOCIATED_BUSIF S0_AXI, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire         s_axi_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire         s_axi_aresetn,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI AWADDR" *)
    input  wire [ 15:0] s0_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI AWPROT" *)
    input  wire [  1:0] s0_axi_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI AWVALID" *)
    input  wire         s0_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI AWREADY" *)
    output wire         s0_axi_awready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI WDATA" *)
    input  wire [ 31:0] s0_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI WSTRB" *)
    input  wire [  3:0] s0_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI WVALID" *)
    input  wire         s0_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI WREADY" *)
    output wire         s0_axi_wready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI BRESP" *)
    output wire [  1:0] s0_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI BVALID" *)
    output wire         s0_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI BREADY" *)
    input  wire         s0_axi_bready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI ARADDR" *)
    input  wire [ 15:0] s0_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI ARPROT" *)
    input  wire [  1:0] s0_axi_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI ARVALID" *)
    input  wire         s0_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI ARREADY" *)
    output wire         s0_axi_arready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI RDATA" *)
    output wire [ 31:0] s0_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI RRESP" *)
    output wire [  1:0] s0_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI RVALID" *)
    output wire         s0_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S0_AXI RREADY" *)
    input  wire         s0_axi_rready,
    // ORAN-IF Interfaces
    //-------------------
    // Early BID ports
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s00_defm_ebid TDATA" *)
    input  wire [ 47:0] s00_defm_ebid_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s00_defm_ebid TVALID" *)
    input  wire         s00_defm_ebid_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s00_defm_ebid TLAST" *)
    input  wire         s00_defm_ebid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s00_defm_ebid TREADY" *)
    output wire         s00_defm_ebid_tready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s00_fram_ebid TDATA" *)
    input  wire [ 47:0] s00_fram_ebid_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s00_fram_ebid TVALID" *)
    input  wire         s00_fram_ebid_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s00_fram_ebid TLAST" *)
    input  wire         s00_fram_ebid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s00_fram_ebid TREADY" *)
    output wire         s00_fram_ebid_tready,
    // PRACH C plane messages
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_tvalid" *)
    input  wire         s0_prach_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_tready" *)
    output wire         s0_prach_tready,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_rtc_pc_id" *)
    input  wire [ 15:0] s0_prach_rtc_pc_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_cc" *)
    input  wire [  3:0] s0_prach_cc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_ss" *)
    input  wire [  7:0] s0_prach_ss,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_section_id" *)
    input  wire [ 11:0] s0_prach_section_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_return_port" *)
    input  wire [  3:0] s0_prach_return_port,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_filter_index" *)
    input  wire [  3:0] s0_prach_filter_index,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_f" *)
    input  wire [  7:0] s0_prach_f,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_sf" *)
    input  wire [  3:0] s0_prach_sf,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_sl" *)
    input  wire [  5:0] s0_prach_sl,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_sy" *)
    input  wire [  5:0] s0_prach_sy,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_time_offset" *)
    input  wire [ 15:0] s0_prach_time_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_frame_structure" *)
    input  wire [  7:0] s0_prach_frame_structure,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_cp_length" *)
    input  wire [ 15:0] s0_prach_cp_length,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_udcomphdr" *)
    input  wire [  7:0] s0_prach_udcomphdr,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_rb" *)
    input  wire         s0_prach_rb,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_syminc" *)
    input  wire         s0_prach_syminc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_start_prbc" *)
    input  wire [  9:0] s0_prach_start_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_num_prbc" *)
    input  wire [  7:0] s0_prach_num_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_remask" *)
    input  wire [ 11:0] s0_prach_remask,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_num_symbol" *)
    input  wire [  3:0] s0_prach_num_symbol,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_beamid" *)
    input  wire [ 14:0] s0_prach_beamid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_prach_if:1.0 s0_prach prach_freqoffset" *)
    input  wire [ 23:0] s0_prach_freqoffset,
    // Timer ports
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing ul_sym_num" *)
    input  wire [ 11:0] s0_ul_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing ul_cta_sym_num" *)
    input  wire [ 11:0] s0_ul_cta_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing ul_update" *)
    input  wire         s0_ul_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing ul_slot_update" *)
    input  wire         s0_ul_slot_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing dl_sym_num" *)
    input  wire [ 11:0] s0_dl_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing dl_cta_sym_num" *)
    input  wire [ 11:0] s0_dl_cta_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing dl_update" *)
    input  wire         s0_dl_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing dl_slot_update" *)
    input  wire         s0_dl_slot_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing ul_toggle" *)
    input  wire         s0_ul_toggle,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing dl_toggle" *)
    input  wire         s0_dl_toggle,
    // (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing ul_symbol_inc" *)
    // input  wire         s0_ul_symbol_inc,
    // (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing dl_symbol_inc" *)
    // input  wire         s0_dl_symbol_inc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing cc_enable" *)
    input  wire         s0_cc_enable,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc0_timing cc_reload" *)
    input  wire         s0_cc_reload,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing ul_sym_num" *)
    input  wire [ 11:0] s1_ul_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing ul_cta_sym_num" *)
    input  wire [ 11:0] s1_ul_cta_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing ul_update" *)
    input  wire         s1_ul_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing ul_slot_update" *)
    input  wire         s1_ul_slot_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing dl_sym_num" *)
    input  wire [ 11:0] s1_dl_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing dl_cta_sym_num" *)
    input  wire [ 11:0] s1_dl_cta_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing dl_update" *)
    input  wire         s1_dl_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing dl_slot_update" *)
    input  wire         s1_dl_slot_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing ul_toggle" *)
    input  wire         s1_ul_toggle,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing dl_toggle" *)
    input  wire         s1_dl_toggle,
    // (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing ul_symbol_inc" *)
    // input  wire         s1_ul_symbol_inc,
    // (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing dl_symbol_inc" *)
    // input  wire         s1_dl_symbol_inc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing cc_enable" *)
    input  wire         s1_cc_enable,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc1_timing cc_reload" *)
    input  wire         s1_cc_reload,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing ul_sym_num" *)
    input  wire [ 11:0] s2_ul_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing ul_cta_sym_num" *)
    input  wire [ 11:0] s2_ul_cta_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing ul_update" *)
    input  wire         s2_ul_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing ul_slot_update" *)
    input  wire         s2_ul_slot_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing dl_sym_num" *)
    input  wire [ 11:0] s2_dl_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing dl_cta_sym_num" *)
    input  wire [ 11:0] s2_dl_cta_sym_num,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing dl_update" *)
    input  wire         s2_dl_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing dl_slot_update" *)
    input  wire         s2_dl_slot_update,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing ul_toggle" *)
    input  wire         s2_ul_toggle,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing dl_toggle" *)
    input  wire         s2_dl_toggle,
    // (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing ul_symbol_inc" *)
    // input  wire         s2_ul_symbol_inc,
    // (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing dl_symbol_inc" *)
    // input  wire         s2_dl_symbol_inc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing cc_enable" *)
    input  wire         s2_cc_enable,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xorif_timing_if:1.0 cc2_timing cc_reload" *)
    input  wire         s2_cc_reload,
    // CARRIER ports for the Framer, the datapath to the ethernet
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m000_data_axis TDATA" *)
    output wire [ 63:0] m000_fram_data_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m000_data_axis TKEEP" *)
    output wire [  7:0] m000_fram_data_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m000_data_axis TVALID" *)
    output wire         m000_fram_data_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m000_data_axis TLAST" *)
    output wire         m000_fram_data_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m000_data_axis TREADY" *)
    input  wire         m000_fram_data_tready,
    input  wire [ 32:0] m000_fram_data_req,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_debug" *)
    input  wire [107:0] s000_fram_bid_debug,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_valid" *)
    input  wire         s000_fram_bid_valid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_tlast" *)
    input  wire         s000_fram_bid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_ready" *)
    output wire         s000_fram_bid_ready,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_off" *)
    input  wire         s000_fram_bid_off,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_beamid15" *)
    input  wire [ 14:0] s000_fram_bid_beamid15,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_remask" *)
    input  wire [ 11:0] s000_fram_bid_remask,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_rb" *)
    input  wire         s000_fram_bid_rb,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_start_prbc" *)
    input  wire [  9:0] s000_fram_bid_start_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_num_prbc" *)
    input  wire [  7:0] s000_fram_bid_num_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_num_symbol" *)
    input  wire [  3:0] s000_fram_bid_num_symbol,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_cc_id" *)
    input  wire [  7:0] s000_fram_bid_cc_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_frequency_offset" *)
    input  wire [ 23:0] s000_fram_bid_frequency_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_time_offset" *)
    input  wire [ 15:0] s000_fram_bid_time_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_frame_structure" *)
    input  wire [  7:0] s000_fram_bid_frame_structure,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_fram_bid bid_cp_length" *)
    input  wire [ 15:0] s000_fram_bid_cp_length,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m001_data_axis TDATA" *)
    output wire [ 63:0] m001_fram_data_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m001_data_axis TKEEP" *)
    output wire [  7:0] m001_fram_data_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m001_data_axis TVALID" *)
    output wire         m001_fram_data_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m001_data_axis TLAST" *)
    output wire         m001_fram_data_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m001_data_axis TREADY" *)
    input  wire         m001_fram_data_tready,
    input  wire [ 32:0] m001_fram_data_req,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_debug" *)
    input  wire [107:0] s001_fram_bid_debug,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_valid" *)
    input  wire         s001_fram_bid_valid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_tlast" *)
    input  wire         s001_fram_bid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_ready" *)
    output wire         s001_fram_bid_ready,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_off" *)
    input  wire         s001_fram_bid_off,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_beamid15" *)
    input  wire [ 14:0] s001_fram_bid_beamid15,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_remask" *)
    input  wire [ 11:0] s001_fram_bid_remask,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_rb" *)
    input  wire         s001_fram_bid_rb,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_start_prbc" *)
    input  wire [  9:0] s001_fram_bid_start_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_num_prbc" *)
    input  wire [  7:0] s001_fram_bid_num_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_num_symbol" *)
    input  wire [  3:0] s001_fram_bid_num_symbol,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_cc_id" *)
    input  wire [  7:0] s001_fram_bid_cc_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_frequency_offset" *)
    input  wire [ 23:0] s001_fram_bid_frequency_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_time_offset" *)
    input  wire [ 15:0] s001_fram_bid_time_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_frame_structure" *)
    input  wire [  7:0] s001_fram_bid_frame_structure,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_fram_bid bid_cp_length" *)
    input  wire [ 15:0] s001_fram_bid_cp_length,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m002_data_axis TDATA" *)
    output wire [ 63:0] m002_fram_data_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m002_data_axis TKEEP" *)
    output wire [  7:0] m002_fram_data_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m002_data_axis TVALID" *)
    output wire         m002_fram_data_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m002_data_axis TLAST" *)
    output wire         m002_fram_data_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m002_data_axis TREADY" *)
    input  wire         m002_fram_data_tready,
    input  wire [ 32:0] m002_fram_data_req,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_debug" *)
    input  wire [107:0] s002_fram_bid_debug,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_valid" *)
    input  wire         s002_fram_bid_valid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_tlast" *)
    input  wire         s002_fram_bid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_ready" *)
    output wire         s002_fram_bid_ready,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_off" *)
    input  wire         s002_fram_bid_off,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_beamid15" *)
    input  wire [ 14:0] s002_fram_bid_beamid15,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_remask" *)
    input  wire [ 11:0] s002_fram_bid_remask,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_rb" *)
    input  wire         s002_fram_bid_rb,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_start_prbc" *)
    input  wire [  9:0] s002_fram_bid_start_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_num_prbc" *)
    input  wire [  7:0] s002_fram_bid_num_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_num_symbol" *)
    input  wire [  3:0] s002_fram_bid_num_symbol,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_cc_id" *)
    input  wire [  7:0] s002_fram_bid_cc_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_frequency_offset" *)
    input  wire [ 23:0] s002_fram_bid_frequency_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_time_offset" *)
    input  wire [ 15:0] s002_fram_bid_time_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_frame_structure" *)
    input  wire [  7:0] s002_fram_bid_frame_structure,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_fram_bid bid_cp_length" *)
    input  wire [ 15:0] s002_fram_bid_cp_length,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m003_data_axis TDATA" *)
    output wire [ 63:0] m003_fram_data_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m003_data_axis TKEEP" *)
    output wire [  7:0] m003_fram_data_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m003_data_axis TVALID" *)
    output wire         m003_fram_data_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m003_data_axis TLAST" *)
    output wire         m003_fram_data_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m003_data_axis TREADY" *)
    input  wire         m003_fram_data_tready,
    input  wire [ 32:0] m003_fram_data_req,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_debug" *)
    input  wire [107:0] s003_fram_bid_debug,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_valid" *)
    input  wire         s003_fram_bid_valid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_tlast" *)
    input  wire         s003_fram_bid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_ready" *)
    output wire         s003_fram_bid_ready,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_off" *)
    input  wire         s003_fram_bid_off,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_beamid15" *)
    input  wire [ 14:0] s003_fram_bid_beamid15,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_remask" *)
    input  wire [ 11:0] s003_fram_bid_remask,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_rb" *)
    input  wire         s003_fram_bid_rb,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_start_prbc" *)
    input  wire [  9:0] s003_fram_bid_start_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_num_prbc" *)
    input  wire [  7:0] s003_fram_bid_num_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_num_symbol" *)
    input  wire [  3:0] s003_fram_bid_num_symbol,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_cc_id" *)
    input  wire [  7:0] s003_fram_bid_cc_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_frequency_offset" *)
    input  wire [ 23:0] s003_fram_bid_frequency_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_time_offset" *)
    input  wire [ 15:0] s003_fram_bid_time_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_frame_structure" *)
    input  wire [  7:0] s003_fram_bid_frame_structure,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_fram_bid bid_cp_length" *)
    input  wire [ 15:0] s003_fram_bid_cp_length,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_unsol_axis TDATA" *)
    output wire [ 63:0] m00_fram_unsol_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_unsol_axis TKEEP" *)
    output wire [  7:0] m00_fram_unsol_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_unsol_axis TVALID" *)
    output wire         m00_fram_unsol_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_unsol_axis TLAST" *)
    output wire         m00_fram_unsol_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_unsol_axis TREADY" *)
    input  wire         m00_fram_unsol_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_unsol_axis TUSER" *)
    output wire [ 31:0] m00_fram_unsol_tuser,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_prach_axis TDATA" *)
    output wire [ 63:0] m00_fram_prach_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_prach_axis TKEEP" *)
    output wire [  7:0] m00_fram_prach_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_prach_axis TVALID" *)
    output wire         m00_fram_prach_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_prach_axis TLAST" *)
    output wire         m00_fram_prach_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_prach_axis TREADY" *)
    input  wire         m00_fram_prach_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m00_prach_axis TUSER" *)
    output wire [ 31:0] m00_fram_prach_tuser,
    // CARRIER ports from the De-framer, the datapath from the ethernet
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s000_data_axis TDATA" *)
    input  wire [ 63:0] s000_defm_data_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s000_data_axis TKEEP" *)
    input  wire [  7:0] s000_defm_data_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s000_data_axis TVALID" *)
    input  wire         s000_defm_data_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s000_data_axis TLAST" *)
    input  wire         s000_defm_data_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s000_data_axis TREADY" *)
    output wire         s000_defm_data_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s000_data_axis TUSER" *)
    input  wire [ 90:0] s000_defm_data_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s000_data_axis TDEST" *)
    input  wire [  4:0] s000_defm_data_tdest,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_valid" *)
    input  wire         s000_defm_bid_valid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_tlast" *)
    input  wire         s000_defm_bid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_ready" *)
    output wire         s000_defm_bid_ready,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_off" *)
    input  wire         s000_defm_bid_off,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_beamid15" *)
    input  wire [ 14:0] s000_defm_bid_beamid15,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_remask" *)
    input  wire [ 11:0] s000_defm_bid_remask,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_rb" *)
    input  wire         s000_defm_bid_rb,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_start_prbc" *)
    input  wire [  9:0] s000_defm_bid_start_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_num_prbc" *)
    input  wire [  7:0] s000_defm_bid_num_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_num_symbol" *)
    input  wire [  3:0] s000_defm_bid_num_symbol,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_cc_id" *)
    input  wire [  7:0] s000_defm_bid_cc_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_frequency_offset" *)
    input  wire [ 23:0] s000_defm_bid_frequency_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_time_offset" *)
    input  wire [ 15:0] s000_defm_bid_time_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_frame_structure" *)
    input  wire [  7:0] s000_defm_bid_frame_structure,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s000_defm_bid bid_cp_length" *)
    input  wire [ 15:0] s000_defm_bid_cp_length,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s001_data_axis TDATA" *)
    input  wire [ 63:0] s001_defm_data_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s001_data_axis TKEEP" *)
    input  wire [  7:0] s001_defm_data_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s001_data_axis TVALID" *)
    input  wire         s001_defm_data_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s001_data_axis TLAST" *)
    input  wire         s001_defm_data_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s001_data_axis TREADY" *)
    output wire         s001_defm_data_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s001_data_axis TUSER" *)
    input  wire [ 90:0] s001_defm_data_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s001_data_axis TDEST" *)
    input  wire [  4:0] s001_defm_data_tdest,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_valid" *)
    input  wire         s001_defm_bid_valid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_tlast" *)
    input  wire         s001_defm_bid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_ready" *)
    output wire         s001_defm_bid_ready,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_off" *)
    input  wire         s001_defm_bid_off,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_beamid15" *)
    input  wire [ 14:0] s001_defm_bid_beamid15,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_remask" *)
    input  wire [ 11:0] s001_defm_bid_remask,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_rb" *)
    input  wire         s001_defm_bid_rb,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_start_prbc" *)
    input  wire [  9:0] s001_defm_bid_start_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_num_prbc" *)
    input  wire [  7:0] s001_defm_bid_num_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_num_symbol" *)
    input  wire [  3:0] s001_defm_bid_num_symbol,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_cc_id" *)
    input  wire [  7:0] s001_defm_bid_cc_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_frequency_offset" *)
    input  wire [ 23:0] s001_defm_bid_frequency_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_time_offset" *)
    input  wire [ 15:0] s001_defm_bid_time_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_frame_structure" *)
    input  wire [  7:0] s001_defm_bid_frame_structure,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s001_defm_bid bid_cp_length" *)
    input  wire [ 15:0] s001_defm_bid_cp_length,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s002_data_axis TDATA" *)
    input  wire [ 63:0] s002_defm_data_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s002_data_axis TKEEP" *)
    input  wire [  7:0] s002_defm_data_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s002_data_axis TVALID" *)
    input  wire         s002_defm_data_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s002_data_axis TLAST" *)
    input  wire         s002_defm_data_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s002_data_axis TREADY" *)
    output wire         s002_defm_data_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s002_data_axis TUSER" *)
    input  wire [ 90:0] s002_defm_data_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s002_data_axis TDEST" *)
    input  wire [  4:0] s002_defm_data_tdest,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_valid" *)
    input  wire         s002_defm_bid_valid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_tlast" *)
    input  wire         s002_defm_bid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_ready" *)
    output wire         s002_defm_bid_ready,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_off" *)
    input  wire         s002_defm_bid_off,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_beamid15" *)
    input  wire [ 14:0] s002_defm_bid_beamid15,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_remask" *)
    input  wire [ 11:0] s002_defm_bid_remask,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_rb" *)
    input  wire         s002_defm_bid_rb,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_start_prbc" *)
    input  wire [  9:0] s002_defm_bid_start_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_num_prbc" *)
    input  wire [  7:0] s002_defm_bid_num_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_num_symbol" *)
    input  wire [  3:0] s002_defm_bid_num_symbol,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_cc_id" *)
    input  wire [  7:0] s002_defm_bid_cc_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_frequency_offset" *)
    input  wire [ 23:0] s002_defm_bid_frequency_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_time_offset" *)
    input  wire [ 15:0] s002_defm_bid_time_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_frame_structure" *)
    input  wire [  7:0] s002_defm_bid_frame_structure,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s002_defm_bid bid_cp_length" *)
    input  wire [ 15:0] s002_defm_bid_cp_length,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s003_data_axis TDATA" *)
    input  wire [ 63:0] s003_defm_data_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s003_data_axis TKEEP" *)
    input  wire [  7:0] s003_defm_data_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s003_data_axis TVALID" *)
    input  wire         s003_defm_data_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s003_data_axis TLAST" *)
    input  wire         s003_defm_data_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s003_data_axis TREADY" *)
    output wire         s003_defm_data_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s003_data_axis TUSER" *)
    input  wire [ 90:0] s003_defm_data_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s003_data_axis TDEST" *)
    input  wire [  4:0] s003_defm_data_tdest,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_valid" *)
    input  wire         s003_defm_bid_valid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_tlast" *)
    input  wire         s003_defm_bid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_ready" *)
    output wire         s003_defm_bid_ready,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_off" *)
    input  wire         s003_defm_bid_off,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_beamid15" *)
    input  wire [ 14:0] s003_defm_bid_beamid15,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_remask" *)
    input  wire [ 11:0] s003_defm_bid_remask,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_rb" *)
    input  wire         s003_defm_bid_rb,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_start_prbc" *)
    input  wire [  9:0] s003_defm_bid_start_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_num_prbc" *)
    input  wire [  7:0] s003_defm_bid_num_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_num_symbol" *)
    input  wire [  3:0] s003_defm_bid_num_symbol,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_cc_id" *)
    input  wire [  7:0] s003_defm_bid_cc_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_frequency_offset" *)
    input  wire [ 23:0] s003_defm_bid_frequency_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_time_offset" *)
    input  wire [ 15:0] s003_defm_bid_time_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_frame_structure" *)
    input  wire [  7:0] s003_defm_bid_frame_structure,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s003_defm_bid bid_cp_length" *)
    input  wire [ 15:0] s003_defm_bid_cp_length,
    // ORAN prase ports
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head ep_debug" *)
    input  wire [127:0] s0_ep_debug,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head t_header_offset_valid" *)
    input  wire         s0_t_header_offset_valid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head runt_packet_len" *)
    input  wire         s0_runt_packet_len,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head rtc_pc_id" *)
    input  wire [ 15:0] s0_rtc_pc_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head concat" *)
    input  wire         s0_concat,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head messagetype" *)
    input  wire [  2:0] s0_messagetype,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head seqid" *)
    input  wire [  7:0] s0_seqid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head subseqid" *)
    input  wire [  6:0] s0_subseqid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head ebit" *)
    input  wire         s0_ebit,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head payloadsize" *)
    input  wire [ 15:0] s0_payloadsize,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head packet_in_window" *)
    input  wire         s0_packet_in_window,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head offset_in_symbol" *)
    input  wire [ 11:0] s0_offset_in_symbol,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head radio_app_head_valid" *)
    input  wire         s0_radio_app_head_valid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head datadirection" *)
    input  wire         s0_datadirection,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head numsections" *)
    input  wire [  7:0] s0_numsections,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head sectiontype" *)
    input  wire [  2:0] s0_sectiontype,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head filterindex" *)
    input  wire [  3:0] s0_filterindex,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head frameid" *)
    input  wire [  7:0] s0_frameid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head subframeid" *)
    input  wire [  3:0] s0_subframeid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head slotid" *)
    input  wire [  5:0] s0_slotid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head symbolid" *)
    input  wire [  5:0] s0_symbolid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head udcomphdr" *)
    input  wire [  7:0] s0_udcomphdr,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head timeoffset" *)
    input  wire [ 15:0] s0_timeoffset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head framestructure" *)
    input  wire [  7:0] s0_framestructure,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head cplength" *)
    input  wire [ 15:0] s0_cplength,
    //
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head section_header_valid" *)
    input  wire         s0_section_header_valid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head numsymbol" *)
    input  wire [  3:0] s0_numsymbol,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head numprbc" *)
    input  wire [  7:0] s0_numprbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head startprbc" *)
    input  wire [  9:0] s0_startprbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head sectionid" *)
    input  wire [ 11:0] s0_sectionid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head rb" *)
    input  wire         s0_rb,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head remask" *)
    input  wire [ 11:0] s0_remask,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head beamid15" *)
    input  wire [ 14:0] s0_beamid15,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_header_if:1.0 s0_xran_head freqoffset" *)
    input  wire [ 23:0] s0_freqoffset,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_bweight TDATA" *)
    input  wire [ 63:0] s0_beamweights_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_bweight TVALID" *)
    input  wire         s0_beamweights_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_bweight TLAST" *)
    input  wire         s0_beamweights_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_bweight TUSER" *)
    input  wire [  3:0] s0_beamweights_tuser,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_unsup TDATA" *)
    input  wire [ 63:0] s0_raw_cplane_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_unsup TVALID" *)
    input  wire         s0_raw_cplane_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_unsup TUSER" *)
    input  wire         s0_raw_cplane_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_unsup TLAST" *)
    input  wire         s0_raw_cplane_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_unsup TKEEP" *)
    input  wire [  7:0] s0_raw_cplane_tkeep,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_unsup_exts TUSER" *)
    input  wire [ 26:0] s0_unsupport_ext_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_unsup_exts TDATA" *)
    input  wire [ 63:0] s0_unsupport_ext_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_unsup_exts TVALID" *)
    input  wire         s0_unsupport_ext_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_unsup_exts TKEEP" *)
    input  wire [  7:0] s0_unsupport_ext_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s0_xran_unsup_exts TLAST" *)
    input  wire         s0_unsupport_ext_tlast,
    // Clocks
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 internal_bus_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET defm_reset:fram_reset, ASSOCIATED_BUSIF s00_defm_ebid:s00_fram_ebid:s0_prach:cc0_timing:cc1_timing:cc2_timing:m000_data_axis:s000_fram_bid:m001_data_axis:s001_fram_bid:m002_data_axis:s002_fram_bid:m003_data_axis:s003_fram_bid:m00_unsol_axis:m00_prach_axis:s000_data_axis:s000_defm_bid:s001_data_axis:s001_defm_bid:s002_data_axis:s002_defm_bid:s003_data_axis:s003_defm_bid:s0_xran_head:s0_xran_bweight:s0_xran_unsup:s0_xran_unsup_exts:s_ssb_axis:s_ssb_ebid:s_ssb_bid, FREQ_HZ 400000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire         internal_bus_clk,
    //
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 defm_reset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input  wire         defm_reset,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 fram_reset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
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
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_ssb_axis TDATA" *)
    input  wire [ 63:0] s_ssb_data_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_ssb_axis TKEEP" *)
    input  wire [  7:0] s_ssb_data_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_ssb_axis TVALID" *)
    input  wire         s_ssb_data_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_ssb_axis TLAST" *)
    input  wire         s_ssb_data_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_ssb_axis TREADY" *)
    output wire         s_ssb_data_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_ssb_axis TUSER" *)
    input  wire [ 90:0] s_ssb_data_tuser,
    // Early BeamID generation
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_ssb_ebid TDATA" *)
    input  wire [ 47:0] s_ssb_ebid_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_ssb_ebid TVALID" *)
    input  wire         s_ssb_ebid_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_ssb_ebid TLAST" *)
    input  wire         s_ssb_ebid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_ssb_ebid TREADY" *)
    output wire         s_ssb_ebid_tready,
    // Outputs to beamid fwd interface
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_valid" *)
    input  wire         s_ssb_bid_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_tlast" *)
    input  wire         s_ssb_bid_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_ready" *)
    output wire         s_ssb_bid_tready,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_off" *)
    input  wire         s_ssb_bid_off,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_beamid15" *)
    input  wire [ 14:0] s_ssb_bid_beamid15,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_remask" *)
    input  wire [ 11:0] s_ssb_bid_remask,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_rb" *)
    input  wire         s_ssb_bid_rb,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_start_prbc" *)
    input  wire [  9:0] s_ssb_bid_start_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_num_prbc" *)
    input  wire [  7:0] s_ssb_bid_num_prbc,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_num_symbol" *)
    input  wire [  3:0] s_ssb_bid_num_symbol,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_cc_id" *)
    input  wire [  7:0] s_ssb_bid_cc_id,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_frequency_offset" *)
    input  wire [ 23:0] s_ssb_bid_frequency_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_time_offset" *)
    input  wire [ 15:0] s_ssb_bid_time_offset,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_frame_structure" *)
    input  wire [  7:0] s_ssb_bid_frame_structure,
    (* X_INTERFACE_INFO = "xilinx.com:xroe_display:xroe_dl_xran_bidfwd_if:1.0 s_ssb_bid bid_cp_length" *)
    input  wire [ 15:0] s_ssb_bid_cp_length,
    // Ready status
    input  wire         fram_ready,
    input  wire         defm_ready,
    // Mandatory 10 MHz strobe
    input  wire         fram_rfs_in,
    input  wire         defm_rfs_in,
    // Radio I/F
    //----------
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET rstn, ASSOCIATED_BUSIF M_DL_AXIS:S_UL_AXIS, FREQ_HZ 491520000, FREQ_TOLERANCE_HZ 0" *)
    input  wire         clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rstn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire         rstn,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_DL_AXIS TDATA" *)
    output wire [383:0] m_dl_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_DL_AXIS TUSER" *)
    output wire [  7:0] m_dl_axis_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_DL_AXIS TLAST" *)
    output wire         m_dl_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_DL_AXIS TVALID" *)
    output wire         m_dl_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_DL_AXIS TREADY" *)
    input  wire         m_dl_axis_tready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_UL_AXIS TDATA" *)
    input  wire [383:0] s_ul_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_UL_AXIS TUSER" *)
    input  wire [  7:0] s_ul_axis_tuser,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_UL_AXIS TLAST" *)
    input  wire         s_ul_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_UL_AXIS TVALID" *)
    input  wire         s_ul_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_UL_AXIS TREADY" *)
    output wire         s_ul_axis_tready
);
// verilog_format: on

  lowphy0 inst (
      // AXI
      //----
      .s_axi_aclk                    (s_axi_aclk),
      .s_axi_aresetn                 (s_axi_aresetn),
      //
      .s0_axi_awaddr                 (s0_axi_awaddr),
      .s0_axi_awprot                 (s0_axi_awprot),
      .s0_axi_awvalid                (s0_axi_awvalid),
      .s0_axi_awready                (s0_axi_awready),
      //
      .s0_axi_wdata                  (s0_axi_wdata),
      .s0_axi_wstrb                  (s0_axi_wstrb),
      .s0_axi_wvalid                 (s0_axi_wvalid),
      .s0_axi_wready                 (s0_axi_wready),
      //
      .s0_axi_bresp                  (s0_axi_bresp),
      .s0_axi_bvalid                 (s0_axi_bvalid),
      .s0_axi_bready                 (s0_axi_bready),
      //
      .s0_axi_araddr                 (s0_axi_araddr),
      .s0_axi_arprot                 (s0_axi_arprot),
      .s0_axi_arvalid                (s0_axi_arvalid),
      .s0_axi_arready                (s0_axi_arready),
      //
      .s0_axi_rdata                  (s0_axi_rdata),
      .s0_axi_rresp                  (s0_axi_rresp),
      .s0_axi_rvalid                 (s0_axi_rvalid),
      .s0_axi_rready                 (s0_axi_rready),
      // ORAN-IF Interfaces
      //-------------------
      // Early BID ports
      .s00_defm_ebid_tdata           (s00_defm_ebid_tdata),
      .s00_defm_ebid_tvalid          (s00_defm_ebid_tvalid),
      .s00_defm_ebid_tlast           (s00_defm_ebid_tlast),
      .s00_defm_ebid_tready          (s00_defm_ebid_tready),
      //
      .s00_fram_ebid_tdata           (s00_fram_ebid_tdata),
      .s00_fram_ebid_tvalid          (s00_fram_ebid_tvalid),
      .s00_fram_ebid_tlast           (s00_fram_ebid_tlast),
      .s00_fram_ebid_tready          (s00_fram_ebid_tready),
      // PRACH C plane messages
      .s0_prach_tvalid               (s0_prach_tvalid),
      .s0_prach_tready               (s0_prach_tready),
      .s0_prach_rtc_pc_id            (s0_prach_rtc_pc_id),
      .s0_prach_cc                   (s0_prach_cc),
      .s0_prach_ss                   (s0_prach_ss),
      .s0_prach_section_id           (s0_prach_section_id),
      .s0_prach_return_port          (s0_prach_return_port),
      .s0_prach_filter_index         (s0_prach_filter_index),
      .s0_prach_f                    (s0_prach_f),
      .s0_prach_sf                   (s0_prach_sf),
      .s0_prach_sl                   (s0_prach_sl),
      .s0_prach_sy                   (s0_prach_sy),
      .s0_prach_time_offset          (s0_prach_time_offset),
      .s0_prach_frame_structure      (s0_prach_frame_structure),
      .s0_prach_cp_length            (s0_prach_cp_length),
      .s0_prach_udcomphdr            (s0_prach_udcomphdr),
      .s0_prach_rb                   (s0_prach_rb),
      .s0_prach_syminc               (s0_prach_syminc),
      .s0_prach_start_prbc           (s0_prach_start_prbc),
      .s0_prach_num_prbc             (s0_prach_num_prbc),
      .s0_prach_remask               (s0_prach_remask),
      .s0_prach_num_symbol           (s0_prach_num_symbol),
      .s0_prach_beamid               (s0_prach_beamid),
      .s0_prach_freqoffset           (s0_prach_freqoffset),
      // Timer ports
      .s0_ul_sym_num                 (s0_ul_sym_num),
      .s0_ul_cta_sym_num             (s0_ul_cta_sym_num),
      .s0_ul_update                  (s0_ul_update),
      .s0_ul_slot_update             (s0_ul_slot_update),
      .s0_dl_sym_num                 (s0_dl_sym_num),
      .s0_dl_cta_sym_num             (s0_dl_cta_sym_num),
      .s0_dl_update                  (s0_dl_update),
      .s0_dl_slot_update             (s0_dl_slot_update),
      .s0_ul_toggle                  (s0_ul_toggle),
      .s0_dl_toggle                  (s0_dl_toggle),
      // .s0_ul_symbol_inc              (s0_ul_symbol_inc),
      // .s0_dl_symbol_inc              (s0_dl_symbol_inc),
      .s0_cc_enable                  (s0_cc_enable),
      .s0_cc_reload                  (s0_cc_reload),
      //
      .s1_ul_sym_num                 (s1_ul_sym_num),
      .s1_ul_cta_sym_num             (s1_ul_cta_sym_num),
      .s1_ul_update                  (s1_ul_update),
      .s1_ul_slot_update             (s1_ul_slot_update),
      .s1_dl_sym_num                 (s1_dl_sym_num),
      .s1_dl_cta_sym_num             (s1_dl_cta_sym_num),
      .s1_dl_update                  (s1_dl_update),
      .s1_dl_slot_update             (s1_dl_slot_update),
      .s1_ul_toggle                  (s1_ul_toggle),
      .s1_dl_toggle                  (s1_dl_toggle),
      // .s1_ul_symbol_inc              (s1_ul_symbol_inc),
      // .s1_dl_symbol_inc              (s1_dl_symbol_inc),
      .s1_cc_enable                  (s1_cc_enable),
      .s1_cc_reload                  (s1_cc_reload),
      //
      .s2_ul_sym_num                 (s2_ul_sym_num),
      .s2_ul_cta_sym_num             (s2_ul_cta_sym_num),
      .s2_ul_update                  (s2_ul_update),
      .s2_ul_slot_update             (s2_ul_slot_update),
      .s2_dl_sym_num                 (s2_dl_sym_num),
      .s2_dl_cta_sym_num             (s2_dl_cta_sym_num),
      .s2_dl_update                  (s2_dl_update),
      .s2_dl_slot_update             (s2_dl_slot_update),
      .s2_ul_toggle                  (s2_ul_toggle),
      .s2_dl_toggle                  (s2_dl_toggle),
      // .s2_ul_symbol_inc              (s2_ul_symbol_inc),
      // .s2_dl_symbol_inc              (s2_dl_symbol_inc),
      .s2_cc_enable                  (s2_cc_enable),
      .s2_cc_reload                  (s2_cc_reload),
      // CARRIER ports for the Framer, the datapath to the ethernet
      .m000_fram_data_tdata          (m000_fram_data_tdata),
      .m000_fram_data_tkeep          (m000_fram_data_tkeep),
      .m000_fram_data_tvalid         (m000_fram_data_tvalid),
      .m000_fram_data_tlast          (m000_fram_data_tlast),
      .m000_fram_data_tready         (m000_fram_data_tready),
      .m000_fram_data_req            (m000_fram_data_req),
      //
      .s000_fram_bid_debug           (s000_fram_bid_debug),
      .s000_fram_bid_valid           (s000_fram_bid_valid),
      .s000_fram_bid_tlast           (s000_fram_bid_tlast),
      .s000_fram_bid_ready           (s000_fram_bid_ready),
      .s000_fram_bid_off             (s000_fram_bid_off),
      .s000_fram_bid_beamid15        (s000_fram_bid_beamid15),
      .s000_fram_bid_remask          (s000_fram_bid_remask),
      .s000_fram_bid_rb              (s000_fram_bid_rb),
      .s000_fram_bid_start_prbc      (s000_fram_bid_start_prbc),
      .s000_fram_bid_num_prbc        (s000_fram_bid_num_prbc),
      .s000_fram_bid_num_symbol      (s000_fram_bid_num_symbol),
      .s000_fram_bid_cc_id           (s000_fram_bid_cc_id),
      .s000_fram_bid_frequency_offset(s000_fram_bid_frequency_offset),
      .s000_fram_bid_time_offset     (s000_fram_bid_time_offset),
      .s000_fram_bid_frame_structure (s000_fram_bid_frame_structure),
      .s000_fram_bid_cp_length       (s000_fram_bid_cp_length),
      //
      .m001_fram_data_tdata          (m001_fram_data_tdata),
      .m001_fram_data_tkeep          (m001_fram_data_tkeep),
      .m001_fram_data_tvalid         (m001_fram_data_tvalid),
      .m001_fram_data_tlast          (m001_fram_data_tlast),
      .m001_fram_data_tready         (m001_fram_data_tready),
      .m001_fram_data_req            (m001_fram_data_req),
      //
      .s001_fram_bid_debug           (s001_fram_bid_debug),
      .s001_fram_bid_valid           (s001_fram_bid_valid),
      .s001_fram_bid_tlast           (s001_fram_bid_tlast),
      .s001_fram_bid_ready           (s001_fram_bid_ready),
      .s001_fram_bid_off             (s001_fram_bid_off),
      .s001_fram_bid_beamid15        (s001_fram_bid_beamid15),
      .s001_fram_bid_remask          (s001_fram_bid_remask),
      .s001_fram_bid_rb              (s001_fram_bid_rb),
      .s001_fram_bid_start_prbc      (s001_fram_bid_start_prbc),
      .s001_fram_bid_num_prbc        (s001_fram_bid_num_prbc),
      .s001_fram_bid_num_symbol      (s001_fram_bid_num_symbol),
      .s001_fram_bid_cc_id           (s001_fram_bid_cc_id),
      .s001_fram_bid_frequency_offset(s001_fram_bid_frequency_offset),
      .s001_fram_bid_time_offset     (s001_fram_bid_time_offset),
      .s001_fram_bid_frame_structure (s001_fram_bid_frame_structure),
      .s001_fram_bid_cp_length       (s001_fram_bid_cp_length),
      //
      .m002_fram_data_tdata          (m002_fram_data_tdata),
      .m002_fram_data_tkeep          (m002_fram_data_tkeep),
      .m002_fram_data_tvalid         (m002_fram_data_tvalid),
      .m002_fram_data_tlast          (m002_fram_data_tlast),
      .m002_fram_data_tready         (m002_fram_data_tready),
      .m002_fram_data_req            (m002_fram_data_req),
      //
      .s002_fram_bid_debug           (s002_fram_bid_debug),
      .s002_fram_bid_valid           (s002_fram_bid_valid),
      .s002_fram_bid_tlast           (s002_fram_bid_tlast),
      .s002_fram_bid_ready           (s002_fram_bid_ready),
      .s002_fram_bid_off             (s002_fram_bid_off),
      .s002_fram_bid_beamid15        (s002_fram_bid_beamid15),
      .s002_fram_bid_remask          (s002_fram_bid_remask),
      .s002_fram_bid_rb              (s002_fram_bid_rb),
      .s002_fram_bid_start_prbc      (s002_fram_bid_start_prbc),
      .s002_fram_bid_num_prbc        (s002_fram_bid_num_prbc),
      .s002_fram_bid_num_symbol      (s002_fram_bid_num_symbol),
      .s002_fram_bid_cc_id           (s002_fram_bid_cc_id),
      .s002_fram_bid_frequency_offset(s002_fram_bid_frequency_offset),
      .s002_fram_bid_time_offset     (s002_fram_bid_time_offset),
      .s002_fram_bid_frame_structure (s002_fram_bid_frame_structure),
      .s002_fram_bid_cp_length       (s002_fram_bid_cp_length),
      //
      .m003_fram_data_tdata          (m003_fram_data_tdata),
      .m003_fram_data_tkeep          (m003_fram_data_tkeep),
      .m003_fram_data_tvalid         (m003_fram_data_tvalid),
      .m003_fram_data_tlast          (m003_fram_data_tlast),
      .m003_fram_data_tready         (m003_fram_data_tready),
      .m003_fram_data_req            (m003_fram_data_req),
      //
      .s003_fram_bid_debug           (s003_fram_bid_debug),
      .s003_fram_bid_valid           (s003_fram_bid_valid),
      .s003_fram_bid_tlast           (s003_fram_bid_tlast),
      .s003_fram_bid_ready           (s003_fram_bid_ready),
      .s003_fram_bid_off             (s003_fram_bid_off),
      .s003_fram_bid_beamid15        (s003_fram_bid_beamid15),
      .s003_fram_bid_remask          (s003_fram_bid_remask),
      .s003_fram_bid_rb              (s003_fram_bid_rb),
      .s003_fram_bid_start_prbc      (s003_fram_bid_start_prbc),
      .s003_fram_bid_num_prbc        (s003_fram_bid_num_prbc),
      .s003_fram_bid_num_symbol      (s003_fram_bid_num_symbol),
      .s003_fram_bid_cc_id           (s003_fram_bid_cc_id),
      .s003_fram_bid_frequency_offset(s003_fram_bid_frequency_offset),
      .s003_fram_bid_time_offset     (s003_fram_bid_time_offset),
      .s003_fram_bid_frame_structure (s003_fram_bid_frame_structure),
      .s003_fram_bid_cp_length       (s003_fram_bid_cp_length),
      //
      .m00_fram_unsol_tdata          (m00_fram_unsol_tdata),
      .m00_fram_unsol_tkeep          (m00_fram_unsol_tkeep),
      .m00_fram_unsol_tvalid         (m00_fram_unsol_tvalid),
      .m00_fram_unsol_tlast          (m00_fram_unsol_tlast),
      .m00_fram_unsol_tready         (m00_fram_unsol_tready),
      .m00_fram_unsol_tuser          (m00_fram_unsol_tuser),
      //
      .m00_fram_prach_tdata          (m00_fram_prach_tdata),
      .m00_fram_prach_tkeep          (m00_fram_prach_tkeep),
      .m00_fram_prach_tvalid         (m00_fram_prach_tvalid),
      .m00_fram_prach_tlast          (m00_fram_prach_tlast),
      .m00_fram_prach_tready         (m00_fram_prach_tready),
      .m00_fram_prach_tuser          (m00_fram_prach_tuser),
      // CARRIER ports from the Framer, the datapath from the ethernet
      .s000_defm_data_tdata          (s000_defm_data_tdata),
      .s000_defm_data_tkeep          (s000_defm_data_tkeep),
      .s000_defm_data_tvalid         (s000_defm_data_tvalid),
      .s000_defm_data_tlast          (s000_defm_data_tlast),
      .s000_defm_data_tready         (s000_defm_data_tready),
      .s000_defm_data_tuser          (s000_defm_data_tuser),
      .s000_defm_data_tdest          (s000_defm_data_tdest),
      //
      .s000_defm_bid_valid           (s000_defm_bid_valid),
      .s000_defm_bid_tlast           (s000_defm_bid_tlast),
      .s000_defm_bid_ready           (s000_defm_bid_ready),
      .s000_defm_bid_off             (s000_defm_bid_off),
      .s000_defm_bid_beamid15        (s000_defm_bid_beamid15),
      .s000_defm_bid_remask          (s000_defm_bid_remask),
      .s000_defm_bid_rb              (s000_defm_bid_rb),
      .s000_defm_bid_start_prbc      (s000_defm_bid_start_prbc),
      .s000_defm_bid_num_prbc        (s000_defm_bid_num_prbc),
      .s000_defm_bid_num_symbol      (s000_defm_bid_num_symbol),
      .s000_defm_bid_cc_id           (s000_defm_bid_cc_id),
      .s000_defm_bid_frequency_offset(s000_defm_bid_frequency_offset),
      .s000_defm_bid_time_offset     (s000_defm_bid_time_offset),
      .s000_defm_bid_frame_structure (s000_defm_bid_frame_structure),
      .s000_defm_bid_cp_length       (s000_defm_bid_cp_length),
      //
      .s001_defm_data_tdata          (s001_defm_data_tdata),
      .s001_defm_data_tkeep          (s001_defm_data_tkeep),
      .s001_defm_data_tvalid         (s001_defm_data_tvalid),
      .s001_defm_data_tlast          (s001_defm_data_tlast),
      .s001_defm_data_tready         (s001_defm_data_tready),
      .s001_defm_data_tuser          (s001_defm_data_tuser),
      .s001_defm_data_tdest          (s001_defm_data_tdest),
      //
      .s001_defm_bid_valid           (s001_defm_bid_valid),
      .s001_defm_bid_tlast           (s001_defm_bid_tlast),
      .s001_defm_bid_ready           (s001_defm_bid_ready),
      .s001_defm_bid_off             (s001_defm_bid_off),
      .s001_defm_bid_beamid15        (s001_defm_bid_beamid15),
      .s001_defm_bid_remask          (s001_defm_bid_remask),
      .s001_defm_bid_rb              (s001_defm_bid_rb),
      .s001_defm_bid_start_prbc      (s001_defm_bid_start_prbc),
      .s001_defm_bid_num_prbc        (s001_defm_bid_num_prbc),
      .s001_defm_bid_num_symbol      (s001_defm_bid_num_symbol),
      .s001_defm_bid_cc_id           (s001_defm_bid_cc_id),
      .s001_defm_bid_frequency_offset(s001_defm_bid_frequency_offset),
      .s001_defm_bid_time_offset     (s001_defm_bid_time_offset),
      .s001_defm_bid_frame_structure (s001_defm_bid_frame_structure),
      .s001_defm_bid_cp_length       (s001_defm_bid_cp_length),
      //
      .s002_defm_data_tdata          (s002_defm_data_tdata),
      .s002_defm_data_tkeep          (s002_defm_data_tkeep),
      .s002_defm_data_tvalid         (s002_defm_data_tvalid),
      .s002_defm_data_tlast          (s002_defm_data_tlast),
      .s002_defm_data_tready         (s002_defm_data_tready),
      .s002_defm_data_tuser          (s002_defm_data_tuser),
      .s002_defm_data_tdest          (s002_defm_data_tdest),
      //
      .s002_defm_bid_valid           (s002_defm_bid_valid),
      .s002_defm_bid_tlast           (s002_defm_bid_tlast),
      .s002_defm_bid_ready           (s002_defm_bid_ready),
      .s002_defm_bid_off             (s002_defm_bid_off),
      .s002_defm_bid_beamid15        (s002_defm_bid_beamid15),
      .s002_defm_bid_remask          (s002_defm_bid_remask),
      .s002_defm_bid_rb              (s002_defm_bid_rb),
      .s002_defm_bid_start_prbc      (s002_defm_bid_start_prbc),
      .s002_defm_bid_num_prbc        (s002_defm_bid_num_prbc),
      .s002_defm_bid_num_symbol      (s002_defm_bid_num_symbol),
      .s002_defm_bid_cc_id           (s002_defm_bid_cc_id),
      .s002_defm_bid_frequency_offset(s002_defm_bid_frequency_offset),
      .s002_defm_bid_time_offset     (s002_defm_bid_time_offset),
      .s002_defm_bid_frame_structure (s002_defm_bid_frame_structure),
      .s002_defm_bid_cp_length       (s002_defm_bid_cp_length),
      //
      .s003_defm_data_tdata          (s003_defm_data_tdata),
      .s003_defm_data_tkeep          (s003_defm_data_tkeep),
      .s003_defm_data_tvalid         (s003_defm_data_tvalid),
      .s003_defm_data_tlast          (s003_defm_data_tlast),
      .s003_defm_data_tready         (s003_defm_data_tready),
      .s003_defm_data_tuser          (s003_defm_data_tuser),
      .s003_defm_data_tdest          (s003_defm_data_tdest),
      //
      .s003_defm_bid_valid           (s003_defm_bid_valid),
      .s003_defm_bid_tlast           (s003_defm_bid_tlast),
      .s003_defm_bid_ready           (s003_defm_bid_ready),
      .s003_defm_bid_off             (s003_defm_bid_off),
      .s003_defm_bid_beamid15        (s003_defm_bid_beamid15),
      .s003_defm_bid_remask          (s003_defm_bid_remask),
      .s003_defm_bid_rb              (s003_defm_bid_rb),
      .s003_defm_bid_start_prbc      (s003_defm_bid_start_prbc),
      .s003_defm_bid_num_prbc        (s003_defm_bid_num_prbc),
      .s003_defm_bid_num_symbol      (s003_defm_bid_num_symbol),
      .s003_defm_bid_cc_id           (s003_defm_bid_cc_id),
      .s003_defm_bid_frequency_offset(s003_defm_bid_frequency_offset),
      .s003_defm_bid_time_offset     (s003_defm_bid_time_offset),
      .s003_defm_bid_frame_structure (s003_defm_bid_frame_structure),
      .s003_defm_bid_cp_length       (s003_defm_bid_cp_length),
      // ORAN prase ports
      .s0_ep_debug                   (s0_ep_debug),
      .s0_t_header_offset_valid      (s0_t_header_offset_valid),
      .s0_runt_packet_len            (s0_runt_packet_len),
      .s0_rtc_pc_id                  (s0_rtc_pc_id),
      .s0_concat                     (s0_concat),
      .s0_messagetype                (s0_messagetype),
      .s0_seqid                      (s0_seqid),
      .s0_subseqid                   (s0_subseqid),
      .s0_ebit                       (s0_ebit),
      .s0_payloadsize                (s0_payloadsize),
      .s0_packet_in_window           (s0_packet_in_window),
      .s0_offset_in_symbol           (s0_offset_in_symbol),
      //
      .s0_radio_app_head_valid       (s0_radio_app_head_valid),
      .s0_datadirection              (s0_datadirection),
      .s0_numsections                (s0_numsections),
      .s0_sectiontype                (s0_sectiontype),
      .s0_filterindex                (s0_filterindex),
      .s0_frameid                    (s0_frameid),
      .s0_subframeid                 (s0_subframeid),
      .s0_slotid                     (s0_slotid),
      .s0_symbolid                   (s0_symbolid),
      .s0_udcomphdr                  (s0_udcomphdr),
      .s0_timeoffset                 (s0_timeoffset),
      .s0_framestructure             (s0_framestructure),
      .s0_cplength                   (s0_cplength),
      //
      .s0_section_header_valid       (s0_section_header_valid),
      .s0_numsymbol                  (s0_numsymbol),
      .s0_numprbc                    (s0_numprbc),
      .s0_startprbc                  (s0_startprbc),
      .s0_sectionid                  (s0_sectionid),
      .s0_rb                         (s0_rb),
      .s0_remask                     (s0_remask),
      .s0_beamid15                   (s0_beamid15),
      .s0_freqoffset                 (s0_freqoffset),
      //
      .s0_beamweights_tdata          (s0_beamweights_tdata),
      .s0_beamweights_tvalid         (s0_beamweights_tvalid),
      .s0_beamweights_tlast          (s0_beamweights_tlast),
      .s0_beamweights_tuser          (s0_beamweights_tuser),
      //
      .s0_raw_cplane_tdata           (s0_raw_cplane_tdata),
      .s0_raw_cplane_tvalid          (s0_raw_cplane_tvalid),
      .s0_raw_cplane_tuser           (s0_raw_cplane_tuser),
      .s0_raw_cplane_tlast           (s0_raw_cplane_tlast),
      .s0_raw_cplane_tkeep           (s0_raw_cplane_tkeep),
      //
      .s0_unsupport_ext_tuser        (s0_unsupport_ext_tuser),
      .s0_unsupport_ext_tdata        (s0_unsupport_ext_tdata),
      .s0_unsupport_ext_tvalid       (s0_unsupport_ext_tvalid),
      .s0_unsupport_ext_tkeep        (s0_unsupport_ext_tkeep),
      .s0_unsupport_ext_tlast        (s0_unsupport_ext_tlast),
      // Clocks
      .internal_bus_clk              (internal_bus_clk),
      //
      .defm_reset                    (defm_reset),
      .fram_reset                    (fram_reset),
      //
      .defm_reset_active             (defm_reset_active),
      .fram0_reset_active            (fram0_reset_active),
      // Timer ports
      .fram_radio_start_10ms         (fram_radio_start_10ms),
      .defm_radio_start_10ms         (defm_radio_start_10ms),
      .fram_radio_start_10ms_cc1     (fram_radio_start_10ms_cc1),
      .defm_radio_start_10ms_cc1     (defm_radio_start_10ms_cc1),
      .fram_radio_start_10ms_cc2     (fram_radio_start_10ms_cc2),
      .defm_radio_start_10ms_cc2     (defm_radio_start_10ms_cc2),
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
      //
      .fram_rfs_in                   (fram_rfs_in),
      .defm_rfs_in                   (defm_rfs_in),
      // Radio I/F
      //----------
      .clk                           (clk),
      .rst                           (~rstn),
      //
      .m_dl_axis_tdata               (m_dl_axis_tdata),
      .m_dl_axis_tuser               (m_dl_axis_tuser),
      .m_dl_axis_tlast               (m_dl_axis_tlast),
      .m_dl_axis_tvalid              (m_dl_axis_tvalid),
      .m_dl_axis_tready              (m_dl_axis_tready),
      //
      .s_ul_axis_tdata               (s_ul_axis_tdata),
      .s_ul_axis_tuser               (s_ul_axis_tuser),
      .s_ul_axis_tlast               (s_ul_axis_tlast),
      .s_ul_axis_tvalid              (s_ul_axis_tvalid),
      .s_ul_axis_tready              (s_ul_axis_tready)
  );

endmodule

`default_nettype wire
