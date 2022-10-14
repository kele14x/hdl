// File: fft_stage.v
// Brief: FFT process stage. Each stage includes:
//          - 1 Twiddler (twidder factor ROM and complex multiplier)
//          - 1 or 2 Butterfly operator
`timescale 1 ns / 1 ps
//
`default_nettype none

module fft_stage #(
    parameter int LOG_FFT_SIZE       = 4,
    parameter int DATA_WIDTH         = 16,
    parameter int PHASE_WIDTH        = 16,
    parameter bit BIT_REVERSED_INPUT = 1   // ?
) (
    input var                          clk,
    input var                          rst,
    // Input
    input var  signed [DATA_WIDTH-1:0] data_i_in,
    input var  signed [DATA_WIDTH-1:0] data_q_in,
    input var                          data_valid_in,
    input var                          data_last_in,
    // Output
    output var signed [DATA_WIDTH+1:0] data_i_out,
    output var signed [DATA_WIDTH+1:0] data_q_out,
    output var                         data_valid_out,
    output var                         data_last_out,
    // Status
    output var                         ovf
);


  // Local parameter
  //================

  // For N = 2 or 4 FFT stage, twiddle is not needed
  localparam bit HasTwiddle = (LOG_FFT_SIZE == 0 || LOG_FFT_SIZE == 1) ? 0 : 1;

  // If LOG_FFT_SIZE is an even number, we have 2 Butterfly operator
  localparam bit HasBf2ii = (LOG_FFT_SIZE % 2 == 0);

  // Log2 FFT size of BF2I
  localparam int LogFftSizeBf2i = HasBf2ii ? (LOG_FFT_SIZE - 1) : LOG_FFT_SIZE;

  // Latency of Butterfly I
  localparam int LatencyBf2i  = 2 ** (LogFftSizeBf2i - 1) + 1;
  // Latency of Butterfly II
  localparam int LatencyBf2ii = HasBf2ii ? (2 ** (LOG_FFT_SIZE - 1) + 1) : 0;
  // Latency of Twiddle
  localparam int LatencyTwiddle = 10;
  // Total latency
  localparam int Latency = LatencyBf2i + LatencyBf2ii + LatencyTwiddle;


  // Signals
  //========

  logic signed [DATA_WIDTH-1:0] twiddle_data_i_in;
  logic signed [DATA_WIDTH-1:0] twiddle_data_q_in;
  logic                         twiddle_data_valid_in;
  logic                         twiddle_data_last_in;

  logic signed [DATA_WIDTH-1:0] twiddle_data_i_out;
  logic signed [DATA_WIDTH-1:0] twiddle_data_q_out;
  logic                         twiddle_data_valid_out;
  logic                         twiddle_data_last_out;

  logic signed [DATA_WIDTH-1:0] bf_data_i_in;
  logic signed [DATA_WIDTH-1:0] bf_data_q_in;
  logic                         bf_data_valid_in;
  logic                         bf_data_last_in;

  logic signed [DATA_WIDTH-1:0] bf_data_i_out;
  logic signed [DATA_WIDTH-1:0] bf_data_q_out;
  logic                         bf_data_valid_out;
  logic                         bf_data_last_out;

  logic signed [  DATA_WIDTH:0] bf_data_i_s;
  logic signed [  DATA_WIDTH:0] bf_data_q_s;
  logic                         bf_data_valid_s;
  logic                         bf_data_last_s;


  // Main
  //=====

  generate
    if (HasTwiddle) begin : g_twiddle

      fft_twiddle #(
          .LOG_SIZE   (LOG_FFT_SIZE),
          .DATA_WIDTH (DATA_WIDTH),
          .PHASE_WIDTH(PHASE_WIDTH)
      ) i_twiddle (
          .clk           (clk),
          .rst           (rst),
          // Input
          .data_i_in     (twiddle_data_i_in),
          .data_q_in     (twiddle_data_q_in),
          .data_valid_in (twiddle_data_valid_in),
          .data_last_in  (twiddle_data_last_in),
          // Output
          .data_i_out    (twiddle_data_i_out),
          .data_q_out    (twiddle_data_q_out),
          .data_valid_out(twiddle_data_valid_out),
          .data_last_out (twiddle_data_last_out),
          // Status
          .ovf           (ovf)
      );

    end else begin : g_no_twiddle

      assign twiddle_data_i_out     = twiddle_data_i_in;
      assign twiddle_data_q_out     = twiddle_data_q_in;
      assign twiddle_data_valid_out = twiddle_data_valid_in;
      assign twiddle_data_last_out  = twiddle_data_last_in;

      assign ovf                    = '0;

    end
  endgenerate

  // The butterfly operator

  fft_bf2 #(
      .LOG_SIZE  (LogFftSizeBf2i),
      .HAS_NJ    (1'b0),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_bf2i (
      .clk           (clk),
      .rst           (rst),
      //
      .data_i_in     (bf_data_i_in),
      .data_q_in     (bf_data_q_in),
      .data_valid_in (bf_data_valid_in),
      .data_last_in  (bf_data_last_in),
      //
      .data_i_out    (bf_data_i_s),
      .data_q_out    (bf_data_q_s),
      .data_valid_out(bf_data_valid_s),
      .data_last_out (bf_data_last_s)
  );

  generate
    if (HasBf2ii) begin : g_bf2ii

      fft_bf2 #(
          .LOG_SIZE  (LOG_FFT_SIZE),
          .HAS_NJ    (1'b1),
          .DATA_WIDTH(DATA_WIDTH + 1)
      ) i_bf2ii (
          .clk           (clk),
          .rst           (rst),
          //
          .data_i_in     (bf_data_i_s),
          .data_q_in     (bf_data_q_s),
          .data_valid_in (bf_data_valid_s),
          .data_last_in  (bf_data_last_s),
          //
          .data_i_out    (bf_data_i_out),
          .data_q_out    (bf_data_q_out),
          .data_valid_out(bf_data_valid_out),
          .data_last_out (bf_data_last_out)
      );

    end else begin : g_no_bf2ii

      assign bf_data_i_out     = bf_data_i_s;
      assign bf_data_q_out     = bf_data_q_s;
      assign bf_data_valid_out = bf_data_valid_s;
      assign bf_data_last_out  = bf_data_last_s;

    end
  endgenerate

  generate
    if (BIT_REVERSED_INPUT) begin : g_dit_fft

      // Twiddle before BFs

      assign twiddle_data_i_in     = data_i_in;
      assign twiddle_data_q_in     = data_q_in;
      assign twiddle_data_valid_in = data_valid_in;
      assign twiddle_data_last_in  = data_last_in;

      assign bf_data_i_in     = twiddle_data_i_out;
      assign bf_data_q_in     = twiddle_data_q_out;
      assign bf_data_valid_in = twiddle_data_valid_out;
      assign bf_data_last_in  = twiddle_data_last_out;

      assign data_i_out     = bf_data_i_out;
      assign data_q_out     = bf_data_q_out;
      assign data_valid_out = bf_data_valid_out;
      assign data_last_out  = bf_data_last_out;

    end else begin : g_dif_fft

      // Twiddle after BFs

      assign bf_data_i_in     = data_i_in;
      assign bf_data_q_in     = data_q_in;
      assign bf_data_valid_in = data_valid_in;
      assign bf_data_last_in  = data_last_in;

      assign twiddle_data_i_in     = bf_data_i_out;
      assign twiddle_data_q_in     = bf_data_q_out;
      assign twiddle_data_valid_in = bf_data_valid_out;
      assign twiddle_data_last_in  = bf_data_last_out;

      assign data_i_out     = twiddle_data_i_out;
      assign data_q_out     = twiddle_data_q_out;
      assign data_valid_out = twiddle_data_valid_out;
      assign data_last_out  = twiddle_data_last_out;

    end
  endgenerate

endmodule

`default_nettype wire
