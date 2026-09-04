`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_hb2 #(
    parameter int           DELAY_BASE    = 8,
    parameter signed [17:0] UNIQ_COE  [2] = '{-18'sd4105, 18'sd36873}
) (
    input var         clk,
    input var         rst,
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
    output var [15:0] dout_dq,
    output var        dout_sf,
    output var        dout_sl,
    output var        dout_sy,
    output var [ 7:0] dout_chn,
    output var        dout_dv,
    output var        dout_last,
    //
    input var         ctrl_bypass
);

  // Parameters

  // fi(1, 18, 17)
  localparam logic signed [35:0] Rng = 1 << 16;

  localparam int Latency = 8;
  localparam int ImpulseLatency = DELAY_BASE + Latency;

  localparam int Delay1 = DELAY_BASE * 1 + 7;
  localparam int Delay2 = DELAY_BASE * 3 + 1;

  // Signals

  logic               ctrl_bypass_s;

  logic        [15:0] xp1           [Delay1];
  logic        [15:0] xp2           [Delay2];

  logic signed [15:0] ay1;
  logic signed [15:0] az1;

  logic signed [15:0] by1;
  logic signed [15:0] bz1;

  logic signed [16:0] asum;
  logic signed [34:0] amult;
  logic signed [35:0] aresult;

  logic signed [16:0] bsum;
  logic signed [34:0] bmult;
  logic signed [35:0] bresult;

  logic signed [36:0] dq;

  // Control CDC

  cdc_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0)
  ) u_cdc_ctrl_bypass (
      .src_clk (1'b1),
      .src_in  (ctrl_bypass),
      //
      .dest_clk(clk),
      .dest_out(ctrl_bypass_s)
  );

  // Data delay line

  always_ff @(posedge clk) begin
    xp1[0] <= din_dp1;
    for (int i = 1; i < Delay1; i++) begin
      xp1[i] <= xp1[i-1];
    end
  end

  always_ff @(posedge clk) begin
    xp2[0] <= din_dp2;
    for (int i = 1; i < Delay2; i++) begin
      xp2[i] <= xp2[i-1];
    end
  end

  // DSP1

  always_ff @(posedge clk) begin
    ay1 <= xp2[DELAY_BASE*0];
    az1 <= xp2[DELAY_BASE*3];
  end

  always_ff @(posedge clk) begin
    asum <= ay1 + az1;
  end

  always_ff @(posedge clk) begin
    amult <= asum * UNIQ_COE[0];
  end

  always_ff @(posedge clk) begin
    aresult <= 36'(amult) + Rng;
  end

  // DSP2

  always_ff @(posedge clk) begin
    by1 <= xp2[DELAY_BASE*1+1];
    bz1 <= xp2[DELAY_BASE*2+1];
  end

  always_ff @(posedge clk) begin
    bsum <= by1 + bz1;
  end

  always_ff @(posedge clk) begin
    bmult <= bsum * UNIQ_COE[1];
  end

  always_ff @(posedge clk) begin
    bresult <= aresult + 36'(bmult);
  end

  // Output

  always_ff @(posedge clk) begin
    dq <= 37'(bresult) + $signed({{5{xp1[DELAY_BASE*1+5][15]}}, xp1[DELAY_BASE*1+5], 16'b0});
  end

  // TODO: saturate
  always_ff @(posedge clk) begin
    if (ctrl_bypass_s) begin
      dout_dq <= xp1[DELAY_BASE*1+6];
    end else begin
      dout_dq <= dq[32:17];
    end
  end

  delay #(
      .WIDTH(13),
      .DEPTH(ImpulseLatency)
  ) u_delay (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din ({din_last, din_dv, din_chn, din_sy, din_sl, din_sf}),
      .dout({dout_last, dout_dv, dout_chn, dout_sy, dout_sl, dout_sf})
  );

  wire unused_hb2 = &{1'b0, rst, dq[36:33], dq[16:0]};

endmodule

`default_nettype wire
