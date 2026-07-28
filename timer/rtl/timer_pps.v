`timescale 1 ns / 1 ps
//
`default_nettype none

module timer_pps #(
    parameter integer FREQ_MODE = 0
) (
    input  wire clk,
    input  wire rst,
    //
    input  wire pps_in,
    //
    output reg  pps_out,
    output reg  pps_pad
);

  // Parameters

  localparam [15:0] TickPerPps = FREQ_MODE == 0 ? 16'd20000 : 16'd24576;

  // Signals

  reg        pps_d;

  reg [ 3:0] pps_ext0;
  reg [15:0] pps_ext1;

  // Main

  always @(posedge clk) begin
    pps_d <= pps_in;
  end

  // Expand pps pulse to 16-clock width, this ensures all clocks could see the
  // pps pulse

  always @(posedge clk) begin
    if (pps_out) begin
      pps_ext0 <= pps_ext0 + 1'd1;
    end else if (&pps_ext0) begin
      pps_ext0 <= 'd0;
    end else begin
      pps_ext0 <= 'd0;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      pps_out <= 1'b0;
    end else if (pps_d) begin
      pps_out <= 1'b1;
    end else if (&pps_ext0) begin
      pps_out <= 1'b0;
    end
  end

  // Extend pps pulse to make it wide enough, this generate 500us pulse on
  // 491.52 MHz clock

  always @(posedge clk) begin
    if (pps_pad) begin
      pps_ext1 <= pps_ext1 + 1'd1;
    end else if (pps_ext1 == TickPerPps - 1) begin
      pps_ext1 <= 'd0;
    end else begin
      pps_ext1 <= 'd0;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      pps_pad <= 1'b0;
    end else if (pps_d) begin
      pps_pad <= 1'b1;
    end else if (pps_ext1 == TickPerPps - 1) begin
      pps_pad <= 1'b0;
    end
  end

endmodule

`default_nettype wire
