// File: fft.sv
// Brief: Top of FFT module.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft #(
    // FFT size, must be power of 2
    parameter int FFT_SIZE          = 4096,
    // Input data width for I and Q
    parameter int INPUT_DATA_WIDTH  = 16,
    // Phase factor data width
    parameter int PHASE_WIDTH       = 16,
    // Output data width for I and Q
    parameter int OUTPUT_DATA_WIDTH = 29,
    // Optional Bit-reverse order module
    parameter bit HAS_BITREVERSE    = 1
) (
    input  var                         clk,
    input  var                         rst,
    // Data input
    input  var [ INPUT_DATA_WIDTH-1:0] data_i_in,
    input  var [ INPUT_DATA_WIDTH-1:0] data_q_in,
    input  var                         data_valid_in,
    input  var                         data_last_in,
    // Data output
    output var [OUTPUT_DATA_WIDTH-1:0] data_i_out,
    output var [OUTPUT_DATA_WIDTH-1:0] data_q_out,
    output var                         data_valid_out,
    output var                         data_last_out,
    // Status output
    output var                         err_input_halt,
    output var                         err_last_unexpected,
    output var                         err_ovf
);


  // Local parameters
  //=================

  localparam int LogFftSize = $clog2(FFT_SIZE);
  localparam int Latency = LogFftSize * 9 + FFT_SIZE - 8 +
    (HAS_BITREVERSE ? ((LogFftSize % 2 == 0) ?
        (FFT_SIZE - 2 ** (LogFftSize / 2 + 1) + 2) :
        (FFT_SIZE - 2 ** ((LogFftSize + 1) / 2) - 2 ** ((LogFftSize - 1) / 2) + 2)) : 0);

  // Signals
  //========

  logic [OUTPUT_DATA_WIDTH-1:0] data_i_s;
  logic [OUTPUT_DATA_WIDTH-1:0] data_q_s;
  logic                         data_valid_s;
  logic                         data_last_s;


  // Check parameters
  //=================

  initial begin
    // Check FFT size
    assert(2 <= FFT_SIZE && FFT_SIZE <= 16384) else begin
      $error("[%m]: FFT size (FFT_SIZE) must be within the range 2 to 16384.");
      #1 $finish;
    end
    assert(FFT_SIZE == 2 ** LogFftSize) else begin
      $error("[%m]: FFT size (FFT_SIZE) must be power of 2.");
      #1 $finish;
    end

    // Check input data width
    assert(8 <= INPUT_DATA_WIDTH && INPUT_DATA_WIDTH <= 32) else begin
      $error("[%m]: Input data width (INPUT_DATA_WIDTH) must be within the range 8 to 32.");
      #1 $finish;
    end

    // Check output data width
    assert(INPUT_DATA_WIDTH <= OUTPUT_DATA_WIDTH &&
      OUTPUT_DATA_WIDTH <= INPUT_DATA_WIDTH + LogFftSize + 1) else begin
      $error("[%m]: Output data width (OUTPUT_DATA_WIDTH) must be within the range %d to %d.",
             INPUT_DATA_WIDTH, INPUT_DATA_WIDTH + LogFftSize + 1);
      #1 $finish;
    end
  end


  // Main
  //=====

  fft_core #(
      .FFT_SIZE         (FFT_SIZE),
      .INPUT_DATA_WIDTH (INPUT_DATA_WIDTH),
      .PHASE_WIDTH      (PHASE_WIDTH),
      .OUTPUT_DATA_WIDTH(OUTPUT_DATA_WIDTH)
  ) i_core (
      .clk                (clk),
      .rst                (rst),
      // Data input
      .data_i_in          (data_i_in),
      .data_q_in          (data_q_in),
      .data_valid_in      (data_valid_in),
      .data_last_in       (data_last_in),
      // Data output
      .data_i_out         (data_i_s),
      .data_q_out         (data_q_s),
      .data_valid_out     (data_valid_s),
      .data_last_out      (data_last_s),
      // Status output
      .err_input_halt     (err_input_halt),
      .err_last_unexpected(err_last_unexpected),
      .err_ovf            (err_ovf)
  );

  generate
    if (HAS_BITREVERSE) begin : g_has_bitreverse

      fft_bitreverse #(
          .FFT_SIZE  (FFT_SIZE),
          .DATA_WIDTH(OUTPUT_DATA_WIDTH * 2)
      ) i_bitrevserse (
          .clk           (clk),
          .rst           (rst),
          // Data input
          .data_in       ({data_q_s, data_i_s}),
          .data_valid_in (data_valid_s),
          .data_last_in  (data_last_s),
          // Data output
          .data_out      ({data_q_out, data_i_out}),
          .data_valid_out(data_valid_out),
          .data_last_out (data_last_out)
      );

    end else begin : g_no_bitrevsere

      assign data_i_out     = data_i_s;
      assign data_q_out     = data_q_s;
      assign data_valid_out = data_valid_s;
      assign data_last_out  = data_last_s;

    end
  endgenerate

endmodule

`default_nettype wire
