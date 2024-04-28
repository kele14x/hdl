`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_hb5 (
    input var         clk,
    input var         rst_n,
    //
    input var  [15:0] din_dp1,
    input var  [15:0] din_dp2,
    input var  [ 7:0] din_chn,
    input var         sync_in,
    //
    output var [15:0] dout_dq,
    output var [ 7:0] dout_chn,
    output var        sync_out
);

  localparam int NumChannel = 256;
  localparam int NumChannelUsed = 48;
  localparam int NumUniqCoe = 4;
  // fi(1, 18, 17)
  localparam logic signed [17:0] UniqCoe[NumUniqCoe] = '{
      -18'sd616,
      18'sd2989,
      -18'sd9818,
      18'sd40178
  };

  localparam logic signed [35:0] Rng = 1 << 16;

  localparam int Latency = 7;
  localparam int Delay1 = 150;
  localparam int Delay2 = 337;

  (* ramstyle = "mlab" *)
  logic [15:0] xp1[Delay1];
  (* ramstyle = "mlab" *)
  logic [15:0] xp2[Delay2];

  logic signed [15:0] ay1;
  logic signed [15:0] ay2;
  logic signed [15:0] ay3;

  logic signed [15:0] az1;
  logic signed [15:0] az2;
  logic signed [15:0] az3;

  logic signed [15:0] by1;
  logic signed [15:0] by2;
  logic signed [15:0] by3;

  logic signed [15:0] bz1;
  logic signed [15:0] bz2;
  logic signed [15:0] bz3;

  logic signed [15:0] cy1;
  logic signed [15:0] cy2;
  logic signed [15:0] cy3;

  logic signed [15:0] cz1;
  logic signed [15:0] cz2;
  logic signed [15:0] cz3;

  logic signed [15:0] dy1;
  logic signed [15:0] dy2;
  logic signed [15:0] dy3;

  logic signed [15:0] dz1;
  logic signed [15:0] dz2;
  logic signed [15:0] dz3;

  logic signed [16:0] asum;
  logic signed [34:0] amult;

  logic signed [16:0] bsum;
  logic signed [34:0] bmult;

  logic signed [16:0] csum;
  logic signed [34:0] cmult;

  logic signed [16:0] dsum;
  logic signed [34:0] dmult;

  logic signed [35:0] result1;
  logic signed [35:0] result2;

  logic signed [35:0] result1_d;
  logic signed [35:0] result2_d;

  logic signed [35:0] dq;

  // Data delay line

  always_ff @(posedge clk) begin
    if (din_chn < 48) begin
      xp1[0] <= din_dp1;
      for (int i = 1; i < Delay1; i++) begin
        xp1[i] <= xp1[i-1];
      end
    end
  end

  always_ff @(posedge clk) begin
    if (din_chn < 48) begin
      xp2[0] <= din_dp2;
      for (int i = 1; i < Delay2; i++) begin
        xp2[i] <= xp2[i-1];
      end
    end
  end

  // DSP1

  always_ff @(posedge clk) begin
    ay1 <= xp2[0];
    ay2 <= ay1;
    ay3 <= ay2;
    az1 <= xp2[336];
    az2 <= az1;
    az3 <= az2;
  end

  always_comb begin
    asum = ay3 + az3;
  end

  always_comb begin
    amult = asum * UniqCoe[0];
  end

  // DSP2

  always_ff @(posedge clk) begin
    by1 <= xp2[48];
    by2 <= by1;
    by3 <= by2;
    bz1 <= xp2[288];
    bz2 <= bz1;
    bz3 <= bz2;
  end

  always_comb begin
    bsum = by3 + bz3;
  end

  always_comb begin
    bmult = bsum * UniqCoe[1];
  end

  always_ff @(posedge clk) begin
    result1 <= amult + bmult + Rng;
  end

  // DSP3

  always_ff @(posedge clk) begin
    cy1 <= xp2[96];
    cy2 <= cy1;
    cy3 <= cy2;
    cz1 <= xp2[240];
    cz2 <= cz1;
    cz3 <= cz2;
  end

  always_comb begin
    csum = cy3 + cz3;
  end

  always_comb begin
    cmult = csum * UniqCoe[2];
  end

  // DSP4

  always_ff @(posedge clk) begin
    dy1 <= xp2[144];
    dy2 <= dy1;
    dy3 <= dy2;
    dz1 <= xp2[192];
    dz2 <= dz1;
    dz3 <= dz2;
  end

  always_comb begin
    dsum = dy3 + dz3;
  end

  always_comb begin
    dmult = dsum * UniqCoe[3];
  end

  always_ff @(posedge clk) begin
    result2 <= cmult + dmult;
  end

  always_ff @(posedge clk) begin
    result1_d <= result1;
    result2_d <= result2;
  end

  always_ff @(posedge clk) begin
    dq <= result1_d + result2_d + $signed({xp1[149], 16'b0});
  end

  assign dout_dq = dq[32:17];

  delay #(
      .WIDTH(1),
      .DELAY(Latency)
  ) u_delay (
      .clk  (clk),
      .rst_n(1'b1),
      .din  (sync_in),
      .dout (sync_out)
  );

  always_ff @(posedge clk) begin
    dout_chn <= din_chn - (Latency - 1);
  end

endmodule

`default_nettype wire
