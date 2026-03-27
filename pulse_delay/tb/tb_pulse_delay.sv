`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_pulse_delay;

  localparam integer WIDTH = 16;

  logic             clk;
  logic             rst;
  logic             pulse_in;
  logic             pulse_out;
  logic [WIDTH-1:0] delay;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst <= 0;
  end

  initial begin
    pulse_in = 0;
    delay = 1;
    wait (!rst);
    #100;

    @(posedge clk);
    pulse_in <= 1;
    @(posedge clk);
    pulse_in <= 0;

    wait (pulse_out);
    #1000 $finish;
  end

  pulse_delay #(.WIDTH(WIDTH)) DUT (.*);

endmodule

`default_nettype wire
