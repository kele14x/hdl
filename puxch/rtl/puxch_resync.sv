`timescale 1 ns / 1 ps
//
`default_nettype none

module puxch_resync #(
    parameter int NUM_ANT = 4
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        sync_in,
    //
    input  wire [31:0] s_axis_tdata [NUM_ANT],
    input  wire [ 7:0] s_axis_tuser [NUM_ANT],
    input  wire        s_axis_tlast [NUM_ANT],
    input  wire        s_axis_tvalid[NUM_ANT],
    output wire        s_axis_tready[NUM_ANT],
    //
    output reg  [15:0] dout_dr,
    output reg  [15:0] dout_di,
    output reg         dout_sf,
    output reg         dout_sl,
    output reg         dout_sy,
    output reg  [ 3:0] dout_chn,
    output reg         dout_dv,
    output wire        dout_last,
    // CSR
    input  wire [ 3:0] ctrl_en,
    input  wire [ 1:0] ctrl_rat,
    input  wire [ 3:0] ctrl_bist,
    input  wire [ 3:0] ctrl_bw
);

  // sync_in => start_of_frame => chn => dout_chn
  //
  localparam int CtrlSignalWidth = 4 + 2 + 4 + 4;

  // Signals

  logic [3:0] ctrl_en_s;
  logic [1:0] ctrl_rat_s;
  logic [3:0] ctrl_bist_s;
  logic [3:0] ctrl_bw_s;

  logic       stat_resync;

  logic       start_of_frame;
  logic       start_of_slot;
  logic [1:0] start_of_symbol;

  logic       start_of_frame_d;
  logic       start_of_slot_d;
  logic       start_of_symbol_d;

  logic [3:0] chn_max;
  logic [3:0] chn;

  localparam int AntIndexWidth = (NUM_ANT <= 1) ? 1 : $clog2(NUM_ANT);

  wire [AntIndexWidth-1:0] chn_idx;

  assign chn_idx = chn[AntIndexWidth-1:0];

  // CDC for control signals

  // Single CDC for all control signals
  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (CtrlSignalWidth)
  ) u_ctrl_cdc (
      .src_clk (1'b1),
      .src_in  ({ctrl_en, ctrl_rat, ctrl_bist, ctrl_bw}),
      .dest_clk(clk),
      .dest_out({ctrl_en_s, ctrl_rat_s, ctrl_bist_s, ctrl_bw_s})
  );

  // Main

  assign s_axis_tready = '{NUM_ANT{1'b1}};

  always_comb begin
    case (ctrl_bw_s)
      4'b0000: chn_max = 4'd15;  // 7.68 (30.72)
      4'b0001: chn_max = 4'd15;  // 15.36 (30.72)
      4'b0010: chn_max = 4'd15;  // 30.72
      4'b0011: chn_max = 4'd7;  // 61.44
      default: chn_max = 4'd3;  // 122.88
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      chn <= '0;
    end else if (start_of_frame) begin
      chn <= '0;
    end else begin
      chn <= (chn == chn_max) ? '0 : chn + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (chn < 4'(NUM_ANT)) begin
      if (ctrl_en_s[chn[1:0]]) begin
        {dout_di, dout_dr} <= s_axis_tdata[chn_idx];
      end else begin
        {dout_di, dout_dr} <= '0;
      end
    end else begin
      {dout_di, dout_dr} <= '0;
    end
  end

  always_ff @(posedge clk) begin
    start_of_frame_d <= start_of_frame;
    start_of_slot_d  <= start_of_slot;
    if (ctrl_rat_s <= 2'd1) begin
      // 15 kHz SCS
      start_of_symbol_d <= start_of_symbol[0];
    end else begin
      // 30 kHz SCS
      start_of_symbol_d <= start_of_symbol[1];
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_sf <= 1'b0;
    end else if (start_of_frame_d) begin
      dout_sf <= 1'b1;
    end else if (dout_chn == 4'(NUM_ANT - 1)) begin
      dout_sf <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_sl <= 1'b0;
    end else if (start_of_slot_d) begin
      dout_sl <= 1'b1;
    end else if (dout_chn == 4'(NUM_ANT - 1)) begin
      dout_sl <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_sy <= 1'b0;
    end else if (start_of_symbol_d) begin
      dout_sy <= 1'b1;
    end else if (dout_chn == 4'(NUM_ANT - 1)) begin
      dout_sy <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    dout_chn <= chn;
  end

  always_ff @(posedge clk) begin
    if (chn < 4'(NUM_ANT)) begin
      // Assert all dout_dv if at least one channel is enabled
      dout_dv <= |ctrl_en_s;
    end else begin
      dout_dv <= 1'b0;
    end
  end

  assign dout_last = 1'b0;

  // Symbol timer

  symbol_timer #(
      .ASYNC(1'b1),
      .MODE (1'b0),
      .FREQ (128),
      .AUTO (1'b0)
  ) u_symbol_timer (
      .clk            (clk),
      .rst            (rst),
      //
      .sync           (sync_in),
      //
      .start_of_frame (start_of_frame),
      .start_of_slot  (start_of_slot),
      .start_of_symbol(start_of_symbol),
      //
      .ctrl_delay     ('0),
      .stat_resync    (stat_resync)
  );

  wire unused_resync = &{1'b0, s_axis_tuser, s_axis_tlast, s_axis_tvalid, ctrl_bist_s, stat_resync};

endmodule

`default_nettype wire
