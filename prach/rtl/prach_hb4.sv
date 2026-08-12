`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_hb4 #(
    parameter int           DELAY_BASE    = 128,
    parameter signed [17:0] UNIQ_COE  [4] = '{-18'sd669, 18'sd3099, -18'sd9939, 18'sd40231}
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

  // Check parameters

  initial begin : drc_check
    assert (DELAY_BASE == 128 || DELAY_BASE == 256)
    else $error("[%m]: sparse HB4 supports DELAY_BASE=128 or 256 only");
  end

  // Parameters

  localparam int NumLane = 8;
  localparam int NumOddHistory = 7;
  localparam int NumCenterHistory = 3;
  localparam int OddHistoryBase = 0;
  localparam int CenterHistoryBase = NumOddHistory * 16;
  localparam int MetadataHistoryBase = CenterHistoryBase + NumCenterHistory * 16;
  localparam int HistoryWidth = MetadataHistoryBase + NumCenterHistory * 13;

  // fi(1, 18, 17)
  localparam logic signed [35:0] Rng = 1 << 16;

  // Signals

  logic ctrl_bypass_s;

  // One word contains all sample ages for one lane. This is an 8-deep,
  // single-read/single-write memory, so all taps are available from one read.
  (* ram_style = "distributed" *)
  logic [HistoryWidth-1:0] lane_history[NumLane];
  logic [HistoryWidth-1:0] history_write;

  logic [3:0] history_count[NumLane];

  logic signed [15:0] a_y0;
  logic signed [15:0] a_z0;
  logic signed [15:0] b_y0;
  logic signed [15:0] b_z0;
  logic signed [15:0] c_y0;
  logic signed [15:0] c_z0;
  logic signed [15:0] d_y0;
  logic signed [15:0] d_z0;

  logic signed [15:0] b_y_delay;
  logic signed [15:0] b_z_delay;
  logic signed [15:0] c_y_delay[2];
  logic signed [15:0] c_z_delay[2];
  logic signed [15:0] d_y_delay[3];
  logic signed [15:0] d_z_delay[3];

  logic signed [15:0] center_in;
  logic signed [15:0] center_delay[8];
  logic [12:0] metadata_in;
  logic [12:0] center_metadata;

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

  wire [2:0] lane = din_chn[2:0];
  // D128 sees the retained phase at chn 0..7 and the adjacent phase at
  // chn 128..135. Both phases are filter samples for the same eight lanes,
  // but only the retained phase advances to D256 after decimation.
  wire lane_valid = din_dv && (din_chn[6:3] == '0) && ((DELAY_BASE == 128) || !din_chn[7]);
  wire [HistoryWidth-1:0] history_read = lane_history[lane];

  always_comb begin
    center_metadata = history_read[MetadataHistoryBase+2*13+:13];
    if ((DELAY_BASE == 128) && (center_metadata[10:3] >= 8'(NumLane))) begin
      center_metadata[11] = 1'b0;
    end
  end

  always_comb begin
    history_write = history_read;

    history_write[OddHistoryBase+:16] = din_dp2;
    for (int i = 1; i < NumOddHistory; i++) begin
      history_write[OddHistoryBase+i*16+:16] = history_read[OddHistoryBase+(i-1)*16+:16];
    end

    history_write[CenterHistoryBase+:16]   = din_dp1;
    history_write[MetadataHistoryBase+:13] = {din_last, din_dv, din_chn, din_sy, din_sl, din_sf};
    for (int i = 1; i < NumCenterHistory; i++) begin
      history_write[CenterHistoryBase+i*16+:16]   = history_read[CenterHistoryBase+(i-1)*16+:16];
      history_write[MetadataHistoryBase+i*13+:13] = history_read[MetadataHistoryBase+(i-1)*13+:13];
    end
  end

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

  // Per-lane event history

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < NumLane; i++) begin
        history_count[i] <= '0;
      end
    end else if (lane_valid) begin
      if (history_count[lane] < NumOddHistory) begin
        history_count[lane] <= history_count[lane] + 1'b1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      a_y0        <= '0;
      a_z0        <= '0;
      b_y0        <= '0;
      b_z0        <= '0;
      c_y0        <= '0;
      c_z0        <= '0;
      d_y0        <= '0;
      d_z0        <= '0;
      center_in   <= '0;
      metadata_in <= '0;
    end else if (lane_valid) begin
      a_y0 <= $signed(din_dp2);
      a_z0 <= history_count[lane] >= 7 ? $signed(history_read[OddHistoryBase+6*16+:16]) : '0;
      b_y0 <= history_count[lane] >= 1 ? $signed(history_read[OddHistoryBase+:16]) : '0;
      b_z0 <= history_count[lane] >= 6 ? $signed(history_read[OddHistoryBase+5*16+:16]) : '0;
      c_y0 <= history_count[lane] >= 2 ? $signed(history_read[OddHistoryBase+1*16+:16]) : '0;
      c_z0 <= history_count[lane] >= 5 ? $signed(history_read[OddHistoryBase+4*16+:16]) : '0;
      d_y0 <= history_count[lane] >= 3 ? $signed(history_read[OddHistoryBase+2*16+:16]) : '0;
      d_z0 <= history_count[lane] >= 4 ? $signed(history_read[OddHistoryBase+3*16+:16]) : '0;

      center_in <= history_count[lane] >= 3 ? $signed(
          history_read[CenterHistoryBase+2*16+:16]
      ) : '0;
      metadata_in <= history_count[lane] >= 3 ? center_metadata : '0;

      lane_history[lane] <= history_write;
    end else begin
      a_y0        <= '0;
      a_z0        <= '0;
      b_y0        <= '0;
      b_z0        <= '0;
      c_y0        <= '0;
      c_z0        <= '0;
      d_y0        <= '0;
      d_z0        <= '0;
      center_in   <= '0;
      metadata_in <= '0;
    end
  end

  // Tap alignment for the four-DSP cascade

  always_ff @(posedge clk) begin
    b_y_delay <= b_y0;
    b_z_delay <= b_z0;

    c_y_delay[0] <= c_y0;
    c_y_delay[1] <= c_y_delay[0];
    c_z_delay[0] <= c_z0;
    c_z_delay[1] <= c_z_delay[0];

    d_y_delay[0] <= d_y0;
    d_y_delay[1] <= d_y_delay[0];
    d_y_delay[2] <= d_y_delay[1];
    d_z_delay[0] <= d_z0;
    d_z_delay[1] <= d_z_delay[0];
    d_z_delay[2] <= d_z_delay[1];

    center_delay[0] <= center_in;
    for (int i = 1; i < 8; i++) begin
      center_delay[i] <= center_delay[i-1];
    end
  end

  // DSP1

  always_ff @(posedge clk) begin
    ay1 <= a_y0;
    az1 <= a_z0;
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
    by1 <= b_y_delay;
    bz1 <= b_z_delay;
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
    cy1 <= c_y_delay[1];
    cz1 <= c_z_delay[1];
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
    dy1 <= d_y_delay[2];
    dz1 <= d_z_delay[2];
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
    dq <= 39'(dresult) + $signed({{7{center_delay[6][15]}}, center_delay[6], 16'b0});
  end

  // TODO: saturate
  always_ff @(posedge clk) begin
    if (ctrl_bypass_s) begin
      dout_dq <= center_delay[7];
    end else begin
      dout_dq <= dq[32:17];
    end
  end

  delay #(
      .WIDTH(13),
      .DEPTH(9),
      .INIT (1'b1)
  ) u_delay (
      .clk (clk),
      .cen (1'b1),
      .rst (rst),
      .din (metadata_in),
      .dout({dout_last, dout_dv, dout_chn, dout_sy, dout_sl, dout_sf})
  );

  wire unused_sparse = &{1'b0, dq[38:33], dq[16:0]};

endmodule

`default_nettype wire
