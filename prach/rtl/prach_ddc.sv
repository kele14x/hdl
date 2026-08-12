`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_ddc #(
    parameter int NUM_ANT   = 4,
    parameter int NUM_STAGE = 6
) (
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
    output var        dout_last,
    // CSR
    //----
    input var  [17:0] ctrl_fcw,
    input var  [ 3:0] ctrl_bw
);

  // Signals

  logic [         19:0] ctrl_cfw_s;

  logic [NUM_STAGE-1:0] ctrl_bypass;

  // 4
  logic [         15:0] mixer_dout_dr;
  logic [         15:0] mixer_dout_di;
  logic                 mixer_dout_sf;
  logic                 mixer_dout_sl;
  logic                 mixer_dout_sy;
  logic [          7:0] mixer_dout_chn;
  logic [          3:0] mixer_dout_chn_unused;
  logic                 mixer_dout_dv;
  logic                 mixer_dout_last;

  // 8/16/32/64/128/256
  logic [         15:0] s0_dp1                [NUM_STAGE+1];
  logic [         15:0] s0_dp2                [NUM_STAGE+1];
  logic                 s0_sf                 [NUM_STAGE+1];
  logic                 s0_sl                 [NUM_STAGE+1];
  logic                 s0_sy                 [NUM_STAGE+1];
  logic [          7:0] s0_chn                [NUM_STAGE+1];
  logic                 s0_dv                 [NUM_STAGE+1];
  logic                 s0_last               [NUM_STAGE+1];

  logic [         15:0] s1_dp1                [  NUM_STAGE];
  logic [         15:0] s1_dp2                [  NUM_STAGE];
  logic                 s1_sf                 [  NUM_STAGE];
  logic                 s1_sl                 [  NUM_STAGE];
  logic                 s1_sy                 [  NUM_STAGE];
  logic [          7:0] s1_chn                [  NUM_STAGE];
  logic                 s1_dv                 [  NUM_STAGE];
  logic                 s1_last               [  NUM_STAGE];

  logic [         15:0] conv_din_dr;
  logic [         15:0] conv_din_di;
  logic                 conv_din_sf;
  logic                 conv_din_sl;
  logic                 conv_din_sy;
  logic [          7:0] conv_din_chn;
  logic                 conv_din_dv;
  logic                 conv_din_last;

  logic [         15:0] conv_dout_dr;
  logic [         15:0] conv_dout_di;
  logic                 conv_dout_sf;
  logic                 conv_dout_sl;
  logic                 conv_dout_sy;
  logic [          7:0] conv_dout_chn;
  logic                 conv_dout_dv;
  logic                 conv_dout_last;

  // Latency:
  //   u_mixer   :  13
  //   u_reshape1:  5
  //   u_hb1     :  8
  //   u_reshape2:  9
  //   u_hb2     :  8
  //   u_reshape3:  17
  //   u_hb3     :  8
  //   u_reshape4:  33
  //   u_hb4     :  10
  //   u_reshape5:  65
  //   u_hb5     :  10
  //   u_reshape6:  5
  //   u_conv    :  8

  // Main

  assign ctrl_cfw_s = {ctrl_fcw, 2'b00};

  // Bypass first/second HB filter based on channel bandwidth
  always_comb begin
    case (ctrl_bw)
      4'b0000: ctrl_bypass = 6'b000011;  // 7.68  (30.72)
      4'b0001: ctrl_bypass = 6'b000011;  // 15.36 (30.72)
      4'b0010: ctrl_bypass = 6'b000011;  // 30.72
      4'b0011: ctrl_bypass = 6'b000001;  // 61.44
      default: ctrl_bypass = 6'b000000;  // 122.88
    endcase
  end

  mixer #(
      .HAS_CDC(1'b0),
      .NUM_ANT(NUM_ANT)
  ) u_mixer (
      .clk      (clk),
      .rst      (rst),
      //
      .din_dr   (din_dr),
      .din_di   (din_di),
      .din_sf   (din_sf),
      .din_sl   (din_sl),
      .din_sy   (din_sy),
      .din_chn  ({2'b00, din_chn[1:0]}),
      .din_dv   (din_dv),
      .din_last (din_last),
      //
      .dout_dr  (mixer_dout_dr),
      .dout_di  (mixer_dout_di),
      .dout_sf  (mixer_dout_sf),
      .dout_sl  (mixer_dout_sl),
      .dout_sy  (mixer_dout_sy),
      .dout_chn (mixer_dout_chn_unused),
      .dout_dv  (mixer_dout_dv),
      .dout_last(mixer_dout_last),
      //
      .ctrl_pinc('{NUM_ANT{ctrl_cfw_s}}),
      .ctrl_poff('{NUM_ANT{20'd0}})
  );

  // Mixer does only has 4-bit CHN port, so matched delay is done here
  delay #(
      .WIDTH(8),
      .DEPTH(13),
      .INIT (1'b0)
  ) u_delay_chn (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (din_chn),
      .dout(mixer_dout_chn)
  );

  assign s0_dp1[0]  = mixer_dout_dr;
  assign s0_dp2[0]  = mixer_dout_di;
  assign s0_sf[0]   = mixer_dout_sf;
  assign s0_sl[0]   = mixer_dout_sl;
  assign s0_sy[0]   = mixer_dout_sy;
  assign s0_chn[0]  = mixer_dout_chn;
  assign s0_dv[0]   = mixer_dout_dv;
  assign s0_last[0] = mixer_dout_last;

  generate
    for (genvar i = 0; i < NUM_STAGE; i++) begin : g_stage

      prach_reshape #(
          .SIZE(8 * 2 ** i)
      ) u_reshape (
          .clk      (clk),
          .rst      (rst),
          //
          .din_dp1  (s0_dp1[i]),
          .din_dp2  (s0_dp2[i]),
          .din_sf   (s0_sf[i]),
          .din_sl   (s0_sl[i]),
          .din_sy   (s0_sy[i]),
          .din_chn  (s0_chn[i]),
          .din_dv   (s0_dv[i]),
          .din_last (s0_last[i]),
          //
          .dout_dq1 (s1_dp1[i]),
          .dout_dq2 (s1_dp2[i]),
          .dout_sf  (s1_sf[i]),
          .dout_sl  (s1_sl[i]),
          .dout_sy  (s1_sy[i]),
          .dout_chn (s1_chn[i]),
          .dout_dv  (s1_dv[i]),
          .dout_last(s1_last[i])
      );

      assign s0_dp2[i+1] = '0;

      if (i == 0) begin : g_hb0

        prach_hb2 #(
            .DELAY_BASE(8),
            .UNIQ_COE  ('{-18'sd4105, 18'sd36873})
        ) u_hb0 (
            .clk        (clk),
            .rst        (rst),
            //
            .din_dp1    (s1_dp1[i]),
            .din_dp2    (s1_dp2[i]),
            .din_sf     (s1_sf[i]),
            .din_sl     (s1_sl[i]),
            .din_sy     (s1_sy[i]),
            .din_chn    (s1_chn[i]),
            .din_dv     (s1_dv[i]),
            .din_last   (s1_last[i]),
            //
            .dout_dq    (s0_dp1[i+1]),
            .dout_sf    (s0_sf[i+1]),
            .dout_sl    (s0_sl[i+1]),
            .dout_sy    (s0_sy[i+1]),
            .dout_chn   (s0_chn[i+1]),
            .dout_dv    (s0_dv[i+1]),
            .dout_last  (s0_last[i+1]),
            //
            .ctrl_bypass(ctrl_bypass[i])
        );

      end else if (i == 1) begin : g_hb1

        prach_hb2 #(
            .DELAY_BASE(16),
            .UNIQ_COE  ('{-18'sd4134, 18'sd36901})
        ) u_hb1 (
            .clk        (clk),
            .rst        (rst),
            //
            .din_dp1    (s1_dp1[i]),
            .din_dp2    (s1_dp2[i]),
            .din_sf     (s1_sf[i]),
            .din_sl     (s1_sl[i]),
            .din_sy     (s1_sy[i]),
            .din_chn    (s1_chn[i]),
            .din_dv     (s1_dv[i]),
            .din_last   (s1_last[i]),
            //
            .dout_dq    (s0_dp1[i+1]),
            .dout_sf    (s0_sf[i+1]),
            .dout_sl    (s0_sl[i+1]),
            .dout_sy    (s0_sy[i+1]),
            .dout_chn   (s0_chn[i+1]),
            .dout_dv    (s0_dv[i+1]),
            .dout_last  (s0_last[i+1]),
            //
            .ctrl_bypass(ctrl_bypass[i])
        );

      end else if (i == 2) begin : g_hb2

        prach_hb2 #(
            .DELAY_BASE(32),
            .UNIQ_COE  ('{-18'sd4249, 18'sd37013})
        ) u_hb2 (
            .clk        (clk),
            .rst        (rst),
            //
            .din_dp1    (s1_dp1[i]),
            .din_dp2    (s1_dp2[i]),
            .din_sf     (s1_sf[i]),
            .din_sl     (s1_sl[i]),
            .din_sy     (s1_sy[i]),
            .din_chn    (s1_chn[i]),
            .din_dv     (s1_dv[i]),
            .din_last   (s1_last[i]),
            //
            .dout_dq    (s0_dp1[i+1]),
            .dout_sf    (s0_sf[i+1]),
            .dout_sl    (s0_sl[i+1]),
            .dout_sy    (s0_sy[i+1]),
            .dout_chn   (s0_chn[i+1]),
            .dout_dv    (s0_dv[i+1]),
            .dout_last  (s0_last[i+1]),
            //
            .ctrl_bypass(ctrl_bypass[i])
        );

      end else if (i == 3) begin : g_hb3

        prach_hb2 #(
            .DELAY_BASE(64),
            .UNIQ_COE  ('{-18'sd4750, 18'sd37456})
        ) u_hb3 (
            .clk        (clk),
            .rst        (rst),
            //
            .din_dp1    (s1_dp1[i]),
            .din_dp2    (s1_dp2[i]),
            .din_sf     (s1_sf[i]),
            .din_sl     (s1_sl[i]),
            .din_sy     (s1_sy[i]),
            .din_chn    (s1_chn[i]),
            .din_dv     (s1_dv[i]),
            .din_last   (s1_last[i]),
            //
            .dout_dq    (s0_dp1[i+1]),
            .dout_sf    (s0_sf[i+1]),
            .dout_sl    (s0_sl[i+1]),
            .dout_sy    (s0_sy[i+1]),
            .dout_chn   (s0_chn[i+1]),
            .dout_dv    (s0_dv[i+1]),
            .dout_last  (s0_last[i+1]),
            //
            .ctrl_bypass(ctrl_bypass[i])
        );

      end else if (i == 4) begin : g_hb4

        prach_hb4 #(
            .DELAY_BASE(128),
            .UNIQ_COE  ('{-18'sd669, 18'sd3099, -18'sd9939, 18'sd40231})
        ) u_hb4 (
            .clk        (clk),
            .rst        (rst),
            //
            .din_dp1    (s1_dp1[i]),
            .din_dp2    (s1_dp2[i]),
            .din_sf     (s1_sf[i]),
            .din_sl     (s1_sl[i]),
            .din_sy     (s1_sy[i]),
            .din_chn    (s1_chn[i]),
            .din_dv     (s1_dv[i]),
            .din_last   (s1_last[i]),
            //
            .dout_dq    (s0_dp1[i+1]),
            .dout_sf    (s0_sf[i+1]),
            .dout_sl    (s0_sl[i+1]),
            .dout_sy    (s0_sy[i+1]),
            .dout_chn   (s0_chn[i+1]),
            .dout_dv    (s0_dv[i+1]),
            .dout_last  (s0_last[i+1]),
            //
            .ctrl_bypass(ctrl_bypass[i])
        );

      end else begin : g_hb5

        prach_hb4 #(
            .DELAY_BASE(256),
            .UNIQ_COE  ('{-18'sd669, 18'sd3099, -18'sd9939, 18'sd40231})
        ) u_hb5 (
            .clk        (clk),
            .rst        (rst),
            //
            .din_dp1    (s1_dp1[i]),
            .din_dp2    (s1_dp2[i]),
            .din_sf     (s1_sf[i]),
            .din_sl     (s1_sl[i]),
            .din_sy     (s1_sy[i]),
            .din_chn    (s1_chn[i]),
            .din_dv     (s1_dv[i]),
            .din_last   (s1_last[i]),
            //
            .dout_dq    (s0_dp1[i+1]),
            .dout_sf    (s0_sf[i+1]),
            .dout_sl    (s0_sl[i+1]),
            .dout_sy    (s0_sy[i+1]),
            .dout_chn   (s0_chn[i+1]),
            .dout_dv    (s0_dv[i+1]),
            .dout_last  (s0_last[i+1]),
            //
            .ctrl_bypass(ctrl_bypass[i])
        );

      end
    end
  endgenerate

  prach_reshape #(
      .SIZE(8)
  ) u_reshape (
      .clk      (clk),
      .rst      (rst),
      //
      .din_dp1  (s0_dp1[NUM_STAGE]),
      .din_dp2  (s0_dp2[NUM_STAGE]),
      .din_sf   (s0_sf[NUM_STAGE]),
      .din_sl   (s0_sl[NUM_STAGE]),
      .din_sy   (s0_sy[NUM_STAGE]),
      .din_chn  (s0_chn[NUM_STAGE]),
      .din_dv   (s0_dv[NUM_STAGE]),
      .din_last (s0_last[NUM_STAGE]),
      //
      .dout_dq1 (conv_din_dr),
      .dout_dq2 (conv_din_di),
      .dout_sf  (conv_din_sf),
      .dout_sl  (conv_din_sl),
      .dout_sy  (conv_din_sy),
      .dout_chn (conv_din_chn),
      .dout_dv  (conv_din_dv),
      .dout_last(conv_din_last)
  );

  prach_conv u_conv (
      .clk      (clk),
      .rst      (rst),
      //
      .din_dr   (conv_din_dr),
      .din_di   (conv_din_di),
      .din_sf   (conv_din_sf),
      .din_sl   (conv_din_sl),
      .din_sy   (conv_din_sy),
      .din_chn  (conv_din_chn),
      .din_dv   (conv_din_dv),
      .din_last (conv_din_last),
      //
      .dout_dr  (conv_dout_dr),
      .dout_di  (conv_dout_di),
      .dout_sf  (conv_dout_sf),
      .dout_sl  (conv_dout_sl),
      .dout_sy  (conv_dout_sy),
      .dout_chn (conv_dout_chn),
      .dout_dv  (conv_dout_dv),
      .dout_last(conv_dout_last)
  );

  // Clear some "rubbish data" caused by HBx
  always_ff @(posedge clk) begin
    if (conv_dout_chn < 8'(NUM_ANT)) begin
      dout_dr <= conv_dout_dr;
      dout_di <= conv_dout_di;
    end else begin
      dout_dr <= '0;
      dout_di <= '0;
    end
    dout_sf   <= conv_dout_sf;
    dout_sl   <= conv_dout_sl;
    dout_sy   <= conv_dout_sy;
    dout_chn  <= conv_dout_chn;
    dout_dv   <= conv_dout_dv && (conv_dout_chn < 8'(NUM_ANT));
    dout_last <= conv_dout_last;
  end

  wire unused_ddc = &{1'b0, mixer_dout_chn_unused};

endmodule

`default_nettype wire
