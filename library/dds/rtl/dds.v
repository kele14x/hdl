// File: dds.sv
// Brief: DDS top module.
`timescale 1ns / 1ps
//
`default_nettype none

module dds #(
    parameter reg                       HAS_PHASE_GEN = 1,
    parameter integer                   PHASE_WIDTH   = 32,
    parameter integer                   DATA_WIDTH    = 16,
    parameter         [PHASE_WIDTH-1:0] INIT_PINC     = 'b0,
    parameter         [PHASE_WIDTH-1:0] INIT_POFF     = 'b0,
    parameter reg                       NEGATIVE_COS  = 0,
    parameter reg                       NEGATIVE_SIN  = 0
) (
    input  wire                          clk,
    input  wire                          rst,
    //
    input  wire                          sync,
    //
    input  wire        [PHASE_WIDTH-1:0] phase_in,
    output wire        [PHASE_WIDTH-1:0] phase_out,
    //
    output wire signed [ DATA_WIDTH-1:0] cos_out,
    output wire signed [ DATA_WIDTH-1:0] sin_out,
    //
    input  wire        [PHASE_WIDTH-1:0] config_poff_in,
    input  wire        [PHASE_WIDTH-1:0] config_pinc_in,
    input  wire                          config_valid
);

  // Check parameters
  //=================

  initial begin
    // Check `PHASE_WIDTH`
    if (HAS_PHASE_GEN) begin
      if (!(2 <= PHASE_WIDTH && PHASE_WIDTH <= 48)) begin
        $error("[%m]: Phase word width (PHASE_WIDTH) must be within the range 2 to 48.");
        #1 $finish();
      end
    end else begin
      if (!(2 <= PHASE_WIDTH && PHASE_WIDTH <= 16)) begin
        $error("[%m]: Phase word width (PHASE_WIDTH) must be within the range 2 to 48.");
        #1 $finish();
      end
    end
    // Check `DATA_WIDTH`
    if (!(3 <= DATA_WIDTH && DATA_WIDTH <= 26)) begin
      $error("[%m]: Data word width (DATA_WIDTH) must be within the range 3 to 26.");
      #1 $finish();
    end
  end


  // Local parameters
  //=================

  localparam LutPhaseWidth = HAS_PHASE_GEN ? ((PHASE_WIDTH > 14) ? 14 : PHASE_WIDTH) :
                             PHASE_WIDTH;


  // Signals
  //========

  wire [  PHASE_WIDTH-1:0] phase_s;
  wire [LutPhaseWidth-1:0] phase_lut;

  generate
    if (HAS_PHASE_GEN) begin : g_phase_gen

      dds_phase_gen #(
          .PHASE_WIDTH(PHASE_WIDTH),
          .INIT_PINC  (INIT_PINC),
          .INIT_POFF  (INIT_POFF)
      ) i_phase_gen (
          .clk           (clk),
          .rst           (rst),
          //
          .sync          (sync),
          //
          .phase_out     (phase_s),
          //
          .config_poff_in(config_poff_in),
          .config_pinc_in(config_pinc_in),
          .config_valid  (config_valid)
      );

      assign phase_lut = phase_s[PHASE_WIDTH-1:PHASE_WIDTH-LutPhaseWidth];

    end else begin : g_lut_only

      assign phase_lut = phase_in[PHASE_WIDTH-1:PHASE_WIDTH-LutPhaseWidth];

    end
  endgenerate

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
