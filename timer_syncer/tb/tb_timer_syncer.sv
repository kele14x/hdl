`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_timer_syncer;

  parameter integer FREQ_MODE = 0;

  logic        clk;
  logic        rst;
  //
  logic        pps_in;
  //
  logic [47:0] tod_sec;
  logic [31:0] tod_ns;
  //
  logic        rx_eth_clk;
  logic        rx_eth_rst;
  //
  logic        tx_eth_clk;
  logic        tx_eth_rst;
  //
  logic        ctrl_clk;
  logic        ctrl_rst;
  //
  logic [79:0] ctl_rx_systemtimer;
  logic [79:0] ctl_tx_systemtimer;
  //
  logic [31:0] stat_rx_resync_cnt;
  logic [31:0] stat_tx_resync_cnt;

  // Generate Clock & Reset

  initial begin
    clk = 1'b0;
    forever #(1.25) clk = ~clk;
  end

  initial begin
    rst = 1'b1;
    repeat (10) @(posedge clk);
    rst <= 1'b0;
  end

  initial begin
    rx_eth_clk = 1'b0;
    forever #(3.2) rx_eth_clk = ~rx_eth_clk;
  end

  initial begin
    rx_eth_rst = 1'b1;
    repeat (10) @(posedge rx_eth_clk);
    rx_eth_rst <= 1'b0;
  end

  initial begin
    tx_eth_clk = 1'b0;
    forever #(3.2) tx_eth_clk = ~tx_eth_clk;
  end

  initial begin
    tx_eth_rst = 1'b1;
    repeat (10) @(posedge tx_eth_clk);
    tx_eth_rst <= 1'b0;
  end

  // Stimulus

  initial begin
    real nanosecond;

    $display("*** Simulation starts ***");
    pps_in  = 1'b0;
    tod_sec = 48'd0;
    tod_ns  = 32'd0;

    wait (rst == 1'b0);

    forever begin
      @(posedge clk);
      nanosecond = nanosecond + 2.5;
      if (nanosecond >= 1e6) begin
        nanosecond = 0;
        tod_sec <= tod_sec + 48'd1;
        tod_ns  <= nanosecond;
        pps_in  <= 1'b1;
      end else begin
        tod_sec <= tod_sec;
        tod_ns  <= nanosecond;
        pps_in  <= 1'b0;
      end
    end
    $finish;
  end

  final begin
    $display("*** Simulation ends ***");
  end

  // DUT

  timer_syncer #(
    .FREQ_MODE  (FREQ_MODE),
    .SIM_SPEEDUP(1'b1)
  ) DUT (.*);

endmodule

`default_nettype wire
