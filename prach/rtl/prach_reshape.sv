`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_reshape #(
    parameter int SIZE = 8
) (
    input  wire         clk,
    input  wire         rst,
    //
    input  wire  [15:0] din_dp1,
    input  wire  [15:0] din_dp2,
    input  wire         din_sf,
    input  wire         din_sl,
    input  wire         din_sy,
    input  wire  [ 7:0] din_chn,
    input  wire         din_dv,
    input  wire         din_last,
    //
    output logic [15:0] dout_dq1,
    output logic [15:0] dout_dq2,
    output wire         dout_sf,
    output wire         dout_sl,
    output wire         dout_sy,
    output wire  [ 7:0] dout_chn,
    output wire         dout_dv,
    output wire         dout_last
);

  // x0s0s, x0s1s
  // x1s0s, x1s1s
  // =>
  // x0s0s, x1s0s
  // x0s1s, x1s1s

  localparam int Latency = SIZE / 2 + 1;

  logic        swap_n;

  logic [15:0] din_dp2_d;

  logic [15:0] delay_in;
  logic [15:0] delay_out;

  assign swap_n = din_chn[$clog2(SIZE/2)];

  delay #(
      .WIDTH(16),
      .DEPTH(SIZE / 2),
      .INIT (1'b0)
  ) u_delay_dq2 (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din ({din_dp2}),
      .dout({din_dp2_d})
  );

  delay #(
      .WIDTH(16),
      .DEPTH(SIZE / 2),
      .INIT (1'b0)
  ) u_delay_dx (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din (delay_in),
      .dout(delay_out)
  );

  always_ff @(posedge clk) begin
    dout_dq1 <= delay_out;
  end

  always_ff @(posedge clk) begin
    if (swap_n) begin
      dout_dq2 <= din_dp1;
    end else begin
      dout_dq2 <= din_dp2_d;
    end
  end

  always_comb begin
    if (swap_n) begin
      delay_in = din_dp2_d;
    end else begin
      delay_in = din_dp1;
    end
  end

  delay #(
      .WIDTH(13),
      .DEPTH(Latency),
      .INIT (1'b0)
  ) u_delay_sync (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din ({din_last, din_dv, din_chn, din_sy, din_sl, din_sf}),
      .dout({dout_last, dout_dv, dout_chn, dout_sy, dout_sl, dout_sf})
  );

  wire unused_reshape = &{1'b0, rst};

endmodule

`default_nettype wire
