// File: fft_radix2_stage.v
// Brief: FFT process stage. Each stage includes:
//          - 1 Twiddler (twidder factor ROM and complex multiplier)
//          - 1 or 2 Butterfly operator
`timescale 1 ns / 1 ps
//
`default_nettype none

module fft_radix2_stage #(
    parameter bit HAS_TWIDDLE        = 0,
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

  localparam int LogSizeTwiddle = BIT_REVERSED_INPUT ? LOG_FFT_SIZE : (LOG_FFT_SIZE + 1);

  // If LOG_FFT_SIZE is an even number, we have 2 Butterfly operator
  localparam bit HasBf2ii = (LOG_FFT_SIZE % 2 == 0);

  // Log2 FFT size of BF2I
  localparam int LogFftSizeBf2i = HasBf2ii ? (LOG_FFT_SIZE - 1) : LOG_FFT_SIZE;

  // Signals
  //========

  logic signed [DATA_WIDTH-1:0] data_i_twiddle;
  logic signed [DATA_WIDTH-1:0] data_q_twiddle;
  logic                         data_valid_twiddle;
  logic                         data_last_twiddle;

  logic signed [  DATA_WIDTH:0] data_i_s;
  logic signed [  DATA_WIDTH:0] data_q_s;
  logic                         data_valid_s;
  logic                         data_last_s;


  // Main
  //=====

  generate
    if (HAS_TWIDDLE) begin : g_twiddle

      fft_radix2_twiddle #(
          .LOG_SIZE   (LogSizeTwiddle),
          .DATA_WIDTH (DATA_WIDTH),
          .PHASE_WIDTH(PHASE_WIDTH)
      ) i_twiddle (
          .clk           (clk),
          .rst           (rst),
          // Input
          .data_i_in     (data_i_in),
          .data_q_in     (data_q_in),
          .data_valid_in (data_valid_in),
          .data_last_in  (data_last_in),
          // Output
          .data_i_out    (data_i_twiddle),
          .data_q_out    (data_q_twiddle),
          .data_valid_out(data_valid_twiddle),
          .data_last_out (data_last_twiddle),
          // Status
          .ovf           (ovf)
      );

    end else begin : g_no_twiddle

      assign data_i_twiddle     = data_i_in;
      assign data_q_twiddle     = data_q_in;
      assign data_valid_twiddle = data_valid_in;
      assign data_last_twiddle  = data_last_in;

      assign ovf                 = 1'b0;

    end
  endgenerate

  // The butterfly operator

  fft_radix2_bf2 #(
      .LOG_SIZE  (LogFftSizeBf2i),
      .HAS_NJ    (1'b0),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_bf2i (
      .clk           (clk),
      .rst           (rst),
      //
      .data_i_in     (data_i_twiddle),
      .data_q_in     (data_q_twiddle),
      .data_valid_in (data_valid_twiddle),
      .data_last_in  (data_last_twiddle),
      //
      .data_i_out    (data_i_s),
      .data_q_out    (data_q_s),
      .data_valid_out(data_valid_s),
      .data_last_out (data_last_s)
  );

  generate
    if (HasBf2ii) begin : g_bf2ii

      fft_radix2_bf2 #(
          .LOG_SIZE  (LOG_FFT_SIZE),
          .HAS_NJ    (1'b1),
          .DATA_WIDTH(DATA_WIDTH + 1)
      ) i_bf2ii (
          .clk           (clk),
          .rst           (rst),
          //
          .data_i_in     (data_i_s),
          .data_q_in     (data_q_s),
          .data_valid_in (data_valid_s),
          .data_last_in  (data_last_s),
          //
          .data_i_out    (data_i_out),
          .data_q_out    (data_q_out),
          .data_valid_out(data_valid_out),
          .data_last_out (data_last_out)
      );
    end else begin : g_no_bf2ii

      assign data_i_out = data_i_s;
      assign data_q_out = data_q_s;
      assign data_valid_out = data_valid_s;
      assign data_last_out = data_last_s;

    end
  endgenerate

endmodule

`default_nettype wire
