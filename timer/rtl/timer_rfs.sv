`timescale 1 ns / 1 ps
//
`default_nettype none

module timer_rfs #(
    parameter integer FREQ_MODE = 0
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        pps_in,
    //
    output logic         rfs_out,
    output logic         rfs_pad,
    //
    input  wire [22:0] ctrl_rfs_offset
);

  // Parameters

  localparam [15:0] TickPerPulse = FREQ_MODE == 0 ? 16'd20000 : 16'd24576;

  localparam [22:0] TickPer10ms = FREQ_MODE == 0 ? 23'd4000000 : 23'd4915200;

  // Signals

  wire [22:0] ctrl_rfs_offset_s;

  logic  [22:0] counter;
  wire        counter_wrap;

  wire        rfs_pulse;

  logic  [ 3:0] rfs_ext0;
  logic  [15:0] rfs_ext1;

  // Control CDC

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (23)
  ) i_ctrl_cdc (
      .src_clk (1'b1),
      .src_in  (ctrl_rfs_offset),
      //
      .dest_clk(clk),
      .dest_out(ctrl_rfs_offset_s)
  );

  // Main

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= 23'd0;
    end else if (pps_in) begin
      counter <= 23'd0;
    end else begin
      counter <= counter_wrap ? 23'd0 : counter + 1'd1;
    end
  end

  assign counter_wrap = (counter == TickPer10ms - 1);

  assign rfs_pulse = (counter == ctrl_rfs_offset_s);

  // Expand pps pulse to 16-clock width, this ensures all clocks could see the
  // pps pulse

  always_ff @(posedge clk) begin
    if (rfs_out) begin
      rfs_ext0 <= rfs_ext0 + 1'd1;
    end else if (&rfs_ext0) begin
      rfs_ext0 <= 'd0;
    end else begin
      rfs_ext0 <= 'd0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rfs_out <= 1'b0;
    end else if (rfs_pulse) begin
      rfs_out <= 1'b1;
    end else if (&rfs_ext0) begin
      rfs_out <= 1'b0;
    end
  end

  // Extend pps pulse to make it wide enough, this generate 500us pulse on
  // 491.52 MHz clock

  always_ff @(posedge clk) begin
    if (rfs_pad) begin
      rfs_ext1 <= rfs_ext1 + 1'd1;
    end else if (rfs_ext1 == TickPerPulse - 1) begin
      rfs_ext1 <= 'd0;
    end else begin
      rfs_ext1 <= 'd0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rfs_pad <= 1'b0;
    end else if (rfs_pulse) begin
      rfs_pad <= 1'b1;
    end else if (rfs_ext1 == TickPerPulse - 1) begin
      rfs_pad <= 1'b0;
    end
  end

endmodule

`default_nettype wire
