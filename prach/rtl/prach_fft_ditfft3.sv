`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_fft_ditfft3 #(
    parameter int DATA_WIDTH = 18
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

  /* verilator lint_off UNUSED */
  localparam int FftSize = 3;
  localparam int Latency = 9;  // 2 + 5 + 2
  /* verilator lint_on UNUSED */

  logic signed [DATA_WIDTH-1:0] s0_dr;
  logic signed [DATA_WIDTH-1:0] s0_di;
  logic                         s0_dv;
  logic                         s0_ovf;

  logic signed [DATA_WIDTH-1:0] s1_dr;
  logic signed [DATA_WIDTH-1:0] s1_di;
  logic                         s1_dv;
  logic                         s1_ovf;

  logic signed [DATA_WIDTH-1:0] s2_dr;
  logic signed [DATA_WIDTH-1:0] s2_di;
  logic                         s2_dv;
  logic                         s2_ovf;

  prach_fft_ditfft3_bf1 #(
      .DATA_WIDTH(DATA_WIDTH)
  ) i_bf1 (
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

  prach_fft_ditfft3_bf2 #(
      .DATA_WIDTH(DATA_WIDTH)
  ) i_bf2 (
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

  prach_fft_ditfft3_bf3 #(
      .DATA_WIDTH(DATA_WIDTH)
  ) i_bf3 (
      .clk    (clk),
      .rst    (rst),
      //
      .din_dr (s1_dr),
      .din_di (s1_di),
      .din_dv (s1_dv),
      //
      .dout_dr(s2_dr),
      .dout_di(s2_di),
      .dout_dv(s2_dv),
      //
      .ovf    (s2_ovf)
  );

  assign dout_dr = s2_dr;
  assign dout_di = s2_di;
  assign dout_dv = s2_dv;
  assign ovf     = s0_ovf | s1_ovf | s2_ovf;

endmodule

`default_nettype wire
