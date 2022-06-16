// File: fft_twiddle_rom.v
// Brief: The twiddle factor rom in FFT algorithm.
`timescale 1ns / 1ps
//
`default_nettype none

module fft_twiddle_rom #(
    parameter integer TWIDDLE_WIDTH = 3,
    parameter integer DATA_WIDTH    = 16
) (
    input  wire                           clk,
    input  wire                           rst,
    //
    input  wire                           en,
    input  wire       [TWIDDLE_WIDTH-1:0] twiddle,
    //
    output reg signed [   DATA_WIDTH-1:0] twiddle_i_out,
    output reg signed [   DATA_WIDTH-1:0] twiddle_q_out
);

  localparam integer LATENCY = 2;
  localparam real PI = 3.14159265359;


  // Signals
  //========

  reg en_d;
  reg rst_d;

  reg [TWIDDLE_WIDTH-1:0] twiddle_bitreversed;

  // The Memory
  reg signed [DATA_WIDTH-1:0] COS_ROM[0:2**TWIDDLE_WIDTH];
  reg signed [DATA_WIDTH-1:0] SIN_ROM[0:2**TWIDDLE_WIDTH]; // negative

  reg signed [   DATA_WIDTH-1:0] twiddle_i_s;
  reg signed [   DATA_WIDTH-1:0] twiddle_q_s;


  // Initializes the memory values
  //==============================

  // Note:
  // 2 * pi = 2 ^ (TWIDDLE_WIDTH + 1)
  //     pi = 2 ^ TWIDDLE_WIDTH
  // pi / 2 = 2 ^ (TWIDDLE_WIDTH - 1)

  // TODO: reduce ROM usage using equation: -sin(x) = cos(pi/2+x)
  initial begin : p_init
    integer i;
    for (i = 0; i < 2 ** TWIDDLE_WIDTH; i = i + 1) begin
      COS_ROM[i] = (2 ** (DATA_WIDTH - 1) - 1) * $cos(PI * i / 2 ** TWIDDLE_WIDTH);
      SIN_ROM[i] = -(2 ** (DATA_WIDTH - 1) - 1) * $sin(PI * i / 2 ** TWIDDLE_WIDTH);
    end
  end

  always @(*) begin : p_reverse
    integer i;
    for (i = 0; i < TWIDDLE_WIDTH; i = i + 1) begin
      twiddle_bitreversed[i] <= twiddle[TWIDDLE_WIDTH-i-1];
    end
  end


  // Memory read
  //============

  always @(posedge clk) begin
    en_d  <= en;
    rst_d <= rst;
  end


  always @(posedge clk) begin
    if (rst) begin
      twiddle_i_s <= 'd0;
      twiddle_q_s <= 'd0;
    end else if (en) begin
      twiddle_i_s <= COS_ROM[twiddle_bitreversed];
      twiddle_q_s <= SIN_ROM[twiddle_bitreversed];
    end
  end

  always @(posedge clk) begin
    if (rst_d) begin
      twiddle_i_out <= 'd0;
      twiddle_q_out <= 'd0;
    end else if (en_d) begin
      twiddle_i_out <= twiddle_i_s;
      twiddle_q_out <= twiddle_q_s;
    end
  end

endmodule

`default_nettype wire
