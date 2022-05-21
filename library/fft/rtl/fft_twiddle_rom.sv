// File: fft_twiddle_rom.sv
// Brief: The twiddle factor rom in FFT algorithm.
`timescale 1ns / 1ps
//
`default_nettype none

module fft_twiddle_rom #(
    parameter int TWIDDLE_WIDTH = 3,
    parameter int DATA_WIDTH    = 16
) (
    input var                             clk,
    input var                             rst,
    //
    input var                             en,
    input var         [TWIDDLE_WIDTH-1:0] twiddle,
    //
    output var signed [   DATA_WIDTH-1:0] twiddle_i_out,
    output var signed [   DATA_WIDTH-1:0] twiddle_q_out
);

  localparam int LATENCY = 2;
  localparam real PI = 3.14159265359;


  // Signals
  //========

  logic en_d;

  logic [TWIDDLE_WIDTH-1:0] twiddle_bitreversed;

  // The Memory
  logic signed [DATA_WIDTH-1:0] COS_ROM[2**TWIDDLE_WIDTH];
  logic signed [DATA_WIDTH-1:0] SIN_ROM[2**TWIDDLE_WIDTH]; // negative

  logic signed [   DATA_WIDTH-1:0] twiddle_i_s;
  logic signed [   DATA_WIDTH-1:0] twiddle_q_s;


  // Initializes the memory values
  //==============================

  // Note:
  // 2 * pi = 2 ^ (TWIDDLE_WIDTH + 1)
  //     pi = 2 ^ TWIDDLE_WIDTH
  // pi / 2 = 2 ^ (TWIDDLE_WIDTH - 1)

  // TODO: reduce ROM usage using equation: -sin(x) = cos(pi/2+x)
  initial begin
    for (int i = 0; i < 2 ** TWIDDLE_WIDTH; i = i + 1) begin
      COS_ROM[i] = (2 ** (DATA_WIDTH - 1) - 1) * $cos(PI * i / 2 ** TWIDDLE_WIDTH);
      SIN_ROM[i] = -(2 ** (DATA_WIDTH - 1) - 1) * $sin(PI * i / 2 ** TWIDDLE_WIDTH);
    end
  end

  always_comb begin
    for (int i = 0; i < TWIDDLE_WIDTH; i++) begin
      twiddle_bitreversed[i] <= twiddle[TWIDDLE_WIDTH-i-1];
    end
  end


  // Memory read
  //============

  always_ff @(posedge clk) begin
    en_d <= en;
  end


  always_ff @(posedge clk) begin
    if (en) begin
      twiddle_i_s <= COS_ROM[twiddle_bitreversed];
      twiddle_q_s <= SIN_ROM[twiddle_bitreversed];
    end
  end

  always_ff @(posedge clk) begin
    if (en_d) begin
      twiddle_i_out <= twiddle_i_s;
      twiddle_q_out <= twiddle_q_s;
    end
  end

endmodule

`default_nettype wire
