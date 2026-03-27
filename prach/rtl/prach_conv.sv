`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_conv (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [15:0] din_dr,
    input  wire [15:0] din_di,
    input  wire        din_sf,
    input  wire        din_sl,
    input  wire        din_sy,
    input  wire [ 7:0] din_chn,
    input  wire        din_dv,
    input  wire        din_last,
    //
    output wire [15:0] dout_dr,
    output wire [15:0] dout_di,
    output wire        dout_sf,
    output wire        dout_sl,
    output wire        dout_sy,
    output wire [ 7:0] dout_chn,
    output wire        dout_dv,
    output wire        dout_last
);

  parameter int Latency = 11;

  logic signed [15:0] cos;
  logic signed [15:0] sin;

  logic        [15:0] din_dr_d;
  logic        [15:0] din_di_d;

  prach_conv_nco u_nco (
      .clk     (clk),
      .rst     (rst),
      //
      .sync_in (din_sf),
      //
      .dout_cos(cos),
      .dout_sin(sin),
      .dout_chn(),
      .sync_out()
  );

  delay #(
      .WIDTH(32),
      .DEPTH(4),
      .INIT (1'b0)
  ) u_dq_delay (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din ({din_di, din_dr}),
      .dout({din_di_d, din_dr_d})
  );

  cmult #(
      .A_WIDTH (16),
      .B_WIDTH (16),
      .P_WIDTH (16),
      .SHIFT   (14),
      //
      .ROUND   (1'b1),
      .SATURATE(1'b0)
  ) u_cmult (
      .clk(clk),
      .rst(rst),
      //
      .ar (din_dr_d),
      .ai (din_di_d),
      //
      .br (cos),
      .bi (sin),
      //
      .pr (dout_dr),
      .pi (dout_di),
      //
      .ovf()
  );

  delay #(
      .WIDTH(13),
      .DEPTH(Latency),
      .INIT (0)
  ) u_delay (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din ({din_last, din_dv, din_chn, din_sy, din_sl, din_sf}),
      .dout({dout_last, dout_dv, dout_chn, dout_sy, dout_sl, dout_sf})
  );

endmodule

`default_nettype wire
