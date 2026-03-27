`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_symbol_timer;

  parameter bit ASYNC = 1'b0;
  parameter bit MODE = 1'b1;  // 0 for UL, 1 for DL
  parameter int FREQ = 32;  // 32: 122.88, 64: 245.76, 128: 491.52
  parameter bit AUTO = 1'b1;

  logic        clk;
  logic        rst;
  //
  logic        sync;
  //
  logic        start_of_frame;
  logic        start_of_slot;
  logic [ 1:0] start_of_symbol;  // {mu1; mu0}
  //
  logic [22:0] ctrl_delay;
  logic        stat_resync;

  // Clock & Reset Generator

  initial begin
    clk = 0;
    forever #(1.017) clk = ~clk;
  end

  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst <= 0;
  end

  // Stimulus

  // Sync driver
  initial begin
    sync = 0;
    wait (rst == 0);

    repeat (1000) @(posedge clk);

    forever begin
      sync <= 1;
      @(posedge clk);
      sync <= 0;
      repeat (38400 * FREQ - 1) @(posedge clk);
    end
  end

  initial begin
    int cnt;
    $display("*** Simulation started ***");

    sync = 0;
    ctrl_delay = 0;
    wait (rst == 0);

    // Send `sync`
    repeat (1000) @(posedge clk);
    sync <= 1;
    @(posedge clk);
    sync <= 0;

    // Wait for SOF caused by sync
    repeat (1000) begin
      @(posedge clk);
      if (start_of_frame) break;
    end

    // Wait for counter roll over
    repeat (5000000) begin
      @(posedge clk);
      cnt = cnt + 1;
      if (start_of_frame) break;
    end

    $display("Clock ticks between SOF: %d", cnt);
    assert (~AUTO || (cnt == 38400 * FREQ))
    else begin
      $error("Unexpected clock ticks between SOF, expected %d", 38400 * FREQ);
    end

    #1000;
    $finish;
  end

  final begin
    $display("*** Simulation finished ***");
  end

  // DUT

  symbol_timer #(
      .ASYNC(ASYNC),
      .MODE (MODE),
      .FREQ (FREQ),
      .AUTO (AUTO)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire
