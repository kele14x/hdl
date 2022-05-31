// File: tb_dds_lut.sv
// Brief: Test bench for module dds_lut
`timescale 1ns / 1ps
//
`default_nettype none

module tb_dds ();

  parameter reg HAS_PHASE_GEN = 1;
  parameter integer PHASE_WIDTH = 32;
  parameter integer DATA_WIDTH = 16;
  parameter reg [PHASE_WIDTH-1:0] INIT_PINC = 'b0;
  parameter reg [PHASE_WIDTH-1:0] INIT_POFF = 'b0;
  parameter reg NEGATIVE_COS = 0;
  parameter reg NEGATIVE_SIN = 0;

  reg                           clk;
  reg                           rst;
  //
  reg                           sync;
  //
  reg         [PHASE_WIDTH-1:0] phase_in;
  wire        [PHASE_WIDTH-1:0] phase_out;
  //
  wire signed [ DATA_WIDTH-1:0] cos_out;
  wire signed [ DATA_WIDTH-1:0] sin_out;
  //
  reg         [PHASE_WIDTH-1:0] config_poff_in;
  reg         [PHASE_WIDTH-1:0] config_pinc_in;
  reg                           config_valid;


  // Stimulation
  //============

  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    #100 rst = 0;
  end

  initial begin
    $display("******************");
    $display("Simulation starts");
    sync = 0;
    phase_in = 0;
    config_poff_in = 0;
    config_pinc_in = 0;
    config_valid = 0;
    wait (rst == 0);

    @(posedge clk);
    config_pinc_in = 10000000;
    config_valid   = 1;
    @(posedge clk);
    config_pinc_in = 0;
    config_valid   = 0;

    repeat (1000) begin
      @(posedge clk);
    end

    $display("Simulation ends");
    $finish();
  end


  // DUT
  //====

  dds #(
      .HAS_PHASE_GEN(HAS_PHASE_GEN),
      .PHASE_WIDTH  (PHASE_WIDTH),
      .DATA_WIDTH   (DATA_WIDTH),
      .INIT_PINC    (INIT_PINC),
      .INIT_POFF    (INIT_POFF),
      .NEGATIVE_COS (NEGATIVE_COS),
      .NEGATIVE_SIN (NEGATIVE_SIN)
  ) DUT (
      .clk           (clk),
      .rst           (rst),
      //
      .sync          (sync),
      //
      .phase_in      (phase_in),
      .phase_out     (phase_out),
      //
      .cos_out       (cos_out),
      .sin_out       (sin_out),
      //
      .config_poff_in(config_poff_in),
      .config_pinc_in(config_pinc_in),
      .config_valid  (config_valid)
  );

endmodule

`default_nettype wire
