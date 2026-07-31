/*
 * eCPRI Interface Statistics Counters
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_statistics (
    input  wire        clk,
    input  wire        rst,
    // Deframer ports
    input  wire        m_mac_header_valid,
    input  wire [47:0] m_mac_dest_mac,
    input  wire [47:0] m_mac_source_mac,
    input  wire        m_mac_with_vlan,
    input  wire [15:0] m_mac_vlan_tag,
    input  wire [15:0] m_mac_ethertype,
    //
    input  wire        m_ecpri_header_valid,
    input  wire        m_ecpri_concat,
    input  wire [ 7:0] m_ecpri_messagetype,
    input  wire [15:0] m_ecpri_payloadsize,
    //
    input  wire        m_trans_header_valid,
    input  wire [15:0] m_trans_rtc_pc_id,
    input  wire [ 7:0] m_trans_seqid,
    input  wire        m_trans_ebit,
    input  wire [ 6:0] m_trans_subseqid,
    //
    input  wire        m_odm_header_valid,
    input  wire [ 7:0] m_odm_measurementid,
    input  wire [ 7:0] m_odm_actiontype,
    input  wire [79:0] m_odm_timestamp,
    input  wire [63:0] m_odm_compensation,
    input  wire [79:0] m_odm_timestamp2,
    // Framer ports
    input  wire        s_trans_header_valid,
    input  wire [ 7:0] s_trans_messagetype,
    input  wire [15:0] s_trans_payloadsize,
    input  wire [15:0] s_trans_rtc_pc_id,
    //
    input  wire        s_odm_header_valid,
    input  wire [ 7:0] s_odm_measurementid,
    input  wire [ 7:0] s_odm_actiontype,
    input  wire [79:0] s_odm_timestamp,
    input  wire [63:0] s_odm_compensation,
    // Control & Status
    //-----------------
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    input  wire        ctrl_tick_snap,
    input  wire        ctrl_tick_clear,
    //
    output wire [31:0] stat_defm_total_pkt_cnt,
    output wire [31:0] stat_defm_ecpri_pkt_cnt,
    output wire [31:0] stat_defm_trans_pkt_cnt,
    output wire [31:0] stat_defm_odm_pkt_cnt,
    //
    output wire [31:0] stat_fram_total_pkt_cnt,
    output wire [31:0] stat_fram_ecpri_pkt_cnt,
    output wire [31:0] stat_fram_trans_pkt_cnt,
    output wire [31:0] stat_fram_odm_pkt_cnt
);

  wire unused_statistics_inputs = &{1'b0,
    m_mac_dest_mac, m_mac_source_mac, m_mac_with_vlan, m_mac_vlan_tag, m_mac_ethertype,
    m_ecpri_concat, m_ecpri_messagetype, m_ecpri_payloadsize,
    m_trans_rtc_pc_id, m_trans_seqid, m_trans_ebit, m_trans_subseqid,
    m_odm_measurementid, m_odm_actiontype, m_odm_timestamp, m_odm_compensation,
    m_odm_timestamp2,
    s_trans_messagetype, s_trans_payloadsize, s_trans_rtc_pc_id,
    s_odm_measurementid, s_odm_actiontype, s_odm_timestamp, s_odm_compensation
  };

  // Signals

  wire tick_snap;
  wire tick_clear;
  wire [5:0] unused_stat_src_ready;
  wire [5:0] unused_stat_dest_valid;

  logic [31:0] defm_total_pkt_cnt;
  logic [31:0] defm_ecpri_pkt_cnt;
  logic [31:0] defm_trans_pkt_cnt;
  logic [31:0] defm_odm_pkt_cnt;

  logic [31:0] fram_trans_pkt_cnt;
  logic [31:0] fram_odm_pkt_cnt;

  // Control CDC

  cdc_pulse #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .REG_OUTPUT  (1),
      .RST_USED    (1)
  ) i_cdc_tick_snap (
      .src_clk   (ctrl_clk),
      .src_rst   (ctrl_rst),
      .src_pulse (ctrl_tick_snap),
      //
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(tick_snap)
  );

  cdc_pulse #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .REG_OUTPUT  (1),
      .RST_USED    (1)
  ) i_cdc_tick_clear (
      .src_clk   (ctrl_clk),
      .src_rst   (ctrl_rst),
      .src_pulse (ctrl_tick_clear),
      //
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(tick_clear)
  );

  // Deframer total packet counter

  always_ff @(posedge clk) begin
    if (tick_clear) begin
      defm_total_pkt_cnt <= 0;
    end else if (m_mac_header_valid) begin
      defm_total_pkt_cnt <= defm_total_pkt_cnt + 1'd1;
    end
  end

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .SRC_SYNC_FF (4),
      .WIDTH       (32)
  ) i_cdc_defm_total_pkt_cnt (
      .src_clk   (clk),
      .src_in    (defm_total_pkt_cnt),
      .src_valid (tick_snap),
      .src_ready (unused_stat_src_ready[0]),
      //
      .dest_clk  (ctrl_clk),
      .dest_out  (stat_defm_total_pkt_cnt),
      .dest_valid(unused_stat_dest_valid[0]),
      .dest_ready(1'b1)
  );

  // Deframer eCPRI packet counter

  always_ff @(posedge clk) begin
    if (tick_clear) begin
      defm_ecpri_pkt_cnt <= 0;
    end else if (m_ecpri_header_valid) begin
      defm_ecpri_pkt_cnt <= defm_ecpri_pkt_cnt + 1'd1;
    end
  end

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .SRC_SYNC_FF (4),
      .WIDTH       (32)
  ) i_cdc_defm_ecpri_pkt_cnt (
      .src_clk   (clk),
      .src_in    (defm_ecpri_pkt_cnt),
      .src_valid (tick_snap),
      .src_ready (unused_stat_src_ready[1]),
      //
      .dest_clk  (ctrl_clk),
      .dest_out  (stat_defm_ecpri_pkt_cnt),
      .dest_valid(unused_stat_dest_valid[1]),
      .dest_ready(1'b1)
  );

  // Deframer Trans packet counter

  always_ff @(posedge clk) begin
    if (tick_clear) begin
      defm_trans_pkt_cnt <= 0;
    end else if (m_trans_header_valid) begin
      defm_trans_pkt_cnt <= defm_trans_pkt_cnt + 1'd1;
    end
  end

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .SRC_SYNC_FF (4),
      .WIDTH       (32)
  ) i_cdc_defm_trans_pkt_cnt (
      .src_clk   (clk),
      .src_in    (defm_trans_pkt_cnt),
      .src_valid (tick_snap),
      .src_ready (unused_stat_src_ready[2]),
      //
      .dest_clk  (ctrl_clk),
      .dest_out  (stat_defm_trans_pkt_cnt),
      .dest_valid(unused_stat_dest_valid[2]),
      .dest_ready(1'b1)
  );

  // Deframer One-Way Delay Measurement packet counter

  always_ff @(posedge clk) begin
    if (tick_clear) begin
      defm_odm_pkt_cnt <= 0;
    end else if (m_odm_header_valid) begin
      defm_odm_pkt_cnt <= defm_odm_pkt_cnt + 1'd1;
    end
  end

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .SRC_SYNC_FF (4),
      .WIDTH       (32)
  ) i_cdc_defm_odm_pkt_cnt (
      .src_clk   (clk),
      .src_in    (defm_odm_pkt_cnt),
      .src_valid (tick_snap),
      .src_ready (unused_stat_src_ready[3]),
      //
      .dest_clk  (ctrl_clk),
      .dest_out  (stat_defm_odm_pkt_cnt),
      .dest_valid(unused_stat_dest_valid[3]),
      .dest_ready(1'b1)
  );

  // Framer total packet counter

  // FIXME: not implemented
  assign stat_fram_total_pkt_cnt = 0;

  // Framer eCPRI packet counter

  // FIXME: not implemented
  assign stat_fram_ecpri_pkt_cnt = 0;

  // Framer Trans packet counter

  always_ff @(posedge clk) begin
    if (tick_clear) begin
      fram_trans_pkt_cnt <= 0;
    end else if (s_trans_header_valid) begin
      fram_trans_pkt_cnt <= fram_trans_pkt_cnt + 1'd1;
    end
  end

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .SRC_SYNC_FF (4),
      .WIDTH       (32)
  ) i_cdc_fram_trans_pkt_cnt (
      .src_clk   (clk),
      .src_in    (fram_trans_pkt_cnt),
      .src_valid (tick_snap),
      .src_ready (unused_stat_src_ready[4]),
      //
      .dest_clk  (ctrl_clk),
      .dest_out  (stat_fram_trans_pkt_cnt),
      .dest_valid(unused_stat_dest_valid[4]),
      .dest_ready(1'b1)
  );

  // Framer One-Way Delay Measurement packet counter

  always_ff @(posedge clk) begin
    if (tick_clear) begin
      fram_odm_pkt_cnt <= 0;
    end else if (s_odm_header_valid) begin
      fram_odm_pkt_cnt <= fram_odm_pkt_cnt + 1'd1;
    end
  end

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .SRC_SYNC_FF (4),
      .WIDTH       (32)
  ) i_cdc_fram_odm_pkt_cnt (
      .src_clk   (clk),
      .src_in    (fram_odm_pkt_cnt),
      .src_valid (tick_snap),
      .src_ready (unused_stat_src_ready[5]),
      //
      .dest_clk  (ctrl_clk),
      .dest_out  (stat_fram_odm_pkt_cnt),
      .dest_valid(unused_stat_dest_valid[5]),
      .dest_ready(1'b1)
  );

endmodule

`default_nettype wire
