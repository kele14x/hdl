`timescale 1 ns / 1 ps `default_nettype none
module eth_if_sim #(
    parameter int NUM_CC       = 2,  // Number of carrier components
    parameter int NUM_ETH_PORT = 2,  // Number of Ethernet ports
    parameter int NUM_DL_LAYER = 16,  // Number of DL layers
    parameter int NUM_UL_LAYER = 8  // Number of Ul layers
) (
    // AXI-Lite Control/Status
    input var         aclk,
    input var         aresetn,
    // XORIF IP AXI4-Lite interface
    //=========================
    input var  [15:0] s00_axi_awaddr,
    input var  [ 2:0] s00_axi_awprot,
    input var         s00_axi_awvalid,
    output var        s00_axi_awready,
    //
    input var  [31:0] s00_axi_wdata,
    input var  [ 3:0] s00_axi_wstrb,
    input var         s00_axi_wvalid,
    output var        s00_axi_wready,
    //
    output var [ 1:0] s00_axi_bresp,
    output var        s00_axi_bvalid,
    input var         s00_axi_bready,
    //
    input var  [15:0] s00_axi_araddr,
    input var  [ 2:0] s00_axi_arprot,
    input var         s00_axi_arvalid,
    output var        s00_axi_arready,
    //
    output var [31:0] s00_axi_rdata,
    output var [ 1:0] s00_axi_rresp,
    output var        s00_axi_rvalid,
    input var         s00_axi_rready,
    // interrupt pin
    output var        s00_interrupt,
    // Other Competent AXI4-Lite Interface
    //====================================
    input var  [15:0] s01_axi_awaddr,
    input var  [ 2:0] s01_axi_awprot,
    input var         s01_axi_awvalid,
    output var        s01_axi_awready,
    //
    input var  [31:0] s01_axi_wdata,
    input var  [ 3:0] s01_axi_wstrb,
    input var         s01_axi_wvalid,
    output var        s01_axi_wready,
    //
    output var [ 1:0] s01_axi_bresp,
    output var        s01_axi_bvalid,
    input var         s01_axi_bready,
    //
    input var  [15:0] s01_axi_araddr,
    input var  [ 2:0] s01_axi_arprot,
    input var         s01_axi_arvalid,
    output var        s01_axi_arready,
    //
    output var [31:0] s01_axi_rdata,
    output var [ 1:0] s01_axi_rresp,
    output var        s01_axi_rvalid,
    input var         s01_axi_rready,
    // interrupt pin
    output var        s01_interrupt,
    // Ethernet Port 0 Interface
    //==========================
    // Clock and Rest
    input var         eth_port_clk          [NUM_ETH_PORT],
    input var         eth_port_rst          [NUM_ETH_PORT],
    // To MAC
    output var [63:0] m_eth_fram_tdata      [NUM_ETH_PORT],
    output var [ 7:0] m_eth_fram_tkeep      [NUM_ETH_PORT],
    output var        m_eth_fram_tvalid     [NUM_ETH_PORT],
    output var        m_eth_fram_tlast      [NUM_ETH_PORT],
    input var         m_eth_fram_tready     [NUM_ETH_PORT],
    // From MAC
    input var         s_eth_mac_tuser       [NUM_ETH_PORT],
    input var         s_eth_mac_bad_fcs     [NUM_ETH_PORT],
    input var  [79:0] s_eth_mac_tstamp_out  [NUM_ETH_PORT],
    input var         s_eth_mac_tstamp_valid[NUM_ETH_PORT],
    //
    input var  [63:0] s_eth_defm_tdata      [NUM_ETH_PORT],
    input var  [ 7:0] s_eth_defm_tkeep      [NUM_ETH_PORT],
    input var         s_eth_defm_tvalid     [NUM_ETH_PORT],
    input var         s_eth_defm_tlast      [NUM_ETH_PORT],
    // To DMA
    output var [63:0] m_message_tdata       [NUM_ETH_PORT],
    output var [ 7:0] m_message_tkeep       [NUM_ETH_PORT],
    output var        m_message_tvalid      [NUM_ETH_PORT],
    output var        m_message_tlast       [NUM_ETH_PORT],
    input var         m_message_tready      [NUM_ETH_PORT],
    output var [79:0] m_message_ts_tdata    [NUM_ETH_PORT],
    output var        m_message_ts_tvalid   [NUM_ETH_PORT],
    // Internal Bus Interface
    //=======================
    // Clock and reset
    input var         clk_400m,
    input var         rst_400m,
    // Radio Interface
    //================
    // Clock and reset
    input var         clk_491m52,
    input var         rst_491m52,
    // Radio frame start
    input var         dl_radio_start_10ms,
    input var         ul_radio_start_10ms,
    // DL data
    output var        dl_sof            [NUM_CC],
    output var        dl_sos            [NUM_CC],
    output var [15:0] dl_data_i         [NUM_CC][NUM_DL_LAYER],
    output var [15:0] dl_data_q         [NUM_CC][NUM_DL_LAYER],
    output var        dl_valid          [NUM_CC]
    // UL data
);

  // Radio IP signal
  //----------------

  // Early BID ports
  logic [ 31:0] m00_defm_ebid_tdata;
  logic         m00_defm_ebid_tvalid;
  logic         m00_defm_ebid_tlast;
  logic         m00_defm_ebid_tready;

  logic [ 31:0] m00_fram_ebid_tdata;
  logic         m00_fram_ebid_tvalid;
  logic         m00_fram_ebid_tlast;
  logic         m00_fram_ebid_tready;

  // PRACH C plane messages
  logic         m0_prach_tvalid;
  logic         m0_prach_tready;
  logic [3 : 0] m0_prach_cc;
  logic [7 : 0] m0_prach_ss;
  logic [ 11:0] m0_prach_section_id;
  logic [3 : 0] m0_prach_return_port;
  logic [3 : 0] m0_prach_filter_index;
  logic [3 : 0] m0_prach_sf;
  logic [5 : 0] m0_prach_sl;
  logic [5 : 0] m0_prach_sy;
  logic [ 15:0] m0_prach_time_offset;
  logic [7 : 0] m0_prach_frame_structure;
  logic [ 15:0] m0_prach_cp_length;
  logic [7 : 0] m0_prach_udcomphdr;
  logic         m0_prach_rb;
  logic         m0_prach_syminc;
  logic [9 : 0] m0_prach_start_prbc;
  logic [7 : 0] m0_prach_num_prbc;
  logic [ 11:0] m0_prach_remask;
  logic [3 : 0] m0_prach_num_symbol;
  logic [ 14:0] m0_prach_beamid;
  logic [ 23:0] m0_prach_freqoffset;

  // Timer ports
  logic [ 11:0] m_ul_sym_num               [      NUM_CC];
  logic [ 11:0] m_ul_cta_sym_num           [      NUM_CC];
  logic         m_ul_update                [      NUM_CC];
  logic [ 11:0] m_dl_sym_num               [      NUM_CC];
  logic [ 11:0] m_dl_cta_sym_num           [      NUM_CC];
  logic         m_dl_update                [      NUM_CC];
  logic         m_ul_toggle                [      NUM_CC];
  logic         m_dl_toggle                [      NUM_CC];
  logic         m_cc_enable                [      NUM_CC];
  logic         m_cc_reload                [      NUM_CC];

  // Uplink data to core from DFE
  logic [ 63:0] s_fram_data_tdata          [NUM_UL_LAYER];
  logic [  7:0] s_fram_data_tkeep          [NUM_UL_LAYER];
  logic         s_fram_data_tvalid         [NUM_UL_LAYER];
  logic         s_fram_data_tlast          [NUM_UL_LAYER];
  logic         s_fram_data_tready         [NUM_UL_LAYER];
  // Core request for uplink data
  logic [ 24:0] s_fram_data_req            [NUM_UL_LAYER];

  logic         m_fram_bid_valid           [NUM_UL_LAYER];
  logic         m_fram_bid_tlast           [NUM_UL_LAYER];
  logic         m_fram_bid_ready           [NUM_UL_LAYER];
  logic         m_fram_bid_off             [NUM_UL_LAYER];
  logic [ 14:0] m_fram_bid_beamid15        [NUM_UL_LAYER];
  logic [ 11:0] m_fram_bid_remask          [NUM_UL_LAYER];
  logic         m_fram_bid_rb              [NUM_UL_LAYER];
  logic [  9:0] m_fram_bid_start_prbc      [NUM_UL_LAYER];
  logic [  7:0] m_fram_bid_num_prbc        [NUM_UL_LAYER];
  logic [  3:0] m_fram_bid_num_symbol      [NUM_UL_LAYER];
  logic [  7:0] m_fram_bid_cc_id           [NUM_UL_LAYER];
  logic [ 23:0] m_fram_bid_frequency_offset[NUM_UL_LAYER];
  logic [ 15:0] m_fram_bid_time_offset     [NUM_UL_LAYER];
  logic [  7:0] m_fram_bid_frame_structure [NUM_UL_LAYER];
  logic [ 15:0] m_fram_bid_cp_length       [NUM_UL_LAYER];

  // UNSOL
  logic [ 63:0] s00_fram_unsol_tdata;
  logic [  7:0] s00_fram_unsol_tkeep;
  logic         s00_fram_unsol_tvalid;
  logic         s00_fram_unsol_tlast;
  logic         s00_fram_unsol_tready;
  logic [ 31:0] s00_fram_unsol_tuser;

  // PRACH
  logic [ 63:0] s00_fram_prach_tdata;
  logic [  7:0] s00_fram_prach_tkeep;
  logic         s00_fram_prach_tvalid;
  logic         s00_fram_prach_tlast;
  logic         s00_fram_prach_tready;
  logic [ 31:0] s00_fram_prach_tuser;

  // Downlink U-Plane data from core to DFE
  logic [ 63:0] m_defm_data_tdata          [NUM_DL_LAYER];
  logic [  7:0] m_defm_data_tkeep          [NUM_DL_LAYER];
  logic         m_defm_data_tvalid         [NUM_DL_LAYER];
  logic         m_defm_data_tlast          [NUM_DL_LAYER];
  logic         m_defm_data_tready         [NUM_DL_LAYER];
  logic [ 30:0] m_defm_data_tuser          [NUM_DL_LAYER];

  // DL BID
  logic         m_defm_bid_valid           [NUM_DL_LAYER];
  logic         m_defm_bid_tlast           [NUM_DL_LAYER];
  logic         m_defm_bid_ready           [NUM_DL_LAYER];
  logic         m_defm_bid_off             [NUM_DL_LAYER];
  logic [ 14:0] m_defm_bid_beamid15        [NUM_DL_LAYER];
  logic [ 11:0] m_defm_bid_remask          [NUM_DL_LAYER];
  logic         m_defm_bid_rb              [NUM_DL_LAYER];
  logic [  9:0] m_defm_bid_start_prbc      [NUM_DL_LAYER];
  logic [  7:0] m_defm_bid_num_prbc        [NUM_DL_LAYER];
  logic [  3:0] m_defm_bid_num_symbol      [NUM_DL_LAYER];
  logic [  7:0] m_defm_bid_cc_id           [NUM_DL_LAYER];
  logic [ 23:0] m_defm_bid_frequency_offset[NUM_DL_LAYER];
  logic [ 15:0] m_defm_bid_time_offset     [NUM_DL_LAYER];
  logic [  7:0] m_defm_bid_frame_structure [NUM_DL_LAYER];
  logic [ 15:0] m_defm_bid_cp_length       [NUM_DL_LAYER];

  // O-RAM Parse Port
  logic         m_t_header_offset_valid    [NUM_ETH_PORT];
  logic         m_runt_packet_len          [NUM_ETH_PORT];
  logic [ 15:0] m_rtc_pc_id                [NUM_ETH_PORT];
  logic         m_concat                   [NUM_ETH_PORT];
  logic [  2:0] m_messagetype              [NUM_ETH_PORT];
  logic [  7:0] m_seqid                    [NUM_ETH_PORT];
  logic [  6:0] m_subseqid                 [NUM_ETH_PORT];
  logic         m_ebit                     [NUM_ETH_PORT];
  logic [ 15:0] m_payloadsize              [NUM_ETH_PORT];
  logic         m_packet_in_window         [NUM_ETH_PORT];
  logic [ 11:0] m_offset_in_symbol         [NUM_ETH_PORT];

  logic         m_radio_app_head_valid     [NUM_ETH_PORT];
  logic         m_datadirection            [NUM_ETH_PORT];
  logic [  7:0] m_numsections              [NUM_ETH_PORT];
  logic [  2:0] m_sectiontype              [NUM_ETH_PORT];
  logic [  3:0] m_filterindex              [NUM_ETH_PORT];
  logic [  7:0] m_frameid                  [NUM_ETH_PORT];
  logic [  3:0] m_subframeid               [NUM_ETH_PORT];
  logic [  5:0] m_slotid                   [NUM_ETH_PORT];
  logic [  5:0] m_symbolid                 [NUM_ETH_PORT];
  logic [  7:0] m_udcomphdr                [NUM_ETH_PORT];
  logic [ 15:0] m_timeoffset               [NUM_ETH_PORT];
  logic [  7:0] m_framestructure           [NUM_ETH_PORT];
  logic [ 15:0] m_cplength                 [NUM_ETH_PORT];

  logic         m_section_header_valid     [NUM_ETH_PORT];
  logic [  3:0] m_numsymbol                [NUM_ETH_PORT];
  logic [  7:0] m_numprbc                  [NUM_ETH_PORT];
  logic [  9:0] m_startprbc                [NUM_ETH_PORT];
  logic [ 11:0] m_sectionid                [NUM_ETH_PORT];
  logic         m_rb                       [NUM_ETH_PORT];
  logic [ 11:0] m_remask                   [NUM_ETH_PORT];
  logic [ 14:0] m_beamid15                 [NUM_ETH_PORT];
  logic [ 23:0] m_freqoffset               [NUM_ETH_PORT];

  logic [ 63:0] m_beamweights_tdata        [NUM_ETH_PORT];
  logic         m_beamweights_tvalid       [NUM_ETH_PORT];
  logic         m_beamweights_tlast        [NUM_ETH_PORT];
  logic         m_beamweights_tuser        [NUM_ETH_PORT];

  logic [ 63:0] m_raw_cplane_tdata         [NUM_ETH_PORT];
  logic         m_raw_cplane_tvalid        [NUM_ETH_PORT];
  logic         m_raw_cplane_tuser         [NUM_ETH_PORT];
  logic         m_raw_cplane_tlast         [NUM_ETH_PORT];
  logic [  7:0] m_raw_cplane_tkeep         [NUM_ETH_PORT];

  logic [ 26:0] m_unsupport_ext_tuser      [NUM_ETH_PORT];
  logic [ 63:0] m_unsupport_ext_tdata      [NUM_ETH_PORT];
  logic         m_unsupport_ext_tvalid     [NUM_ETH_PORT];
  logic [  7:0] m_unsupport_ext_tkeep      [NUM_ETH_PORT];
  logic         m_unsupport_ext_tlast      [NUM_ETH_PORT];

  // SSB Data
  logic [ 63:0] m_ssb_data_tdata;
  logic [  7:0] m_ssb_data_tkeep;
  logic         m_ssb_data_tvalid;
  logic         m_ssb_data_tlast;
  logic         m_ssb_data_tready;
  logic [ 30:0] m_ssb_data_tuser;

  // SSB Early BeamID generation
  logic [ 31:0] m_ssb_ebid_tdata;
  logic         m_ssb_ebid_tvalid;
  logic         m_ssb_ebid_tlast;
  logic         m_ssb_ebid_tready;

  // SSB beamid fwd interface
  logic         m_ssb_bid_tvalid;
  logic         m_ssb_bid_tlast;
  logic         m_ssb_bid_tready;
  logic         m_ssb_bid_off;
  logic [ 14:0] m_ssb_bid_beamid15;
  logic [ 11:0] m_ssb_bid_remask;
  logic         m_ssb_bid_rb;
  logic [  9:0] m_ssb_bid_start_prbc;
  logic [  7:0] m_ssb_bid_num_prbc;
  logic [  3:0] m_ssb_bid_num_symbol;
  logic [  7:0] m_ssb_bid_cc_id;
  logic [ 23:0] m_ssb_bid_frequency_offset;
  logic [ 15:0] m_ssb_bid_time_offset;
  logic [  7:0] m_ssb_bid_frame_structure;
  logic [ 15:0] m_ssb_bid_cp_length;

  // Reset to XORIF IP
  logic         defm_reset;
  logic         fram_reset;

  // Reset from XORIF IP
  logic         defm_reset_active;
  logic         fram_reset_active          [NUM_ETH_PORT];

  // Timer to XORIF IP
  logic         defm_radio_start_10ms;
  logic         fram_radio_start_10ms;

  // Ready status from XORIF IP
  logic         defm_ready;
  logic         fram_ready;

  // Others signals
  //---------------

  // TODO: connect
  logic [3:0] ctrl_bandwidth             [      NUM_CC] = '{NUM_CC{0}};
  logic [1:0] ctrl_numerology            [      NUM_CC] = '{NUM_CC{1}};
  logic [1:0] ctrl_compression_mode      [      NUM_CC] = '{NUM_CC{1}};


  // TODO: Reset generator

  assign defm_reset = rst_400m;
  assign fram_reset = rst_400m;

  // Symbol timing generation

  symbol_timing i_symbol_timing (
      // Adaptor Timer
      //==============
      .clk_491m52           (clk_491m52),
      .rst_491m52           (rst_491m52),
      // Timing base
      .dl_radio_start_10ms  (dl_radio_start_10ms),
      .ul_radio_start_10ms  (ul_radio_start_10ms),
      // XORIF Timer
      //============
      .clk_400m             (clk_400m),
      .rst_400m             (rst_400m),
      //
      .defm_radio_start_10ms(defm_radio_start_10ms),
      .fram_radio_start_10ms(fram_radio_start_10ms)
  );

  oran_radio_if i_oran_radio_if (
      .m00_defm_ebid_tdata           (m00_defm_ebid_tdata),
      .m00_defm_ebid_tvalid          (m00_defm_ebid_tvalid),
      .m00_defm_ebid_tlast           (m00_defm_ebid_tlast),
      .m00_defm_ebid_tready          (m00_defm_ebid_tready),
      //
      .m00_fram_ebid_tdata           (m00_fram_ebid_tdata),
      .m00_fram_ebid_tvalid          (m00_fram_ebid_tvalid),
      .m00_fram_ebid_tlast           (m00_fram_ebid_tlast),
      .m00_fram_ebid_tready          (m00_fram_ebid_tready),
      //
      .m0_prach_tvalid               (m0_prach_tvalid),
      .m0_prach_tready               (m0_prach_tready),
      .m0_prach_cc                   (m0_prach_cc),
      .m0_prach_ss                   (m0_prach_ss),
      .m0_prach_section_id           (m0_prach_section_id),
      .m0_prach_return_port          (m0_prach_return_port),
      .m0_prach_filter_index         (m0_prach_filter_index),
      .m0_prach_sf                   (m0_prach_sf),
      .m0_prach_sl                   (m0_prach_sl),
      .m0_prach_sy                   (m0_prach_sy),
      .m0_prach_time_offset          (m0_prach_time_offset),
      .m0_prach_frame_structure      (m0_prach_frame_structure),
      .m0_prach_cp_length            (m0_prach_cp_length),
      .m0_prach_udcomphdr            (m0_prach_udcomphdr),
      .m0_prach_rb                   (m0_prach_rb),
      .m0_prach_syminc               (m0_prach_syminc),
      .m0_prach_start_prbc           (m0_prach_start_prbc),
      .m0_prach_num_prbc             (m0_prach_num_prbc),
      .m0_prach_remask               (m0_prach_remask),
      .m0_prach_num_symbol           (m0_prach_num_symbol),
      .m0_prach_beamid               (m0_prach_beamid),
      .m0_prach_freqoffset           (m0_prach_freqoffset),
      //
      .m0_ul_sym_num                 (m_ul_sym_num[0]),
      .m0_ul_cta_sym_num             (m_ul_cta_sym_num[0]),
      .m0_ul_update                  (m_ul_update[0]),
      .m0_dl_sym_num                 (m_dl_sym_num[0]),
      .m0_dl_cta_sym_num             (m_dl_cta_sym_num[0]),
      .m0_dl_update                  (m_dl_update[0]),
      .m0_ul_toggle                  (m_ul_toggle[0]),
      .m0_dl_toggle                  (m_dl_toggle[0]),
      .m0_cc_enable                  (m_cc_enable[0]),
      .m0_cc_reload                  (m_cc_reload[0]),
      //
      .m1_ul_sym_num                 (m_ul_sym_num[1]),
      .m1_ul_cta_sym_num             (m_ul_cta_sym_num[1]),
      .m1_ul_update                  (m_ul_update[1]),
      .m1_dl_sym_num                 (m_dl_sym_num[1]),
      .m1_dl_cta_sym_num             (m_dl_cta_sym_num[1]),
      .m1_dl_update                  (m_dl_update[1]),
      .m1_ul_toggle                  (m_ul_toggle[1]),
      .m1_dl_toggle                  (m_dl_toggle[1]),
      .m1_cc_enable                  (m_cc_enable[1]),
      .m1_cc_reload                  (m_cc_reload[1]),
      //
      .s000_fram_data_tdata          (s_fram_data_tdata[0]),
      .s000_fram_data_tkeep          (s_fram_data_tkeep[0]),
      .s000_fram_data_tvalid         (s_fram_data_tvalid[0]),
      .s000_fram_data_tlast          (s_fram_data_tlast[0]),
      .s000_fram_data_tready         (s_fram_data_tready[0]),
      //
      .s000_fram_data_req            (s_fram_data_req[0]),
      //
      .m000_fram_bid_valid           (m_fram_bid_valid[0]),
      .m000_fram_bid_tlast           (m_fram_bid_tlast[0]),
      .m000_fram_bid_ready           (m_fram_bid_ready[0]),
      .m000_fram_bid_off             (m_fram_bid_off[0]),
      .m000_fram_bid_beamid15        (m_fram_bid_beamid15[0]),
      .m000_fram_bid_remask          (m_fram_bid_remask[0]),
      .m000_fram_bid_rb              (m_fram_bid_rb[0]),
      .m000_fram_bid_start_prbc      (m_fram_bid_start_prbc[0]),
      .m000_fram_bid_num_prbc        (m_fram_bid_num_prbc[0]),
      .m000_fram_bid_num_symbol      (m_fram_bid_num_symbol[0]),
      .m000_fram_bid_cc_id           (m_fram_bid_cc_id[0]),
      .m000_fram_bid_frequency_offset(m_fram_bid_frequency_offset[0]),
      .m000_fram_bid_time_offset     (m_fram_bid_time_offset[0]),
      .m000_fram_bid_frame_structure (m_fram_bid_frame_structure[0]),
      .m000_fram_bid_cp_length       (m_fram_bid_cp_length[0]),
      //
      .s001_fram_data_tdata          (s_fram_data_tdata[1]),
      .s001_fram_data_tkeep          (s_fram_data_tkeep[1]),
      .s001_fram_data_tvalid         (s_fram_data_tvalid[1]),
      .s001_fram_data_tlast          (s_fram_data_tlast[1]),
      .s001_fram_data_tready         (s_fram_data_tready[1]),
      //
      .s001_fram_data_req            (s_fram_data_req[1]),
      //
      .m001_fram_bid_valid           (m_fram_bid_valid[1]),
      .m001_fram_bid_tlast           (m_fram_bid_tlast[1]),
      .m001_fram_bid_ready           (m_fram_bid_ready[1]),
      .m001_fram_bid_off             (m_fram_bid_off[1]),
      .m001_fram_bid_beamid15        (m_fram_bid_beamid15[1]),
      .m001_fram_bid_remask          (m_fram_bid_remask[1]),
      .m001_fram_bid_rb              (m_fram_bid_rb[1]),
      .m001_fram_bid_start_prbc      (m_fram_bid_start_prbc[1]),
      .m001_fram_bid_num_prbc        (m_fram_bid_num_prbc[1]),
      .m001_fram_bid_num_symbol      (m_fram_bid_num_symbol[1]),
      .m001_fram_bid_cc_id           (m_fram_bid_cc_id[1]),
      .m001_fram_bid_frequency_offset(m_fram_bid_frequency_offset[1]),
      .m001_fram_bid_time_offset     (m_fram_bid_time_offset[1]),
      .m001_fram_bid_frame_structure (m_fram_bid_frame_structure[1]),
      .m001_fram_bid_cp_length       (m_fram_bid_cp_length[1]),
      //
      .s002_fram_data_tdata          (s_fram_data_tdata[2]),
      .s002_fram_data_tkeep          (s_fram_data_tkeep[2]),
      .s002_fram_data_tvalid         (s_fram_data_tvalid[2]),
      .s002_fram_data_tlast          (s_fram_data_tlast[2]),
      .s002_fram_data_tready         (s_fram_data_tready[2]),
      //
      .s002_fram_data_req            (s_fram_data_req[2]),
      //
      .m002_fram_bid_valid           (m_fram_bid_valid[2]),
      .m002_fram_bid_tlast           (m_fram_bid_tlast[2]),
      .m002_fram_bid_ready           (m_fram_bid_ready[2]),
      .m002_fram_bid_off             (m_fram_bid_off[2]),
      .m002_fram_bid_beamid15        (m_fram_bid_beamid15[2]),
      .m002_fram_bid_remask          (m_fram_bid_remask[2]),
      .m002_fram_bid_rb              (m_fram_bid_rb[2]),
      .m002_fram_bid_start_prbc      (m_fram_bid_start_prbc[2]),
      .m002_fram_bid_num_prbc        (m_fram_bid_num_prbc[2]),
      .m002_fram_bid_num_symbol      (m_fram_bid_num_symbol[2]),
      .m002_fram_bid_cc_id           (m_fram_bid_cc_id[2]),
      .m002_fram_bid_frequency_offset(m_fram_bid_frequency_offset[2]),
      .m002_fram_bid_time_offset     (m_fram_bid_time_offset[2]),
      .m002_fram_bid_frame_structure (m_fram_bid_frame_structure[2]),
      .m002_fram_bid_cp_length       (m_fram_bid_cp_length[2]),
      //
      .s003_fram_data_tdata          (s_fram_data_tdata[3]),
      .s003_fram_data_tkeep          (s_fram_data_tkeep[3]),
      .s003_fram_data_tvalid         (s_fram_data_tvalid[3]),
      .s003_fram_data_tlast          (s_fram_data_tlast[3]),
      .s003_fram_data_tready         (s_fram_data_tready[3]),
      //
      .s003_fram_data_req            (s_fram_data_req[3]),
      //
      .m003_fram_bid_valid           (m_fram_bid_valid[3]),
      .m003_fram_bid_tlast           (m_fram_bid_tlast[3]),
      .m003_fram_bid_ready           (m_fram_bid_ready[3]),
      .m003_fram_bid_off             (m_fram_bid_off[3]),
      .m003_fram_bid_beamid15        (m_fram_bid_beamid15[3]),
      .m003_fram_bid_remask          (m_fram_bid_remask[3]),
      .m003_fram_bid_rb              (m_fram_bid_rb[3]),
      .m003_fram_bid_start_prbc      (m_fram_bid_start_prbc[3]),
      .m003_fram_bid_num_prbc        (m_fram_bid_num_prbc[3]),
      .m003_fram_bid_num_symbol      (m_fram_bid_num_symbol[3]),
      .m003_fram_bid_cc_id           (m_fram_bid_cc_id[3]),
      .m003_fram_bid_frequency_offset(m_fram_bid_frequency_offset[3]),
      .m003_fram_bid_time_offset     (m_fram_bid_time_offset[3]),
      .m003_fram_bid_frame_structure (m_fram_bid_frame_structure[3]),
      .m003_fram_bid_cp_length       (m_fram_bid_cp_length[3]),
      //
      .s004_fram_data_tdata          (s_fram_data_tdata[4]),
      .s004_fram_data_tkeep          (s_fram_data_tkeep[4]),
      .s004_fram_data_tvalid         (s_fram_data_tvalid[4]),
      .s004_fram_data_tlast          (s_fram_data_tlast[4]),
      .s004_fram_data_tready         (s_fram_data_tready[4]),
      //
      .s004_fram_data_req            (s_fram_data_req[4]),
      //
      .m004_fram_bid_valid           (m_fram_bid_valid[4]),
      .m004_fram_bid_tlast           (m_fram_bid_tlast[4]),
      .m004_fram_bid_ready           (m_fram_bid_ready[4]),
      .m004_fram_bid_off             (m_fram_bid_off[4]),
      .m004_fram_bid_beamid15        (m_fram_bid_beamid15[4]),
      .m004_fram_bid_remask          (m_fram_bid_remask[4]),
      .m004_fram_bid_rb              (m_fram_bid_rb[4]),
      .m004_fram_bid_start_prbc      (m_fram_bid_start_prbc[4]),
      .m004_fram_bid_num_prbc        (m_fram_bid_num_prbc[4]),
      .m004_fram_bid_num_symbol      (m_fram_bid_num_symbol[4]),
      .m004_fram_bid_cc_id           (m_fram_bid_cc_id[4]),
      .m004_fram_bid_frequency_offset(m_fram_bid_frequency_offset[4]),
      .m004_fram_bid_time_offset     (m_fram_bid_time_offset[4]),
      .m004_fram_bid_frame_structure (m_fram_bid_frame_structure[4]),
      .m004_fram_bid_cp_length       (m_fram_bid_cp_length[4]),
      //
      .s005_fram_data_tdata          (s_fram_data_tdata[5]),
      .s005_fram_data_tkeep          (s_fram_data_tkeep[5]),
      .s005_fram_data_tvalid         (s_fram_data_tvalid[5]),
      .s005_fram_data_tlast          (s_fram_data_tlast[5]),
      .s005_fram_data_tready         (s_fram_data_tready[5]),
      //
      .s005_fram_data_req            (s_fram_data_req[5]),
      //
      .m005_fram_bid_valid           (m_fram_bid_valid[5]),
      .m005_fram_bid_tlast           (m_fram_bid_tlast[5]),
      .m005_fram_bid_ready           (m_fram_bid_ready[5]),
      .m005_fram_bid_off             (m_fram_bid_off[5]),
      .m005_fram_bid_beamid15        (m_fram_bid_beamid15[5]),
      .m005_fram_bid_remask          (m_fram_bid_remask[5]),
      .m005_fram_bid_rb              (m_fram_bid_rb[5]),
      .m005_fram_bid_start_prbc      (m_fram_bid_start_prbc[5]),
      .m005_fram_bid_num_prbc        (m_fram_bid_num_prbc[5]),
      .m005_fram_bid_num_symbol      (m_fram_bid_num_symbol[5]),
      .m005_fram_bid_cc_id           (m_fram_bid_cc_id[5]),
      .m005_fram_bid_frequency_offset(m_fram_bid_frequency_offset[5]),
      .m005_fram_bid_time_offset     (m_fram_bid_time_offset[5]),
      .m005_fram_bid_frame_structure (m_fram_bid_frame_structure[5]),
      .m005_fram_bid_cp_length       (m_fram_bid_cp_length[5]),
      //
      .s006_fram_data_tdata          (s_fram_data_tdata[6]),
      .s006_fram_data_tkeep          (s_fram_data_tkeep[6]),
      .s006_fram_data_tvalid         (s_fram_data_tvalid[6]),
      .s006_fram_data_tlast          (s_fram_data_tlast[6]),
      .s006_fram_data_tready         (s_fram_data_tready[6]),
      //
      .s006_fram_data_req            (s_fram_data_req[6]),
      //
      .m006_fram_bid_valid           (m_fram_bid_valid[6]),
      .m006_fram_bid_tlast           (m_fram_bid_tlast[6]),
      .m006_fram_bid_ready           (m_fram_bid_ready[6]),
      .m006_fram_bid_off             (m_fram_bid_off[6]),
      .m006_fram_bid_beamid15        (m_fram_bid_beamid15[6]),
      .m006_fram_bid_remask          (m_fram_bid_remask[6]),
      .m006_fram_bid_rb              (m_fram_bid_rb[6]),
      .m006_fram_bid_start_prbc      (m_fram_bid_start_prbc[6]),
      .m006_fram_bid_num_prbc        (m_fram_bid_num_prbc[6]),
      .m006_fram_bid_num_symbol      (m_fram_bid_num_symbol[6]),
      .m006_fram_bid_cc_id           (m_fram_bid_cc_id[6]),
      .m006_fram_bid_frequency_offset(m_fram_bid_frequency_offset[6]),
      .m006_fram_bid_time_offset     (m_fram_bid_time_offset[6]),
      .m006_fram_bid_frame_structure (m_fram_bid_frame_structure[6]),
      .m006_fram_bid_cp_length       (m_fram_bid_cp_length[6]),
      //
      .s007_fram_data_tdata          (s_fram_data_tdata[7]),
      .s007_fram_data_tkeep          (s_fram_data_tkeep[7]),
      .s007_fram_data_tvalid         (s_fram_data_tvalid[7]),
      .s007_fram_data_tlast          (s_fram_data_tlast[7]),
      .s007_fram_data_tready         (s_fram_data_tready[7]),
      //
      .s007_fram_data_req            (s_fram_data_req[7]),
      //
      .m007_fram_bid_valid           (m_fram_bid_valid[7]),
      .m007_fram_bid_tlast           (m_fram_bid_tlast[7]),
      .m007_fram_bid_ready           (m_fram_bid_ready[7]),
      .m007_fram_bid_off             (m_fram_bid_off[7]),
      .m007_fram_bid_beamid15        (m_fram_bid_beamid15[7]),
      .m007_fram_bid_remask          (m_fram_bid_remask[7]),
      .m007_fram_bid_rb              (m_fram_bid_rb[7]),
      .m007_fram_bid_start_prbc      (m_fram_bid_start_prbc[7]),
      .m007_fram_bid_num_prbc        (m_fram_bid_num_prbc[7]),
      .m007_fram_bid_num_symbol      (m_fram_bid_num_symbol[7]),
      .m007_fram_bid_cc_id           (m_fram_bid_cc_id[7]),
      .m007_fram_bid_frequency_offset(m_fram_bid_frequency_offset[7]),
      .m007_fram_bid_time_offset     (m_fram_bid_time_offset[7]),
      .m007_fram_bid_frame_structure (m_fram_bid_frame_structure[7]),
      .m007_fram_bid_cp_length       (m_fram_bid_cp_length[7]),
      //
      .s00_fram_unsol_tdata          (s00_fram_unsol_tdata),
      .s00_fram_unsol_tkeep          (s00_fram_unsol_tkeep),
      .s00_fram_unsol_tvalid         (s00_fram_unsol_tvalid),
      .s00_fram_unsol_tlast          (s00_fram_unsol_tlast),
      .s00_fram_unsol_tready         (s00_fram_unsol_tready),
      .s00_fram_unsol_tuser          (s00_fram_unsol_tuser),
      //
      .s00_fram_prach_tdata          (s00_fram_prach_tdata),
      .s00_fram_prach_tkeep          (s00_fram_prach_tkeep),
      .s00_fram_prach_tvalid         (s00_fram_prach_tvalid),
      .s00_fram_prach_tlast          (s00_fram_prach_tlast),
      .s00_fram_prach_tready         (s00_fram_prach_tready),
      .s00_fram_prach_tuser          (s00_fram_prach_tuser),
      //
      .m000_defm_data_tdata          (m_defm_data_tdata[00]),
      .m000_defm_data_tkeep          (m_defm_data_tkeep[00]),
      .m000_defm_data_tvalid         (m_defm_data_tvalid[00]),
      .m000_defm_data_tlast          (m_defm_data_tlast[00]),
      .m000_defm_data_tready         (m_defm_data_tready[00]),
      .m000_defm_data_tuser          (m_defm_data_tuser[00]),
      //
      .m000_defm_bid_valid           (m_defm_bid_valid[00]),
      .m000_defm_bid_tlast           (m_defm_bid_tlast[00]),
      .m000_defm_bid_ready           (m_defm_bid_ready[00]),
      .m000_defm_bid_off             (m_defm_bid_off[00]),
      .m000_defm_bid_beamid15        (m_defm_bid_beamid15[00]),
      .m000_defm_bid_remask          (m_defm_bid_remask[00]),
      .m000_defm_bid_rb              (m_defm_bid_rb[00]),
      .m000_defm_bid_start_prbc      (m_defm_bid_start_prbc[00]),
      .m000_defm_bid_num_prbc        (m_defm_bid_num_prbc[00]),
      .m000_defm_bid_num_symbol      (m_defm_bid_num_symbol[00]),
      .m000_defm_bid_cc_id           (m_defm_bid_cc_id[00]),
      .m000_defm_bid_frequency_offset(m_defm_bid_frequency_offset[00]),
      .m000_defm_bid_time_offset     (m_defm_bid_time_offset[00]),
      .m000_defm_bid_frame_structure (m_defm_bid_frame_structure[00]),
      .m000_defm_bid_cp_length       (m_defm_bid_cp_length[00]),
      //
      .m001_defm_data_tdata          (m_defm_data_tdata[01]),
      .m001_defm_data_tkeep          (m_defm_data_tkeep[01]),
      .m001_defm_data_tvalid         (m_defm_data_tvalid[01]),
      .m001_defm_data_tlast          (m_defm_data_tlast[01]),
      .m001_defm_data_tready         (m_defm_data_tready[01]),
      .m001_defm_data_tuser          (m_defm_data_tuser[01]),
      .m001_defm_bid_valid           (m_defm_bid_valid[01]),
      .m001_defm_bid_tlast           (m_defm_bid_tlast[01]),
      .m001_defm_bid_ready           (m_defm_bid_ready[01]),
      .m001_defm_bid_off             (m_defm_bid_off[01]),
      .m001_defm_bid_beamid15        (m_defm_bid_beamid15[01]),
      .m001_defm_bid_remask          (m_defm_bid_remask[01]),
      .m001_defm_bid_rb              (m_defm_bid_rb[01]),
      .m001_defm_bid_start_prbc      (m_defm_bid_start_prbc[01]),
      .m001_defm_bid_num_prbc        (m_defm_bid_num_prbc[01]),
      .m001_defm_bid_num_symbol      (m_defm_bid_num_symbol[01]),
      .m001_defm_bid_cc_id           (m_defm_bid_cc_id[01]),
      .m001_defm_bid_frequency_offset(m_defm_bid_frequency_offset[01]),
      .m001_defm_bid_time_offset     (m_defm_bid_time_offset[01]),
      .m001_defm_bid_frame_structure (m_defm_bid_frame_structure[01]),
      .m001_defm_bid_cp_length       (m_defm_bid_cp_length[01]),
      //
      .m002_defm_data_tdata          (m_defm_data_tdata[02]),
      .m002_defm_data_tkeep          (m_defm_data_tkeep[02]),
      .m002_defm_data_tvalid         (m_defm_data_tvalid[02]),
      .m002_defm_data_tlast          (m_defm_data_tlast[02]),
      .m002_defm_data_tready         (m_defm_data_tready[02]),
      .m002_defm_data_tuser          (m_defm_data_tuser[02]),
      //
      .m002_defm_bid_valid           (m_defm_bid_valid[02]),
      .m002_defm_bid_tlast           (m_defm_bid_tlast[02]),
      .m002_defm_bid_ready           (m_defm_bid_ready[02]),
      .m002_defm_bid_off             (m_defm_bid_off[02]),
      .m002_defm_bid_beamid15        (m_defm_bid_beamid15[02]),
      .m002_defm_bid_remask          (m_defm_bid_remask[02]),
      .m002_defm_bid_rb              (m_defm_bid_rb[02]),
      .m002_defm_bid_start_prbc      (m_defm_bid_start_prbc[02]),
      .m002_defm_bid_num_prbc        (m_defm_bid_num_prbc[02]),
      .m002_defm_bid_num_symbol      (m_defm_bid_num_symbol[02]),
      .m002_defm_bid_cc_id           (m_defm_bid_cc_id[02]),
      .m002_defm_bid_frequency_offset(m_defm_bid_frequency_offset[02]),
      .m002_defm_bid_time_offset     (m_defm_bid_time_offset[02]),
      .m002_defm_bid_frame_structure (m_defm_bid_frame_structure[02]),
      .m002_defm_bid_cp_length       (m_defm_bid_cp_length[02]),
      //
      .m003_defm_data_tdata          (m_defm_data_tdata[03]),
      .m003_defm_data_tkeep          (m_defm_data_tkeep[03]),
      .m003_defm_data_tvalid         (m_defm_data_tvalid[03]),
      .m003_defm_data_tlast          (m_defm_data_tlast[03]),
      .m003_defm_data_tready         (m_defm_data_tready[03]),
      .m003_defm_data_tuser          (m_defm_data_tuser[03]),
      //
      .m003_defm_bid_valid           (m_defm_bid_valid[03]),
      .m003_defm_bid_tlast           (m_defm_bid_tlast[03]),
      .m003_defm_bid_ready           (m_defm_bid_ready[03]),
      .m003_defm_bid_off             (m_defm_bid_off[03]),
      .m003_defm_bid_beamid15        (m_defm_bid_beamid15[03]),
      .m003_defm_bid_remask          (m_defm_bid_remask[03]),
      .m003_defm_bid_rb              (m_defm_bid_rb[03]),
      .m003_defm_bid_start_prbc      (m_defm_bid_start_prbc[03]),
      .m003_defm_bid_num_prbc        (m_defm_bid_num_prbc[03]),
      .m003_defm_bid_num_symbol      (m_defm_bid_num_symbol[03]),
      .m003_defm_bid_cc_id           (m_defm_bid_cc_id[03]),
      .m003_defm_bid_frequency_offset(m_defm_bid_frequency_offset[03]),
      .m003_defm_bid_time_offset     (m_defm_bid_time_offset[03]),
      .m003_defm_bid_frame_structure (m_defm_bid_frame_structure[03]),
      .m003_defm_bid_cp_length       (m_defm_bid_cp_length[03]),
      //
      .m004_defm_data_tdata          (m_defm_data_tdata[04]),
      .m004_defm_data_tkeep          (m_defm_data_tkeep[04]),
      .m004_defm_data_tvalid         (m_defm_data_tvalid[04]),
      .m004_defm_data_tlast          (m_defm_data_tlast[04]),
      .m004_defm_data_tready         (m_defm_data_tready[04]),
      .m004_defm_data_tuser          (m_defm_data_tuser[04]),
      //
      .m004_defm_bid_valid           (m_defm_bid_valid[04]),
      .m004_defm_bid_tlast           (m_defm_bid_tlast[04]),
      .m004_defm_bid_ready           (m_defm_bid_ready[04]),
      .m004_defm_bid_off             (m_defm_bid_off[04]),
      .m004_defm_bid_beamid15        (m_defm_bid_beamid15[04]),
      .m004_defm_bid_remask          (m_defm_bid_remask[04]),
      .m004_defm_bid_rb              (m_defm_bid_rb[04]),
      .m004_defm_bid_start_prbc      (m_defm_bid_start_prbc[04]),
      .m004_defm_bid_num_prbc        (m_defm_bid_num_prbc[04]),
      .m004_defm_bid_num_symbol      (m_defm_bid_num_symbol[04]),
      .m004_defm_bid_cc_id           (m_defm_bid_cc_id[04]),
      .m004_defm_bid_frequency_offset(m_defm_bid_frequency_offset[04]),
      .m004_defm_bid_time_offset     (m_defm_bid_time_offset[04]),
      .m004_defm_bid_frame_structure (m_defm_bid_frame_structure[04]),
      .m004_defm_bid_cp_length       (m_defm_bid_cp_length[04]),
      //
      .m005_defm_data_tdata          (m_defm_data_tdata[05]),
      .m005_defm_data_tkeep          (m_defm_data_tkeep[05]),
      .m005_defm_data_tvalid         (m_defm_data_tvalid[05]),
      .m005_defm_data_tlast          (m_defm_data_tlast[05]),
      .m005_defm_data_tready         (m_defm_data_tready[05]),
      .m005_defm_data_tuser          (m_defm_data_tuser[05]),
      //
      .m005_defm_bid_valid           (m_defm_bid_valid[05]),
      .m005_defm_bid_tlast           (m_defm_bid_tlast[05]),
      .m005_defm_bid_ready           (m_defm_bid_ready[05]),
      .m005_defm_bid_off             (m_defm_bid_off[05]),
      .m005_defm_bid_beamid15        (m_defm_bid_beamid15[05]),
      .m005_defm_bid_remask          (m_defm_bid_remask[05]),
      .m005_defm_bid_rb              (m_defm_bid_rb[05]),
      .m005_defm_bid_start_prbc      (m_defm_bid_start_prbc[05]),
      .m005_defm_bid_num_prbc        (m_defm_bid_num_prbc[05]),
      .m005_defm_bid_num_symbol      (m_defm_bid_num_symbol[05]),
      .m005_defm_bid_cc_id           (m_defm_bid_cc_id[05]),
      .m005_defm_bid_frequency_offset(m_defm_bid_frequency_offset[05]),
      .m005_defm_bid_time_offset     (m_defm_bid_time_offset[05]),
      .m005_defm_bid_frame_structure (m_defm_bid_frame_structure[05]),
      .m005_defm_bid_cp_length       (m_defm_bid_cp_length[05]),
      //
      .m006_defm_data_tdata          (m_defm_data_tdata[06]),
      .m006_defm_data_tkeep          (m_defm_data_tkeep[06]),
      .m006_defm_data_tvalid         (m_defm_data_tvalid[06]),
      .m006_defm_data_tlast          (m_defm_data_tlast[06]),
      .m006_defm_data_tready         (m_defm_data_tready[06]),
      .m006_defm_data_tuser          (m_defm_data_tuser[06]),
      //
      .m006_defm_bid_valid           (m_defm_bid_valid[06]),
      .m006_defm_bid_tlast           (m_defm_bid_tlast[06]),
      .m006_defm_bid_ready           (m_defm_bid_ready[06]),
      .m006_defm_bid_off             (m_defm_bid_off[06]),
      .m006_defm_bid_beamid15        (m_defm_bid_beamid15[06]),
      .m006_defm_bid_remask          (m_defm_bid_remask[06]),
      .m006_defm_bid_rb              (m_defm_bid_rb[06]),
      .m006_defm_bid_start_prbc      (m_defm_bid_start_prbc[06]),
      .m006_defm_bid_num_prbc        (m_defm_bid_num_prbc[06]),
      .m006_defm_bid_num_symbol      (m_defm_bid_num_symbol[06]),
      .m006_defm_bid_cc_id           (m_defm_bid_cc_id[06]),
      .m006_defm_bid_frequency_offset(m_defm_bid_frequency_offset[06]),
      .m006_defm_bid_time_offset     (m_defm_bid_time_offset[06]),
      .m006_defm_bid_frame_structure (m_defm_bid_frame_structure[06]),
      .m006_defm_bid_cp_length       (m_defm_bid_cp_length[06]),
      //
      .m007_defm_data_tdata          (m_defm_data_tdata[07]),
      .m007_defm_data_tkeep          (m_defm_data_tkeep[07]),
      .m007_defm_data_tvalid         (m_defm_data_tvalid[07]),
      .m007_defm_data_tlast          (m_defm_data_tlast[07]),
      .m007_defm_data_tready         (m_defm_data_tready[07]),
      .m007_defm_data_tuser          (m_defm_data_tuser[07]),
      //
      .m007_defm_bid_valid           (m_defm_bid_valid[07]),
      .m007_defm_bid_tlast           (m_defm_bid_tlast[07]),
      .m007_defm_bid_ready           (m_defm_bid_ready[07]),
      .m007_defm_bid_off             (m_defm_bid_off[07]),
      .m007_defm_bid_beamid15        (m_defm_bid_beamid15[07]),
      .m007_defm_bid_remask          (m_defm_bid_remask[07]),
      .m007_defm_bid_rb              (m_defm_bid_rb[07]),
      .m007_defm_bid_start_prbc      (m_defm_bid_start_prbc[07]),
      .m007_defm_bid_num_prbc        (m_defm_bid_num_prbc[07]),
      .m007_defm_bid_num_symbol      (m_defm_bid_num_symbol[07]),
      .m007_defm_bid_cc_id           (m_defm_bid_cc_id[07]),
      .m007_defm_bid_frequency_offset(m_defm_bid_frequency_offset[07]),
      .m007_defm_bid_time_offset     (m_defm_bid_time_offset[07]),
      .m007_defm_bid_frame_structure (m_defm_bid_frame_structure[07]),
      .m007_defm_bid_cp_length       (m_defm_bid_cp_length[07]),
      //
      .m008_defm_data_tdata          (m_defm_data_tdata[08]),
      .m008_defm_data_tkeep          (m_defm_data_tkeep[08]),
      .m008_defm_data_tvalid         (m_defm_data_tvalid[08]),
      .m008_defm_data_tlast          (m_defm_data_tlast[08]),
      .m008_defm_data_tready         (m_defm_data_tready[08]),
      .m008_defm_data_tuser          (m_defm_data_tuser[08]),
      //
      .m008_defm_bid_valid           (m_defm_bid_valid[08]),
      .m008_defm_bid_tlast           (m_defm_bid_tlast[08]),
      .m008_defm_bid_ready           (m_defm_bid_ready[08]),
      .m008_defm_bid_off             (m_defm_bid_off[08]),
      .m008_defm_bid_beamid15        (m_defm_bid_beamid15[08]),
      .m008_defm_bid_remask          (m_defm_bid_remask[08]),
      .m008_defm_bid_rb              (m_defm_bid_rb[08]),
      .m008_defm_bid_start_prbc      (m_defm_bid_start_prbc[08]),
      .m008_defm_bid_num_prbc        (m_defm_bid_num_prbc[08]),
      .m008_defm_bid_num_symbol      (m_defm_bid_num_symbol[08]),
      .m008_defm_bid_cc_id           (m_defm_bid_cc_id[08]),
      .m008_defm_bid_frequency_offset(m_defm_bid_frequency_offset[08]),
      .m008_defm_bid_time_offset     (m_defm_bid_time_offset[08]),
      .m008_defm_bid_frame_structure (m_defm_bid_frame_structure[08]),
      .m008_defm_bid_cp_length       (m_defm_bid_cp_length[08]),
      //
      .m009_defm_data_tdata          (m_defm_data_tdata[09]),
      .m009_defm_data_tkeep          (m_defm_data_tkeep[09]),
      .m009_defm_data_tvalid         (m_defm_data_tvalid[09]),
      .m009_defm_data_tlast          (m_defm_data_tlast[09]),
      .m009_defm_data_tready         (m_defm_data_tready[09]),
      .m009_defm_data_tuser          (m_defm_data_tuser[09]),
      //
      .m009_defm_bid_valid           (m_defm_bid_valid[09]),
      .m009_defm_bid_tlast           (m_defm_bid_tlast[09]),
      .m009_defm_bid_ready           (m_defm_bid_ready[09]),
      .m009_defm_bid_off             (m_defm_bid_off[09]),
      .m009_defm_bid_beamid15        (m_defm_bid_beamid15[09]),
      .m009_defm_bid_remask          (m_defm_bid_remask[09]),
      .m009_defm_bid_rb              (m_defm_bid_rb[09]),
      .m009_defm_bid_start_prbc      (m_defm_bid_start_prbc[09]),
      .m009_defm_bid_num_prbc        (m_defm_bid_num_prbc[09]),
      .m009_defm_bid_num_symbol      (m_defm_bid_num_symbol[09]),
      .m009_defm_bid_cc_id           (m_defm_bid_cc_id[09]),
      .m009_defm_bid_frequency_offset(m_defm_bid_frequency_offset[09]),
      .m009_defm_bid_time_offset     (m_defm_bid_time_offset[09]),
      .m009_defm_bid_frame_structure (m_defm_bid_frame_structure[09]),
      .m009_defm_bid_cp_length       (m_defm_bid_cp_length[09]),
      //
      .m010_defm_data_tdata          (m_defm_data_tdata[10]),
      .m010_defm_data_tkeep          (m_defm_data_tkeep[10]),
      .m010_defm_data_tvalid         (m_defm_data_tvalid[10]),
      .m010_defm_data_tlast          (m_defm_data_tlast[10]),
      .m010_defm_data_tready         (m_defm_data_tready[10]),
      .m010_defm_data_tuser          (m_defm_data_tuser[10]),
      //
      .m010_defm_bid_valid           (m_defm_bid_valid[10]),
      .m010_defm_bid_tlast           (m_defm_bid_tlast[10]),
      .m010_defm_bid_ready           (m_defm_bid_ready[10]),
      .m010_defm_bid_off             (m_defm_bid_off[10]),
      .m010_defm_bid_beamid15        (m_defm_bid_beamid15[10]),
      .m010_defm_bid_remask          (m_defm_bid_remask[10]),
      .m010_defm_bid_rb              (m_defm_bid_rb[10]),
      .m010_defm_bid_start_prbc      (m_defm_bid_start_prbc[10]),
      .m010_defm_bid_num_prbc        (m_defm_bid_num_prbc[10]),
      .m010_defm_bid_num_symbol      (m_defm_bid_num_symbol[10]),
      .m010_defm_bid_cc_id           (m_defm_bid_cc_id[10]),
      .m010_defm_bid_frequency_offset(m_defm_bid_frequency_offset[10]),
      .m010_defm_bid_time_offset     (m_defm_bid_time_offset[10]),
      .m010_defm_bid_frame_structure (m_defm_bid_frame_structure[10]),
      .m010_defm_bid_cp_length       (m_defm_bid_cp_length[10]),
      //
      .m011_defm_data_tdata          (m_defm_data_tdata[11]),
      .m011_defm_data_tkeep          (m_defm_data_tkeep[11]),
      .m011_defm_data_tvalid         (m_defm_data_tvalid[11]),
      .m011_defm_data_tlast          (m_defm_data_tlast[11]),
      .m011_defm_data_tready         (m_defm_data_tready[11]),
      .m011_defm_data_tuser          (m_defm_data_tuser[11]),
      //
      .m011_defm_bid_valid           (m_defm_bid_valid[11]),
      .m011_defm_bid_tlast           (m_defm_bid_tlast[11]),
      .m011_defm_bid_ready           (m_defm_bid_ready[11]),
      .m011_defm_bid_off             (m_defm_bid_off[11]),
      .m011_defm_bid_beamid15        (m_defm_bid_beamid15[11]),
      .m011_defm_bid_remask          (m_defm_bid_remask[11]),
      .m011_defm_bid_rb              (m_defm_bid_rb[11]),
      .m011_defm_bid_start_prbc      (m_defm_bid_start_prbc[11]),
      .m011_defm_bid_num_prbc        (m_defm_bid_num_prbc[11]),
      .m011_defm_bid_num_symbol      (m_defm_bid_num_symbol[11]),
      .m011_defm_bid_cc_id           (m_defm_bid_cc_id[11]),
      .m011_defm_bid_frequency_offset(m_defm_bid_frequency_offset[11]),
      .m011_defm_bid_time_offset     (m_defm_bid_time_offset[11]),
      .m011_defm_bid_frame_structure (m_defm_bid_frame_structure[11]),
      .m011_defm_bid_cp_length       (m_defm_bid_cp_length[11]),
      //
      .m012_defm_data_tdata          (m_defm_data_tdata[12]),
      .m012_defm_data_tkeep          (m_defm_data_tkeep[12]),
      .m012_defm_data_tvalid         (m_defm_data_tvalid[12]),
      .m012_defm_data_tlast          (m_defm_data_tlast[12]),
      .m012_defm_data_tready         (m_defm_data_tready[12]),
      .m012_defm_data_tuser          (m_defm_data_tuser[12]),
      //
      .m012_defm_bid_valid           (m_defm_bid_valid[12]),
      .m012_defm_bid_tlast           (m_defm_bid_tlast[12]),
      .m012_defm_bid_ready           (m_defm_bid_ready[12]),
      .m012_defm_bid_off             (m_defm_bid_off[12]),
      .m012_defm_bid_beamid15        (m_defm_bid_beamid15[12]),
      .m012_defm_bid_remask          (m_defm_bid_remask[12]),
      .m012_defm_bid_rb              (m_defm_bid_rb[12]),
      .m012_defm_bid_start_prbc      (m_defm_bid_start_prbc[12]),
      .m012_defm_bid_num_prbc        (m_defm_bid_num_prbc[12]),
      .m012_defm_bid_num_symbol      (m_defm_bid_num_symbol[12]),
      .m012_defm_bid_cc_id           (m_defm_bid_cc_id[12]),
      .m012_defm_bid_frequency_offset(m_defm_bid_frequency_offset[12]),
      .m012_defm_bid_time_offset     (m_defm_bid_time_offset[12]),
      .m012_defm_bid_frame_structure (m_defm_bid_frame_structure[12]),
      .m012_defm_bid_cp_length       (m_defm_bid_cp_length[12]),
      //
      .m013_defm_data_tdata          (m_defm_data_tdata[13]),
      .m013_defm_data_tkeep          (m_defm_data_tkeep[13]),
      .m013_defm_data_tvalid         (m_defm_data_tvalid[13]),
      .m013_defm_data_tlast          (m_defm_data_tlast[13]),
      .m013_defm_data_tready         (m_defm_data_tready[13]),
      .m013_defm_data_tuser          (m_defm_data_tuser[13]),
      //
      .m013_defm_bid_valid           (m_defm_bid_valid[13]),
      .m013_defm_bid_tlast           (m_defm_bid_tlast[13]),
      .m013_defm_bid_ready           (m_defm_bid_ready[13]),
      .m013_defm_bid_off             (m_defm_bid_off[13]),
      .m013_defm_bid_beamid15        (m_defm_bid_beamid15[13]),
      .m013_defm_bid_remask          (m_defm_bid_remask[13]),
      .m013_defm_bid_rb              (m_defm_bid_rb[13]),
      .m013_defm_bid_start_prbc      (m_defm_bid_start_prbc[13]),
      .m013_defm_bid_num_prbc        (m_defm_bid_num_prbc[13]),
      .m013_defm_bid_num_symbol      (m_defm_bid_num_symbol[13]),
      .m013_defm_bid_cc_id           (m_defm_bid_cc_id[13]),
      .m013_defm_bid_frequency_offset(m_defm_bid_frequency_offset[13]),
      .m013_defm_bid_time_offset     (m_defm_bid_time_offset[13]),
      .m013_defm_bid_frame_structure (m_defm_bid_frame_structure[13]),
      .m013_defm_bid_cp_length       (m_defm_bid_cp_length[13]),
      //
      .m014_defm_data_tdata          (m_defm_data_tdata[14]),
      .m014_defm_data_tkeep          (m_defm_data_tkeep[14]),
      .m014_defm_data_tvalid         (m_defm_data_tvalid[14]),
      .m014_defm_data_tlast          (m_defm_data_tlast[14]),
      .m014_defm_data_tready         (m_defm_data_tready[14]),
      .m014_defm_data_tuser          (m_defm_data_tuser[14]),
      //
      .m014_defm_bid_valid           (m_defm_bid_valid[14]),
      .m014_defm_bid_tlast           (m_defm_bid_tlast[14]),
      .m014_defm_bid_ready           (m_defm_bid_ready[14]),
      .m014_defm_bid_off             (m_defm_bid_off[14]),
      .m014_defm_bid_beamid15        (m_defm_bid_beamid15[14]),
      .m014_defm_bid_remask          (m_defm_bid_remask[14]),
      .m014_defm_bid_rb              (m_defm_bid_rb[14]),
      .m014_defm_bid_start_prbc      (m_defm_bid_start_prbc[14]),
      .m014_defm_bid_num_prbc        (m_defm_bid_num_prbc[14]),
      .m014_defm_bid_num_symbol      (m_defm_bid_num_symbol[14]),
      .m014_defm_bid_cc_id           (m_defm_bid_cc_id[14]),
      .m014_defm_bid_frequency_offset(m_defm_bid_frequency_offset[14]),
      .m014_defm_bid_time_offset     (m_defm_bid_time_offset[14]),
      .m014_defm_bid_frame_structure (m_defm_bid_frame_structure[14]),
      .m014_defm_bid_cp_length       (m_defm_bid_cp_length[14]),
      //
      .m015_defm_data_tdata          (m_defm_data_tdata[15]),
      .m015_defm_data_tkeep          (m_defm_data_tkeep[15]),
      .m015_defm_data_tvalid         (m_defm_data_tvalid[15]),
      .m015_defm_data_tlast          (m_defm_data_tlast[15]),
      .m015_defm_data_tready         (m_defm_data_tready[15]),
      .m015_defm_data_tuser          (m_defm_data_tuser[15]),
      //
      .m015_defm_bid_valid           (m_defm_bid_valid[15]),
      .m015_defm_bid_tlast           (m_defm_bid_tlast[15]),
      .m015_defm_bid_ready           (m_defm_bid_ready[15]),
      .m015_defm_bid_off             (m_defm_bid_off[15]),
      .m015_defm_bid_beamid15        (m_defm_bid_beamid15[15]),
      .m015_defm_bid_remask          (m_defm_bid_remask[15]),
      .m015_defm_bid_rb              (m_defm_bid_rb[15]),
      .m015_defm_bid_start_prbc      (m_defm_bid_start_prbc[15]),
      .m015_defm_bid_num_prbc        (m_defm_bid_num_prbc[15]),
      .m015_defm_bid_num_symbol      (m_defm_bid_num_symbol[15]),
      .m015_defm_bid_cc_id           (m_defm_bid_cc_id[15]),
      .m015_defm_bid_frequency_offset(m_defm_bid_frequency_offset[15]),
      .m015_defm_bid_time_offset     (m_defm_bid_time_offset[15]),
      .m015_defm_bid_frame_structure (m_defm_bid_frame_structure[15]),
      .m015_defm_bid_cp_length       (m_defm_bid_cp_length[15]),
      //
      .tx0_eth_port_clk              (eth_port_clk[0]),
      .fram0_reset_active            (fram_reset_active[0]),
      //
      .m0_eth_fram_tdata             (m_eth_fram_tdata[0]),
      .m0_eth_fram_tkeep             (m_eth_fram_tkeep[0]),
      .m0_eth_fram_tvalid            (m_eth_fram_tvalid[0]),
      .m0_eth_fram_tlast             (m_eth_fram_tlast[0]),
      .m0_eth_fram_tready            (m_eth_fram_tready[0]),
      //
      .s0_eth_mac_tuser              (s_eth_mac_tuser[0]),
      .s0_eth_mac_bad_fcs            (s_eth_mac_bad_fcs[0]),
      .s0_eth_mac_tstamp_out         (s_eth_mac_tstamp_out[0]),
      .s0_eth_mac_tstamp_valid       (s_eth_mac_tstamp_valid[0]),
      //
      .s0_eth_defm_tdata             (s_eth_defm_tdata[0]),
      .s0_eth_defm_tkeep             (s_eth_defm_tkeep[0]),
      .s0_eth_defm_tvalid            (s_eth_defm_tvalid[0]),
      .s0_eth_defm_tlast             (s_eth_defm_tlast[0]),
      //
      .m0_message_tdata              (m_message_tdata[0]),
      .m0_message_tkeep              (m_message_tkeep[0]),
      .m0_message_tvalid             (m_message_tvalid[0]),
      .m0_message_tlast              (m_message_tlast[0]),
      .m0_message_tready             (m_message_tready[0]),
      .m0_message_ts_tdata           (m_message_ts_tdata[0]),
      .m0_message_ts_tvalid          (m_message_ts_tvalid[0]),
      //
      .m0_t_header_offset_valid      (m_t_header_offset_valid[0]),
      .m0_runt_packet_len            (m_runt_packet_len[0]),
      .m0_rtc_pc_id                  (m_rtc_pc_id[0]),
      .m0_concat                     (m_concat[0]),
      .m0_messagetype                (m_messagetype[0]),
      .m0_seqid                      (m_seqid[0]),
      .m0_subseqid                   (m_subseqid[0]),
      .m0_ebit                       (m_ebit[0]),
      .m0_payloadsize                (m_payloadsize[0]),
      .m0_packet_in_window           (m_packet_in_window[0]),
      .m0_offset_in_symbol           (m_offset_in_symbol[0]),
      //
      .m0_radio_app_head_valid       (m_radio_app_head_valid[0]),
      .m0_datadirection              (m_datadirection[0]),
      .m0_numsections                (m_numsections[0]),
      .m0_sectiontype                (m_sectiontype[0]),
      .m0_filterindex                (m_filterindex[0]),
      .m0_frameid                    (m_frameid[0]),
      .m0_subframeid                 (m_subframeid[0]),
      .m0_slotid                     (m_slotid[0]),
      .m0_symbolid                   (m_symbolid[0]),
      .m0_udcomphdr                  (m_udcomphdr[0]),
      .m0_timeoffset                 (m_timeoffset[0]),
      .m0_framestructure             (m_framestructure[0]),
      .m0_cplength                   (m_cplength[0]),
      //
      .m0_section_header_valid       (m_section_header_valid[0]),
      .m0_numsymbol                  (m_numsymbol[0]),
      .m0_numprbc                    (m_numprbc[0]),
      .m0_startprbc                  (m_startprbc[0]),
      .m0_sectionid                  (m_sectionid[0]),
      .m0_rb                         (m_rb[0]),
      .m0_remask                     (m_remask[0]),
      .m0_beamid15                   (m_beamid15[0]),
      .m0_freqoffset                 (m_freqoffset[0]),
      //
      .m0_beamweights_tdata          (m_beamweights_tdata[0]),
      .m0_beamweights_tvalid         (m_beamweights_tvalid[0]),
      .m0_beamweights_tlast          (m_beamweights_tlast[0]),
      .m0_beamweights_tuser          (m_beamweights_tuser[0]),
      //
      .m0_raw_cplane_tdata           (m_raw_cplane_tdata[0]),
      .m0_raw_cplane_tvalid          (m_raw_cplane_tvalid[0]),
      .m0_raw_cplane_tuser           (m_raw_cplane_tuser[0]),
      .m0_raw_cplane_tlast           (m_raw_cplane_tlast[0]),
      .m0_raw_cplane_tkeep           (m_raw_cplane_tkeep[0]),
      //
      .m0_unsupport_ext_tuser        (m_unsupport_ext_tuser[0]),
      .m0_unsupport_ext_tdata        (m_unsupport_ext_tdata[0]),
      .m0_unsupport_ext_tvalid       (m_unsupport_ext_tvalid[0]),
      .m0_unsupport_ext_tkeep        (m_unsupport_ext_tkeep[0]),
      .m0_unsupport_ext_tlast        (m_unsupport_ext_tlast[0]),
      //
      .tx1_eth_port_clk              (eth_port_clk[1]),
      .fram1_reset_active            (fram_reset_active[1]),
      //
      .m1_eth_fram_tdata             (m_eth_fram_tdata[1]),
      .m1_eth_fram_tkeep             (m_eth_fram_tkeep[1]),
      .m1_eth_fram_tvalid            (m_eth_fram_tvalid[1]),
      .m1_eth_fram_tlast             (m_eth_fram_tlast[1]),
      .m1_eth_fram_tready            (m_eth_fram_tready[1]),
      //
      .s1_eth_mac_tuser              (s_eth_mac_tuser[1]),
      .s1_eth_mac_bad_fcs            (s_eth_mac_bad_fcs[1]),
      .s1_eth_mac_tstamp_out         (s_eth_mac_tstamp_out[1]),
      .s1_eth_mac_tstamp_valid       (s_eth_mac_tstamp_valid[1]),
      //
      .s1_eth_defm_tdata             (s_eth_defm_tdata[1]),
      .s1_eth_defm_tkeep             (s_eth_defm_tkeep[1]),
      .s1_eth_defm_tvalid            (s_eth_defm_tvalid[1]),
      .s1_eth_defm_tlast             (s_eth_defm_tlast[1]),
      //
      .m1_message_tdata              (m_message_tdata[1]),
      .m1_message_tkeep              (m_message_tkeep[1]),
      .m1_message_tvalid             (m_message_tvalid[1]),
      .m1_message_tlast              (m_message_tlast[1]),
      .m1_message_tready             (m_message_tready[1]),
      .m1_message_ts_tdata           (m_message_ts_tdata[1]),
      .m1_message_ts_tvalid          (m_message_ts_tvalid[1]),
      //
      .m1_t_header_offset_valid      (m_t_header_offset_valid[1]),
      .m1_runt_packet_len            (m_runt_packet_len[1]),
      .m1_rtc_pc_id                  (m_rtc_pc_id[1]),
      .m1_concat                     (m_concat[1]),
      .m1_messagetype                (m_messagetype[1]),
      .m1_seqid                      (m_seqid[1]),
      .m1_subseqid                   (m_subseqid[1]),
      .m1_ebit                       (m_ebit[1]),
      .m1_payloadsize                (m_payloadsize[1]),
      .m1_packet_in_window           (m_packet_in_window[1]),
      .m1_offset_in_symbol           (m_offset_in_symbol[1]),
      //
      .m1_radio_app_head_valid       (m_radio_app_head_valid[1]),
      .m1_datadirection              (m_datadirection[1]),
      .m1_numsections                (m_numsections[1]),
      .m1_sectiontype                (m_sectiontype[1]),
      .m1_filterindex                (m_filterindex[1]),
      .m1_frameid                    (m_frameid[1]),
      .m1_subframeid                 (m_subframeid[1]),
      .m1_slotid                     (m_slotid[1]),
      .m1_symbolid                   (m_symbolid[1]),
      .m1_udcomphdr                  (m_udcomphdr[1]),
      .m1_timeoffset                 (m_timeoffset[1]),
      .m1_framestructure             (m_framestructure[1]),
      .m1_cplength                   (m_cplength[1]),
      //
      .m1_section_header_valid       (m_section_header_valid[1]),
      .m1_numsymbol                  (m_numsymbol[1]),
      .m1_numprbc                    (m_numprbc[1]),
      .m1_startprbc                  (m_startprbc[1]),
      .m1_sectionid                  (m_sectionid[1]),
      .m1_rb                         (m_rb[1]),
      .m1_remask                     (m_remask[1]),
      .m1_beamid15                   (m_beamid15[1]),
      .m1_freqoffset                 (m_freqoffset[1]),
      //
      .m1_beamweights_tdata          (m_beamweights_tdata[1]),
      .m1_beamweights_tvalid         (m_beamweights_tvalid[1]),
      .m1_beamweights_tlast          (m_beamweights_tlast[1]),
      .m1_beamweights_tuser          (m_beamweights_tuser[1]),
      //
      .m1_raw_cplane_tdata           (m_raw_cplane_tdata[1]),
      .m1_raw_cplane_tvalid          (m_raw_cplane_tvalid[1]),
      .m1_raw_cplane_tuser           (m_raw_cplane_tuser[1]),
      .m1_raw_cplane_tlast           (m_raw_cplane_tlast[1]),
      .m1_raw_cplane_tkeep           (m_raw_cplane_tkeep[1]),
      //
      .m1_unsupport_ext_tuser        (m_unsupport_ext_tuser[1]),
      .m1_unsupport_ext_tdata        (m_unsupport_ext_tdata[1]),
      .m1_unsupport_ext_tvalid       (m_unsupport_ext_tvalid[1]),
      .m1_unsupport_ext_tkeep        (m_unsupport_ext_tkeep[1]),
      .m1_unsupport_ext_tlast        (m_unsupport_ext_tlast[1]),
      //
      .defm_reset                    (defm_reset),
      .fram_reset                    (fram_reset),
      //
      .defm_radio_start_10ms         (defm_radio_start_10ms),
      .fram_radio_start_10ms         (fram_radio_start_10ms),
      //
      .internal_bus_clk              (clk_400m),
      //
      .defm_reset_active             (defm_reset_active),
      //
      .m_ssb_data_tdata              (m_ssb_data_tdata),
      .m_ssb_data_tkeep              (m_ssb_data_tkeep),
      .m_ssb_data_tvalid             (m_ssb_data_tvalid),
      .m_ssb_data_tlast              (m_ssb_data_tlast),
      .m_ssb_data_tready             (m_ssb_data_tready),
      .m_ssb_data_tuser              (m_ssb_data_tuser),
      //
      .m_ssb_ebid_tdata              (m_ssb_ebid_tdata),
      .m_ssb_ebid_tvalid             (m_ssb_ebid_tvalid),
      .m_ssb_ebid_tlast              (m_ssb_ebid_tlast),
      .m_ssb_ebid_tready             (m_ssb_ebid_tready),
      //
      .m_ssb_bid_tvalid              (m_ssb_bid_tvalid),
      .m_ssb_bid_tlast               (m_ssb_bid_tlast),
      .m_ssb_bid_tready              (m_ssb_bid_tready),
      .m_ssb_bid_off                 (m_ssb_bid_off),
      .m_ssb_bid_beamid15            (m_ssb_bid_beamid15),
      .m_ssb_bid_remask              (m_ssb_bid_remask),
      .m_ssb_bid_rb                  (m_ssb_bid_rb),
      .m_ssb_bid_start_prbc          (m_ssb_bid_start_prbc),
      .m_ssb_bid_num_prbc            (m_ssb_bid_num_prbc),
      .m_ssb_bid_num_symbol          (m_ssb_bid_num_symbol),
      .m_ssb_bid_cc_id               (m_ssb_bid_cc_id),
      .m_ssb_bid_frequency_offset    (m_ssb_bid_frequency_offset),
      .m_ssb_bid_time_offset         (m_ssb_bid_time_offset),
      .m_ssb_bid_frame_structure     (m_ssb_bid_frame_structure),
      .m_ssb_bid_cp_length           (m_ssb_bid_cp_length),
      //
      .fram_ready                    (fram_ready),
      .defm_ready                    (defm_ready),
      // AXI
      .interrupt                     (s00_interrupt),
      //
      .s_axi_aclk                    (aclk),
      .s_axi_aresetn                 (aresetn),
      //
      .s_axi_awaddr                  (s00_axi_awaddr),
      .s_axi_awvalid                 (s00_axi_awvalid),
      .s_axi_awready                 (s00_axi_awready),
      //
      .s_axi_wdata                   (s00_axi_wdata),
      .s_axi_wstrb                   (s00_axi_wstrb),
      .s_axi_wvalid                  (s00_axi_wvalid),
      .s_axi_wready                  (s00_axi_wready),
      //
      .s_axi_bresp                   (s00_axi_bresp),
      .s_axi_bvalid                  (s00_axi_bvalid),
      .s_axi_bready                  (s00_axi_bready),
      //
      .s_axi_araddr                  (s00_axi_araddr),
      .s_axi_arvalid                 (s00_axi_arvalid),
      .s_axi_arready                 (s00_axi_arready),
      //
      .s_axi_rdata                   (s00_axi_rdata),
      .s_axi_rresp                   (s00_axi_rresp),
      .s_axi_rvalid                  (s00_axi_rvalid),
      .s_axi_rready                  (s00_axi_rready)
  );


  dl_adaptor_sim i_dl_adaptor_sim (
      // Interface with XORIF
      //=====================
      .clk_400m             (clk_400m),
      .rst_400m             (rst_400m),
      //
      .defm_radio_start_10ms(defm_radio_start_10ms),
      .s_dl_update          (m_dl_update),
      //
      .s_defm_data_tdata    (m_defm_data_tdata),
      .s_defm_data_tkeep    (m_defm_data_tkeep),
      .s_defm_data_tvalid   (m_defm_data_tvalid),
      .s_defm_data_tlast    (m_defm_data_tlast),
      .s_defm_data_tready   (m_defm_data_tready),
      .s_defm_data_tuser    (m_defm_data_tuser),
      // Interface with DFE
      //===================
      .clk_491m52           (clk_491m52),
      .rst_491m52           (rst_491m52),
      //
      .dl_radio_start_10ms  (dl_radio_start_10ms),
      //
      .dl_sof               (dl_sof),
      .dl_sos               (dl_sos),
      .dl_data_i            (dl_data_i),
      .dl_data_q            (dl_data_q),
      .dl_valid             (dl_valid),
      // Control Interface
      .ctrl_bandwidth       (ctrl_bandwidth),
      .ctrl_numerology      (ctrl_numerology),
      .ctrl_compression_mode(ctrl_compression_mode)
  );


  srs_adaptor_sim #(
    .NUM_ETH_PORT (NUM_ETH_PORT),
    .NUM_SRS_LAYER(64),
    .NUM_CC       (NUM_CC)
  ) i_srs_adaptor_sim (
    // Interface with DFE
    //===================
    .clk_491m52       (clk_491m52),
    .rst_491m52       (rst_491m52),
    // SRS Section Header
    .srs_buf_numsymbol(),
    .srs_buf_symbol   (),
    .srs_buf_valid    (),
    // SRS data request
    .srs_req_layer    (),
    .srs_req_symbol   (),
    .srs_req_cc       (),
    .srs_req_valid    (),
    // SRS data
    .srs_data         (), // {4'b exponent, 9'b mantissa Q, 9'b mantissa I}
    .srs_sop          (),
    .srs_eop          (),
    // Interface with XORIF
    //=====================
    .clk_400m         (clk_400m),
    .rst_400m         (rst_400m),
    // ORAN Parse Port
    .m_t_header_offset_valid(m_t_header_offset_valid)    ,
    .m_runt_packet_len      (m_runt_packet_len)          ,
    .m_rtc_pc_id(m_rtc_pc_id)                ,
    .m_concat(m_concat)                   ,
    .m_messagetype(m_messagetype)              ,
    .m_seqid(m_seqid)                    ,
    .m_subseqid(m_subseqid)                 ,
    .m_ebit(m_ebit)                     ,
    .m_payloadsize(m_payloadsize)              ,
    .m_packet_in_window(m_packet_in_window)         ,
    .m_offset_in_symbol(m_offset_in_symbol)         ,
    //
    .m_radio_app_head_valid(m_radio_app_head_valid)     ,
    .m_datadirection(m_datadirection)            ,
    .m_numsections(m_numsections)              ,
    .m_sectiontype(m_sectiontype)              ,
    .m_filterindex(m_filterindex)              ,
    .m_frameid(m_frameid)                  ,
    .m_subframeid(m_subframeid)               ,
    .m_slotid(m_slotid)                   ,
    .m_symbolid(m_symbolid)                 ,
    .m_udcomphdr(m_udcomphdr)                ,
    .m_timeoffset(m_timeoffset)               ,
    .m_framestructure(m_framestructure)           ,
    .m_cplength(m_cplength)                 ,
    //
    .m_section_header_valid(m_section_header_valid)     ,
    .m_numsymbol(m_numsymbol)                ,
    .m_numprbc(m_numprbc)                  ,
    .m_startprbc(m_startprbc)                ,
    .m_sectionid(m_sectionid)                ,
    .m_rb(m_rb)                       ,
    .m_remask(m_remask)                   ,
    .m_beamid15(m_beamid15)                 ,
    .m_freqoffset(m_freqoffset)               ,
    // UNSOL port
    .s00_fram_unsol_tdata(s00_fram_unsol_tdata),
    .s00_fram_unsol_tkeep(s00_fram_unsol_tkeep),
    .s00_fram_unsol_tvalid(s00_fram_unsol_tvalid),
    .s00_fram_unsol_tlast(s00_fram_unsol_tlast),
    .s00_fram_unsol_tready(s00_fram_unsol_tready),
    .s00_fram_unsol_tuser(s00_fram_unsol_tuser)
    );

endmodule
