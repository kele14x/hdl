`timescale 1 ns / 1 ps
//
`default_nettype none

module timer_core_400 #(
    parameter int SIM_SPEED_UP = 0
) (
    input  wire         clk,
    input  wire         rst,
    //
    input  wire         pps_in,
    output logic        pps_out,
    //
    output wire  [47:0] tod_sec,
    output wire  [31:0] tod_ns,
    //
    input  wire         ctrl_clk,
    input  wire         ctrl_rst,
    //
    input  wire         ctrl_rtc_offset_valid,
    input  wire  [31:0] ctrl_rtc_offset_ns,
    input  wire  [47:0] ctrl_rtc_offset_sec,
    //
    input  wire         ctrl_rtc_current_snap,
    //
    output wire  [31:0] stat_rtc_current_ns,
    output wire  [47:0] stat_rtc_current_sec
);

  // Note:
  // The clock frequency is 400 MHz, which is 2.5 ns per clock cycle.
  // The timer increments depending on the state, which is used to correct
  // for fractional error of the counter.

  // Parameters

  // 3'b101, ~= 2.5 ns
  localparam [32:0] TimerIncrement = 33'd5;

  localparam [31:0] NsPerSecond =
      ((SIM_SPEED_UP != 0) ? 32'd100_000 : 32'd1_000_000_000);

  wire unused_pps_in = pps_in;

  // The nanosecond counter value that is about to wrap
  localparam [31:0] IntTimerNsWrapConst = NsPerSecond - 3;

  // Signals

  logic [32:0] int_timer_ns_frac_reg;  // 32 bit ns, 1 bit frac
  wire int_timer_ns_frac_wrap;
  logic [47:0] int_timer_sec_reg;

  wire [31:0] int_timer_ns;
  wire [47:0] int_timer_sec;

  logic [31:0] timer_ns_pre;
  logic [47:0] timer_sec_pre;

  logic [31:0] timer_ns;
  wire timer_ns_carry;
  logic [47:0] timer_sec;

  logic timer_ns_wrap;
  logic timer_ns_wrap_d;

  // control & status

  wire rtc_current_snap;

  wire [31:0] rtc_offset_ns;
  wire [47:0] rtc_offset_sec;

  wire cdc_rtc_current_ns_src_ready;
  wire cdc_rtc_current_ns_dest_valid;
  wire cdc_rtc_current_sec_src_ready;
  wire cdc_rtc_current_sec_dest_valid;
  wire cdc_rtc_offset_ns_src_ready;
  wire cdc_rtc_offset_ns_dest_valid;
  wire cdc_rtc_offset_sec_src_ready;
  wire cdc_rtc_offset_sec_dest_valid;
  wire unused_cdc_outputs = &{1'b0, unused_pps_in, cdc_rtc_current_ns_src_ready, cdc_rtc_current_ns_dest_valid, cdc_rtc_current_sec_src_ready, cdc_rtc_current_sec_dest_valid, cdc_rtc_offset_ns_src_ready, cdc_rtc_offset_ns_dest_valid, cdc_rtc_offset_sec_src_ready, cdc_rtc_offset_sec_dest_valid, 1'b0};

  // Internal second and nanosecond counter
  // Which is free running, predictable counter

  always_ff @(posedge clk) begin
    if (rst) begin
      int_timer_ns_frac_reg <= 'd0;
    end else if (int_timer_ns_frac_wrap) begin
      int_timer_ns_frac_reg <= 'd0;
    end else begin
      int_timer_ns_frac_reg <= int_timer_ns_frac_reg + TimerIncrement;
    end
  end

  assign int_timer_ns_frac_wrap = (int_timer_ns_frac_reg[32:1] == IntTimerNsWrapConst);

  always_ff @(posedge clk) begin
    if (rst) begin
      int_timer_sec_reg <= 'd0;
    end else if (int_timer_ns_frac_wrap) begin
      int_timer_sec_reg <= int_timer_sec_reg + 1'd1;
    end
  end

  assign int_timer_ns  = int_timer_ns_frac_reg[32:1];
  assign int_timer_sec = int_timer_sec_reg;

  // Timer + offset = current time
  // We know that int_timer_ns < NsPerSecond, and rtc_offset_ns < NsPerSecond,
  // so timer_ns_pre < 2 * NsPerSecond. A single wrap check is sufficient.

  always_ff @(posedge clk) begin
    timer_ns_pre <= int_timer_ns + rtc_offset_ns;
  end

  always_ff @(posedge clk) begin
    timer_sec_pre <= int_timer_sec + rtc_offset_sec;
  end

  assign timer_ns_carry = (timer_ns_pre >= NsPerSecond);

  // Carry ns to sec to get the correct time

  always_ff @(posedge clk) begin
    if (timer_ns_carry) begin
      timer_ns <= timer_ns_pre - NsPerSecond;
    end else begin
      timer_ns <= timer_ns_pre;
    end
  end

  always_ff @(posedge clk) begin
    if (timer_ns_carry) begin
      timer_sec <= timer_sec_pre + 1'd1;
    end else begin
      timer_sec <= timer_sec_pre;
    end
  end

  assign tod_sec = timer_sec;
  assign tod_ns  = timer_ns;

  // PPS output

  always_ff @(posedge clk) begin
    timer_ns_wrap <= (timer_ns_pre >= IntTimerNsWrapConst);
  end

  always_ff @(posedge clk) begin
    timer_ns_wrap_d <= timer_ns_wrap;
  end

  always_ff @(posedge clk) begin
    // Rising edge of timer_ns_wrap
    pps_out <= timer_ns_wrap && ~timer_ns_wrap_d;
  end

  // CDC for getting current time

  cdc_pulse #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .REG_OUTPUT  (0),
      .RST_USED    (1)
  ) i_cdc_rtc_current_snap (
      .src_clk   (ctrl_clk),
      .src_rst   (ctrl_rst),
      .src_pulse (ctrl_rtc_current_snap),
      //
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(rtc_current_snap)
  );

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .SRC_SYNC_FF (4),
      .WIDTH       (32)
  ) i_cdc_rtc_current_ns (
      .src_clk   (clk),
      .src_in    (timer_ns),
      .src_valid (rtc_current_snap),
      .src_ready (cdc_rtc_current_ns_src_ready),
      //
      .dest_clk  (ctrl_clk),
      .dest_out  (stat_rtc_current_ns),
      .dest_valid(cdc_rtc_current_ns_dest_valid),
      .dest_ready(1'b1)
  );

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .SRC_SYNC_FF (4),
      .WIDTH       (48)
  ) i_cdc_rtc_current_sec (
      .src_clk   (clk),
      .src_in    (timer_sec),
      .src_valid (rtc_current_snap),
      .src_ready (cdc_rtc_current_sec_src_ready),
      //
      .dest_clk  (ctrl_clk),
      .dest_out  (stat_rtc_current_sec),
      .dest_valid(cdc_rtc_current_sec_dest_valid),
      .dest_ready(1'b1)
  );

  // CDC for setting RTC offset

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .SRC_SYNC_FF (4),
      .WIDTH       (32)
  ) i_cdc_rtc_offset_ns (
      .src_clk   (ctrl_clk),
      .src_in    (ctrl_rtc_offset_ns),
      .src_valid (ctrl_rtc_offset_valid),
      .src_ready (cdc_rtc_offset_ns_src_ready),
      //
      .dest_clk  (clk),
      .dest_out  (rtc_offset_ns),
      .dest_valid(cdc_rtc_offset_ns_dest_valid),
      .dest_ready(1'b1)
  );

  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .SRC_SYNC_FF (4),
      .WIDTH       (48)
  ) i_cdc_rtc_offset_sec (
      .src_clk   (ctrl_clk),
      .src_in    (ctrl_rtc_offset_sec),
      .src_valid (ctrl_rtc_offset_valid),
      .src_ready (cdc_rtc_offset_sec_src_ready),
      //
      .dest_clk  (clk),
      .dest_out  (rtc_offset_sec),
      .dest_valid(cdc_rtc_offset_sec_dest_valid),
      .dest_ready(1'b1)
  );

endmodule

`default_nettype wire
