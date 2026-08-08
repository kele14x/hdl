`timescale 1 ns / 1 ps
//
`default_nettype none

module lowphy_band #(
    parameter int NUM_CC     = 3,
    parameter int NUM_ANT    = 4,
    parameter int CC_ID      = 0,
    parameter int ANT_ID     = 0,
    parameter bit HAS_BFP    = 1'b1,
    parameter bit HALF_BLOCK = 1'b0
) (
    // AXI
    //----
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,
    //
    input  wire [ 11:0] s_axi_awaddr,
    input  wire [  2:0] s_axi_awprot,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,
    //
    input  wire [ 31:0] s_axi_wdata,
    input  wire [  3:0] s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,
    //
    output wire [  1:0] s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,
    //
    input  wire [ 11:0] s_axi_araddr,
    input  wire [  2:0] s_axi_arprot,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,
    //
    output wire [ 31:0] s_axi_rdata,
    output wire [  1:0] s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,
    // ORAN-IF Interfaces
    //-------------------
    // Early BID ports
    input  wire [ 47:0] s_defm_ebid_tdata,
    input  wire         s_defm_ebid_tvalid,
    input  wire         s_defm_ebid_tlast,
    output wire         s_defm_ebid_tready,
    //
    input  wire [ 47:0] s_fram_ebid_tdata,
    input  wire         s_fram_ebid_tvalid,
    input  wire         s_fram_ebid_tlast,
    output wire         s_fram_ebid_tready,
    // PRACH C plane messages
    input  wire         s_prach_tvalid,
    output wire         s_prach_tready,
    input  wire [ 15:0] s_prach_rtc_pc_id,
    input  wire [  3:0] s_prach_cc,
    input  wire [  7:0] s_prach_ss,
    input  wire [ 11:0] s_prach_section_id,
    input  wire [  3:0] s_prach_return_port,
    input  wire [  3:0] s_prach_filter_index,
    input  wire [  7:0] s_prach_f,
    input  wire [  3:0] s_prach_sf,
    input  wire [  5:0] s_prach_sl,
    input  wire [  5:0] s_prach_sy,
    input  wire [ 15:0] s_prach_time_offset,
    input  wire [  7:0] s_prach_frame_structure,
    input  wire [ 15:0] s_prach_cp_length,
    input  wire [  7:0] s_prach_udcomphdr,
    input  wire         s_prach_rb,
    input  wire         s_prach_syminc,
    input  wire [  9:0] s_prach_start_prbc,
    input  wire [  7:0] s_prach_num_prbc,
    input  wire [ 11:0] s_prach_remask,
    input  wire [  3:0] s_prach_num_symbol,
    input  wire [ 14:0] s_prach_beamid,
    input  wire [ 23:0] s_prach_freqoffset,
    // Timer ports
    input  wire [ 11:0] s_ul_sym_num               [ NUM_CC],
    input  wire [ 11:0] s_ul_cta_sym_num           [ NUM_CC],
    input  wire         s_ul_update                [ NUM_CC],
    input  wire         s_ul_slot_update           [ NUM_CC],
    input  wire [ 11:0] s_dl_sym_num               [ NUM_CC],
    input  wire [ 11:0] s_dl_cta_sym_num           [ NUM_CC],
    input  wire         s_dl_update                [ NUM_CC],
    input  wire         s_dl_slot_update           [ NUM_CC],
    input  wire         s_ul_toggle                [ NUM_CC],
    input  wire         s_dl_toggle                [ NUM_CC],
    // output wire         s_ul_symbol_inc               [NUM_CC],
    // output wire         s_dl_symbol_inc               [NUM_CC],
    input  wire         s_cc_enable                [ NUM_CC],
    input  wire         s_cc_reload                [ NUM_CC],
    // CARRIER ports for the Framer, the datapath to the ethernet
    output wire [ 63:0] m_fram_data_tdata          [NUM_ANT],
    output wire [  7:0] m_fram_data_tkeep          [NUM_ANT],
    output wire         m_fram_data_tvalid         [NUM_ANT],
    output wire         m_fram_data_tlast          [NUM_ANT],
    input  wire         m_fram_data_tready         [NUM_ANT],
    input  wire [ 32:0] m_fram_data_req            [NUM_ANT],
    //
    input  wire [107:0] s_fram_bid_debug           [NUM_ANT],
    input  wire         s_fram_bid_valid           [NUM_ANT],
    input  wire         s_fram_bid_tlast           [NUM_ANT],
    output wire         s_fram_bid_ready           [NUM_ANT],
    input  wire         s_fram_bid_off             [NUM_ANT],
    input  wire [ 14:0] s_fram_bid_beamid15        [NUM_ANT],
    input  wire [ 11:0] s_fram_bid_remask          [NUM_ANT],
    input  wire         s_fram_bid_rb              [NUM_ANT],
    input  wire [  9:0] s_fram_bid_start_prbc      [NUM_ANT],
    input  wire [  7:0] s_fram_bid_num_prbc        [NUM_ANT],
    input  wire [  3:0] s_fram_bid_num_symbol      [NUM_ANT],
    input  wire [  7:0] s_fram_bid_cc_id           [NUM_ANT],
    input  wire [ 23:0] s_fram_bid_frequency_offset[NUM_ANT],
    input  wire [ 15:0] s_fram_bid_time_offset     [NUM_ANT],
    input  wire [  7:0] s_fram_bid_frame_structure [NUM_ANT],
    input  wire [ 15:0] s_fram_bid_cp_length       [NUM_ANT],
    //
    output wire [ 63:0] m_fram_unsol_tdata,
    output wire [  7:0] m_fram_unsol_tkeep,
    output wire         m_fram_unsol_tvalid,
    output wire         m_fram_unsol_tlast,
    input  wire         m_fram_unsol_tready,
    output wire [ 31:0] m_fram_unsol_tuser,
    //
    output wire [ 63:0] m_fram_prach_tdata,
    output wire [  7:0] m_fram_prach_tkeep,
    output wire         m_fram_prach_tvalid,
    output wire         m_fram_prach_tlast,
    input  wire         m_fram_prach_tready,
    output wire [ 31:0] m_fram_prach_tuser,
    // CARRIER ports from the Framer, the datapath from the ethernet
    input  wire [ 63:0] s_defm_data_tdata          [NUM_ANT],
    input  wire [  7:0] s_defm_data_tkeep          [NUM_ANT],
    input  wire         s_defm_data_tvalid         [NUM_ANT],
    input  wire         s_defm_data_tlast          [NUM_ANT],
    output wire         s_defm_data_tready         [NUM_ANT],
    input  wire [ 90:0] s_defm_data_tuser          [NUM_ANT],
    input  wire [  4:0] s_defm_data_tdest          [NUM_ANT],
    //
    input  wire         s_defm_bid_valid           [NUM_ANT],
    input  wire         s_defm_bid_tlast           [NUM_ANT],
    output wire         s_defm_bid_ready           [NUM_ANT],
    input  wire         s_defm_bid_off             [NUM_ANT],
    input  wire [ 14:0] s_defm_bid_beamid15        [NUM_ANT],
    input  wire [ 11:0] s_defm_bid_remask          [NUM_ANT],
    input  wire         s_defm_bid_rb              [NUM_ANT],
    input  wire [  9:0] s_defm_bid_start_prbc      [NUM_ANT],
    input  wire [  7:0] s_defm_bid_num_prbc        [NUM_ANT],
    input  wire [  3:0] s_defm_bid_num_symbol      [NUM_ANT],
    input  wire [  7:0] s_defm_bid_cc_id           [NUM_ANT],
    input  wire [ 23:0] s_defm_bid_frequency_offset[NUM_ANT],
    input  wire [ 15:0] s_defm_bid_time_offset     [NUM_ANT],
    input  wire [  7:0] s_defm_bid_frame_structure [NUM_ANT],
    input  wire [ 15:0] s_defm_bid_cp_length       [NUM_ANT],
    // ORAN prase ports
    input  wire [127:0] s_ep_debug,
    input  wire         s_t_header_offset_valid,
    input  wire         s_runt_packet_len,
    input  wire [ 15:0] s_rtc_pc_id,
    input  wire         s_concat,
    input  wire [  2:0] s_messagetype,
    input  wire [  7:0] s_seqid,
    input  wire [  6:0] s_subseqid,
    input  wire         s_ebit,
    input  wire [ 15:0] s_payloadsize,
    input  wire         s_packet_in_window,
    input  wire [ 11:0] s_offset_in_symbol,
    //
    input  wire         s_radio_app_head_valid,
    input  wire         s_datadirection,
    input  wire [  7:0] s_numsections,
    input  wire [  2:0] s_sectiontype,
    input  wire [  3:0] s_filterindex,
    input  wire [  7:0] s_frameid,
    input  wire [  3:0] s_subframeid,
    input  wire [  5:0] s_slotid,
    input  wire [  5:0] s_symbolid,
    input  wire [  7:0] s_udcomphdr,
    input  wire [ 15:0] s_timeoffset,
    input  wire [  7:0] s_framestructure,
    input  wire [ 15:0] s_cplength,
    //
    input  wire         s_section_header_valid,
    input  wire [  3:0] s_numsymbol,
    input  wire [  7:0] s_numprbc,
    input  wire [  9:0] s_startprbc,
    input  wire [ 11:0] s_sectionid,
    input  wire         s_rb,
    input  wire [ 11:0] s_remask,
    input  wire [ 14:0] s_beamid15,
    input  wire [ 23:0] s_freqoffset,
    //
    input  wire [ 63:0] s_beamweights_tdata,
    input  wire         s_beamweights_tvalid,
    input  wire         s_beamweights_tlast,
    input  wire [  3:0] s_beamweights_tuser,
    //
    input  wire [ 63:0] s_raw_cplane_tdata,
    input  wire         s_raw_cplane_tvalid,
    input  wire         s_raw_cplane_tuser,
    input  wire         s_raw_cplane_tlast,
    input  wire [  7:0] s_raw_cplane_tkeep,
    //
    input  wire [ 26:0] s_unsupport_ext_tuser,
    input  wire [ 63:0] s_unsupport_ext_tdata,
    input  wire         s_unsupport_ext_tvalid,
    input  wire [  7:0] s_unsupport_ext_tkeep,
    input  wire         s_unsupport_ext_tlast,
    // Clocks
    input  wire         internal_bus_clk,
    //
    input  wire         defm_reset,
    input  wire         fram_reset,
    //
    input  wire         defm_reset_active,
    input  wire         fram0_reset_active,
    // Timer ports
    output wire         fram_radio_start_10ms      [ NUM_CC],
    output wire         defm_radio_start_10ms      [ NUM_CC],
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
    // Mandatory 10 MHz strobe
    input  wire         fram_rfs_in,
    input  wire         defm_rfs_in,
    // Radio I/F
    //----------
    input  wire         clk,
    input  wire         rst,
    //
    output wire [ 31:0] m_axis_tdata               [ NUM_CC][NUM_ANT],
    output wire [  7:0] m_axis_tuser               [ NUM_CC][NUM_ANT],
    output wire         m_axis_tlast               [ NUM_CC][NUM_ANT],
    output wire         m_axis_tvalid              [ NUM_CC][NUM_ANT],
    input  wire         m_axis_tready              [ NUM_CC][NUM_ANT],
    //
    input  wire [ 31:0] s_axis_tdata               [ NUM_CC][NUM_ANT],
    input  wire [  7:0] s_axis_tuser               [ NUM_CC][NUM_ANT],
    input  wire         s_axis_tlast               [ NUM_CC][NUM_ANT],
    input  wire         s_axis_tvalid              [ NUM_CC][NUM_ANT],
    output wire         s_axis_tready              [ NUM_CC][NUM_ANT]
);

  // Parmaeters

  initial begin
    // Check NUM_CC
    if (NUM_CC < 1 || NUM_CC > 3) begin
      $fatal(1, "Number of CCs (NUM_CC) must be between 1 and 3, get %d [%m]", NUM_CC);
    end

    // Check NUM_ANT
    if (NUM_ANT != 1 && NUM_ANT != 2 && NUM_ANT != 4) begin
      $fatal(1, "Number of antennas (NUM_ANT) must be 1, 2, or 4, get %d [%m]", NUM_ANT);
    end

    // Check CC_ID
    if (CC_ID < 0 || CC_ID >= NUM_CC) begin
      $fatal(1, "Carrier ID (CC_ID) must be between 0 and NUM_CC-1, get %d [%m]", CC_ID);
    end
  end

  // Signals

  // DL control signals

  logic [ 3:0] ctrl_dl_en                     [NUM_CC];
  logic [ 1:0] ctrl_dl_rat                    [NUM_CC];
  logic [ 3:0] ctrl_dl_bist                   [NUM_CC];
  logic [ 3:0] ctrl_dl_bw                     [NUM_CC];
  logic [ 8:0] ctrl_dl_nprb                   [NUM_CC];
  logic [22:0] ctrl_dl_rfs_offset             [NUM_CC];

  logic [ 3:0] ctrl_dl_ud_comp_meth;
  logic [ 3:0] ctrl_dl_ud_iq_width;
  logic [ 3:0] ctrl_dl_fs_offset;

  logic [16:0] ctrl_dl_gain                   [NUM_CC] [NUM_ANT];
  logic [16:0] ctrl_dl_gain_reg               [NUM_CC] [      4];

  // UL control signals

  logic [ 3:0] ctrl_ul_en                     [NUM_CC];
  logic [ 1:0] ctrl_ul_rat                    [NUM_CC];
  logic [ 3:0] ctrl_ul_bist                   [NUM_CC];
  logic [ 3:0] ctrl_ul_bw                     [NUM_CC];
  logic [ 8:0] ctrl_ul_nprb                   [NUM_CC];
  logic [22:0] ctrl_ul_rfs_offset             [NUM_CC];

  logic [ 3:0] ctrl_ul_ud_comp_meth;
  logic [ 3:0] ctrl_ul_ud_iq_width;
  logic [ 3:0] ctrl_ul_fs_offset;

  logic [16:0] ctrl_ul_gain                   [NUM_CC] [NUM_ANT];
  logic [16:0] ctrl_ul_gain_reg               [NUM_CC] [      4];

  // PRACH control signals

  logic [ 3:0] ctrl_prach_bist_bist           [NUM_CC];
  logic [ 3:0] ctrl_prach_en                  [NUM_CC];
  logic [ 1:0] ctrl_prach_rat                 [NUM_CC];
  logic [ 3:0] ctrl_prach_format              [NUM_CC];
  logic [ 3:0] ctrl_prach_bw                  [NUM_CC];
  logic [22:0] ctrl_prach_rfs_offset          [NUM_CC];
  logic [22:0] ctrl_prach_ta3_offset          [NUM_CC];
  //
  logic [ 3:0] ctrl_prach_bist_static_c       [NUM_CC];

  logic [ 3:0] ctrl_prach_ud_comp_meth;
  logic [ 3:0] ctrl_prach_ud_iq_width;
  logic [ 3:0] ctrl_prach_ud_fs_offset;

  logic [ 3:0] ctrl_prach_cfg0_subframe_inc   [NUM_CC];
  logic [ 3:0] ctrl_prach_cfg0_subframe_id    [NUM_CC];
  logic [ 5:0] ctrl_prach_cfg0_slot_id        [NUM_CC];
  logic [ 5:0] ctrl_prach_cfg0_symbol_id      [NUM_CC];

  logic [15:0] ctrl_prach_cfg1_time_offset    [NUM_CC];
  logic [15:0] ctrl_prach_cfg1_cp_length      [NUM_CC];

  logic [ 3:0] ctrl_prach_cfg2_num_symbol     [NUM_CC];
  logic [23:0] ctrl_prach_cfg2_freq_offset    [NUM_CC];

  logic [15:0] ctrl_prach_cfg3_sampling_offset[NUM_CC];

  logic [ 3:0] stat_prach_msg0_subframe_id    [NUM_CC];
  logic [ 5:0] stat_prach_msg0_slot_id        [NUM_CC];
  logic [ 5:0] stat_prach_msg0_symbol_id      [NUM_CC];

  logic [15:0] stat_prach_msg1_time_offset    [NUM_CC];
  logic [15:0] stat_prach_msg1_cp_length      [NUM_CC];

  logic [ 3:0] stat_prach_msg2_num_symbol     [NUM_CC];
  logic [23:0] stat_prach_msg2_freq_offset    [NUM_CC];

  // Phase Compenstaion RAM

  logic [ 5:0] ctrl_dl_phase_comp_addr;
  logic        ctrl_dl_phase_comp_en;
  logic        ctrl_dl_phase_comp_we;
  logic [31:0] ctrl_dl_phase_comp_din;
  logic [31:0] ctrl_dl_phase_comp_dout;
  logic        ctrl_dl_phase_comp_valid;

  logic [ 5:0] ctrl_ul_phase_comp_addr;
  logic        ctrl_ul_phase_comp_en;
  logic        ctrl_ul_phase_comp_we;
  logic [31:0] ctrl_ul_phase_comp_din;
  logic [31:0] ctrl_ul_phase_comp_dout;
  logic        ctrl_ul_phase_comp_valid;
  logic        defm_reset_s;
  logic        fram_reset_s;

  wire         unused_inputs;

  assign unused_inputs = &{
      1'b0,
      s_defm_ebid_tdata,
      s_defm_ebid_tvalid,
      s_defm_ebid_tlast,
      s_fram_ebid_tdata,
      s_fram_ebid_tvalid,
      s_fram_ebid_tlast,
      m_fram_unsol_tready,
      s_ep_debug,
      s_t_header_offset_valid,
      s_runt_packet_len,
      s_rtc_pc_id,
      s_concat,
      s_messagetype,
      s_seqid,
      s_subseqid,
      s_ebit,
      s_payloadsize,
      s_packet_in_window,
      s_offset_in_symbol,
      s_radio_app_head_valid,
      s_datadirection,
      s_numsections,
      s_sectiontype,
      s_filterindex,
      s_frameid,
      s_subframeid,
      s_slotid,
      s_symbolid,
      s_udcomphdr,
      s_timeoffset,
      s_framestructure,
      s_cplength,
      s_section_header_valid,
      s_numsymbol,
      s_numprbc,
      s_startprbc,
      s_sectionid,
      s_rb,
      s_remask,
      s_beamid15,
      s_freqoffset,
      s_beamweights_tdata,
      s_beamweights_tvalid,
      s_beamweights_tlast,
      s_beamweights_tuser,
      s_raw_cplane_tdata,
      s_raw_cplane_tvalid,
      s_raw_cplane_tuser,
      s_raw_cplane_tlast,
      s_raw_cplane_tkeep,
      s_unsupport_ext_tuser,
      s_unsupport_ext_tdata,
      s_unsupport_ext_tvalid,
      s_unsupport_ext_tkeep,
      s_unsupport_ext_tlast,
      defm_reset_active,
      fram0_reset_active,
      s_ssb_data_tdata,
      s_ssb_data_tkeep,
      s_ssb_data_tvalid,
      s_ssb_data_tlast,
      s_ssb_data_tuser,
      s_ssb_ebid_tdata,
      s_ssb_ebid_tvalid,
      s_ssb_ebid_tlast,
      s_ssb_bid_tvalid,
      s_ssb_bid_tlast,
      s_ssb_bid_off,
      s_ssb_bid_beamid15,
      s_ssb_bid_remask,
      s_ssb_bid_rb,
      s_ssb_bid_start_prbc,
      s_ssb_bid_num_prbc,
      s_ssb_bid_num_symbol,
      s_ssb_bid_cc_id,
      s_ssb_bid_frequency_offset,
      s_ssb_bid_time_offset,
      s_ssb_bid_frame_structure,
      s_ssb_bid_cp_length,
      fram_ready,
      defm_ready
  };

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : gen_unused_cc
      wire unused_cc_inputs;

      assign unused_cc_inputs = &{
          1'b0,
          s_ul_cta_sym_num[cc],
          s_ul_update[cc],
          s_ul_slot_update[cc],
          s_dl_cta_sym_num[cc],
          s_dl_update[cc],
          s_dl_slot_update[cc],
          s_ul_toggle[cc],
          s_dl_toggle[cc],
          s_cc_enable[cc],
          s_cc_reload[cc],
          ctrl_prach_format[cc]
      };
    end

    for (genvar ant = 0; ant < NUM_ANT; ant++) begin : gen_unused_ant
      wire unused_ant_inputs;

      assign unused_ant_inputs = &{
          1'b0,
          s_fram_bid_debug[ant],
          s_fram_bid_valid[ant],
          s_fram_bid_tlast[ant],
          s_fram_bid_off[ant],
          s_fram_bid_beamid15[ant],
          s_fram_bid_remask[ant],
          s_fram_bid_rb[ant],
          s_fram_bid_start_prbc[ant],
          s_fram_bid_num_prbc[ant],
          s_fram_bid_num_symbol[ant],
          s_fram_bid_cc_id[ant],
          s_fram_bid_frequency_offset[ant],
          s_fram_bid_time_offset[ant],
          s_fram_bid_frame_structure[ant],
          s_fram_bid_cp_length[ant],
          s_defm_bid_valid[ant],
          s_defm_bid_tlast[ant],
          s_defm_bid_off[ant],
          s_defm_bid_beamid15[ant],
          s_defm_bid_remask[ant],
          s_defm_bid_rb[ant],
          s_defm_bid_start_prbc[ant],
          s_defm_bid_num_prbc[ant],
          s_defm_bid_num_symbol[ant],
          s_defm_bid_cc_id[ant],
          s_defm_bid_frequency_offset[ant],
          s_defm_bid_time_offset[ant],
          s_defm_bid_frame_structure[ant],
          s_defm_bid_cp_length[ant]
      };
    end

    for (genvar cc = 0; cc < NUM_CC; cc++) begin : gen_gain_cc
      for (genvar ant = 0; ant < 4; ant++) begin : gen_gain_ant
        if (ant < NUM_ANT) begin : gen_active_gain
          assign ctrl_dl_gain[cc][ant] = ctrl_dl_gain_reg[cc][ant];
          assign ctrl_ul_gain[cc][ant] = ctrl_ul_gain_reg[cc][ant];
        end else begin : gen_inactive_gain
          wire unused_gain_inputs;

          assign unused_gain_inputs = &{1'b0, ctrl_dl_gain_reg[cc][ant], ctrl_ul_gain_reg[cc][ant]};
        end
      end
    end
  endgenerate

  // Main

  // Eearly BID

  assign s_defm_ebid_tready = 1'b1;

  assign s_fram_ebid_tready = 1'b1;

  // Framer

  assign s_fram_bid_ready = '{NUM_ANT{1'b1}};

  assign m_fram_unsol_tdata = 'b0;
  assign m_fram_unsol_tkeep = 'b0;
  assign m_fram_unsol_tvalid = 1'b0;
  assign m_fram_unsol_tlast = 1'b0;
  assign m_fram_unsol_tuser = 'b0;

  // Deframer

  assign s_defm_bid_ready = '{NUM_ANT{1'b1}};

  cdc_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0)
  ) defm_reset_cdc (
      .src_clk (1'b0),
      .src_in  (defm_reset),
      .dest_clk(internal_bus_clk),
      .dest_out(defm_reset_s)
  );

  cdc_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0)
  ) fram_reset_cdc (
      .src_clk (1'b0),
      .src_in  (fram_reset),
      .dest_clk(internal_bus_clk),
      .dest_out(fram_reset_s)
  );

  pdxch_top #(
      .NUM_CC    (NUM_CC),
      .NUM_ANT   (NUM_ANT),
      .HALF_BLOCK(HALF_BLOCK)
  ) u_pdxch (
      // DFE Ports
      //----------
      .clk                  (clk),
      .rst                  (rst),
      //
      .m_axis_tdata         (m_axis_tdata),
      .m_axis_tuser         (m_axis_tuser),
      .m_axis_tlast         (m_axis_tlast),
      .m_axis_tvalid        (m_axis_tvalid),
      .m_axis_tready        (m_axis_tready),
      // O-RAN
      //------
      .clk_eth_xran         (internal_bus_clk),
      .rst_eth_xran         (defm_reset_s),
      //
      .sync_in              (defm_rfs_in),
      //
      .defm_radio_start_10ms(defm_radio_start_10ms),
      .s_dl_sym_num         (s_dl_sym_num),
      // U-Plane
      .s_defm_data_tdata    (s_defm_data_tdata),
      .s_defm_data_tkeep    (s_defm_data_tkeep),
      .s_defm_data_tvalid   (s_defm_data_tvalid),
      .s_defm_data_tlast    (s_defm_data_tlast),
      .s_defm_data_tready   (s_defm_data_tready),
      .s_defm_data_tuser    (s_defm_data_tuser),
      .s_defm_data_tdest    (s_defm_data_tdest),
      // CSR
      //----
      .ctrl_clk             (s_axi_aclk),
      .ctrl_rst             (~s_axi_aresetn),
      //
      .ctrl_ud_comp_meth    (ctrl_dl_ud_comp_meth),
      .ctrl_ud_iq_width     (ctrl_dl_ud_iq_width),
      .ctrl_fs_offset       (ctrl_dl_fs_offset),
      //
      .ctrl_en              (ctrl_dl_en),
      .ctrl_rat             (ctrl_dl_rat),
      .ctrl_bist            (ctrl_dl_bist),
      .ctrl_bw              (ctrl_dl_bw),
      .ctrl_nprb            (ctrl_dl_nprb),
      .ctrl_rfs_offset      (ctrl_dl_rfs_offset),
      //
      .ctrl_gain            (ctrl_dl_gain),
      //
      .ctrl_phase_comp_addr (ctrl_dl_phase_comp_addr),
      .ctrl_phase_comp_en   (ctrl_dl_phase_comp_en),
      .ctrl_phase_comp_we   (ctrl_dl_phase_comp_we),
      .ctrl_phase_comp_din  (ctrl_dl_phase_comp_din),
      .ctrl_phase_comp_dout (ctrl_dl_phase_comp_dout),
      .ctrl_phase_comp_valid(ctrl_dl_phase_comp_valid)
  );

  puxch_top #(
      .NUM_CC (NUM_CC),
      .NUM_ANT(NUM_ANT),
      .HAS_BFP(HAS_BFP),
      .HALF_BLOCK(HALF_BLOCK)
  ) u_puxch (
      // Clock & Reset
      //--------------
      .clk                  (clk),
      .rst                  (rst),
      //
      .s_axis_tdata         (s_axis_tdata),
      .s_axis_tuser         (s_axis_tuser),
      .s_axis_tlast         (s_axis_tlast),
      .s_axis_tvalid        (s_axis_tvalid),
      .s_axis_tready        (s_axis_tready),
      // O-RAN U-Plane
      //--------------
      .clk_eth_xran         (internal_bus_clk),
      .rst_eth_xran         (fram_reset_s),
      //
      .sync_in              (fram_rfs_in),
      //
      .fram_radio_start_10ms(fram_radio_start_10ms),
      .s_ul_sym_num         (s_ul_sym_num),
      //
      .m_fram_data_tdata    (m_fram_data_tdata),
      .m_fram_data_tkeep    (m_fram_data_tkeep),
      .m_fram_data_tvalid   (m_fram_data_tvalid),
      .m_fram_data_tlast    (m_fram_data_tlast),
      .m_fram_data_tready   (m_fram_data_tready),
      .m_fram_data_req      (m_fram_data_req),
      // CSR
      //----
      .ctrl_clk             (s_axi_aclk),
      .ctrl_rst             (~s_axi_aresetn),
      //
      .ctrl_ud_comp_meth    (ctrl_ul_ud_comp_meth),
      .ctrl_ud_iq_width     (ctrl_ul_ud_iq_width),
      .ctrl_fs_offset       (ctrl_ul_fs_offset),
      //
      .ctrl_en              (ctrl_ul_en),
      .ctrl_rat             (ctrl_ul_rat),
      .ctrl_bist            (ctrl_ul_bist),
      .ctrl_bw              (ctrl_ul_bw),
      .ctrl_nprb            (ctrl_ul_nprb),
      .ctrl_rfs_offset      (ctrl_ul_rfs_offset),
      .ctrl_gain            (ctrl_ul_gain),
      //
      .ctrl_phase_comp_addr (ctrl_ul_phase_comp_addr),
      .ctrl_phase_comp_en   (ctrl_ul_phase_comp_en),
      .ctrl_phase_comp_we   (ctrl_ul_phase_comp_we),
      .ctrl_phase_comp_din  (ctrl_ul_phase_comp_din),
      .ctrl_phase_comp_dout (ctrl_ul_phase_comp_dout),
      .ctrl_phase_comp_valid(ctrl_ul_phase_comp_valid)
  );

  prach_top #(
      .NUM_CC (NUM_CC),
      .NUM_ANT(NUM_ANT),
      .ANT_ID (ANT_ID)
  ) u_prach (
      // Clock & Reset
      //--------------
      .clk                    (clk),
      .rst                    (rst),
      //
      .s_axis_tdata           (s_axis_tdata),
      .s_axis_tlast           (s_axis_tlast),
      .s_axis_tuser           (s_axis_tuser),
      .s_axis_tvalid          (s_axis_tvalid),
      .s_axis_tready          (s_axis_tready),
      // ORAN
      //--------
      .clk_eth_xran           (internal_bus_clk),
      .rst_eth_xran           (fram_reset_s),
      //
      .sync_in                (fram_rfs_in),
      // PRACH C plane messages
      .s_prach_tvalid         (s_prach_tvalid),
      .s_prach_tready         (s_prach_tready),
      .s_prach_rtc_pc_id      (s_prach_rtc_pc_id),
      .s_prach_cc             (s_prach_cc),
      .s_prach_ss             (s_prach_ss),
      .s_prach_section_id     (s_prach_section_id),
      .s_prach_return_port    (s_prach_return_port),
      .s_prach_filter_index   (s_prach_filter_index),
      .s_prach_f              (s_prach_f),
      .s_prach_sf             (s_prach_sf),
      .s_prach_sl             (s_prach_sl),
      .s_prach_sy             (s_prach_sy),
      .s_prach_time_offset    (s_prach_time_offset),
      .s_prach_frame_structure(s_prach_frame_structure),
      .s_prach_cp_length      (s_prach_cp_length),
      .s_prach_udcomphdr      (s_prach_udcomphdr),
      .s_prach_rb             (s_prach_rb),
      .s_prach_syminc         (s_prach_syminc),
      .s_prach_start_prbc     (s_prach_start_prbc),
      .s_prach_num_prbc       (s_prach_num_prbc),
      .s_prach_remask         (s_prach_remask),
      .s_prach_num_symbol     (s_prach_num_symbol),
      .s_prach_beamid         (s_prach_beamid),
      .s_prach_freqoffset     (s_prach_freqoffset),
      // PRACH U-Plane
      .m_fram_prach_tdata     (m_fram_prach_tdata),
      .m_fram_prach_tkeep     (m_fram_prach_tkeep),
      .m_fram_prach_tlast     (m_fram_prach_tlast),
      .m_fram_prach_tuser     (m_fram_prach_tuser),
      .m_fram_prach_tvalid    (m_fram_prach_tvalid),
      .m_fram_prach_tready    (m_fram_prach_tready),
      // CSR
      //----
      .ctrl_clk               (s_axi_aclk),
      .ctrl_rst               (~s_axi_aresetn),
      //
      .ctrl_fs_offset         (ctrl_prach_ud_fs_offset),
      //
      .ctrl_bist              (ctrl_prach_bist_bist),
      .ctrl_en                (ctrl_prach_en),
      .ctrl_rat               (ctrl_prach_rat),
      .ctrl_bw                (ctrl_prach_bw),
      .ctrl_rfs_offset        (ctrl_prach_rfs_offset),
      .ctrl_ta3_offset        (ctrl_prach_ta3_offset),
      //
      .ctrl_static_c          (ctrl_prach_bist_static_c),
      //
      .ctrl_subframe_inc      (ctrl_prach_cfg0_subframe_inc),
      .ctrl_subframe_id       (ctrl_prach_cfg0_subframe_id),
      .ctrl_slot_id           (ctrl_prach_cfg0_slot_id),
      .ctrl_symbol_id         (ctrl_prach_cfg0_symbol_id),
      //
      .ctrl_time_offset       (ctrl_prach_cfg1_time_offset),
      .ctrl_cp_length         (ctrl_prach_cfg1_cp_length),
      //
      .ctrl_num_symbol        (ctrl_prach_cfg2_num_symbol),
      .ctrl_freq_offset       (ctrl_prach_cfg2_freq_offset),
      //
      .ctrl_sampling_offset   (ctrl_prach_cfg3_sampling_offset),
      //
      .stat_subframe_id       (stat_prach_msg0_subframe_id),
      .stat_slot_id           (stat_prach_msg0_slot_id),
      .stat_symbol_id         (stat_prach_msg0_symbol_id),
      //
      .stat_time_offset       (stat_prach_msg1_time_offset),
      .stat_cp_length         (stat_prach_msg1_cp_length),
      //
      .stat_num_symbol        (stat_prach_msg2_num_symbol),
      .stat_freq_offset       (stat_prach_msg2_freq_offset)
  );

  // SSB

  assign s_ssb_data_tready = 1'b1;

  assign s_ssb_ebid_tready = 1'b1;

  assign s_ssb_bid_tready  = 1'b1;

  // Timer

  // assign m_ul_symbol_inc = '{ NUM_CC {1'b0}};
  // assign m_dl_symbol_inc = '{ NUM_CC {1'b0}};

  // Main

  lowphy_regs u_regs (
      .s_axi_aclk                      (s_axi_aclk),
      .s_axi_aresetn                   (s_axi_aresetn),
      //
      .s_axi_awaddr                    (s_axi_awaddr),
      .s_axi_awprot                    (s_axi_awprot),
      .s_axi_awvalid                   (s_axi_awvalid),
      .s_axi_awready                   (s_axi_awready),
      //
      .s_axi_wdata                     (s_axi_wdata),
      .s_axi_wstrb                     (s_axi_wstrb),
      .s_axi_wvalid                    (s_axi_wvalid),
      .s_axi_wready                    (s_axi_wready),
      //
      .s_axi_bresp                     (s_axi_bresp),
      .s_axi_bvalid                    (s_axi_bvalid),
      .s_axi_bready                    (s_axi_bready),
      //
      .s_axi_araddr                    (s_axi_araddr),
      .s_axi_arprot                    (s_axi_arprot),
      .s_axi_arvalid                   (s_axi_arvalid),
      .s_axi_arready                   (s_axi_arready),
      //
      .s_axi_rdata                     (s_axi_rdata),
      .s_axi_rresp                     (s_axi_rresp),
      .s_axi_rvalid                    (s_axi_rvalid),
      .s_axi_rready                    (s_axi_rready),
      // dl_en.cc0,
      .dl_en_cc0_out                   (ctrl_dl_en[0]),
      // dl_en.cc1,
      .dl_en_cc1_out                   (ctrl_dl_en[1]),
      // dl_en.cc2,
      .dl_en_cc2_out                   (ctrl_dl_en[2]),
      // dl_rat.cc0,
      .dl_rat_cc0_out                  (ctrl_dl_rat[0]),
      // dl_rat.cc1,
      .dl_rat_cc1_out                  (ctrl_dl_rat[1]),
      // dl_rat.cc2,
      .dl_rat_cc2_out                  (ctrl_dl_rat[2]),
      // dl_bist.cc0,
      .dl_bist_cc0_out                 (ctrl_dl_bist[0]),
      // dl_bist.cc1,
      .dl_bist_cc1_out                 (ctrl_dl_bist[1]),
      // dl_bist.cc2,
      .dl_bist_cc2_out                 (ctrl_dl_bist[2]),
      // dl_bw.cc0,
      .dl_bw_cc0_out                   (ctrl_dl_bw[0]),
      // dl_bw.cc1,
      .dl_bw_cc1_out                   (ctrl_dl_bw[1]),
      // dl_bw.cc2,
      .dl_bw_cc2_out                   (ctrl_dl_bw[2]),
      // dl_nprb_0.val,
      .dl_nprb_0_val_out               (ctrl_dl_nprb[0]),
      // dl_nprb_1.val,
      .dl_nprb_1_val_out               (ctrl_dl_nprb[1]),
      // dl_nprb_2.val,
      .dl_nprb_2_val_out               (ctrl_dl_nprb[2]),
      // dl_rfs_offset_0.val,
      .dl_rfs_offset_0_val_out         (ctrl_dl_rfs_offset[0]),
      // dl_rfs_offset_1.val,
      .dl_rfs_offset_1_val_out         (ctrl_dl_rfs_offset[1]),
      // dl_rfs_offset_2.val,
      .dl_rfs_offset_2_val_out         (ctrl_dl_rfs_offset[2]),
      // dl_ud.comp_meth,
      .dl_ud_comp_meth_out             (ctrl_dl_ud_comp_meth),
      // dl_ud.iq_width,
      .dl_ud_iq_width_out              (ctrl_dl_ud_iq_width),
      // dl_ud.fs_offset,
      .dl_ud_fs_offset_out             (ctrl_dl_fs_offset),
      // dl_gain_0_0.val,
      .dl_gain_0_0_val_out             (ctrl_dl_gain_reg[0][0]),
      // dl_gain_0_1.val,
      .dl_gain_0_1_val_out             (ctrl_dl_gain_reg[0][1]),
      // dl_gain_0_2.val,
      .dl_gain_0_2_val_out             (ctrl_dl_gain_reg[0][2]),
      // dl_gain_0_3.val,
      .dl_gain_0_3_val_out             (ctrl_dl_gain_reg[0][3]),
      // dl_gain_1_0.val,
      .dl_gain_1_0_val_out             (ctrl_dl_gain_reg[1][0]),
      // dl_gain_1_1.val,
      .dl_gain_1_1_val_out             (ctrl_dl_gain_reg[1][1]),
      // dl_gain_1_2.val,
      .dl_gain_1_2_val_out             (ctrl_dl_gain_reg[1][2]),
      // dl_gain_1_3.val,
      .dl_gain_1_3_val_out             (ctrl_dl_gain_reg[1][3]),
      // dl_gain_2_0.val,
      .dl_gain_2_0_val_out             (ctrl_dl_gain_reg[2][0]),
      // dl_gain_2_1.val,
      .dl_gain_2_1_val_out             (ctrl_dl_gain_reg[2][1]),
      // dl_gain_2_2.val,
      .dl_gain_2_2_val_out             (ctrl_dl_gain_reg[2][2]),
      // dl_gain_2_3.val,
      .dl_gain_2_3_val_out             (ctrl_dl_gain_reg[2][3]),
      // ul_en.cc0,
      .ul_en_cc0_out                   (ctrl_ul_en[0]),
      // ul_en.cc1,
      .ul_en_cc1_out                   (ctrl_ul_en[1]),
      // ul_en.cc2,
      .ul_en_cc2_out                   (ctrl_ul_en[2]),
      // ul_rat.cc0,
      .ul_rat_cc0_out                  (ctrl_ul_rat[0]),
      // ul_rat.cc1,
      .ul_rat_cc1_out                  (ctrl_ul_rat[1]),
      // ul_rat.cc2,
      .ul_rat_cc2_out                  (ctrl_ul_rat[2]),
      // ul_bist.bist_cc0,
      .ul_bist_bist_cc0_out            (ctrl_ul_bist[0]),
      // ul_bist.bist_cc1,
      .ul_bist_bist_cc1_out            (ctrl_ul_bist[1]),
      // ul_bist.bist_cc2,
      .ul_bist_bist_cc2_out            (ctrl_ul_bist[2]),
      // ul_bw.cc0,
      .ul_bw_cc0_out                   (ctrl_ul_bw[0]),
      // ul_bw.cc1,
      .ul_bw_cc1_out                   (ctrl_ul_bw[1]),
      // ul_bw.cc2,
      .ul_bw_cc2_out                   (ctrl_ul_bw[2]),
      // ul_nprb_0.val,
      .ul_nprb_0_val_out               (ctrl_ul_nprb[0]),
      // ul_nprb_1.val,
      .ul_nprb_1_val_out               (ctrl_ul_nprb[1]),
      // ul_nprb_2.val,
      .ul_nprb_2_val_out               (ctrl_ul_nprb[2]),
      // ul_rfs_offset_0.val,
      .ul_rfs_offset_0_val_out         (ctrl_ul_rfs_offset[0]),
      // ul_rfs_offset_1.val,
      .ul_rfs_offset_1_val_out         (ctrl_ul_rfs_offset[1]),
      // ul_rfs_offset_2.val,
      .ul_rfs_offset_2_val_out         (ctrl_ul_rfs_offset[2]),
      // ul_ud.comp_meth,
      .ul_ud_comp_meth_out             (ctrl_ul_ud_comp_meth),
      // ul_ud.iq_width,
      .ul_ud_iq_width_out              (ctrl_ul_ud_iq_width),
      // ul_ud.fs_offset,
      .ul_ud_fs_offset_out             (ctrl_ul_fs_offset),
      // ul_gain_0_0.val,
      .ul_gain_0_0_val_out             (ctrl_ul_gain_reg[0][0]),
      // ul_gain_0_1.val,
      .ul_gain_0_1_val_out             (ctrl_ul_gain_reg[0][1]),
      // ul_gain_0_2.val,
      .ul_gain_0_2_val_out             (ctrl_ul_gain_reg[0][2]),
      // ul_gain_0_3.val,
      .ul_gain_0_3_val_out             (ctrl_ul_gain_reg[0][3]),
      // ul_gain_1_0.val,
      .ul_gain_1_0_val_out             (ctrl_ul_gain_reg[1][0]),
      // ul_gain_1_1.val,
      .ul_gain_1_1_val_out             (ctrl_ul_gain_reg[1][1]),
      // ul_gain_1_2.val,
      .ul_gain_1_2_val_out             (ctrl_ul_gain_reg[1][2]),
      // ul_gain_1_3.val,
      .ul_gain_1_3_val_out             (ctrl_ul_gain_reg[1][3]),
      // ul_gain_2_0.val,
      .ul_gain_2_0_val_out             (ctrl_ul_gain_reg[2][0]),
      // ul_gain_2_1.val,
      .ul_gain_2_1_val_out             (ctrl_ul_gain_reg[2][1]),
      // ul_gain_2_2.val,
      .ul_gain_2_2_val_out             (ctrl_ul_gain_reg[2][2]),
      // ul_gain_2_3.val,
      .ul_gain_2_3_val_out             (ctrl_ul_gain_reg[2][3]),
      // prach_en.cc0,
      .prach_en_cc0_out                (ctrl_prach_en[0]),
      // prach_en.cc1,
      .prach_en_cc1_out                (ctrl_prach_en[1]),
      // prach_en.cc2,
      .prach_en_cc2_out                (ctrl_prach_en[2]),
      // prach_format.cc0,
      .prach_format_cc0_out            (ctrl_prach_format[0]),
      // prach_format.cc1,
      .prach_format_cc1_out            (ctrl_prach_format[1]),
      // prach_format.cc2,
      .prach_format_cc2_out            (ctrl_prach_format[2]),
      // prach_rat.cc0,
      .prach_rat_cc0_out               (ctrl_prach_rat[0]),
      // prach_rat.cc1,
      .prach_rat_cc1_out               (ctrl_prach_rat[1]),
      // prach_rat.cc2,
      .prach_rat_cc2_out               (ctrl_prach_rat[2]),
      // prach_bist.bist_cc0,
      .prach_bist_bist_cc0_out         (ctrl_prach_bist_bist[0]),
      // prach_bist.bist_cc1,
      .prach_bist_bist_cc1_out         (ctrl_prach_bist_bist[1]),
      // prach_bist.bist_cc2,
      .prach_bist_bist_cc2_out         (ctrl_prach_bist_bist[2]),
      // prach_bist.static_c_cc0,
      .prach_bist_static_c_cc0_out     (ctrl_prach_bist_static_c[0]),
      // prach_bist.static_c_cc1,
      .prach_bist_static_c_cc1_out     (ctrl_prach_bist_static_c[1]),
      // prach_bist.static_c_cc2,
      .prach_bist_static_c_cc2_out     (ctrl_prach_bist_static_c[2]),
      // prach_bw.cc0,
      .prach_bw_cc0_out                (ctrl_prach_bw[0]),
      // prach_bw.cc1,
      .prach_bw_cc1_out                (ctrl_prach_bw[1]),
      // prach_bw.cc2,
      .prach_bw_cc2_out                (ctrl_prach_bw[2]),
      // prach_rfs_offset_0.val,
      .prach_rfs_offset_0_val_out      (ctrl_prach_rfs_offset[0]),
      // prach_rfs_offset_1.val,
      .prach_rfs_offset_1_val_out      (ctrl_prach_rfs_offset[1]),
      // prach_rfs_offset_2.val,
      .prach_rfs_offset_2_val_out      (ctrl_prach_rfs_offset[2]),
      // prach_ta3_offset_0.val,
      .prach_ta3_offset_0_val_out      (ctrl_prach_ta3_offset[0]),
      // prach_ta3_offset_1.val,
      .prach_ta3_offset_1_val_out      (ctrl_prach_ta3_offset[1]),
      // prach_ta3_offset_2.val,
      .prach_ta3_offset_2_val_out      (ctrl_prach_ta3_offset[2]),
      // prach_ud.comp_meth,
      .prach_ud_comp_meth_out          (ctrl_prach_ud_comp_meth),
      // prach_ud.iq_width,
      .prach_ud_iq_width_out           (ctrl_prach_ud_iq_width),
      // prach_ud.fs_offset,
      .prach_ud_fs_offset_out          (ctrl_prach_ud_fs_offset),
      // prach_cfg0_0.symbol_id,
      .prach_cfg0_0_symbol_id_out      (ctrl_prach_cfg0_symbol_id[0]),
      // prach_cfg0_0.slot_id,
      .prach_cfg0_0_slot_id_out        (ctrl_prach_cfg0_slot_id[0]),
      // prach_cfg0_0.subframe_id,
      .prach_cfg0_0_subframe_id_out    (ctrl_prach_cfg0_subframe_id[0]),
      // prach_cfg0_0.subframe_inc,
      .prach_cfg0_0_subframe_inc_out   (ctrl_prach_cfg0_subframe_inc[0]),
      // prach_cfg0_1.symbol_id,
      .prach_cfg0_1_symbol_id_out      (ctrl_prach_cfg0_symbol_id[1]),
      // prach_cfg0_1.slot_id,
      .prach_cfg0_1_slot_id_out        (ctrl_prach_cfg0_slot_id[1]),
      // prach_cfg0_1.subframe_id,
      .prach_cfg0_1_subframe_id_out    (ctrl_prach_cfg0_subframe_id[1]),
      // prach_cfg0_1.subframe_inc,
      .prach_cfg0_1_subframe_inc_out   (ctrl_prach_cfg0_subframe_inc[1]),
      // prach_cfg0_2.symbol_id,
      .prach_cfg0_2_symbol_id_out      (ctrl_prach_cfg0_symbol_id[2]),
      // prach_cfg0_2.slot_id,
      .prach_cfg0_2_slot_id_out        (ctrl_prach_cfg0_slot_id[2]),
      // prach_cfg0_2.subframe_id,
      .prach_cfg0_2_subframe_id_out    (ctrl_prach_cfg0_subframe_id[2]),
      // prach_cfg0_2.subframe_inc,
      .prach_cfg0_2_subframe_inc_out   (ctrl_prach_cfg0_subframe_inc[2]),
      // prach_cfg1_0.time_offset,
      .prach_cfg1_0_time_offset_out    (ctrl_prach_cfg1_time_offset[0]),
      // prach_cfg1_0.cp_length,
      .prach_cfg1_0_cp_length_out      (ctrl_prach_cfg1_cp_length[0]),
      // prach_cfg1_1.time_offset,
      .prach_cfg1_1_time_offset_out    (ctrl_prach_cfg1_time_offset[1]),
      // prach_cfg1_1.cp_length,
      .prach_cfg1_1_cp_length_out      (ctrl_prach_cfg1_cp_length[1]),
      // prach_cfg1_2.time_offset,
      .prach_cfg1_2_time_offset_out    (ctrl_prach_cfg1_time_offset[2]),
      // prach_cfg1_2.cp_length,
      .prach_cfg1_2_cp_length_out      (ctrl_prach_cfg1_cp_length[2]),
      // prach_cfg2_0.num_symbol,
      .prach_cfg2_0_num_symbol_out     (ctrl_prach_cfg2_num_symbol[0]),
      // prach_cfg2_0.freq_offset,
      .prach_cfg2_0_freq_offset_out    (ctrl_prach_cfg2_freq_offset[0]),
      // prach_cfg2_1.num_symbol,
      .prach_cfg2_1_num_symbol_out     (ctrl_prach_cfg2_num_symbol[1]),
      // prach_cfg2_1.freq_offset,
      .prach_cfg2_1_freq_offset_out    (ctrl_prach_cfg2_freq_offset[1]),
      // prach_cfg2_2.num_symbol,
      .prach_cfg2_2_num_symbol_out     (ctrl_prach_cfg2_num_symbol[2]),
      // prach_cfg2_2.freq_offset,
      .prach_cfg2_2_freq_offset_out    (ctrl_prach_cfg2_freq_offset[2]),
      // prach_cfg3_0.sampling_offset,
      .prach_cfg3_0_sampling_offset_out(ctrl_prach_cfg3_sampling_offset[0]),
      // prach_cfg3_1.sampling_offset,
      .prach_cfg3_1_sampling_offset_out(ctrl_prach_cfg3_sampling_offset[1]),
      // prach_cfg3_2.sampling_offset,
      .prach_cfg3_2_sampling_offset_out(ctrl_prach_cfg3_sampling_offset[2]),
      // prach_msg0_0.symbol_id,
      .prach_msg0_0_symbol_id_in       (stat_prach_msg0_symbol_id[0]),
      // prach_msg0_0.slot_id,
      .prach_msg0_0_slot_id_in         (stat_prach_msg0_slot_id[0]),
      // prach_msg0_0.subframe_id,
      .prach_msg0_0_subframe_id_in     (stat_prach_msg0_subframe_id[0]),
      // prach_msg0_1.symbol_id,
      .prach_msg0_1_symbol_id_in       (stat_prach_msg0_symbol_id[1]),
      // prach_msg0_1.slot_id,
      .prach_msg0_1_slot_id_in         (stat_prach_msg0_slot_id[1]),
      // prach_msg0_1.subframe_id,
      .prach_msg0_1_subframe_id_in     (stat_prach_msg0_subframe_id[1]),
      // prach_msg0_2.symbol_id,
      .prach_msg0_2_symbol_id_in       (stat_prach_msg0_symbol_id[2]),
      // prach_msg0_2.slot_id,
      .prach_msg0_2_slot_id_in         (stat_prach_msg0_slot_id[2]),
      // prach_msg0_2.subframe_id,
      .prach_msg0_2_subframe_id_in     (stat_prach_msg0_subframe_id[2]),
      // prach_msg1_0.time_offset,
      .prach_msg1_0_time_offset_in     (stat_prach_msg1_time_offset[0]),
      // prach_msg1_0.cp_length,
      .prach_msg1_0_cp_length_in       (stat_prach_msg1_cp_length[0]),
      // prach_msg1_1.time_offset,
      .prach_msg1_1_time_offset_in     (stat_prach_msg1_time_offset[1]),
      // prach_msg1_1.cp_length,
      .prach_msg1_1_cp_length_in       (stat_prach_msg1_cp_length[1]),
      // prach_msg1_2.time_offset,
      .prach_msg1_2_time_offset_in     (stat_prach_msg1_time_offset[2]),
      // prach_msg1_2.cp_length,
      .prach_msg1_2_cp_length_in       (stat_prach_msg1_cp_length[2]),
      // prach_msg2_0.num_symbol,
      .prach_msg2_0_num_symbol_in      (stat_prach_msg2_num_symbol[0]),
      // prach_msg2_0.freq_offset,
      .prach_msg2_0_freq_offset_in     (stat_prach_msg2_freq_offset[0]),
      // prach_msg2_1.num_symbol,
      .prach_msg2_1_num_symbol_in      (stat_prach_msg2_num_symbol[1]),
      // prach_msg2_1.freq_offset,
      .prach_msg2_1_freq_offset_in     (stat_prach_msg2_freq_offset[1]),
      // prach_msg2_2.num_symbol,
      .prach_msg2_2_num_symbol_in      (stat_prach_msg2_num_symbol[2]),
      // prach_msg2_2.freq_offset,
      .prach_msg2_2_freq_offset_in     (stat_prach_msg2_freq_offset[2]),
      // dl_phase_comp,
      .dl_phase_comp_addr              (ctrl_dl_phase_comp_addr),
      .dl_phase_comp_en                (ctrl_dl_phase_comp_en),
      .dl_phase_comp_we                (ctrl_dl_phase_comp_we),
      .dl_phase_comp_din               (ctrl_dl_phase_comp_din),
      .dl_phase_comp_dout              (ctrl_dl_phase_comp_dout),
      .dl_phase_comp_valid             (ctrl_dl_phase_comp_valid),
      // ul_phase_comp,
      .ul_phase_comp_addr              (ctrl_ul_phase_comp_addr),
      .ul_phase_comp_en                (ctrl_ul_phase_comp_en),
      .ul_phase_comp_we                (ctrl_ul_phase_comp_we),
      .ul_phase_comp_din               (ctrl_ul_phase_comp_din),
      .ul_phase_comp_dout              (ctrl_ul_phase_comp_dout),
      .ul_phase_comp_valid             (ctrl_ul_phase_comp_valid)
  );

endmodule

`default_nettype wire
