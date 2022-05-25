// File: tb_shift_ram.sv
// Brief: Testbench for module shift_ram
`default_nettype none
//
`timescale 1 ns / 1 ps

module tb_shift_ram;

  parameter int DEPTH = 4;
  parameter int DATA_WIDTH = 16;

  logic clk;
  logic rst;

  logic [DATA_WIDTH-1:0] din;
  logic [DATA_WIDTH-1:0] dout;

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

    for (int i = 0; i < DEPTH * 2; i++) begin
      @(posedge clk);
      din <= i;
    end
  end

  shift_ram #(
      .DEPTH     (DEPTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire
