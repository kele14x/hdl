// File: fft_stage.sv
// Brief: FFT process stage. Each stage includes:
//          - 1 Twiddler (twidder factor ROM and complex multiplier)
//          - 1 or 2 Butterfly operator
`timescale 1 ns / 1 ps
//
`default_nettype none

module fft_stage #(
    parameter integer NUM_ANT            = 4,
    parameter logic   INV_FFT            = 1'b0,
    parameter integer LOG_FFT_SIZE       = 4,
    parameter integer DATA_WIDTH         = 18,
    parameter logic   BIT_REVERSED_INPUT = 1'b1
) (
    input  wire                         clk,
    input  wire                         rst,
    // Input
    input  wire signed [DATA_WIDTH-1:0] din_dr,
    input  wire signed [DATA_WIDTH-1:0] din_di,
    input  wire                         din_dv,
    // Output
    output wire signed [DATA_WIDTH-1:0] dout_dr,
    output wire signed [DATA_WIDTH-1:0] dout_di,
    output wire                         dout_dv,
    //
    input  wire        [           1:0] ctrl_itlv,
    input  wire        [           1:0] ctrl_bypass,
    input  wire                         ctrl_scale,
    //
    output wire                         stat_ovf
);

  // Local parameter

  // For N = 2 or 4 FFT stage, twiddle is not needed
  localparam logic HasTwiddle = (LOG_FFT_SIZE > 2) ? 1 : 0;

  // If LOG_FFT_SIZE is an even number, we have 2 Butterfly operator
  localparam logic HasBf2ii = (LOG_FFT_SIZE % 2 == 0) ? 1 : 0;
  // Log2 FFT size of BF2I
  localparam integer LogFftSizeBf2i = HasBf2ii ? (LOG_FFT_SIZE - 1) : LOG_FFT_SIZE;
  // The LOG_FFT_SIZE=2 stage has no twiddle multiplier to provide the /2
  // scaling used by the other stages. Scale its last butterfly explicitly.
  localparam logic ScaleBfi = !HasTwiddle && !BIT_REVERSED_INPUT;
  localparam logic ScaleBfii = !HasTwiddle && BIT_REVERSED_INPUT;

  // Signals

  wire signed [DATA_WIDTH-1:0] twiddle_din_dr;
  wire signed [DATA_WIDTH-1:0] twiddle_din_di;
  wire                         twiddle_din_dv;

  wire signed [DATA_WIDTH-1:0] twiddle_dout_dr;
  wire signed [DATA_WIDTH-1:0] twiddle_dout_di;
  wire                         twiddle_dout_dv;

  wire signed [DATA_WIDTH-1:0] bfi_din_dr;
  wire signed [DATA_WIDTH-1:0] bfi_din_di;
  wire                         bfi_din_dv;

  wire signed [DATA_WIDTH-1:0] bfi_dout_dr;
  wire signed [DATA_WIDTH-1:0] bfi_dout_di;
  wire                         bfi_dout_dv;

  wire signed [DATA_WIDTH-1:0] ct_din_dr;
  wire signed [DATA_WIDTH-1:0] ct_din_di;
  wire                         ct_din_dv;

  wire signed [DATA_WIDTH-1:0] ct_dout_dr;
  wire signed [DATA_WIDTH-1:0] ct_dout_di;
  wire                         ct_dout_dv;

  wire signed [DATA_WIDTH-1:0] bfii_din_dr;
  wire signed [DATA_WIDTH-1:0] bfii_din_di;
  wire                         bfii_din_dv;

  wire signed [DATA_WIDTH-1:0] bfii_dout_dr;
  wire signed [DATA_WIDTH-1:0] bfii_dout_di;
  wire                         bfii_dout_dv;

  wire                         bfi_bypass;
  wire                         unused_ct_bypass;
  wire        [           1:0] unused_twiddle_bypass;
  wire                         bfii_bypass;

  wire                         twiddle_ovf;
  wire                         bfi_ovf;
  wire                         bfii_ovf;

  // Main

  generate
    if (HasTwiddle) begin : g_twiddle

      (* keep_hierarchy="yes" *)
      fft_twiddle #(
          .NUM_ANT     (NUM_ANT),
          .INV_FFT     (INV_FFT),
          .LOG_FFT_SIZE(LOG_FFT_SIZE),
          .DATA_WIDTH  (DATA_WIDTH)
      ) i_twiddle (
          .clk        (clk),
          .rst        (rst),
          // Input
          .din_dr     (twiddle_din_dr),
          .din_di     (twiddle_din_di),
          .din_dv     (twiddle_din_dv),
          // Output
          .dout_dr    (twiddle_dout_dr),
          .dout_di    (twiddle_dout_di),
          .dout_dv    (twiddle_dout_dv),
          //
          .ctrl_itlv  (ctrl_itlv),
          .ctrl_bypass(unused_twiddle_bypass),
          // Status
          .stat_ovf   (twiddle_ovf)
      );

    end else begin : g_no_twiddle

      assign twiddle_dout_dr = twiddle_din_dr;
      assign twiddle_dout_di = twiddle_din_di;
      assign twiddle_dout_dv = twiddle_din_dv;

      assign twiddle_ovf = 1'b0;

    end
  endgenerate

  // The butterfly operator

  (* keep_hierarchy="yes" *)
  fft_bf2 #(
      .NUM_ANT     (NUM_ANT),
      .LOG_FFT_SIZE(LogFftSizeBf2i),
      .DATA_WIDTH  (DATA_WIDTH),
      .SCALE       (ScaleBfi)
  ) i_bf2i (
      .clk        (clk),
      .rst        (rst),
      //
      .din_dr     (bfi_din_dr),
      .din_di     (bfi_din_di),
      .din_dv     (bfi_din_dv),
      //
      .dout_dr    (bfi_dout_dr),
      .dout_di    (bfi_dout_di),
      .dout_dv    (bfi_dout_dv),
      //
      .ctrl_itlv  (ctrl_itlv),
      .ctrl_bypass(bfi_bypass),
      .ctrl_scale (ctrl_scale),
      //
      .stat_ovf   (bfi_ovf)
  );

  generate
    if (HasBf2ii) begin : g_bf2ii

      (* keep_hierarchy="yes" *)
      fft_ct #(
          .NUM_ANT     (NUM_ANT),
          .INV_FFT     (INV_FFT),
          .LOG_FFT_SIZE(LOG_FFT_SIZE),
          .DATA_WIDTH  (DATA_WIDTH)
      ) i_ct (
          .clk        (clk),
          .rst        (rst),
          //
          .din_dr     (ct_din_dr),
          .din_di     (ct_din_di),
          .din_dv     (ct_din_dv),
          //
          .dout_dr    (ct_dout_dr),
          .dout_di    (ct_dout_di),
          .dout_dv    (ct_dout_dv),
          //
          .ctrl_itlv  (ctrl_itlv),
          .ctrl_bypass(unused_ct_bypass)
      );

      (* keep_hierarchy="yes" *)
      fft_bf2 #(
          .NUM_ANT     (NUM_ANT),
          .LOG_FFT_SIZE(LOG_FFT_SIZE),
          .DATA_WIDTH  (DATA_WIDTH),
          .SCALE       (ScaleBfii)
      ) i_bf2ii (
          .clk        (clk),
          .rst        (rst),
          //
          .din_dr     (bfii_din_dr),
          .din_di     (bfii_din_di),
          .din_dv     (bfii_din_dv),
          //
          .dout_dr    (bfii_dout_dr),
          .dout_di    (bfii_dout_di),
          .dout_dv    (bfii_dout_dv),
          //
          .ctrl_itlv  (ctrl_itlv),
          .ctrl_bypass(bfii_bypass),
          .ctrl_scale (ctrl_scale),
          //
          .stat_ovf   (bfii_ovf)
      );

    end else begin : g_no_bf2ii

      assign ct_dout_dr = ct_din_dr;
      assign ct_dout_di = ct_din_di;
      assign ct_dout_dv = ct_din_dv;

      assign bfii_dout_dr = bfii_din_dr;
      assign bfii_dout_di = bfii_din_di;
      assign bfii_dout_dv = bfii_din_dv;

      assign bfii_ovf = bfii_bypass & 1'b0;

    end
  endgenerate

  generate
    if (BIT_REVERSED_INPUT) begin : g_dit_fft

      // Twiddle -> BFi -> [CT -> BFii]

      assign twiddle_din_dr        = din_dr;
      assign twiddle_din_di        = din_di;
      assign twiddle_din_dv        = din_dv;

      assign bfi_din_dr            = twiddle_dout_dr;
      assign bfi_din_di            = twiddle_dout_di;
      assign bfi_din_dv            = twiddle_dout_dv;

      assign ct_din_dr             = bfi_dout_dr;
      assign ct_din_di             = bfi_dout_di;
      assign ct_din_dv             = bfi_dout_dv;

      assign bfii_din_dr           = ct_dout_dr;
      assign bfii_din_di           = ct_dout_di;
      assign bfii_din_dv           = ct_dout_dv;

      assign dout_dr               = bfii_dout_dr;
      assign dout_di               = bfii_dout_di;
      assign dout_dv               = bfii_dout_dv;

      assign unused_twiddle_bypass = HasBf2ii ? ctrl_bypass : {2{ctrl_bypass[0]}};

      assign bfi_bypass            = ctrl_bypass[0];
      assign unused_ct_bypass      = ctrl_bypass[1];
      assign bfii_bypass           = ctrl_bypass[1];

    end else begin : g_dif_fft

      // [BFII -> CT] -> BFI -> Twiddle

      assign bfii_din_dr           = din_dr;
      assign bfii_din_di           = din_di;
      assign bfii_din_dv           = din_dv;

      assign ct_din_dr             = bfii_dout_dr;
      assign ct_din_di             = bfii_dout_di;
      assign ct_din_dv             = bfii_dout_dv;

      assign bfi_din_dr            = ct_dout_dr;
      assign bfi_din_di            = ct_dout_di;
      assign bfi_din_dv            = ct_dout_dv;

      assign twiddle_din_dr        = bfi_dout_dr;
      assign twiddle_din_di        = bfi_dout_di;
      assign twiddle_din_dv        = bfi_dout_dv;

      assign dout_dr               = twiddle_dout_dr;
      assign dout_di               = twiddle_dout_di;
      assign dout_dv               = twiddle_dout_dv;

      assign unused_twiddle_bypass = HasBf2ii ? ctrl_bypass : {2{ctrl_bypass[1]}};

      assign bfii_bypass           = ctrl_bypass[0];
      assign unused_ct_bypass      = ctrl_bypass[0];
      assign bfi_bypass            = ctrl_bypass[1];

    end
  endgenerate

  assign stat_ovf = twiddle_ovf | bfi_ovf | bfii_ovf;

endmodule

`default_nettype wire
