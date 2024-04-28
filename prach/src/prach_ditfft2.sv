`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_ditfft2 #(
    parameter int NUM_FFT_LENGTH = 6,
    parameter bit SCALE          = 0
) (
    input var         clk,
    input var         rst_n,
    //
    input var  [17:0] din_dr,
    input var  [17:0] din_di,
    input var         din_dv,
    input var         sync_in,
    input var         din_dv_ahead,
    input var         sync_ahead_in,
    //
    output var [17:0] dout_dr,
    output var [17:0] dout_di,
    output var        dout_dv,
    output var        sync_out,
    output var        dout_dv_ahead,
    output var        sync_ahead_out
);

  logic [17:0] s0_dr;
  logic [17:0] s0_di;
  logic        s0_dv;
  logic        s0_sync;
  logic        s0_dv_ahead;
  logic        s0_sync_ahead;

  prach_ditfft2_twiddler #(
      .NUM_FFT_LENGTH(NUM_FFT_LENGTH)
  ) u_twiddler (
      .clk           (clk),
      .rst_n         (rst_n),
      //
      .din_dr        (din_dr),
      .din_di        (din_di),
      .din_dv        (din_dv),
      .sync_in       (sync_in),
      .din_dv_ahead  (din_dv_ahead),
      .sync_ahead_in (sync_ahead_in),
      //
      .dout_dr       (s0_dr),
      .dout_di       (s0_di),
      .dout_dv       (s0_dv),
      .sync_out      (s0_sync),
      .dout_dv_ahead (s0_dv_ahead),
      .sync_ahead_out(s0_sync_ahead)
  );

  prach_ditfft2_bf #(
      .NUM_FFT_LENGTH(NUM_FFT_LENGTH),
      .SCALE         (SCALE)
  ) u_bf (
      .clk           (clk),
      .rst_n         (rst_n),
      //
      .din_dr        (s0_dr),
      .din_di        (s0_di),
      .din_dv        (s0_dv),
      .sync_in       (s0_sync),
      .din_dv_ahead  (s0_dv_ahead),
      .sync_ahead_in (s0_sync_ahead),
      //
      .dout_dr       (dout_dr),
      .dout_di       (dout_di),
      .dout_dv       (dout_dv),
      .sync_out      (sync_out),
      .dout_dv_ahead (dout_dv_ahead),
      .sync_ahead_out(sync_ahead_out)
  );

endmodule

`default_nettype wire
