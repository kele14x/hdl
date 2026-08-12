`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_conv (
    input var         clk,
    input var         rst,
    //
    input var  [15:0] din_dr,
    input var  [15:0] din_di,
    input var         din_sf,
    input var         din_sl,
    input var         din_sy,
    input var  [ 7:0] din_chn,
    input var         din_dv,
    input var         din_last,
    //
    output var [15:0] dout_dr,
    output var [15:0] dout_di,
    output var        dout_sf,
    output var        dout_sl,
    output var        dout_sy,
    output var [ 7:0] dout_chn,
    output var        dout_dv,
    output var        dout_last
);

  parameter int Latency = 11;

  logic signed [15:0] cos;
  logic signed [15:0] sin;

  logic        [15:0] din_dr_d;
  logic        [15:0] din_di_d;
  logic        [ 7:0] nco_dout_chn;
  logic               nco_sync_out;
  logic               cmult_ovf;

  prach_conv_nco u_nco (
      .clk     (clk),
      .rst     (rst),
      //
      .sync_in (din_sf),
      //
      .dout_cos(cos),
      .dout_sin(sin),
      .dout_chn(nco_dout_chn),
      .sync_out(nco_sync_out)
  );

  delay #(
      .WIDTH(32),
      .DEPTH(4),
      .INIT (0)
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
      .ROUND   (1),
      .SATURATE(0)
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
      .ovf(cmult_ovf)
      //
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

  wire unused_conv = &{1'b0, nco_dout_chn, nco_sync_out, cmult_ovf};

endmodule

`default_nettype wire
