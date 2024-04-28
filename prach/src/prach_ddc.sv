`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_ddc (
    input var         clk,
    input var         rst_n,
    //
    input var  [15:0] din_dr  [3],
    input var  [15:0] din_di  [3],
    input var  [ 7:0] din_chn,
    input var         sync_in,
    //
    output var [15:0] dout_dr,
    output var [15:0] dout_di,
    output var [ 7:0] dout_chn,
    output var        sync_out,
    // CSR
    //----
    input var  [16:0] ctrl_fcw[3][8]
);

  // 8
  logic [15:0] mixer_dout_dr  [3];
  logic [15:0] mixer_dout_di  [3];
  logic [ 7:0] mixer_dout_chn;
  logic        mixer_sync_out;

  // 16
  logic [15:0] hb1_din_dp1    [3];
  logic [15:0] hb1_din_dp2    [3];
  logic [ 7:0] hb1_din_chn;
  logic        hb1_sync_in;

  logic [15:0] hb1_dout_dq    [3];
  logic [ 7:0] hb1_dout_chn;
  logic        hb1_sync_out;

  // 32
  logic [15:0] hb2_din_dp1    [2];
  logic [15:0] hb2_din_dp2    [2];
  logic [ 7:0] hb2_din_chn;
  logic        hb2_sync_in;

  logic [15:0] hb2_dout_dq    [2];
  logic [ 7:0] hb2_dout_chn;
  logic        hb2_sync_out;

  // 64
  logic [15:0] hb3_din_dp1;
  logic [15:0] hb3_din_dp2;
  logic [ 7:0] hb3_din_chn;
  logic        hb3_sync_in;

  logic [15:0] hb3_dout_dq;
  logic [ 7:0] hb3_dout_chn;
  logic        hb3_sync_out;

  // 128
  logic [15:0] hb4_din_dp1;
  logic [15:0] hb4_din_dp2;
  logic [ 7:0] hb4_din_chn;
  logic        hb4_sync_in;

  logic [15:0] hb4_dout_dq;
  logic [ 7:0] hb4_dout_chn;
  logic        hb4_sync_out;

  // 256
  logic [15:0] hb5_din_dp1;
  logic [15:0] hb5_din_dp2;
  logic [ 7:0] hb5_din_chn;
  logic        hb5_sync_in;

  logic [15:0] hb5_dout_dq;
  logic [ 7:0] hb5_dout_chn;
  logic        hb5_sync_out;

  logic [15:0] conv_din_dr;
  logic [15:0] conv_din_di;
  logic [ 7:0] conv_din_chn;
  logic        conv_sync_in;

  logic [15:0] conv_dout_dr;
  logic [15:0] conv_dout_di;
  logic [ 7:0] conv_dout_chn;
  logic        conv_sync_out;


  // Latency:
  //   u_mixer   :  8
  //   u_reshape1:  9
  //   u_hb1     :  6
  //   u_reshape2:  17
  //   u_hb2     :  6
  //   u_reshape3:  33
  //   u_hb3     :  6
  //   u_reshape4:  64
  //   u_hb4     :  7
  //   u_reshape5:  129
  //   u_hb5     :  7
  //   u_reshape6:  9
  //   u_conv    :  8

  prach_mixer u_mixer (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dr  (din_dr),
      .din_di  (din_di),
      .din_chn (din_chn),
      .sync_in (sync_in),
      //
      .dout_dr (mixer_dout_dr),
      .dout_di (mixer_dout_di),
      .dout_chn(mixer_dout_chn),
      .sync_out(mixer_sync_out),
      //----
      .ctrl_fcw(ctrl_fcw)
  );

  prach_reshape1 u_reshape1 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dr  (mixer_dout_dr),
      .din_di  (mixer_dout_di),
      .din_chn (mixer_dout_chn),
      .sync_in (mixer_sync_out),
      //
      .dout_dp1(hb1_din_dp1),
      .dout_dp2(hb1_din_dp2),
      .dout_chn(hb1_din_chn),
      .sync_out(hb1_sync_in)
  );

  prach_hb1 u_hb1 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dp1 (hb1_din_dp1),
      .din_dp2 (hb1_din_dp2),
      .din_chn (hb1_din_chn),
      .sync_in (hb1_sync_in),
      //
      .dout_dq (hb1_dout_dq),
      .dout_chn(hb1_dout_chn),
      .sync_out(hb1_sync_out)
  );

  prach_reshape2 u_reshape2 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dq  (hb1_dout_dq),
      .din_chn (hb1_dout_chn),
      .sync_in (hb1_sync_out),
      //
      .dout_dp1(hb2_din_dp1),
      .dout_dp2(hb2_din_dp2),
      .dout_chn(hb2_din_chn),
      .sync_out(hb2_sync_in)
  );

  prach_hb2 u_hb2 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dp1 (hb2_din_dp1),
      .din_dp2 (hb2_din_dp2),
      .din_chn (hb2_din_chn),
      .sync_in (hb2_sync_in),
      //
      .dout_dq (hb2_dout_dq),
      .dout_chn(hb2_dout_chn),
      .sync_out(hb2_sync_out)
  );

  prach_reshape_ch #(
      .SIZE(64)
  ) u_reshape3 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dq1 (hb2_dout_dq[0]),
      .din_dq2 (hb2_dout_dq[1]),
      .din_chn (hb2_dout_chn),
      .sync_in (hb2_sync_out),
      //
      .dout_dp1(hb3_din_dp1),
      .dout_dp2(hb3_din_dp2),
      .dout_chn(hb3_din_chn),
      .sync_out(hb3_sync_in)
  );

  prach_hb3 u_hb3 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dp1 (hb3_din_dp1),
      .din_dp2 (hb3_din_dp2),
      .din_chn (hb3_din_chn),
      .sync_in (hb3_sync_in),
      //
      .dout_dq (hb3_dout_dq),
      .dout_chn(hb3_dout_chn),
      .sync_out(hb3_sync_out)
  );

  prach_reshape_ch #(
      .SIZE(128)
  ) u_reshape4 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dq1 (hb3_dout_dq),
      .din_dq2 ('0),
      .din_chn (hb3_dout_chn),
      .sync_in (hb3_sync_out),
      //
      .dout_dp1(hb4_din_dp1),
      .dout_dp2(hb4_din_dp2),
      .dout_chn(hb4_din_chn),
      .sync_out(hb4_sync_in)
  );

  prach_hb4 u_hb4 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dp1 (hb4_din_dp1),
      .din_dp2 (hb4_din_dp2),
      .din_chn (hb4_din_chn),
      .sync_in (hb4_sync_in),
      //
      .dout_dq (hb4_dout_dq),
      .dout_chn(hb4_dout_chn),
      .sync_out(hb4_sync_out)
  );

  prach_reshape_ch #(
      .SIZE(256)
  ) u_reshape5 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dq1 (hb4_dout_dq),
      .din_dq2 ('0),
      .din_chn (hb4_dout_chn),
      .sync_in (hb4_sync_out),
      //
      .dout_dp1(hb5_din_dp1),
      .dout_dp2(hb5_din_dp2),
      .dout_chn(hb5_din_chn),
      .sync_out(hb5_sync_in)
  );

  prach_hb5 u_hb5 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dp1 (hb5_din_dp1),
      .din_dp2 (hb5_din_dp2),
      .din_chn (hb5_din_chn),
      .sync_in (hb5_sync_in),
      //
      .dout_dq (hb5_dout_dq),
      .dout_chn(hb5_dout_chn),
      .sync_out(hb5_sync_out)
  );

  prach_reshape_ch #(
      .SIZE(16)
  ) u_reshape6 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dq1 (hb5_dout_dq),
      .din_dq2 ('0),
      .din_chn (hb5_dout_chn),
      .sync_in (hb5_sync_out),
      //
      .dout_dp1(conv_din_dr),
      .dout_dp2(conv_din_di),
      .dout_chn(conv_din_chn),
      .sync_out(conv_sync_in)
  );

  prach_conv u_conv (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dr  (conv_din_dr),
      .din_di  (conv_din_di),
      .din_chn (conv_din_chn),
      .sync_in (conv_sync_in),
      //
      .dout_dr (conv_dout_dr),
      .dout_di (conv_dout_di),
      .dout_chn(conv_dout_chn),
      .sync_out(conv_sync_out)
  );

  assign dout_dr  = conv_dout_dr;
  assign dout_di  = conv_dout_di;
  assign dout_chn = conv_dout_chn;
  assign sync_out = conv_sync_out;

endmodule

`default_nettype wire
