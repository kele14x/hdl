`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_symbol_timer;

  parameter int FREQUENCY = 4;

  logic        clk;
  logic        rst;
  //
  logic        sync;
  logic [ 7:0] sync_frame;
  //
  logic        start_of_frame;
  logic        start_of_symbol;
  //
  logic [14:0] current_sample;
  logic [ 3:0] current_symbol;
  logic [ 4:0] current_subframe_slot;
  logic [ 7:0] current_frame;
  //
  logic [22:0] shift;

  initial begin
    clk = 0;
    forever begin
      #1.017 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    #100;
    rst = 0;
  end

  initial begin
    sync = 1'b0;
    sync_frame = 8'd0;
    shift = 23'd0;
    wait (rst == 0);
    // Send Sync
    @(posedge clk);
    @(posedge clk);
    sync <= 1'b1;
    @(posedge clk);
    sync <= 1'b0;
    // Wait 10ms
    #(11 * 1000 * 1000);
    $finish;
  end

  symbol_timer #(
      .MODE     (1),
      .FREQUENCY(FREQUENCY)
  ) UUT (
      .*
  );

endmodule

`default_nettype wire
