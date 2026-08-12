`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_fft_ditfft2 #(
    parameter int FFT_SIZE   = 4,
    parameter int DATA_WIDTH = 18,
    parameter int SCALE      = 0
) (
    input var                          clk,
    input var                          rst,
    //
    input var  signed [DATA_WIDTH-1:0] din_dr,
    input var  signed [DATA_WIDTH-1:0] din_di,
    input var                          din_dv,
    //
    output var signed [DATA_WIDTH-1:0] dout_dr,
    output var signed [DATA_WIDTH-1:0] dout_di,
    output var                         dout_dv,
    //
    output var                         ovf
);

  logic signed [DATA_WIDTH-1:0] s0_dr;
  logic signed [DATA_WIDTH-1:0] s0_di;
  logic                         s0_dv;
  logic                         s0_ovf;

  logic signed [DATA_WIDTH-1:0] s1_dr;
  logic signed [DATA_WIDTH-1:0] s1_di;
  logic                         s1_dv;
  logic                         s1_ovf;

  prach_fft_ditfft2_twiddler #(
      .FFT_SIZE  (FFT_SIZE),
      .DATA_WIDTH(DATA_WIDTH),
      .SCALE     (SCALE)
  ) u_twiddler (
      .clk    (clk),
      .rst    (rst),
      //
      .din_dr (din_dr),
      .din_di (din_di),
      .din_dv (din_dv),
      //
      .dout_dr(s0_dr),
      .dout_di(s0_di),
      .dout_dv(s0_dv),
      //
      .ovf    (s0_ovf)
  );

  prach_fft_ditfft2_bf #(
      .FFT_SIZE  (FFT_SIZE),
      .DATA_WIDTH(DATA_WIDTH)
  ) u_bf (
      .clk    (clk),
      .rst    (rst),
      //
      .din_dr (s0_dr),
      .din_di (s0_di),
      .din_dv (s0_dv),
      //
      .dout_dr(s1_dr),
      .dout_di(s1_di),
      .dout_dv(s1_dv),
      //
      .ovf    (s1_ovf)
  );

  assign dout_dr = s1_dr;
  assign dout_di = s1_di;
  assign dout_dv = s1_dv;
  assign ovf     = s0_ovf | s1_ovf;

endmodule

`default_nettype wire
