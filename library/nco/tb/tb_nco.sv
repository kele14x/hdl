// File: tb_nco.sv
// Brief: Testbench for module nco.
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_nco;

  parameter int PHASE_WIDTH = 32;
  parameter int PHASE_ENTRIES = 3072;
  parameter int DATA_WIDTH = 16;
  parameter bit NEGATIVE_SIN = 0;

  bit                          clk;
  bit                          rst;
  //
  bit                          sync;
  //
  bit signed [ DATA_WIDTH-1:0] cos;
  bit signed [ DATA_WIDTH-1:0] sin;
  //
  bit        [PHASE_WIDTH-1:0] ctrl_poff;
  bit        [PHASE_WIDTH-1:0] ctrl_pinc;


  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    repeat (16) @(posedge clk);
    rst <= 0;
  end

  initial begin
    sync = 0;
    ctrl_poff = 0;
    ctrl_pinc = (3072 << 20) - 64000;
    wait (rst == 0);
    #100;
    @(posedge clk);
    sync <= 1;
    @(posedge clk);
    sync <= 0;
    #1000;
    $finish;
  end

  nco #(
      .PHASE_WIDTH  (PHASE_WIDTH),
      .PHASE_ENTRIES(PHASE_ENTRIES),
      .DATA_WIDTH   (DATA_WIDTH),
      .NEGATIVE_SIN (NEGATIVE_SIN)
  ) DUT (
      .clk      (clk),
      .rst      (rst),
      //
      .sync     (sync),
      //
      .cos      (cos),
      .sin      (sin),
      //
      .ctrl_poff(ctrl_poff),
      .ctrl_pinc(ctrl_pinc)
  );

endmodule

`default_nettype wire
