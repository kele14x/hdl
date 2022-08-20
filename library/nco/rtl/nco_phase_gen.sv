// File: dds_phase_gen.sv
// Brief: DDS phase generator
`timescale 1ns / 1ps
//
`default_nettype none

module dds_phase_gen #(
    parameter integer                   PHASE_WIDTH     = 32,
    parameter integer                   LUT_PHASE_WIDTH = 14,
    parameter         [PHASE_WIDTH-1:0] INIT_PINC       = 'b0,
    parameter         [PHASE_WIDTH-1:0] INIT_POFF       = 'b0
) (
    input  wire                   clk,
    input  wire                   rst,
    //
    input  wire                   sync,
    //
    output reg  [PHASE_WIDTH-1:0] phase_out,
    //
    input  wire [PHASE_WIDTH-1:0] config_poff_in,
    input  wire [PHASE_WIDTH-1:0] config_pinc_in,
    input  wire                   config_valid
);

  // Local parameters
  //=================

  localparam integer Latency = 3;


  // Signals
  //========

  reg [PHASE_WIDTH-1:0] phase_accumulator;

  // TODO: sync with pinc/poff to `phase_out`, this enables pipeline interface
  //       for `config_*` input.
  reg [PHASE_WIDTH-1:0] phase_pinc;
  reg [PHASE_WIDTH-1:0] phase_poff;


  // Main
  //=====

  // Config interface

  always @(posedge clk) begin
    if (rst) begin
      phase_pinc <= INIT_PINC;
    end else if (config_valid) begin
      phase_pinc <= config_pinc_in;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      phase_poff <= INIT_POFF;
    end else if (config_valid) begin
      phase_poff <= config_poff_in;
    end
  end

  // Phase accumulator

  always @(posedge clk) begin
    if (rst || sync) begin
      phase_accumulator <= INIT_POFF;
    end else begin
      phase_accumulator <= phase_accumulator + phase_pinc;
    end
  end

  // TODO: add phase dither logic

  always @(posedge clk) begin
    phase_out = phase_accumulator + phase_poff;
  end

endmodule

`default_nettype wire
