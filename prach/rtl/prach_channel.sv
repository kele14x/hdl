`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_channel #(
    parameter int CC_ID   = 0,
    parameter int ANT_ID  = 0,
    parameter int NUM_ANT = 4
) (
    // Clock & Reset
    //--------------
    input  wire        clk,
    input  wire        rst,
    // Ant 0,1,2,3 interleaved
    input  wire [31:0] s_axis_tdata           [NUM_ANT],
    input  wire        s_axis_tlast           [NUM_ANT],
    input  wire [ 7:0] s_axis_tuser           [NUM_ANT],
    input  wire        s_axis_tvalid          [NUM_ANT],
    output wire        s_axis_tready          [NUM_ANT],
    // ORAN C-Plane
    //-------------
    input  wire        clk_eth_xran,
    input  wire        rst_eth_xran,
    //
    input  wire        sync_in,
    //
    input  wire        s_prach_tvalid,
    input  wire [15:0] s_prach_rtc_pc_id,
    input  wire [ 3:0] s_prach_cc,
    input  wire [ 7:0] s_prach_ss,
    input  wire [11:0] s_prach_section_id,
    input  wire [ 3:0] s_prach_return_port,
    input  wire [ 3:0] s_prach_filter_index,
    input  wire [ 7:0] s_prach_f,
    input  wire [ 3:0] s_prach_sf,
    input  wire [ 5:0] s_prach_sl,
    input  wire [ 5:0] s_prach_sy,
    input  wire [15:0] s_prach_time_offset,
    input  wire [ 7:0] s_prach_frame_structure,
    input  wire [15:0] s_prach_cp_length,
    input  wire [ 7:0] s_prach_udcomphdr,
    input  wire        s_prach_rb,
    input  wire        s_prach_syminc,
    input  wire [ 9:0] s_prach_start_prbc,
    input  wire [ 7:0] s_prach_num_prbc,
    input  wire [11:0] s_prach_remask,
    input  wire [ 3:0] s_prach_num_symbol,
    input  wire [14:0] s_prach_beamid,
    input  wire [23:0] s_prach_freqoffset,
    //
    output wire [63:0] m_axis_tdata,
    output wire [ 7:0] m_axis_tkeep,
    output wire        m_axis_tlast,
    output wire [31:0] m_axis_tuser,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    // CSR
    //----
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    input  wire [ 3:0] ctrl_fs_offset,
    //
    input  wire [ 3:0] ctrl_en,
    input  wire [ 1:0] ctrl_rat,
    input  wire [ 3:0] ctrl_bist,
    input  wire [ 3:0] ctrl_bw,
    input  wire [22:0] ctrl_rfs_offset,
    input  wire [22:0] ctrl_ta3_offset,
    //
    input  wire [ 3:0] ctrl_static_c,
    //
    input  wire [ 3:0] ctrl_subframe_inc,
    input  wire [ 3:0] ctrl_subframe_id,
    input  wire [ 5:0] ctrl_slot_id,
    input  wire [ 5:0] ctrl_symbol_id,
    //
    input  wire [15:0] ctrl_time_offset,
    input  wire [15:0] ctrl_cp_length,
    //
    input  wire [ 3:0] ctrl_num_symbol,
    input  wire [23:0] ctrl_freq_offset,
    //
    input  wire [15:0] ctrl_sampling_offset,
    // Status
    output wire [ 3:0] stat_subframe_id,
    output wire [ 5:0] stat_slot_id,
    output wire [ 5:0] stat_symbol_id,
    //
    output wire [15:0] stat_time_offset,
    output wire [15:0] stat_cp_length,
    //
    output wire [ 3:0] stat_num_symbol,
    output wire [23:0] stat_freq_offset
);

  logic [       22:0] ctrl_rfs_offset_s;

  logic               sync_s;
  logic               sync_cdc;

  logic [NUM_ANT-1:0] rd_channel_req;
  logic [NUM_ANT-1:0] rd_channel_ack;

  logic [        8:0] rd_start_symbol0;
  logic [        8:0] rd_start_symbol1;
  logic [       18:0] rd_start_sample;
  logic [        3:0] rd_num_symbol;
  logic [       17:0] rd_fcw;
  logic [       11:0] rd_section_id;

  logic [       15:0] resync_dout_dr;
  logic [       15:0] resync_dout_di;
  logic               resync_dout_sf;
  logic               resync_dout_sl;
  logic               resync_dout_sy;
  logic [        7:0] resync_dout_chn;
  logic               resync_dout_dv;
  logic               resync_dout_last;

  logic [       15:0] ddc_dout_dr;
  logic [       15:0] ddc_dout_di;
  logic               ddc_dout_sf;
  logic               ddc_dout_sl;
  logic               ddc_dout_sy;
  logic [        7:0] ddc_dout_chn;
  logic               ddc_dout_dv;
  logic               ddc_dout_last;

  logic [       15:0] stream2block_dout_dr;
  logic [       15:0] stream2block_dout_di;
  logic               stream2block_dout_sf;
  logic               stream2block_dout_sl;
  logic               stream2block_dout_sy;
  logic [        1:0] stream2block_dout_chn;
  logic               stream2block_dout_dv;
  logic               stream2block_dout_last;

  logic [       15:0] fft_dout_dr;
  logic [       15:0] fft_dout_di;
  logic               fft_dout_sf;
  logic               fft_dout_sl;
  logic               fft_dout_sy;
  logic [        1:0] fft_dout_chn;
  logic               fft_dout_dv;
  logic               fft_dout_last;
  logic               fft_ovf;

  // Main

  // Single CDC for control signals
  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (23)
  ) u_ctrl_cdc (
      .src_clk (1'b1),
      .src_in  (ctrl_rfs_offset),
      .dest_clk(clk_eth_xran),
      .dest_out(ctrl_rfs_offset_s)
  );

  // Delay the sync_in pulse to align with the start of the 10ms symbol,
  // this is start time of PUXCH Channel processing
  pulse_delay #(
      .WIDTH(23)
  ) u_pulse_delay_in (
      .clk      (clk_eth_xran),
      .rst      (rst_eth_xran),
      //
      .pulse_in (sync_in),
      .pulse_out(sync_s),
      //
      .delay    (ctrl_rfs_offset_s)
  );

  cdc_pulse #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1'b1),
      .REG_OUTPUT  (1'b1),
      .RST_USED    (1'b1)
  ) u_cdc_sync (
      .src_clk   (clk_eth_xran),
      .src_rst   (rst_eth_xran),
      .src_pulse (sync_s),
      //
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(sync_cdc)
  );

  prach_ctrl #(
      .CC_ID  (CC_ID),
      .ANT_ID (ANT_ID),
      .NUM_ANT(NUM_ANT)
  ) u_ctrl (
      .clk                    (clk),
      .rst                    (rst),
      //
      .rd_channel_req         (rd_channel_req),
      .rd_channel_ack         (rd_channel_ack),
      //
      .rd_start_symbol0       (rd_start_symbol0),
      .rd_start_symbol1       (rd_start_symbol1),
      .rd_start_sample        (rd_start_sample),
      .rd_num_symbol          (rd_num_symbol),
      .rd_fcw                 (rd_fcw),
      .rd_section_id          (rd_section_id),
      //-------------
      .clk_eth_xran           (clk_eth_xran),
      .rst_eth_xran           (rst_eth_xran),
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
      //----
      .ctrl_clk               (ctrl_clk),
      .ctrl_rst               (ctrl_rst),
      //
      .ctrl_rat               (ctrl_rat),
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
      // Status
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

  prach_resync #(
      .NUM_ANT(NUM_ANT)
  ) u_resync (
      .clk          (clk),
      .rst          (rst),
      //
      .sync_in      (sync_cdc),
      //
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tuser (s_axis_tuser),
      .s_axis_tvalid(s_axis_tvalid),
      .s_axis_tready(s_axis_tready),
      //
      .dout_dr      (resync_dout_dr),
      .dout_di      (resync_dout_di),
      .dout_sf      (resync_dout_sf),
      .dout_sl      (resync_dout_sl),
      .dout_sy      (resync_dout_sy),
      .dout_chn     (resync_dout_chn),
      .dout_dv      (resync_dout_dv),
      .dout_last    (resync_dout_last),
      // CSR
      .ctrl_en      (ctrl_en),
      .ctrl_bist    (ctrl_bist),
      .ctrl_bw      (ctrl_bw)
  );

  prach_ddc #(
      .NUM_ANT  (NUM_ANT),
      .NUM_STAGE(6)
  ) u_ddc (
      .clk      (clk),
      .rst      (rst),
      //
      .din_dr   (resync_dout_dr),
      .din_di   (resync_dout_di),
      .din_sf   (resync_dout_sf),
      .din_sl   (resync_dout_sl),
      .din_sy   (resync_dout_sy),
      .din_chn  (resync_dout_chn),
      .din_dv   (resync_dout_dv),
      .din_last (resync_dout_last),
      //
      .dout_dr  (ddc_dout_dr),
      .dout_di  (ddc_dout_di),
      .dout_sf  (ddc_dout_sf),
      .dout_sl  (ddc_dout_sl),
      .dout_sy  (ddc_dout_sy),
      .dout_chn (ddc_dout_chn),
      .dout_dv  (ddc_dout_dv),
      .dout_last(ddc_dout_last),
      //
      .ctrl_fcw (rd_fcw),
      .ctrl_bw  (ctrl_bw)
  );

  prach_stream2block #(
      .NUM_ANT(NUM_ANT)
  ) u_stream2block (
      .clk               (clk),
      .rst               (rst),
      //
      .din_dr            (ddc_dout_dr),
      .din_di            (ddc_dout_di),
      .din_sf            (ddc_dout_sf),
      .din_sl            (ddc_dout_sl),
      .din_sy            (ddc_dout_sy),
      .din_chn           (ddc_dout_chn),
      .din_dv            (ddc_dout_dv),
      .din_last          (ddc_dout_last),
      //
      .dout_dr           (stream2block_dout_dr),
      .dout_di           (stream2block_dout_di),
      .dout_sf           (stream2block_dout_sf),
      .dout_sl           (stream2block_dout_sl),
      .dout_sy           (stream2block_dout_sy),
      .dout_chn          (stream2block_dout_chn),
      .dout_dv           (stream2block_dout_dv),
      .dout_last         (stream2block_dout_last),
      //
      .rd_channel_req    (rd_channel_req),
      .rd_channel_ack    (rd_channel_ack),
      //
      .ctrl_start_symbol0(rd_start_symbol0),
      .ctrl_start_symbol1(rd_start_symbol1),
      .ctrl_start_sample (rd_start_sample),
      .ctrl_num_symbol   (rd_num_symbol)
  );

  prach_fft #(
      .FFT_SIZE  (1536),
      .DATA_WIDTH(16)
  ) u_fft (
      .clk      (clk),
      .rst      (rst),
      //
      .din_dr   (stream2block_dout_dr),
      .din_di   (stream2block_dout_di),
      .din_sf   (stream2block_dout_sf),
      .din_sl   (stream2block_dout_sl),
      .din_sy   (stream2block_dout_sy),
      .din_chn  (stream2block_dout_chn),
      .din_dv   (stream2block_dout_dv),
      .din_last (stream2block_dout_last),
      //
      .dout_dr  (fft_dout_dr),
      .dout_di  (fft_dout_di),
      .dout_sf  (fft_dout_sf),
      .dout_sl  (fft_dout_sl),
      .dout_sy  (fft_dout_sy),
      .dout_chn (fft_dout_chn),
      .dout_dv  (fft_dout_dv),
      .dout_last(fft_dout_last),
      .ovf      (fft_ovf)
      //
  );

  prach_framer #(
      .CC_ID  (CC_ID),
      .ANT_ID (ANT_ID),
      .NUM_ANT(NUM_ANT)
  ) u_framer (
      .clk              (clk),
      .rst              (rst),
      //
      .din_dr           (fft_dout_dr),
      .din_di           (fft_dout_di),
      .din_sf           (fft_dout_sf),
      .din_sl           (fft_dout_sl),
      .din_sy           (fft_dout_sy),
      .din_chn          (fft_dout_chn),
      .din_dv           (fft_dout_dv),
      .din_last         (fft_dout_last),
      //
      .rd_section_id    (rd_section_id),
      // C-Plane
      .clk_eth_xran     (clk_eth_xran),
      .rst_eth_xran     (rst_eth_xran),
      // U-Plane
      .m_axis_tdata     (m_axis_tdata),
      .m_axis_tkeep     (m_axis_tkeep),
      .m_axis_tlast     (m_axis_tlast),
      .m_axis_tuser     (m_axis_tuser),
      .m_axis_tvalid    (m_axis_tvalid),
      .m_axis_tready    (m_axis_tready),
      // CSR
      .ctrl_fs_offset(ctrl_fs_offset)
  );

  wire unused_channel = &{1'b0, ctrl_ta3_offset, fft_ovf};

endmodule

`default_nettype wire
