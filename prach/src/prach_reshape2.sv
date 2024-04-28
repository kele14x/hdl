`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_reshape2 (
    input var         clk,
    input var         rst_n,
    //
    input var  [15:0] din_dq  [3],
    input var  [ 7:0] din_chn,
    input var         sync_in,
    //
    output var [15:0] dout_dp1[2],
    output var [15:0] dout_dp2[2],
    output var [ 7:0] dout_chn,
    output var        sync_out
);

  prach_reshape_ch #(
      .SIZE(32)
  ) u_ch1 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dq1 (din_dq[0]),
      .din_dq2 (din_dq[1]),
      .din_chn (din_chn),
      .sync_in (sync_in),
      //
      .dout_dp1(dout_dp1[0]),
      .dout_dp2(dout_dp2[0]),
      .dout_chn(dout_chn),
      .sync_out(sync_out)
  );

  prach_reshape_ch #(
      .SIZE(32)
  ) u_ch2 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dq1 (din_dq[2]),
      .din_dq2 ('0),
      .din_chn (din_chn),
      .sync_in (sync_in),
      //
      .dout_dp1(dout_dp1[1]),
      .dout_dp2(dout_dp2[1]),
      .dout_chn(),
      .sync_out()
  );

endmodule

`default_nettype wire
