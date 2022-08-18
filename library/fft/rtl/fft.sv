// File: fft.sv
// Brief: Top of FFT module.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft #(
    // Log2 of FFT size
    parameter int LOG_FFT_SIZE       = 12,
    // Input data width for I and Q
    parameter int INPUT_DATA_WIDTH   = 16,
    // Phase factor data width
    parameter int PHASE_WIDTH        = 16,
    // Output data width for I and Q
    parameter int OUTPUT_DATA_WIDTH  = 29,
    // This select the structure of FFT (DIT if reversed / DIF if not)
    parameter bit BIT_REVERSED_INPUT = 1
) (
    input var                          clk,
    input var                          rst,
    // Data input
    input var  [ INPUT_DATA_WIDTH-1:0] data_i_in,
    input var  [ INPUT_DATA_WIDTH-1:0] data_q_in,
    input var                          data_valid_in,
    input var                          data_last_in,
    // Data output
    output var [OUTPUT_DATA_WIDTH-1:0] data_i_out,
    output var [OUTPUT_DATA_WIDTH-1:0] data_q_out,
    output var                         data_valid_out,
    output var                         data_last_out,
    //
    input var  [                  4:0] ctrl_sra_bits,
    // Status output
    output var                         err_input_halt,
    output var                         err_last_unexpected,
    output var                         err_ovf
);


  // Local parameters
  //=================

  // Total core latency in clock ticks
  localparam int Latency = LOG_FFT_SIZE * 9 + LOG_FFT_SIZE - 8;


  // Check parameters
  //=================

  initial begin
    // Check FFT size
    assert (1 <= LOG_FFT_SIZE && LOG_FFT_SIZE <= 14)
    else begin
      $error("[%m]: Log2 FFT size (LOG_FFT_SIZE) must be within the range 1 to 14, got %d.",
             LOG_FFT_SIZE);
      #1 $finish;
    end

    // Check input data width
    assert (8 <= INPUT_DATA_WIDTH && INPUT_DATA_WIDTH <= 32)
    else begin
      $error("[%m]: Input data width (INPUT_DATA_WIDTH) must be within the range 8 to 32, got %d.",
             INPUT_DATA_WIDTH);
      #1 $finish;
    end

    // Check output data width
    assert(INPUT_DATA_WIDTH <= OUTPUT_DATA_WIDTH &&
      OUTPUT_DATA_WIDTH <= INPUT_DATA_WIDTH + LOG_FFT_SIZE + 1)
    else begin
      $error(
          "[%m]: Output data width (OUTPUT_DATA_WIDTH) must be within the range %0d to %0d, got %0d.",
          INPUT_DATA_WIDTH, INPUT_DATA_WIDTH + LOG_FFT_SIZE + 1, OUTPUT_DATA_WIDTH);
      #1 $finish;
    end
  end


  // Signals
  //========

  // state = 0: idle or first data, 1: left data
  logic                        state;
  // Counter count from 0 to LOG_FFT_SIZE - 1
  logic [    LOG_FFT_SIZE-1:0] counter;

  logic [INPUT_DATA_WIDTH-1:0] data_i_r;
  logic [INPUT_DATA_WIDTH-1:0] data_q_r;
  logic                        data_valid_r;
  logic                        data_last_r;


  // Main
  //=====

  // FFT State & Counter
  // TODO: do not use `data_last_in` as sync method. This handles when input
  //       packet contains more or less samples than `LOG_FFT_SIZE`

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 1'b0;
    end else if (data_valid_in && data_last_in) begin
      state <= 1'b0;
    end else if (data_valid_in) begin
      state <= 1'b1;
    end else begin
      state <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= 'd0;
    end else if (data_valid_in && data_last_in) begin
      counter <= 'd0;
    end else if (data_valid_in) begin
      counter <= counter + 1;
    end else begin
      counter <= 'd0;
    end
  end

  // Input register

  always_ff @(posedge clk) begin
    data_i_r     <= data_i_in;
    data_q_r     <= data_q_in;
    data_valid_r <= data_valid_in;
    data_last_r  <= data_last_in;
  end

  always_ff @(posedge clk) begin
    err_last_unexpected <= (data_last_in && ~&counter);
  end

  always_ff @(posedge clk) begin
    err_input_halt <= (!data_valid_in && |counter);
  end

  // The FFT Core

  fft_core #(
      .LOG_FFT_SIZE      (LOG_FFT_SIZE),
      .INPUT_DATA_WIDTH  (INPUT_DATA_WIDTH),
      .PHASE_WIDTH       (PHASE_WIDTH),
      .OUTPUT_DATA_WIDTH (OUTPUT_DATA_WIDTH),
      .BIT_REVERSED_INPUT(BIT_REVERSED_INPUT)
  ) i_core (
      .clk           (clk),
      .rst           (rst),
      // Data input
      .data_i_in     (data_i_in),
      .data_q_in     (data_q_in),
      .data_valid_in (data_valid_in),
      .data_last_in  (data_last_in),
      // Data output
      .data_i_out    (data_i_out),
      .data_q_out    (data_q_out),
      .data_valid_out(data_valid_out),
      .data_last_out (data_last_out),
      // Control input
      .ctrl_sra_bits (ctrl_sra_bits),
      // Status output
      .err_ovf       (err_ovf)
  );

endmodule

`default_nettype wire
