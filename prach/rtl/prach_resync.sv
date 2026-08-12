`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_resync #(
    parameter int NUM_ANT = 4
) (
    input var         clk,
    input var         rst,
    //
    input var         sync_in,
    //
    input var  [31:0] s_axis_tdata [NUM_ANT],
    input var  [ 7:0] s_axis_tuser [NUM_ANT],
    input var         s_axis_tlast [NUM_ANT],
    input var         s_axis_tvalid[NUM_ANT],
    output var        s_axis_tready[NUM_ANT],
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
    input var  [ 3:0] ctrl_en,
    input var  [ 3:0] ctrl_bist,
    input var  [ 3:0] ctrl_bw
);

  // Notes
  // sync_in => start_of_frame => chn => dout_chn

  // Parameters

  localparam int CtrlSignalWidth = 4 + 4 + 4;

  // Signals

  logic [                3:0] ctrl_en_s;
  logic [                3:0] ctrl_bist_s;
  logic [                3:0] ctrl_bw_s;

  logic [CtrlSignalWidth-1:0] ctrl_combined;
  logic [CtrlSignalWidth-1:0] ctrl_combined_s;

  logic                       stat_resync;

  logic                       start_of_frame;
  logic                       start_of_slot;
  logic [                1:0] start_of_symbol;

  logic                       start_of_frame_d;
  logic                       start_of_slot_d;
  logic                       start_of_symbol_d;

  // Counter output 0 ~ 255 for PRACH (1.92 MHz)
  logic [                7:0] chn_out;

  // Internal counter for polling input AXIS
  logic [                3:0] chn_max;
  logic [                3:0] chn;

  localparam int AntIndexWidth = (NUM_ANT <= 1) ? 1 : $clog2(NUM_ANT);

  wire [AntIndexWidth-1:0] chn_idx;

  assign chn_idx = chn[AntIndexWidth-1:0];

  // CDC for control signals

  // Pack all control signals into a single wide bus
  assign ctrl_combined = {ctrl_en, ctrl_bist, ctrl_bw};

  // Single CDC for all control signals
  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (CtrlSignalWidth)
  ) i_cdc_ctrl_signals (
      .src_clk (1'b1),
      .src_in  (ctrl_combined),
      .dest_clk(clk),
      .dest_out(ctrl_combined_s)
  );

  // Unpack the combined signals
  assign {ctrl_en_s, ctrl_bist_s, ctrl_bw_s} = ctrl_combined_s;

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
      chn <= 'd0;
    end else if (start_of_frame) begin
      chn <= 'd0;
    end else begin
      chn <= (chn == chn_max) ? '0 : chn + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      chn_out <= 'd0;
    end else if (start_of_frame) begin
      chn_out <= 'd0;
    end else begin
      chn_out <= chn_out + 1'b1;
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

  // For PRACH, we always use 15 kHz SCS to count the symbol number
  always_ff @(posedge clk) begin
    start_of_frame_d  <= start_of_frame;
    start_of_slot_d   <= start_of_slot;
    start_of_symbol_d <= start_of_symbol[0];
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_sf <= 1'b0;
    end else if (start_of_frame_d) begin
      dout_sf <= 1'b1;
    end else if (dout_chn == 8'(NUM_ANT - 1)) begin
      dout_sf <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_sl <= 1'b0;
    end else if (start_of_slot_d) begin
      dout_sl <= 1'b1;
    end else if (dout_chn == 8'(NUM_ANT - 1)) begin
      dout_sl <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_sy <= 1'b0;
    end else if (start_of_symbol_d) begin
      dout_sy <= 1'b1;
    end else if (dout_chn == 8'(NUM_ANT - 1)) begin
      dout_sy <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    dout_chn <= chn_out;
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
      .ASYNC(0),
      .MODE (0),
      .FREQ (128),
      .AUTO (0)
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

endmodule

`default_nettype wire
