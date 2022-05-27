// File: fft_twiddle_rom.sv
// Brief: The twiddle factor rom in FFT algorithm.
`timescale 1ns / 1ps
//
`default_nettype none

module dds_lut #(
    parameter integer PHASE_WIDTH = 12,
    parameter integer DATA_WIDTH  = 16
) (
    input wire                           clk,
    input wire                           rst,
    input wire                           en,
    //
    input wire         [PHASE_WIDTH-1:0] phase,
    //
    output reg signed [ DATA_WIDTH-1:0] cos_out,
    output reg signed [ DATA_WIDTH-1:0] sin_out
);

  localparam integer Latency = 2;
  localparam real    PI = 3.14159265359;


  // Signals
  //========

  reg en_d;

  reg [PHASE_WIDTH-1:0] cos_phase;
  reg [PHASE_WIDTH-1:0] sin_phase;

  // The Memory
  reg signed [DATA_WIDTH-1:0] COS_ROM[0:2**PHASE_WIDTH-1];

  reg signed [   DATA_WIDTH-1:0] cos_s;
  reg signed [   DATA_WIDTH-1:0] sin_s;


  // Initializes the memory values
  //==============================

  // Note:
  // 2 * pi = 2 ^ PHASE_WIDTH (0)
  //     pi = 2 ^ (PHASE_WIDTH - 1)
  // pi / 2 = 2 ^ (PHASE_WIDTH - 2)
  // pi / 4 = 2 ^ (PHASE_WIDTH - 3)

  initial begin : p_init
    integer i;
    for (i = 0; i < 2 ** PHASE_WIDTH; i = i + 1) begin
      COS_ROM[i] = (2 ** (DATA_WIDTH - 1) - 1) * $cos(PI * i / 2 ** (PHASE_WIDTH - 1));
    end
  end

  // Memory read
  //============

  always @(posedge clk) begin
    en_d <= en;
  end


  always @(*) begin
    cos_phase = phase;
    sin_phase = phase - (1 << (PHASE_WIDTH - 2));
  end

  // Reduce ROM usage using equation: sin(x) = cos(x - pi / 2)
  always @(posedge clk) begin
    if (en) begin
      cos_s <= COS_ROM[cos_phase];
      sin_s <= COS_ROM[sin_phase];
    end
  end

  always @(posedge clk) begin
    if (en_d) begin
      cos_out <= cos_s;
      sin_out <= sin_s;
    end
  end

endmodule

`default_nettype wire
