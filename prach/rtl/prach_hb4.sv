`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_hb4 #(
    parameter int           DELAY_BASE    = 128,
    parameter signed [17:0] UNIQ_COE  [4] = '{-18'sd669, 18'sd3099, -18'sd9939, 18'sd40231}
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [15:0] din_dp1,
    input  wire [15:0] din_dp2,
    input  wire        din_sf,
    input  wire        din_sl,
    input  wire        din_sy,
    input  wire [ 7:0] din_chn,
    input  wire        din_dv,
    input  wire        din_last,
    //
    output logic  [15:0] dout_dq,
    output wire        dout_sf,
    output wire        dout_sl,
    output wire        dout_sy,
    output wire [ 7:0] dout_chn,
    output wire        dout_dv,
    output wire        dout_last,
    //
    input  wire        ctrl_bypass
);

  // Parameters

  // fi(1, 18, 17)
  localparam logic signed [35:0] Rng = 1 << 16;

  localparam int Latency = 10;
  localparam int ImpulseLatency = DELAY_BASE * 3 + Latency;

  localparam int Delay1 = DELAY_BASE * 3 + 9;
  localparam int Delay2 = DELAY_BASE * 7 + 1;

  // Signals

  logic               ctrl_bypass_s;

  logic        [15:0] xp1           [Delay1];
  logic        [15:0] xp2           [Delay2];

  logic signed [15:0] ay1;

  logic signed [15:0] az1;

  logic signed [15:0] by1;

  logic signed [15:0] bz1;

  logic signed [15:0] cy1;

  logic signed [15:0] cz1;

  logic signed [15:0] dy1;

  logic signed [15:0] dz1;

  logic signed [16:0] asum;
  logic signed [34:0] amult;
  logic signed [35:0] aresult;

  logic signed [16:0] bsum;
  logic signed [34:0] bmult;
  logic signed [35:0] bresult;

  logic signed [16:0] csum;
  logic signed [34:0] cmult;
  logic signed [36:0] cresult;

  logic signed [16:0] dsum;
  logic signed [34:0] dmult;
  logic signed [37:0] dresult;

  logic signed [38:0] dq;

  // Control CDC

  cdc_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0)
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
    az1 <= xp2[DELAY_BASE*7];
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
    bz1 <= xp2[DELAY_BASE*6+1];
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

  // DSP3

  always_ff @(posedge clk) begin
    cy1 <= xp2[DELAY_BASE*2+2];
    cz1 <= xp2[DELAY_BASE*5+2];
  end

  always_ff @(posedge clk) begin
    csum <= cy1 + cz1;
  end

  always_ff @(posedge clk) begin
    cmult <= csum * UNIQ_COE[2];
  end

  always_ff @(posedge clk) begin
    cresult <= 37'(cmult) + 37'(bresult);
  end

  // DSP4

  always_ff @(posedge clk) begin
    dy1 <= xp2[DELAY_BASE*3+3];
    dz1 <= xp2[DELAY_BASE*4+3];
  end

  always_ff @(posedge clk) begin
    dsum <= dy1 + dz1;
  end

  always_ff @(posedge clk) begin
    dmult <= dsum * UNIQ_COE[3];
  end

  always_ff @(posedge clk) begin
    dresult <= 38'(cresult) + 38'(dmult);
  end

  always_ff @(posedge clk) begin
    dq <= 39'(dresult) + $signed({{7{xp1[DELAY_BASE*3+7][15]}}, xp1[DELAY_BASE*3+7], 16'b0});
  end

  // TODO: saturate
  always_ff @(posedge clk) begin
    if (ctrl_bypass_s) begin
      dout_dq <= xp1[DELAY_BASE*3+8];
    end else begin
      dout_dq <= dq[32:17];
    end
  end

  delay #(
      .WIDTH(13),
      .DEPTH(ImpulseLatency),
      .INIT (0)
  ) u_delay (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din ({din_last, din_dv, din_chn, din_sy, din_sl, din_sf}),
      .dout({dout_last, dout_dv, dout_chn, dout_sy, dout_sl, dout_sf})
  );

  wire unused_hb4 = &{1'b0, rst, dq[38:33], dq[16:0]};

endmodule

`default_nettype wire
