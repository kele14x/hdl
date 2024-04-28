`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_ditfft3 (
    input var         clk,
    input var         rst_n,
    //
    input var  [17:0] din_dr,
    input var  [17:0] din_di,
    input var         din_dv,
    input var         sync_in,
    //
    output var [17:0] dout_dr,
    output var [17:0] dout_di,
    output var        dout_dv,
    output var        sync_out
);

  localparam int NumFftPoints = 3;
  localparam int Latency = 10;

  logic [17:0] s0_dr;
  logic [17:0] s0_di;
  logic        s0_dv;
  logic        s0_sync;

  logic [17:0] s1_dr;
  logic [17:0] s1_di;
  logic        s1_dv;
  logic        s1_sync;

  prach_ditfft3_bf1 i_bf1 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dr  (din_dr),
      .din_di  (din_di),
      .din_dv  (din_dv),
      .sync_in (sync_in),
      //
      .dout_dr (s0_dr),
      .dout_di (s0_di),
      .dout_dv (s0_dv),
      .sync_out(s0_sync)
  );

  prach_ditfft3_bf2 i_bf2 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dr  (s0_dr),
      .din_di  (s0_di),
      .din_dv  (s0_dv),
      .sync_in (s0_sync),
      //
      .dout_dr (s1_dr),
      .dout_di (s1_di),
      .dout_dv (s1_dv),
      .sync_out(s1_sync)
  );

  prach_ditfft3_bf3 i_bf3 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dr  (s1_dr),
      .din_di  (s1_di),
      .din_dv  (s1_dv),
      .sync_in (s1_sync),
      //
      .dout_dr (dout_dr),
      .dout_di (dout_di),
      .dout_dv (dout_dv),
      .sync_out(sync_out)
  );

endmodule

`default_nettype wire
