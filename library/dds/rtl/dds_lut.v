// File: dds_lut.sv
// Brief: DDS phase-cosine look-up table.
`timescale 1ns / 1ps
//
`default_nettype none

module dds_lut #(
    parameter integer PHASE_WIDTH  = 12,
    parameter integer DATA_WIDTH   = 16,
    parameter reg     NEGATIVE_COS = 0,
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
  localparam integer PhaseWidthThreshold = 9;


  // Check parameters
  //=================

  initial begin
    if (!(2 <= PHASE_WIDTH && PHASE_WIDTH <= 23)) begin
      $error("[%m]: Phase word width (PHASE_WIDTH) must be with in the range 2 to 23");
      #1 $finish();
    end
  end


  // Main
  //=====

  generate
    if (PHASE_WIDTH <= PhaseWidthThreshold) begin : g_lut_fabric

      dds_lut_fabric #(
          .PHASE_WIDTH (PHASE_WIDTH),
          .DATA_WIDTH  (DATA_WIDTH),
          .NEGATIVE_COS(NEGATIVE_COS),
          .NEGATIVE_SIN(NEGATIVE_SIN)
      ) i_lut_fabric (
          .clk    (clk),
          .rst    (rst),
          .en     (en),
          //
          .phase  (phase),
          //
          .cos_out(cos_out),
          .sin_out(sin_out)
      );

    end else begin : g_lut_block

      dds_lut_block #(
          .PHASE_WIDTH (PHASE_WIDTH),
          .DATA_WIDTH  (DATA_WIDTH),
          .NEGATIVE_COS(NEGATIVE_COS),
          .NEGATIVE_SIN(NEGATIVE_SIN)
      ) i_lut_block (
          .clk    (clk),
          .rst    (rst),
          .en     (en),
          //
          .phase  (phase),
          //
          .cos_out(cos_out),
          .sin_out(sin_out)
      );

    end
  endgenerate


endmodule

`default_nettype wire
