`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_ctrl #(
    parameter int CC_ID   = 0,
    parameter int ANT_ID  = 0,
    parameter int NUM_ANT = 4
) (
    // Clock & Reset
    //--------------
    input  wire               clk,
    input  wire               rst,
    //
    output reg  [NUM_ANT-1:0] rd_channel_req,
    input  wire [NUM_ANT-1:0] rd_channel_ack,
    output reg  [        8:0] rd_start_symbol0,
    output reg  [        8:0] rd_start_symbol1,
    output reg  [       18:0] rd_start_sample,
    output reg  [        3:0] rd_num_symbol,
    output reg  [       17:0] rd_fcw,
    output reg  [       11:0] rd_section_id,
    // ORAN C-Plane
    //-------------
    input  wire               clk_eth_xran,
    input  wire               rst_eth_xran,
    //
    input  wire               s_prach_tvalid,
    input  wire [       15:0] s_prach_rtc_pc_id,
    input  wire [        3:0] s_prach_cc,
    input  wire [        7:0] s_prach_ss,
    input  wire [       11:0] s_prach_section_id,
    input  wire [        3:0] s_prach_return_port,
    input  wire [        3:0] s_prach_filter_index,
    input  wire [        7:0] s_prach_f,
    input  wire [        3:0] s_prach_sf,
    input  wire [        5:0] s_prach_sl,
    input  wire [        5:0] s_prach_sy,
    input  wire [       15:0] s_prach_time_offset,
    input  wire [        7:0] s_prach_frame_structure,
    input  wire [       15:0] s_prach_cp_length,
    input  wire [        7:0] s_prach_udcomphdr,
    input  wire               s_prach_rb,
    input  wire               s_prach_syminc,
    input  wire [        9:0] s_prach_start_prbc,
    input  wire [        7:0] s_prach_num_prbc,
    input  wire [       11:0] s_prach_remask,
    input  wire [        3:0] s_prach_num_symbol,
    input  wire [       14:0] s_prach_beamid,
    input  wire [       23:0] s_prach_freqoffset,
    // CSR
    //----
    input  wire               ctrl_clk,
    input  wire               ctrl_rst,
    //
    input  wire [        1:0] ctrl_rat,
    //
    input  wire [        3:0] ctrl_static_c,
    //
    input  wire [        3:0] ctrl_subframe_inc,
    input  wire [        3:0] ctrl_subframe_id,
    input  wire [        5:0] ctrl_slot_id,
    input  wire [        5:0] ctrl_symbol_id,
    //
    input  wire [       15:0] ctrl_time_offset,
    input  wire [       15:0] ctrl_cp_length,
    //
    input  wire [        3:0] ctrl_num_symbol,
    input  wire [       23:0] ctrl_freq_offset,
    //
    input  wire [       15:0] ctrl_sampling_offset,
    // Status
    output wire [        3:0] stat_subframe_id,
    output wire [        5:0] stat_slot_id,
    output wire [        5:0] stat_symbol_id,
    //
    output wire [       15:0] stat_time_offset,
    output wire [       15:0] stat_cp_length,
    //
    output wire [        3:0] stat_num_symbol,
    output wire [       23:0] stat_freq_offset
);

  // Parameters

  // Use a single CDC module for all control signals
  // Combine all control signals into a single wide bus for efficient CDC crossing
  localparam int CtrlSignalWidth = 2 + 4 + 4 + 4 + 6 + 6 + 16 + 16 + 4 + 24 + 16;

  localparam int StatusSignalWidth = 4 + 6 + 6 + 16 + 16 + 4 + 24;

  // Define the combined width of all s_prach signals
  localparam integer PrachSignalWidth = 16 + 4 + 8 + 12 + 4 + 4 + 8 + 4 + 6 + 6 + 16 + 8 + 16 + 8 +
                                        1 + 1 + 10 + 8 + 12 + 4 + 15 + 24;

  // Helper

  function automatic logic [17:0] get_fcw(input logic [23:0] freq_offset);
    // Assume the freq_offset is with in the range [-98304, 98304 - 864]
    // Which is [-61.44 MHz, 61.44 - 0.54 MHz]
    // The output is the FCW, which should be in the range [0, 196608)
    logic signed [23:0] temp;
    temp = -24'sd864 - $signed(freq_offset);
    if (temp >= 0) begin
      return temp[17:0];
    end else begin
      return 18'(25'sd196608 + temp);
    end
  endfunction

  // Control signals

  logic [  CtrlSignalWidth-1:0] ctrl_combined;
  logic [  CtrlSignalWidth-1:0] ctrl_combined_s;

  logic [                  1:0] ctrl_rat_s;
  //
  logic [                  3:0] ctrl_static_c_s;
  //
  logic [                  3:0] ctrl_subframe_inc_s;
  logic [                  3:0] ctrl_subframe_id_s;
  logic [                  5:0] ctrl_slot_id_s;
  logic [                  5:0] ctrl_symbol_id_s;
  //
  logic [                 15:0] ctrl_time_offset_s;
  logic [                 15:0] ctrl_cp_length_s;
  //
  logic [                  3:0] ctrl_num_symbol_s;
  logic [                 23:0] ctrl_freq_offset_s;
  //
  logic [                 15:0] ctrl_sampling_offset_s;

  logic [                  3:0] stat_subframe_id_r;
  logic [                  5:0] stat_slot_id_r;
  logic [                  5:0] stat_symbol_id_r;
  //
  logic [                 15:0] stat_time_offset_r;
  logic [                 15:0] stat_cp_length_r;
  //
  logic [                  3:0] stat_num_symbol_r;
  logic [                 23:0] stat_freq_offset_r;

  // Combined PRACH Control/Status signals for CDC crossing

  logic [ PrachSignalWidth-1:0] s_prach_combined;
  logic [ PrachSignalWidth-1:0] s_prach_combined_s;
  logic                         s_prach_tvalid_s;

  logic [StatusSignalWidth-1:0] stat_combined_r;
  logic [StatusSignalWidth-1:0] stat_combined;

  logic [                 15:0] s_prach_rtc_pc_id_s;
  logic [                  3:0] s_prach_cc_s;
  logic [                  7:0] s_prach_ss_s;
  logic [                 11:0] s_prach_section_id_s;
  logic [                  3:0] s_prach_return_port_s;
  logic [                  3:0] s_prach_filter_index_s;
  logic [                  7:0] s_prach_f_s;
  logic [                  3:0] s_prach_sf_s;
  logic [                  5:0] s_prach_sl_s;
  logic [                  5:0] s_prach_sy_s;
  logic [                 15:0] s_prach_time_offset_s;
  logic [                  7:0] s_prach_frame_structure_s;
  logic [                 15:0] s_prach_cp_length_s;
  logic [                  7:0] s_prach_udcomphdr_s;
  logic                         s_prach_rb_s;
  logic                         s_prach_syminc_s;
  logic [                  9:0] s_prach_start_prbc_s;
  logic [                  7:0] s_prach_num_prbc_s;
  logic [                 11:0] s_prach_remask_s;
  logic [                  3:0] s_prach_num_symbol_s;
  logic [                 14:0] s_prach_beamid_s;
  logic [                 23:0] s_prach_freqoffset_s;

  // Calculated values

  logic [                  8:0] c_start_symbol;
  logic [                 18:0] c_start_sample;
  logic [                  3:0] c_num_symbol;
  logic [                 17:0] c_fcw;

  logic                         c_plane_match;
  logic                         prach_src_ready;
  logic                         static_c_en;
  logic [                  8:0] static_symbol_base;
  logic [                 18:0] static_sample_offset;
  logic [                 18:0] prach_sample_offset;
  logic [                  1:0] unused_ctrl_rat_lsb;
  logic [                  5:0] unused_ctrl_slot_id_msb;

  // Control CDC

  // Pack all control signals into a single wide bus
  assign ctrl_combined = {
    ctrl_rat,
    ctrl_static_c,
    ctrl_subframe_inc,
    ctrl_subframe_id,
    ctrl_slot_id,
    ctrl_symbol_id,
    ctrl_time_offset,
    ctrl_cp_length,
    ctrl_num_symbol,
    ctrl_freq_offset,
    ctrl_sampling_offset
  };

  // Single CDC for all control signals
  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (CtrlSignalWidth)
  ) i_cdc_ctrl_signals (
      .src_clk (1'b1),
      .src_in  (ctrl_combined),
      .dest_clk(clk),
      .dest_out(ctrl_combined_s)
  );

  // Unpack the combined signals
  assign {
    ctrl_rat_s,
    ctrl_static_c_s,
    ctrl_subframe_inc_s,
    ctrl_subframe_id_s,
    ctrl_slot_id_s,
    ctrl_symbol_id_s,
    ctrl_time_offset_s,
    ctrl_cp_length_s,
    ctrl_num_symbol_s,
    ctrl_freq_offset_s,
    ctrl_sampling_offset_s
  } = ctrl_combined_s;

  // CDC for PRACH signals using handshake
  // Combine all s_prach_* signals into a single wide bus for efficient CDC crossing

  // Pack all s_prach signals into a single wide bus
  assign s_prach_combined = {
    s_prach_rtc_pc_id,
    s_prach_cc,
    s_prach_ss,
    s_prach_section_id,
    s_prach_return_port,
    s_prach_filter_index,
    s_prach_f,
    s_prach_sf,
    s_prach_sl,
    s_prach_sy,
    s_prach_time_offset,
    s_prach_frame_structure,
    s_prach_cp_length,
    s_prach_udcomphdr,
    s_prach_rb,
    s_prach_syminc,
    s_prach_start_prbc,
    s_prach_num_prbc,
    s_prach_remask,
    s_prach_num_symbol,
    s_prach_beamid,
    s_prach_freqoffset
  };

  // CDC handshake for all PRACH signals
  cdc_handshake_f #(
      .DEST_EXT_HSK(1'b0),
      .DEST_SYNC_FF(2),
      .INIT_SYNC_FF(1'b1),
      .SRC_SYNC_FF (2),
      .WIDTH       (PrachSignalWidth)
  ) i_cdc_prach_signals (
      .src_clk   (clk_eth_xran),
      .src_in    (s_prach_combined),
      .src_valid (s_prach_tvalid),
      //
      .dest_clk  (clk),
      .dest_out  (s_prach_combined_s),
      .dest_valid(s_prach_tvalid_s),
      .dest_ready(1'b1),
      .src_ready (prach_src_ready)
  );

  // Unpack the combined signals
  assign {
    s_prach_rtc_pc_id_s,
    s_prach_cc_s,
    s_prach_ss_s,
    s_prach_section_id_s,
    s_prach_return_port_s,
    s_prach_filter_index_s,
    s_prach_f_s,
    s_prach_sf_s,
    s_prach_sl_s,
    s_prach_sy_s,
    s_prach_time_offset_s,
    s_prach_frame_structure_s,
    s_prach_cp_length_s,
    s_prach_udcomphdr_s,
    s_prach_rb_s,
    s_prach_syminc_s,
    s_prach_start_prbc_s,
    s_prach_num_prbc_s,
    s_prach_remask_s,
    s_prach_num_symbol_s,
    s_prach_beamid_s,
    s_prach_freqoffset_s
  } = s_prach_combined_s;

  generate
    if (ANT_ID == 0) begin : g_c_plane_match_ant0
      assign c_plane_match = s_prach_tvalid_s && (4'(CC_ID) == s_prach_cc_s) &&
                             (s_prach_ss_s < 8'(NUM_ANT));
    end else begin : g_c_plane_match_antn
      assign c_plane_match = s_prach_tvalid_s && (4'(CC_ID) == s_prach_cc_s) &&
                             (s_prach_ss_s >= 8'(ANT_ID)) && (s_prach_ss_s < 8'(ANT_ID + NUM_ANT));
    end
  endgenerate
  assign static_c_en = |ctrl_static_c_s;
  assign static_symbol_base = 9'(ctrl_subframe_id_s) + 9'(ctrl_subframe_inc_s);
  assign prach_sample_offset = 19'(s_prach_time_offset_s) - 19'(ctrl_sampling_offset_s);
  assign static_sample_offset = 19'(ctrl_time_offset_s) - 19'(ctrl_sampling_offset_s);
  assign unused_ctrl_rat_lsb = {ctrl_rat_s[0], 1'b0};
  assign unused_ctrl_slot_id_msb = {ctrl_slot_id_s[5:1], 1'b0};

  // Start Symbol ID from C-Plane

  always_ff @(posedge clk) begin
    if (c_plane_match) begin
      if (ctrl_rat_s[1] == 1'b0) begin  // 15 kHz SCS
        c_start_symbol <= s_prach_sf_s * 14;
      end else begin  // 30 kHz SCS
        c_start_symbol <= s_prach_sf_s * 28 + s_prach_sl_s[0] * 14;
      end
    end
  end

  // O-RAN.WG4.CUS.0-v10.00 4.3.3
  // Start sample point in Ts, from C-Plane

  // Preamble Format 0: T_CP = 3168 Ts, T_SEQ = 24576 Ts, T_GP = 2976 Ts, 1 ms in total
  // Preamble Format 1: T_CP = 21024 Ts, T_SEQ = 24576 Ts (2x), T_GP = 21984 Ts, 3 ms in total
  //
  // Ts = 1/30.72e6

  always_ff @(posedge clk) begin
    if (c_plane_match) begin
      if (s_prach_cp_length_s == '0) begin
        if (s_prach_num_symbol_s == 1) begin  // F0
          if (s_prach_time_offset_s == 0) begin
            c_start_sample <= 19'd3168 + prach_sample_offset;
          end else begin
            c_start_sample <= prach_sample_offset;
          end
        end else begin  // F1
          if (s_prach_time_offset_s == 0) begin
            c_start_sample <= 19'd21024 + prach_sample_offset;
          end else begin
            c_start_sample <= prach_sample_offset;
          end
        end
      end else begin
        c_start_sample <= 19'(s_prach_cp_length_s) + prach_sample_offset;
      end
    end
  end

  // Number of symbol, F0 = 1, F1 = 2
  always_ff @(posedge clk) begin
    if (c_plane_match) begin
      c_num_symbol <= s_prach_num_symbol_s;
    end
  end

  // C-Plane freqOffset is in solution of 0.625kHz (1/2 of f_RE) and refer to
  // from the "center of channel" to the lowest of RE. The FCW value should be:
  //   FCW = - (freqOffset + nRE), which nRE = 864 for PRACH
  //
  //
  //   |    freqOffset (negative)    |
  //   | <---------------------------+                              |
  //   |--->|                     Channel                           |
  //   |  PRACH  |

  always_ff @(posedge clk) begin
    if (c_plane_match) begin
      c_fcw <= get_fcw(s_prach_freqoffset_s);
    end
  end

  // Static C-Plane

  always_ff @(posedge clk) begin
    if (static_c_en) begin
      if (ctrl_rat_s[1] == 1'b0) begin  // 15 kHz SCS
        rd_start_symbol0 <= 9'(ctrl_subframe_id_s) * 9'd14;
        rd_start_symbol1 <= static_symbol_base * 9'd14;
      end else begin  // 30 kHz SCS
        rd_start_symbol0 <= 9'(ctrl_subframe_id_s) * 9'd28 + {8'd0, ctrl_slot_id_s[0]} * 9'd14;
        rd_start_symbol1 <= static_symbol_base * 9'd28 + {8'd0, ctrl_slot_id_s[0]} * 9'd14;
      end
    end else begin
      rd_start_symbol0 <= c_start_symbol;
      rd_start_symbol1 <= c_start_symbol;
    end
  end

  always_ff @(posedge clk) begin
    if (static_c_en) begin
      if (ctrl_cp_length_s == '0) begin
        if (ctrl_num_symbol_s <= 1) begin  // F0
          if (ctrl_time_offset_s == '0) begin
            rd_start_sample <= 19'd3168 + static_sample_offset;
          end else begin
            rd_start_sample <= static_sample_offset;
          end
        end else begin  // F1
          if (ctrl_time_offset_s == '0) begin
            rd_start_sample <= 19'd21024 + static_sample_offset;
          end else begin
            rd_start_sample <= static_sample_offset;
          end
        end
      end else begin
        rd_start_sample <= 19'(ctrl_cp_length_s) + static_sample_offset;
      end
    end else begin
      rd_start_sample <= c_start_sample;
    end
  end

  always_ff @(posedge clk) begin
    if (static_c_en) begin
      rd_num_symbol <= ctrl_num_symbol_s;
    end else begin
      rd_num_symbol <= c_num_symbol;
    end
  end

  always_ff @(posedge clk) begin
    if (static_c_en) begin
      rd_fcw <= get_fcw(ctrl_freq_offset_s);
    end else begin
      rd_fcw <= c_fcw;
    end
  end

  always_ff @(posedge clk) begin
    if (static_c_en) begin
      rd_section_id <= 12'd2048;
    end else begin
      rd_section_id <= s_prach_section_id_s;
    end
  end

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_ant

      always_ff @(posedge clk) begin
        if (rst) begin
          rd_channel_req[i] <= 1'b0;
        end else if (static_c_en) begin
          rd_channel_req[i] <= 1'b1;
        end else if (s_prach_tvalid_s && (4'(CC_ID) == s_prach_cc_s) && (8'(ANT_ID + i) == s_prach_ss_s)) begin
          rd_channel_req[i] <= 1'b1;
        end else if (rd_channel_ack[i]) begin
          rd_channel_req[i] <= 1'b0;
        end
      end

    end
  endgenerate

  // Report C-Plane
  //---------------

  always_ff @(posedge clk) begin
    if (c_plane_match) begin
      stat_subframe_id_r <= s_prach_sf_s;
      stat_slot_id_r     <= s_prach_sl_s;
      stat_symbol_id_r   <= s_prach_sy_s;
      //
      stat_time_offset_r <= s_prach_time_offset_s;
      stat_cp_length_r   <= s_prach_cp_length_s;
      //
      stat_num_symbol_r  <= s_prach_num_symbol_s;
      stat_freq_offset_r <= s_prach_freqoffset_s;
    end
  end

  // CDC for status signals back to ctrl_clk domain
  // Combine all status signals into a single CDC crossing
  assign stat_combined_r = {
    stat_freq_offset_r,
    stat_num_symbol_r,
    stat_cp_length_r,
    stat_time_offset_r,
    stat_symbol_id_r,
    stat_slot_id_r,
    stat_subframe_id_r
  };

  // Single CDC instance for all status signals
  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (76)
  ) i_cdc_stat_combined (
      .src_clk (1'b1),
      .src_in  (stat_combined_r),
      .dest_clk(ctrl_clk),
      .dest_out(stat_combined)
  );

  assign {
    stat_freq_offset ,
    stat_num_symbol  ,
    stat_cp_length   ,
    stat_time_offset ,
    stat_symbol_id   ,
    stat_slot_id     ,
    stat_subframe_id
  } = stat_combined;

  wire unused_ctrl = &{
    1'b0,
    rst_eth_xran,
    ctrl_rst,
    ctrl_symbol_id_s,
    s_prach_rtc_pc_id_s,
    s_prach_return_port_s,
    s_prach_filter_index_s,
    s_prach_f_s,
    s_prach_frame_structure_s,
    s_prach_udcomphdr_s,
    s_prach_rb_s,
    s_prach_syminc_s,
    s_prach_start_prbc_s,
    s_prach_num_prbc_s,
    s_prach_remask_s,
    s_prach_beamid_s,
    unused_ctrl_rat_lsb,
    unused_ctrl_slot_id_msb,
    prach_src_ready
  };

endmodule

`default_nettype wire
