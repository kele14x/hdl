`timescale 1 ns / 1 ps
//
`default_nettype none

module puxch_channel #(
    parameter int NUM_ANT    = 4,
    /* verilator lint_off UNUSED */
    parameter int HALF_BLOCK = 0,
    /* verilator lint_on UNUSED */
    parameter int HALF_FFT   = 0
) (
    // Internal I/F
    //-------------
    input var         clk,
    input var         rst,
    //
    input var  [31:0] s_axis_tdata         [NUM_ANT],
    input var  [ 7:0] s_axis_tuser         [NUM_ANT],
    input var         s_axis_tlast         [NUM_ANT],
    input var         s_axis_tvalid        [NUM_ANT],
    output var        s_axis_tready        [NUM_ANT],
    //
    output var [15:0] dout_dr,
    output var [15:0] dout_di,
    output var        dout_sf,
    output var        dout_sl,
    output var        dout_sy,
    output var [ 3:0] dout_chn,
    output var        dout_dv,
    output var        dout_last,
    // O-RAN I/F
    //----------
    input var         clk_eth_xran,
    input var         rst_eth_xran,
    //
    input var         sync_in,
    //
    output var        fram_radio_start_10ms,
    // CSR
    //----
    input var         ctrl_clk,
    input var         ctrl_rst,
    //
    input var  [ 3:0] ctrl_en,
    input var  [ 1:0] ctrl_rat,
    input var  [ 3:0] ctrl_bist,
    input var  [ 3:0] ctrl_bw,
    input var  [ 8:0] ctrl_nprb,
    input var  [22:0] ctrl_rfs_offset,
    //
    input var  [16:0] ctrl_gain            [NUM_ANT],
    // addr = [3:0]symbol
    input var  [ 3:0] ctrl_phase_comp_addr,
    input var         ctrl_phase_comp_we,
    input var  [31:0] ctrl_phase_comp_din
);

  localparam int LogFftSize = (HALF_FFT != 0) ? 11 : 12;

  // HALF_BLOCK is retained for compatibility with existing instantiations.

  logic [ 1:0] ctrl_rat_s;
  logic [22:0] ctrl_rfs_offset_s;

  logic        sync_s;
  logic        sync_s_cdc;

  logic [15:0] offset;

  logic [15:0] resync_dout_dr;
  logic [15:0] resync_dout_di;
  logic        resync_dout_sf;
  logic        resync_dout_sl;
  logic        resync_dout_sy;
  logic [ 3:0] resync_dout_chn;
  logic        resync_dout_dv;
  logic        resync_dout_last;

  logic [15:0] gain_dout_dr;
  logic [15:0] gain_dout_di;
  logic        gain_dout_sf;
  logic        gain_dout_sl;
  logic        gain_dout_sy;
  logic [ 3:0] gain_dout_chn;
  logic        gain_dout_dv;
  logic        gain_dout_last;

  logic [15:0] conv_dout_dr;
  logic [15:0] conv_dout_di;
  logic        conv_dout_sf;
  logic        conv_dout_sl;
  logic        conv_dout_sy;
  logic [ 3:0] conv_dout_chn;
  logic        conv_dout_dv;
  logic        conv_dout_last;

  logic [15:0] fft_dout_dr;
  logic [15:0] fft_dout_di;
  /* verilator lint_off UNUSED */
  logic        fft_stat_ovf;
  /* verilator lint_on UNUSED */
  logic        fft_dout_sf;
  logic        fft_dout_sl;
  logic        fft_dout_sy;
  logic [ 3:0] fft_dout_chn;
  logic        fft_dout_dv;
  logic        fft_dout_last;

  logic [15:0] phase_comp_dout_dr;
  logic [15:0] phase_comp_dout_di;
  logic        phase_comp_dout_sf;
  logic        phase_comp_dout_sl;
  logic        phase_comp_dout_sy;
  logic [ 3:0] phase_comp_dout_chn;
  logic        phase_comp_dout_dv;
  logic        phase_comp_dout_last;

  logic [ 1:0] ctrl_size;
  logic [ 1:0] ctrl_itlv;

  // Main

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_rat == 2'b00) begin  // LTE
      ctrl_size <= 2'b01;  // 2k
    end else if (ctrl_rat == 2'b01) begin  // NR 15 kHz SCS
      case (ctrl_bw)
        4'd0:    ctrl_size <= 2'b01; // 2k
        4'd1:    ctrl_size <= 2'b01; // 2k
        4'd2:    ctrl_size <= 2'b01; // 2k
        default: ctrl_size <= 2'b10; // 4k
      endcase
    end else begin  // NR 30kHz SCS
      case (ctrl_bw)
        4'd0:    ctrl_size <= 2'b00; // 1k
        4'd1:    ctrl_size <= 2'b00; // 1k
        4'd2:    ctrl_size <= 2'b00; // 1k
        4'd3:    ctrl_size <= 2'b01; // 2k
        default: ctrl_size <= 2'b10; // 4k
      endcase
    end
  end

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_rat == 2'b00) begin  // LTE
      ctrl_itlv <= 2'b00;  // 16
    end else if (ctrl_rat == 2'b01) begin  // NR 15 kHz SCS
      case (ctrl_bw)
        4'd0:    ctrl_itlv <= 2'b00; // 16
        4'd1:    ctrl_itlv <= 2'b00; // 16
        4'd2:    ctrl_itlv <= 2'b00; // 16
        default: ctrl_itlv <= 2'b01; // 8
      endcase
    end else begin  // NR 30kHz SCS
      case (ctrl_bw)
        4'd0:    ctrl_itlv <= 2'b00; // 16
        4'd1:    ctrl_itlv <= 2'b00; // 16
        4'd2:    ctrl_itlv <= 2'b00; // 16
        4'd3:    ctrl_itlv <= 2'b01; // 8
        default: ctrl_itlv <= 2'b10; // 4
      endcase
    end
  end

  // sync_in -> | rfs_offset | -> sync_s -> | offset | -> fram_radio_start_10ms
  //                                     -> | CDC | -> sync_s_cdc

  // Single CDC for control signals
  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (23 + 2)
  ) u_ctrl_cdc (
      .src_clk (1'b1),
      .src_in  ({ctrl_rat, ctrl_rfs_offset}),
      .dest_clk(clk_eth_xran),
      .dest_out({ctrl_rat_s, ctrl_rfs_offset_s})
  );

  // Delay the sync_in pulse to align with the start of the 10ms symbol,
  // this is start time of PUXCH Channel processing
  pulse_delay #(
      .WIDTH(23)
  ) u_pulse_delay_in (
      .clk      (clk_eth_xran),
      .rst      (rst_eth_xran),
      //
      .pulse_in (sync_in),
      .pulse_out(sync_s),
      //
      .delay    (ctrl_rfs_offset_s)
  );

  // Delay the sync_in pulse to align the output of PUXCH with the start of the 10ms symbol
  // It's output will be feed into ORAN-IF IP, this is the end time of PUXCH Channel output
  always_comb begin
    if (ctrl_rat_s <= 1) begin  // 15 kHz SCS
      offset = 54477;  // (2048+2048+160)*16*2/2.5
    end else begin  // 30 kHz SCS
      offset = 27341;  // (1024+1024+88)*16*2/2.5
    end
  end

  pulse_delay #(
      .WIDTH(16)
  ) u_pulse_delay_out (
      .clk      (clk_eth_xran),
      .rst      (rst_eth_xran),
      //
      .pulse_in (sync_s),
      .pulse_out(fram_radio_start_10ms),
      //
      .delay    (offset)
  );

  // CDC for sync_s to clk domain
  cdc_pulse #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .REG_OUTPUT  (1),
      .RST_USED    (1)
  ) u_cdc_pulse (
      .src_clk   (clk_eth_xran),
      .src_rst   (rst_eth_xran),
      .src_pulse (sync_s),
      //
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(sync_s_cdc)
  );

  puxch_resync #(
      .NUM_ANT(NUM_ANT)
  ) u_resync (
      .clk          (clk),
      .rst          (rst),
      //
      .sync_in      (sync_s_cdc),
      //
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tuser (s_axis_tuser),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tvalid(s_axis_tvalid),
      .s_axis_tready(s_axis_tready),
      //
      .dout_dr      (resync_dout_dr),
      .dout_di      (resync_dout_di),
      .dout_sf      (resync_dout_sf),
      .dout_sl      (resync_dout_sl),
      .dout_sy      (resync_dout_sy),
      .dout_chn     (resync_dout_chn),
      .dout_dv      (resync_dout_dv),
      .dout_last    (resync_dout_last),
      // CSR
      .ctrl_en      (ctrl_en),
      .ctrl_rat     (ctrl_rat),
      .ctrl_bist    (ctrl_bist),
      .ctrl_bw      (ctrl_bw)
  );

  gain #(
      .HAS_CDC   (1),
      .NUM_ANT   (NUM_ANT),
      .COMPLEX   (0),
      .GAIN_WIDTH(17)
  ) u_gain (
      .clk         (clk),
      .rst         (rst),
      //
      .din_dr      (resync_dout_dr),
      .din_di      (resync_dout_di),
      .din_sf      (resync_dout_sf),
      .din_sl      (resync_dout_sl),
      .din_sy      (resync_dout_sy),
      .din_chn     (resync_dout_chn),
      .din_dv      (resync_dout_dv),
      .din_last    (resync_dout_last),
      //
      .dout_dr     (gain_dout_dr),
      .dout_di     (gain_dout_di),
      .dout_sf     (gain_dout_sf),
      .dout_sl     (gain_dout_sl),
      .dout_sy     (gain_dout_sy),
      .dout_chn    (gain_dout_chn),
      .dout_dv     (gain_dout_dv),
      .dout_last   (gain_dout_last),
      //----
      .ctrl_gain_dr(ctrl_gain),
      .ctrl_gain_di('{NUM_ANT{'0}})
  );

  puxch_conv #(
      .NUM_ANT(NUM_ANT)
  ) u_conv (
      .clk      (clk),
      .rst      (rst),
      //
      .din_dr   (gain_dout_dr),
      .din_di   (gain_dout_di),
      .din_sf   (gain_dout_sf),
      .din_sl   (gain_dout_sl),
      .din_sy   (gain_dout_sy),
      .din_chn  (gain_dout_chn),
      .din_dv   (gain_dout_dv),
      .din_last (gain_dout_last),
      //
      .dout_dr  (conv_dout_dr),
      .dout_di  (conv_dout_di),
      .dout_sf  (conv_dout_sf),
      .dout_sl  (conv_dout_sl),
      .dout_sy  (conv_dout_sy),
      .dout_chn (conv_dout_chn),
      .dout_dv  (conv_dout_dv),
      .dout_last(conv_dout_last),
      //
      .ctrl_rat (ctrl_rat),
      .ctrl_bw  (ctrl_bw),
      .ctrl_nprb(ctrl_nprb)
  );

  fft #(
      .NUM_ANT           (NUM_ANT),
      .INV_FFT           (0),
      .LOG_FFT_SIZE      (LogFftSize),
      .DATA_WIDTH        (16),
      .BIT_REVERSED_INPUT(0)
  ) u_fft (
      .clk      (clk),
      .rst      (rst),
      //
      .din_dr   (conv_dout_dr),
      .din_di   (conv_dout_di),
      .din_sf   (conv_dout_sf),
      .din_sl   (conv_dout_sl),
      .din_sy   (conv_dout_sy),
      .din_chn  (conv_dout_chn),
      .din_dv   (conv_dout_dv),
      .din_last (conv_dout_last),
      //
      .dout_dr  (fft_dout_dr),
      .dout_di  (fft_dout_di),
      .dout_sf  (fft_dout_sf),
      .dout_sl  (fft_dout_sl),
      .dout_sy  (fft_dout_sy),
      .dout_chn (fft_dout_chn),
      .dout_dv  (fft_dout_dv),
      .dout_last(fft_dout_last),
      //
      .ctrl_size(ctrl_size),
      .ctrl_itlv(ctrl_itlv),
      .stat_ovf (fft_stat_ovf)
      //
  );

  phase_comp #(
      .HAS_CDC(1),
      .NUM_ANT(NUM_ANT)
  ) u_phase_comp (
      .clk                 (clk),
      .rst                 (rst),
      //
      .din_dr              (fft_dout_dr),
      .din_di              (fft_dout_di),
      .din_sf              (fft_dout_sf),
      .din_sl              (fft_dout_sl),
      .din_sy              (fft_dout_sy),
      .din_chn             (fft_dout_chn),
      .din_dv              (fft_dout_dv),
      .din_last            (fft_dout_last),
      //
      .dout_dr             (phase_comp_dout_dr),
      .dout_di             (phase_comp_dout_di),
      .dout_sf             (phase_comp_dout_sf),
      .dout_sl             (phase_comp_dout_sl),
      .dout_sy             (phase_comp_dout_sy),
      .dout_chn            (phase_comp_dout_chn),
      .dout_dv             (phase_comp_dout_dv),
      .dout_last           (phase_comp_dout_last),
      //----
      .ctrl_clk            (ctrl_clk),
      .ctrl_rst            (ctrl_rst),
      //
      .ctrl_rat            (ctrl_rat),
      //
      .ctrl_phase_comp_addr(ctrl_phase_comp_addr),
      .ctrl_phase_comp_we  (ctrl_phase_comp_we),
      .ctrl_phase_comp_din (ctrl_phase_comp_din)
  );

  assign dout_dr   = phase_comp_dout_dr;
  assign dout_di   = phase_comp_dout_di;
  assign dout_sf   = phase_comp_dout_sf;
  assign dout_sl   = phase_comp_dout_sl;
  assign dout_sy   = phase_comp_dout_sy;
  assign dout_chn  = phase_comp_dout_chn;
  assign dout_dv   = phase_comp_dout_dv;
  assign dout_last = phase_comp_dout_last;

endmodule

`default_nettype wire
