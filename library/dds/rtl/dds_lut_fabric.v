// File: dds_lut_fabric.v
// Brief: DDS phase-cosine/sine look-up table using fabric memory resource. When
//        Phase Word Width (PHASE_WIDTH) is small, it is effective that directly
//        store full waveform of both cosine and sine in fabric logic.
`timescale 1ns / 1ps
//
`default_nettype none

module dds_lut_fabric #(
    parameter integer PHASE_WIDTH  = 9,
    parameter integer DATA_WIDTH   = 16,
    parameter reg     NEGATIVE_SIN = 0
) (
    input  wire                          clk,
    input  wire                          rst,
    input  wire                          en,
    //
    input  wire        [PHASE_WIDTH-1:0] phase,
    //
    output wire signed [ DATA_WIDTH-1:0] cos_out,
    output wire signed [ DATA_WIDTH-1:0] sin_out
);

  // Local parameters
  //=================

  localparam integer Latency = 4;
  localparam real PI = 3.14159265359;


  // Functions
  //==========

  // This function calculates the initial value of index `idx` in memory.
  function automatic [DATA_WIDTH*2-1:0] init_mem(input integer idx);
    reg signed [DATA_WIDTH-1:0] cos;
    reg signed [DATA_WIDTH-1:0] sin;
    begin
      cos = (2 ** (DATA_WIDTH - 1) - 1) * $cos(PI * idx / 2 ** (PHASE_WIDTH - 1));
      sin = (2 ** (DATA_WIDTH - 1) - 1) * $sin(PI * idx / 2 ** (PHASE_WIDTH - 1));
      if (NEGATIVE_SIN) begin
        sin = -sin;
      end
      init_mem = {sin, cos};
    end
  endfunction


  // Signals
  //========

  reg [DATA_WIDTH-1:0] out_r, out_d1, out_d2, out_d3;

  // TODO: add `ram_style` attributes to fin control the RAM style (like
  //       "register", "distributed", or "block").
  reg [DATA_WIDTH*2-1:0] MEM[0:2**PHASE_WIDTH-1];


  // Main
  //=====

  initial begin : p_init
    integer i;
    for (i = 0; i < 2 ** PHASE_WIDTH; i = i + 1) begin
      MEM[i] = init_mem(i);
    end
  end

  // Memory read

  always @(posedge clk) begin
    if (en) begin
      out_r = MEM[phase];
    end
  end

  always @(posedge clk) begin
    out_d1 <= out_r;
    out_d2 <= out_d1;
    out_d3 <= out_d2;
  end

  assign {sin_out, cos_out} = out_d3;

endmodule

`default_nettype wire
