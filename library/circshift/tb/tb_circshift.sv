// File: tb_circshift.sv
// Brief: Testbench for circshift module

`timescale 1 ns / 1 ns
//
`default_nettype none

module tb_circshift;

  parameter int DATA_WIDTH = 6;

  bit                  clk;
  bit                  rst;
  //
  bit [DATA_WIDTH-1:0] din       [64];
  bit                  din_valid [64];
  //
  bit [DATA_WIDTH-1:0] dout      [64];
  bit                  dout_valid[64];
  //
  bit [           5:0] shift;
  bit [           5:0] base;

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
    wait (rst == 0);

    for (int i = 0; i < 40; i++) begin
      @(posedge clk);
      for (int j = 0; j < 40; j++) begin
        din[j] <= j;
        din_valid[j] <= 1;
      end
      shift <= i;
      base <= 40;
    end
    #100;
    $finish;
  end

  circshift #(.DATA_WIDTH(DATA_WIDTH)) UUT (.*);

endmodule : tb_circshift

`default_nettype wire
