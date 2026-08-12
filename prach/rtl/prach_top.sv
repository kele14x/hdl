`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_top #(
    parameter int NUM_CC  = 3,
    parameter int NUM_ANT = 4,
    parameter int ANT_ID  = 0
) (
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
    input var         m_fram_prach_tready,
    // CSR
    //----
    input var         ctrl_clk,
    input var         ctrl_rst,
    //
    input var  [ 3:0] ctrl_fs_offset,
    // 0 = disable, 1 = enable
    input var  [ 3:0] ctrl_bist              [NUM_CC],
    // 0 = disable, 1 = enable
    input var  [ 3:0] ctrl_en                [NUM_CC],
    // 0 = LTE, 1 = NR 15kHz, 2 = NR 30kHz
    input var  [ 1:0] ctrl_rat               [NUM_CC],
    // 0 = 5, 1 = 10, 2 = 15/20/25, 3 = 30/40/50
    input var  [ 3:0] ctrl_bw                [NUM_CC],
    // 1 = 2.5 ns
    input var  [22:0] ctrl_rfs_offset        [NUM_CC],
    input var  [22:0] ctrl_ta3_offset        [NUM_CC],
    //
    input var  [ 3:0] ctrl_static_c          [NUM_CC],
    //
    input var  [ 3:0] ctrl_subframe_inc      [NUM_CC],
    input var  [ 3:0] ctrl_subframe_id       [NUM_CC],
    input var  [ 5:0] ctrl_slot_id           [NUM_CC],
    input var  [ 5:0] ctrl_symbol_id         [NUM_CC],
    //
    input var  [15:0] ctrl_time_offset       [NUM_CC],
    input var  [15:0] ctrl_cp_length         [NUM_CC],
    //
    input var  [ 3:0] ctrl_num_symbol        [NUM_CC],
    input var  [23:0] ctrl_freq_offset       [NUM_CC],
    //
    input var  [15:0] ctrl_sampling_offset   [NUM_CC],
    //
    output var [ 3:0] stat_subframe_id       [NUM_CC],
    output var [ 5:0] stat_slot_id           [NUM_CC],
    output var [ 5:0] stat_symbol_id         [NUM_CC],
    //
    output var [15:0] stat_time_offset       [NUM_CC],
    output var [15:0] stat_cp_length         [NUM_CC],
    //
    output var [ 3:0] stat_num_symbol        [NUM_CC],
    output var [23:0] stat_freq_offset       [NUM_CC]
);

  logic [63:0] m_axis_tdata [NUM_CC];
  logic [ 7:0] m_axis_tkeep [NUM_CC];
  logic        m_axis_tlast [NUM_CC];
  logic [31:0] m_axis_tuser [NUM_CC];
  logic        m_axis_tvalid[NUM_CC];
  logic        m_axis_tready[NUM_CC];

  // Main

  assign s_prach_tready = 1'b1;

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc

      prach_channel #(
          .CC_ID  (cc),
          .ANT_ID (ANT_ID),
          .NUM_ANT(NUM_ANT)
      ) u_channel (
          .clk                    (clk),
          .rst                    (rst),
          //
          .s_axis_tdata           (s_axis_tdata[cc]),
          .s_axis_tlast           (s_axis_tlast[cc]),
          .s_axis_tuser           (s_axis_tuser[cc]),
          .s_axis_tvalid          (s_axis_tvalid[cc]),
          .s_axis_tready          (s_axis_tready[cc]),
          // ORAN
          .clk_eth_xran           (clk_eth_xran),
          .rst_eth_xran           (rst_eth_xran),
          //
          .sync_in                (sync_in),
          //
          .s_prach_tvalid         (s_prach_tvalid),
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
          //
          .m_axis_tdata           (m_axis_tdata[cc]),
          .m_axis_tkeep           (m_axis_tkeep[cc]),
          .m_axis_tlast           (m_axis_tlast[cc]),
          .m_axis_tuser           (m_axis_tuser[cc]),
          .m_axis_tvalid          (m_axis_tvalid[cc]),
          .m_axis_tready          (m_axis_tready[cc]),
          // CSR
          .ctrl_clk               (ctrl_clk),
          .ctrl_rst               (ctrl_rst),
          //
          .ctrl_fs_offset         (ctrl_fs_offset),
          //
          .ctrl_bist              (ctrl_bist[cc]),
          .ctrl_en                (ctrl_en[cc]),
          .ctrl_rat               (ctrl_rat[cc]),
          .ctrl_bw                (ctrl_bw[cc]),
          .ctrl_rfs_offset        (ctrl_rfs_offset[cc]),
          .ctrl_ta3_offset        (ctrl_ta3_offset[cc]),
          //
          .ctrl_static_c          (ctrl_static_c[cc]),
          //
          .ctrl_subframe_inc      (ctrl_subframe_inc[cc]),
          .ctrl_subframe_id       (ctrl_subframe_id[cc]),
          .ctrl_slot_id           (ctrl_slot_id[cc]),
          .ctrl_symbol_id         (ctrl_symbol_id[cc]),
          //
          .ctrl_time_offset       (ctrl_time_offset[cc]),
          .ctrl_cp_length         (ctrl_cp_length[cc]),
          //
          .ctrl_num_symbol        (ctrl_num_symbol[cc]),
          .ctrl_freq_offset       (ctrl_freq_offset[cc]),
          //
          .ctrl_sampling_offset   (ctrl_sampling_offset[cc]),
          //
          .stat_subframe_id       (stat_subframe_id[cc]),
          .stat_slot_id           (stat_slot_id[cc]),
          .stat_symbol_id         (stat_symbol_id[cc]),
          //
          .stat_time_offset       (stat_time_offset[cc]),
          .stat_cp_length         (stat_cp_length[cc]),
          //
          .stat_num_symbol        (stat_num_symbol[cc]),
          .stat_freq_offset       (stat_freq_offset[cc])
      );

    end
  endgenerate

  // verilog_format: off
  axis_switch #(
      .NUM_SRC   (NUM_CC),
      .NUM_DEST  (1),
      .DATA_WIDTH(64),
      .USER_WIDTH(32)
  ) u_switch (
      .clk          (clk_eth_xran),
      .rst          (rst_eth_xran),
      //
      .s_axis_tdata ({m_axis_tdata[2],  m_axis_tdata[1],  m_axis_tdata[0]}),
      .s_axis_tkeep ({m_axis_tkeep[2],  m_axis_tkeep[1],  m_axis_tkeep[0]}),
      .s_axis_tlast ({m_axis_tlast[2],  m_axis_tlast[1],  m_axis_tlast[0]}),
      .s_axis_tdest ({1'b1, 1'b1, 1'b1}),
      .s_axis_tuser ({m_axis_tuser[2],  m_axis_tuser[1],  m_axis_tuser[0]}),
      .s_axis_tvalid({m_axis_tvalid[2], m_axis_tvalid[1], m_axis_tvalid[0]}),
      .s_axis_tready({m_axis_tready[2], m_axis_tready[1], m_axis_tready[0]}),
      //
      .m_axis_tdata (m_fram_prach_tdata),
      .m_axis_tkeep (m_fram_prach_tkeep),
      .m_axis_tlast (m_fram_prach_tlast),
      .m_axis_tuser (m_fram_prach_tuser),
      .m_axis_tvalid(m_fram_prach_tvalid),
      .m_axis_tready(m_fram_prach_tready)
  );
  // verilog_format: on

endmodule

`default_nettype wire
