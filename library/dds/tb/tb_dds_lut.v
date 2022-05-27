// File: tb_dds_lut.sv
// Brief: Test bench for module dds_lut
`timescale 1ns / 1ps
//
`default_nettype none

module tb_dds_lut;

  parameter integer PHASE_WIDTH = 12;
  parameter integer DATA_WIDTH  = 16;

  reg                           clk;
  reg                           rst;
  reg                           en;
  //
  reg         [PHASE_WIDTH-1:0] phase;
  //
  wire signed [ DATA_WIDTH-1:0] cos_out;
  wire signed [ DATA_WIDTH-1:0] sin_out;


  // Stimulation


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

  initial begin : p_stimu
    integer i;
    phase = 0;
    wait (rst == 0);
    for (i = 0; i < 2**PHASE_WIDTH; i = i + 1) begin
      @(posedge clk);
      phase <= i;
      en <= 1;
    end
  end


  // DUT
  //====

  dds_lut #(
    .PHASE_WIDTH(PHASE_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
  ) DUT (
    .clk    (clk),
    .rst    (rst),
    .en     (en),
    .phase  (phase),
    .cos_out(cos_out),
    .sin_out(sin_out)
  );

endmodule

`default_nettype wire
