`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_reshape #(
    parameter int SIZE = 8
) (
    input var         clk,
    /* verilator lint_off UNUSED */
    input var         rst,
    /* verilator lint_on UNUSED */
    //
    input var  [15:0] din_dp1,
    input var  [15:0] din_dp2,
    input var         din_sf,
    input var         din_sl,
    input var         din_sy,
    input var  [ 7:0] din_chn,
    input var         din_dv,
    input var         din_last,
    //
    output var [15:0] dout_dq1,
    output var [15:0] dout_dq2,
    output var        dout_sf,
    output var        dout_sl,
    output var        dout_sy,
    output var [ 7:0] dout_chn,
    output var        dout_dv,
    output var        dout_last
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
      .DEPTH(SIZE / 2)
  ) u_delay_dq2 (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din ({din_dp2}),
      .dout({din_dp2_d})
  );

  delay #(
      .WIDTH(16),
      .DEPTH(SIZE / 2)
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
      .DEPTH(Latency)
  ) u_delay_sync (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din ({din_last, din_dv, din_chn, din_sy, din_sl, din_sf}),
      .dout({dout_last, dout_dv, dout_chn, dout_sy, dout_sl, dout_sf})
  );

endmodule

`default_nettype wire
