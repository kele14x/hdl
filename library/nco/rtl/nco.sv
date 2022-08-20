// File: nco.sv
// Brief: Numerically-controlled oscillator (NCO) module for NR & LTE.
`timescale 1 ns / 1 ps
//
`default_nettype none

module nco #(
    parameter int PHASE_WIDTH  = 32,
    parameter int DATA_WIDTH   = 16,
    parameter bit NEGATIVE_SIN = 0
) (
    input var                           clk,
    input var                           rst,
    //
    input var                           sync,
    //
    output var signed [ DATA_WIDTH-1:0] cos,
    output var signed [ DATA_WIDTH-1:0] sin,
    //
    input var         [PHASE_WIDTH-1:0] config_poff,
    input var         [PHASE_WIDTH-1:0] config_pinc
);

  // Local parameters
  //=================

  localparam integer Latency = 7;

  localparam integer LutPhaseWidth = (PHASE_WIDTH > 14) ? 14 : PHASE_WIDTH;


  // Check parameters
  //=================

  initial begin
    assert (2 <= PHASE_WIDTH && PHASE_WIDTH <= 16)
    else begin
      $error("[%m]: Phase word width (PHASE_WIDTH) must be within the range 2 to 16, got %d.",
             PHASE_WIDTH);
      #1 $finish;
    end

    assert (3 <= DATA_WIDTH && DATA_WIDTH <= 26)
    else begin
      $error("[%m]: Data word width (DATA_WIDTH) must be within the range 3 to 26, got %d",
             DATA_WIDTH);
      #1 $finish;
    end
  end


  // Signals
  //========

  wire [LutPhaseWidth-1:0] phase_s;


  // Main
  //=====

  dds_phase_gen #(
      .PHASE_WIDTH    (PHASE_WIDTH),
      .LUT_PHASE_WIDTH(LutPhaseWidth),
      .INIT_PINC      (INIT_PINC),
      .INIT_POFF      (INIT_POFF)
  ) i_phase_gen (
      .clk        (clk),
      .rst        (rst),
      //
      .sync       (sync),
      //
      .phase_out  (phase_s),
      //
      .config_poff(config_poff),
      .config_pinc(config_pinc)
  );


  dds_lut #(
      .PHASE_WIDTH (LutPhaseWidth),
      .DATA_WIDTH  (DATA_WIDTH),
      .NEGATIVE_COS(NEGATIVE_COS),
      .NEGATIVE_SIN(NEGATIVE_SIN)
  ) i_lut (
      .clk    (clk),
      .rst    (rst),
      .en     (1'b1),
      //
      .phase  (phase_lut),
      //
      .cos_out(cos_out),
      .sin_out(sin_out)
  );

endmodule

`default_nettype wire
