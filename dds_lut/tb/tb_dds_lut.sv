// File: tb_dds_lut.sv
// Brief: Testbench for module dds_lut.
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_dds_lut;

  parameter string STRUCTURE = "FULL";
  parameter string USE_DUAL_PORT = "FALSE";
  parameter int PHASE_WIDTH = 10;
  parameter int DATA_WIDTH = 16;
  parameter bit NEGATIVE_COS = 0;
  parameter bit NEGATIVE_SIN = 0;

  bit                          clk;
  bit                          rst;
  bit                          en;
  //
  bit        [PHASE_WIDTH-1:0] phase;
  //
  bit signed [ DATA_WIDTH-1:0] cos_out;
  bit signed [ DATA_WIDTH-1:0] sin_out;


  initial begin
    clk = 0;
    forever begin
       #5 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    repeat(16) @(posedge clk);
    rst <= 0;
  end

  initial begin
    en = 0;
    phase = 0;
    wait(rst == 0);
    for (int i = 0; i < 2**PHASE_WIDTH; i++) begin
      @(posedge clk);
      en <= 1;
      phase <= i;
    end
    @(posedge clk);
    en <= 0;
    phase <= '0;
    #100;
    $finish;
  end


  dds_lut #(
      .STRUCTURE   (STRUCTURE),
      .USE_DUAL_PORT   (USE_DUAL_PORT),
      .PHASE_WIDTH   (PHASE_WIDTH),
      .DATA_WIDTH   (DATA_WIDTH),
      .NEGATIVE_COS   (NEGATIVE_COS),
      .NEGATIVE_SIN   (NEGATIVE_SIN)
  ) DUT (
      .clk    (clk),
      .rst    (rst),
      .en     (en),
      //
      .phase  (phase),
      //
      .cos_out(cos_out),
      .sin_out(sin_out)
  );

endmodule

`default_nettype wire
