`timescale 1 ns / 1 ps
//
`default_nettype none

module prach #(
    parameter int NUM_CC  = 3,
    parameter int NUM_ANT = 4,
    parameter int ANT_ID  = 0
) (
    // AXI
    input var         s_axi_aclk,
    input var         s_axi_aresetn,
    //
    input var  [10:0] s_axi_awaddr,
    input var  [ 2:0] s_axi_awprot,
    input var         s_axi_awvalid,
    output var        s_axi_awready,
    //
    input var  [31:0] s_axi_wdata,
    input var  [ 3:0] s_axi_wstrb,
    input var         s_axi_wvalid,
    output var        s_axi_wready,
    //
    output var [ 1:0] s_axi_bresp,
    output var        s_axi_bvalid,
    input var         s_axi_bready,
    //
    input var  [10:0] s_axi_araddr,
    input var  [ 2:0] s_axi_arprot,
    input var         s_axi_arvalid,
    output var        s_axi_arready,
    //
    output var [31:0] s_axi_rdata,
    output var [ 1:0] s_axi_rresp,
    output var        s_axi_rvalid,
    input var         s_axi_rready,
    // Clock & Reset
    //--------------
    input var         clk,
    input var         rst,
    //
    input var  [31:0] s_axis_tdata           [NUM_CC][NUM_ANT],
    input var         s_axis_tlast           [NUM_CC][NUM_ANT],
    input var  [ 7:0] s_axis_tuser           [NUM_CC][NUM_ANT],
    input var         s_axis_tvalid          [NUM_CC][NUM_ANT],
    output var        s_axis_tready          [NUM_CC][NUM_ANT],
    // ORAN
    //--------
    input var         clk_eth_xran,
    input var         rst_eth_xran,
    //
    input var         sync_in,
    // PRACH C plane messages
    input var         s_prach_tvalid,
    output var        s_prach_tready,
    input var  [15:0] s_prach_rtc_pc_id,
    input var  [ 3:0] s_prach_cc,
    input var  [ 7:0] s_prach_ss,
    input var  [11:0] s_prach_section_id,
    input var  [ 3:0] s_prach_return_port,
    input var  [ 3:0] s_prach_filter_index,
    input var  [ 7:0] s_prach_f,
    input var  [ 3:0] s_prach_sf,
    input var  [ 5:0] s_prach_sl,
    input var  [ 5:0] s_prach_sy,
    input var  [15:0] s_prach_time_offset,
    input var  [ 7:0] s_prach_frame_structure,
    input var  [15:0] s_prach_cp_length,
    input var  [ 7:0] s_prach_udcomphdr,
    input var         s_prach_rb,
    input var         s_prach_syminc,
    input var  [ 9:0] s_prach_start_prbc,
    input var  [ 7:0] s_prach_num_prbc,
    input var  [11:0] s_prach_remask,
    input var  [ 3:0] s_prach_num_symbol,
    input var  [14:0] s_prach_beamid,
    input var  [23:0] s_prach_freqoffset,
    // PRACH U-Plane
    output var [63:0] m_fram_prach_tdata,
    output var [ 7:0] m_fram_prach_tkeep,
    output var        m_fram_prach_tlast,
    output var [31:0] m_fram_prach_tuser,
    output var        m_fram_prach_tvalid,
    input var         m_fram_prach_tready
);

  // Signals

  /* verilator lint_off UNUSED */
  logic [ 3:0] ctrl_ud_comp_meth;
  logic [ 3:0] ctrl_ud_iq_width;
  /* verilator lint_on UNUSED */
  logic [ 3:0] ctrl_fs_offset;
  //
  logic [ 3:0] ctrl_bist           [NUM_CC];
  logic [ 3:0] ctrl_en             [NUM_CC];
  /* verilator lint_off UNUSED */
  logic [ 3:0] ctrl_format         [NUM_CC];
  /* verilator lint_on UNUSED */
  logic [ 1:0] ctrl_rat            [NUM_CC];
  logic [ 3:0] ctrl_bw             [NUM_CC];
  logic [22:0] ctrl_rfs_offset     [NUM_CC];
  logic [22:0] ctrl_ta3_offset     [NUM_CC];
  //
  logic [ 3:0] ctrl_static_c       [NUM_CC];
  //
  logic [ 3:0] ctrl_subframe_inc   [NUM_CC];
  logic [ 3:0] ctrl_subframe_id    [NUM_CC];
  logic [ 5:0] ctrl_slot_id        [NUM_CC];
  logic [ 5:0] ctrl_symbol_id      [NUM_CC];
  //
  logic [15:0] ctrl_time_offset    [NUM_CC];
  logic [15:0] ctrl_cp_length      [NUM_CC];
  //
  logic [ 3:0] ctrl_num_symbol     [NUM_CC];
  logic [23:0] ctrl_freq_offset    [NUM_CC];
  //
  logic [15:0] ctrl_sampling_offset[NUM_CC];
  //
  logic [ 3:0] stat_subframe_id    [NUM_CC];
  logic [ 5:0] stat_slot_id        [NUM_CC];
  logic [ 5:0] stat_symbol_id      [NUM_CC];
  //
  logic [15:0] stat_time_offset    [NUM_CC];
  logic [15:0] stat_cp_length      [NUM_CC];
  //
  logic [ 3:0] stat_num_symbol     [NUM_CC];
  logic [23:0] stat_freq_offset    [NUM_CC];

  // Main

  prach_regs i_prach_regs (
      // AXI-Lite Slave Interface
      //-------------------------
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
      // prach_en.cc0,
      .prach_en_cc0_out                (ctrl_en[0]),
      // prach_en.cc1,
      .prach_en_cc1_out                (ctrl_en[1]),
      // prach_en.cc2,
      .prach_en_cc2_out                (ctrl_en[2]),
      // prach_format.cc0,
      .prach_format_cc0_out            (ctrl_format[0]),
      // prach_format.cc1,
      .prach_format_cc1_out            (ctrl_format[1]),
      // prach_format.cc2,
      .prach_format_cc2_out            (ctrl_format[2]),
      // prach_rat.cc0,
      .prach_rat_cc0_out               (ctrl_rat[0]),
      // prach_rat.cc1,
      .prach_rat_cc1_out               (ctrl_rat[1]),
      // prach_rat.cc2,
      .prach_rat_cc2_out               (ctrl_rat[2]),
      // prach_bist.bist_cc0,
      .prach_bist_bist_cc0_out         (ctrl_bist[0]),
      // prach_bist.bist_cc1,
      .prach_bist_bist_cc1_out         (ctrl_bist[1]),
      // prach_bist.bist_cc2,
      .prach_bist_bist_cc2_out         (ctrl_bist[2]),
      // prach_bist.static_c_cc0,
      .prach_bist_static_c_cc0_out     (ctrl_static_c[0]),
      // prach_bist.static_c_cc1,
      .prach_bist_static_c_cc1_out     (ctrl_static_c[1]),
      // prach_bist.static_c_cc2,
      .prach_bist_static_c_cc2_out     (ctrl_static_c[2]),
      // prach_bw.cc0,
      .prach_bw_cc0_out                (ctrl_bw[0]),
      // prach_bw.cc1,
      .prach_bw_cc1_out                (ctrl_bw[1]),
      // prach_bw.cc2,
      .prach_bw_cc2_out                (ctrl_bw[2]),
      // prach_rfs_offset_0.val,
      .prach_rfs_offset_0_val_out      (ctrl_rfs_offset[0]),
      // prach_rfs_offset_1.val,
      .prach_rfs_offset_1_val_out      (ctrl_rfs_offset[1]),
      // prach_rfs_offset_2.val,
      .prach_rfs_offset_2_val_out      (ctrl_rfs_offset[2]),
      // prach_ta3_offset_0.val,
      .prach_ta3_offset_0_val_out      (ctrl_ta3_offset[0]),
      // prach_ta3_offset_1.val,
      .prach_ta3_offset_1_val_out      (ctrl_ta3_offset[1]),
      // prach_ta3_offset_2.val,
      .prach_ta3_offset_2_val_out      (ctrl_ta3_offset[2]),
      // prach_ud.comp_meth,
      .prach_ud_comp_meth_out          (ctrl_ud_comp_meth),
      // prach_ud.iq_width,
      .prach_ud_iq_width_out           (ctrl_ud_iq_width),
      // prach_ud.fs_offset,
      .prach_ud_fs_offset_out          (ctrl_fs_offset),
      // prach_cfg0_0.symbol_id,
      .prach_cfg0_0_symbol_id_out      (ctrl_symbol_id[0]),
      // prach_cfg0_0.slot_id,
      .prach_cfg0_0_slot_id_out        (ctrl_slot_id[0]),
      // prach_cfg0_0.subframe_id,
      .prach_cfg0_0_subframe_id_out    (ctrl_subframe_id[0]),
      // prach_cfg0_0.subframe_inc,
      .prach_cfg0_0_subframe_inc_out   (ctrl_subframe_inc[0]),
      // prach_cfg0_1.symbol_id,
      .prach_cfg0_1_symbol_id_out      (ctrl_symbol_id[1]),
      // prach_cfg0_1.slot_id,
      .prach_cfg0_1_slot_id_out        (ctrl_slot_id[1]),
      // prach_cfg0_1.subframe_id,
      .prach_cfg0_1_subframe_id_out    (ctrl_subframe_id[1]),
      // prach_cfg0_1.subframe_inc,
      .prach_cfg0_1_subframe_inc_out   (ctrl_subframe_inc[1]),
      // prach_cfg0_2.symbol_id,
      .prach_cfg0_2_symbol_id_out      (ctrl_symbol_id[2]),
      // prach_cfg0_2.slot_id,
      .prach_cfg0_2_slot_id_out        (ctrl_slot_id[2]),
      // prach_cfg0_2.subframe_id,
      .prach_cfg0_2_subframe_id_out    (ctrl_subframe_id[2]),
      // prach_cfg0_2.subframe_inc,
      .prach_cfg0_2_subframe_inc_out   (ctrl_subframe_inc[2]),
      // prach_cfg1_0.time_offset,
      .prach_cfg1_0_time_offset_out    (ctrl_time_offset[0]),
      // prach_cfg1_0.cp_length,
      .prach_cfg1_0_cp_length_out      (ctrl_cp_length[0]),
      // prach_cfg1_1.time_offset,
      .prach_cfg1_1_time_offset_out    (ctrl_time_offset[1]),
      // prach_cfg1_1.cp_length,
      .prach_cfg1_1_cp_length_out      (ctrl_cp_length[1]),
      // prach_cfg1_2.time_offset,
      .prach_cfg1_2_time_offset_out    (ctrl_time_offset[2]),
      // prach_cfg1_2.cp_length,
      .prach_cfg1_2_cp_length_out      (ctrl_cp_length[2]),
      // prach_cfg2_0.num_symbol,
      .prach_cfg2_0_num_symbol_out     (ctrl_num_symbol[0]),
      // prach_cfg2_0.freq_offset,
      .prach_cfg2_0_freq_offset_out    (ctrl_freq_offset[0]),
      // prach_cfg2_1.num_symbol,
      .prach_cfg2_1_num_symbol_out     (ctrl_num_symbol[1]),
      // prach_cfg2_1.freq_offset,
      .prach_cfg2_1_freq_offset_out    (ctrl_freq_offset[1]),
      // prach_cfg2_2.num_symbol,
      .prach_cfg2_2_num_symbol_out     (ctrl_num_symbol[2]),
      // prach_cfg2_2.freq_offset,
      .prach_cfg2_2_freq_offset_out    (ctrl_freq_offset[2]),
      // prach_cfg3_0.sampling_offset,
      .prach_cfg3_0_sampling_offset_out(ctrl_sampling_offset[0]),
      // prach_cfg3_1.sampling_offset,
      .prach_cfg3_1_sampling_offset_out(ctrl_sampling_offset[1]),
      // prach_cfg3_2.sampling_offset,
      .prach_cfg3_2_sampling_offset_out(ctrl_sampling_offset[2]),
      // prach_msg0_0.symbol_id,
      .prach_msg0_0_symbol_id_in       (stat_symbol_id[0]),
      // prach_msg0_0.slot_id,
      .prach_msg0_0_slot_id_in         (stat_slot_id[0]),
      // prach_msg0_0.subframe_id,
      .prach_msg0_0_subframe_id_in     (stat_subframe_id[0]),
      // prach_msg0_1.symbol_id,
      .prach_msg0_1_symbol_id_in       (stat_symbol_id[1]),
      // prach_msg0_1.slot_id,
      .prach_msg0_1_slot_id_in         (stat_slot_id[1]),
      // prach_msg0_1.subframe_id,
      .prach_msg0_1_subframe_id_in     (stat_subframe_id[1]),
      // prach_msg0_2.symbol_id,
      .prach_msg0_2_symbol_id_in       (stat_symbol_id[2]),
      // prach_msg0_2.slot_id,
      .prach_msg0_2_slot_id_in         (stat_slot_id[2]),
      // prach_msg0_2.subframe_id,
      .prach_msg0_2_subframe_id_in     (stat_subframe_id[2]),
      // prach_msg1_0.time_offset,
      .prach_msg1_0_time_offset_in     (stat_time_offset[0]),
      // prach_msg1_0.cp_length,
      .prach_msg1_0_cp_length_in       (stat_cp_length[0]),
      // prach_msg1_1.time_offset,
      .prach_msg1_1_time_offset_in     (stat_time_offset[1]),
      // prach_msg1_1.cp_length,
      .prach_msg1_1_cp_length_in       (stat_cp_length[1]),
      // prach_msg1_2.time_offset,
      .prach_msg1_2_time_offset_in     (stat_time_offset[2]),
      // prach_msg1_2.cp_length,
      .prach_msg1_2_cp_length_in       (stat_cp_length[2]),
      // prach_msg2_0.num_symbol,
      .prach_msg2_0_num_symbol_in      (stat_num_symbol[0]),
      // prach_msg2_0.freq_offset,
      .prach_msg2_0_freq_offset_in     (stat_freq_offset[0]),
      // prach_msg2_1.num_symbol,
      .prach_msg2_1_num_symbol_in      (stat_num_symbol[1]),
      // prach_msg2_1.freq_offset,
      .prach_msg2_1_freq_offset_in     (stat_freq_offset[1]),
      // prach_msg2_2.num_symbol,
      .prach_msg2_2_num_symbol_in      (stat_num_symbol[2]),
      // prach_msg2_2.freq_offset,
      .prach_msg2_2_freq_offset_in     (stat_freq_offset[2])
  );

  prach_top #(
      .NUM_CC (NUM_CC),
      .NUM_ANT(NUM_ANT),
      .ANT_ID (ANT_ID)
  ) i_prach_top (
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
      .clk_eth_xran           (clk_eth_xran),
      .rst_eth_xran           (rst_eth_xran),
      //
      .sync_in                (sync_in),
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
      .ctrl_fs_offset         (ctrl_fs_offset),
      //
      .ctrl_bist              (ctrl_bist),
      .ctrl_en                (ctrl_en),
      .ctrl_rat               (ctrl_rat),
      .ctrl_bw                (ctrl_bw),
      .ctrl_rfs_offset        (ctrl_rfs_offset),
      .ctrl_ta3_offset        (ctrl_ta3_offset),
      //
      .ctrl_static_c          (ctrl_static_c),
      //
      .ctrl_subframe_inc      (ctrl_subframe_inc),
      .ctrl_subframe_id       (ctrl_subframe_id),
      .ctrl_slot_id           (ctrl_slot_id),
      .ctrl_symbol_id         (ctrl_symbol_id),
      //
      .ctrl_time_offset       (ctrl_time_offset),
      .ctrl_cp_length         (ctrl_cp_length),
      //
      .ctrl_num_symbol        (ctrl_num_symbol),
      .ctrl_freq_offset       (ctrl_freq_offset),
      //
      .ctrl_sampling_offset   (ctrl_sampling_offset),
      //
      .stat_subframe_id       (stat_subframe_id),
      .stat_slot_id           (stat_slot_id),
      .stat_symbol_id         (stat_symbol_id),
      //
      .stat_time_offset       (stat_time_offset),
      .stat_cp_length         (stat_cp_length),
      //
      .stat_num_symbol        (stat_num_symbol),
      .stat_freq_offset       (stat_freq_offset)
  );

endmodule

`default_nettype wire
