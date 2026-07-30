`timescale 1 ns / 1 ps
//
`default_nettype none

module timer_syncer_390p625 #(
    parameter reg SIM_SPEEDUP = 1'b0
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        pps_in,
    //
    input  wire [47:0] tod_sec,
    input  wire [31:0] tod_ns,
    //
    input  wire        eth_clk,
    input  wire        eth_rst,
    //
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    output wire [79:0] ctl_systemtimer,
    //
    output wire [31:0] stat_resync_cnt
);

  // Parameters

  localparam [31:0] NanosecondsPerSecond = SIM_SPEEDUP ? 32'd1_000_000 : 32'd1_000_000_000;

  // Signals

  reg  [47:0] second_counter;  // 48-bit second counter
  reg  [31:0] nanosecond_counter;  // 32-bit nanosecond counter
  reg  [ 4:0] nanosecond_frac;  // 5-bit nanosecond fraction

  wire [47:0] second_counter_next;
  wire [31:0] nanosecond_counter_next;
  wire [ 4:0] nanosecond_frac_next;

  wire        nanosecond_counter_wrap;
  wire [31:0] nanosecond_counter_inc;
  wire [ 4:0] nanosecond_frac_inc;

  wire        sync_pulse;

  wire        pps_sync_eth;
  wire [47:0] tod_sec_eth;
  wire [31:0] tod_ns_eth;

  reg  [31:0] stat_resync_cnt_r;

  wire cdc_pps_sync_rx_src_ready;
  wire unused_inputs = &{1'b0, rst, ctrl_rst, cdc_pps_sync_rx_src_ready, 1'b0};

  // Main

  assign ctl_systemtimer = {second_counter, nanosecond_counter};

  // Timer for eth_clk

  always @(posedge eth_clk) begin
    if (eth_rst) begin
      second_counter     <= 48'd0;
      nanosecond_counter <= 32'd0;
      nanosecond_frac    <= 5'd0;
    end else begin
      second_counter     <= second_counter_next;
      nanosecond_counter <= nanosecond_counter_next;
      nanosecond_frac    <= nanosecond_frac_next;
    end
  end

  // Load the secound/nanosecond counter when input ToD is updated,
  // second counter is only updated by pps_in, nanosecond counter is updated by
  // pps_in and self increase

  assign second_counter_next = sync_pulse ? tod_sec_eth : second_counter;

  assign nanosecond_counter_next = sync_pulse ? tod_ns_eth : nanosecond_counter_inc;

  assign nanosecond_frac_next = sync_pulse ? 5'd0 : nanosecond_frac_inc;

  // 0 ~ 24
  assign nanosecond_frac_inc = (nanosecond_frac == 5'd24) ? 5'd0 : nanosecond_frac + 5'd1;

  // Stop the nanosecond counter when it is about to wrap, so it will not be
  // equal or larger than 1e9
  assign nanosecond_counter_wrap = (
    nanosecond_counter == NanosecondsPerSecond - 3 ||
    nanosecond_counter == NanosecondsPerSecond - 2 ||
    nanosecond_counter == NanosecondsPerSecond - 1);

  // Nanosecond counter increaes 2.56 at each tick, which is 2 or 3
  // Which is 64 in 25 clock ticks, 3 for 14 of them, and 2 for 11 of them
  assign nanosecond_counter_inc = nanosecond_counter_wrap ? nanosecond_counter :
    nanosecond_counter + ((
      nanosecond_frac == 5'd0 ||
      nanosecond_frac == 5'd2 ||
      nanosecond_frac == 5'd4 ||
      nanosecond_frac == 5'd6 ||
      nanosecond_frac == 5'd8 ||
      nanosecond_frac == 5'd9 ||
      nanosecond_frac == 5'd11 ||
      nanosecond_frac == 5'd13 ||
      nanosecond_frac == 5'd15 ||
      nanosecond_frac == 5'd16 ||
      nanosecond_frac == 5'd17 ||
      nanosecond_frac == 5'd19 ||
      nanosecond_frac == 5'd21 ||
      nanosecond_frac == 5'd23
    ) ? 32'd3 : 32'd2);

  always @(posedge eth_clk) begin
    if (eth_rst) begin
      stat_resync_cnt_r <= 32'd0;
    end else if (pps_sync_eth && !nanosecond_counter_wrap) begin
      stat_resync_cnt_r <= stat_resync_cnt_r + 32'd1;
    end
  end

  // Sync between `eth_clk` and `clk`

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .SRC_SYNC_FF (4),
      .WIDTH       (81)
  ) i_cdc_pps_sync_rx (
      .src_clk   (clk),
      .src_in    ({pps_in, tod_sec, tod_ns}),
      .src_valid (1'b1),
      .src_ready (cdc_pps_sync_rx_src_ready),
      //
      .dest_clk  (eth_clk),
      .dest_out  ({pps_sync_eth, tod_sec_eth, tod_ns_eth}),
      .dest_valid(sync_pulse),
      .dest_ready(1'b1)
  );

  // Status CDC

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (32)
  ) i_cdc_stat_resync_cnt (
      .src_clk (1'b1),
      .src_in  (stat_resync_cnt_r),
      //
      .dest_clk(ctrl_clk),
      .dest_out(stat_resync_cnt)
  );

endmodule

`default_nettype wire
