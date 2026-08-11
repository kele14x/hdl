`timescale 1 ns / 1 ps
//
`default_nettype none

module timer_syncer #(
    parameter integer FREQ_MODE   = 0,  // 0: 156.25 MHz, 1: 312.5 MHz, 2: 390.625 MHz
    parameter int SIM_SPEEDUP = 0
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        pps_in,
    //
    input  wire [47:0] tod_sec,
    input  wire [31:0] tod_ns,
    //
    input  wire        rx_eth_clk,
    input  wire        rx_eth_rst,
    //
    input  wire        tx_eth_clk,
    input  wire        tx_eth_rst,
    //
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    output wire [79:0] ctl_rx_systemtimer,
    output wire [79:0] ctl_tx_systemtimer,
    //
    output wire [31:0] stat_rx_resync_cnt,
    output wire [31:0] stat_tx_resync_cnt
);

  timer_syncer_ch #(
      .FREQ_MODE  (FREQ_MODE),
      .SIM_SPEEDUP(SIM_SPEEDUP)
  ) i_rx_syncer (
      .clk            (clk),
      .rst            (rst),
      //
      .pps_in         (pps_in),
      //
      .tod_sec        (tod_sec),
      .tod_ns         (tod_ns),
      //
      .eth_clk        (rx_eth_clk),
      .eth_rst        (rx_eth_rst),
      //
      .ctrl_clk       (ctrl_clk),
      .ctrl_rst       (ctrl_rst),
      //
      .ctl_systemtimer(ctl_rx_systemtimer),
      //
      .stat_resync_cnt(stat_rx_resync_cnt)
  );

  timer_syncer_ch #(
      .FREQ_MODE  (FREQ_MODE),
      .SIM_SPEEDUP(SIM_SPEEDUP)
  ) i_tx_syncer (
      .clk            (clk),
      .rst            (rst),
      //
      .pps_in         (pps_in),
      //
      .tod_sec        (tod_sec),
      .tod_ns         (tod_ns),
      //
      .eth_clk        (tx_eth_clk),
      .eth_rst        (tx_eth_rst),
      //
      .ctrl_clk       (ctrl_clk),
      .ctrl_rst       (ctrl_rst),
      //
      .ctl_systemtimer(ctl_tx_systemtimer),
      //
      .stat_resync_cnt(stat_tx_resync_cnt)
  );

endmodule

`default_nettype wire
