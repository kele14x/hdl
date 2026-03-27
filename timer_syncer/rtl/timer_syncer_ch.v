`timescale 1 ns / 1 ps
//
`default_nettype none

module timer_syncer_ch #(
    parameter integer FREQ_MODE   = 0, // 0: 156.25 MHz, 1: 312.5 MHz, 2: 390.625 MHz
    parameter integer SIM_SPEEDUP = 0
)(
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        pps_in,
    //
    input  wire [47:0] tod_sec,
    input  wire [31:0] tod_ns,
    //
    input  wire        eth_clk,
    input  wire        eth_rst,
    //
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    output wire [79:0] ctl_systemtimer,
    //
    output wire [31:0] stat_resync_cnt
);

  generate
    if (FREQ_MODE == 0) begin : g_156p25

      timer_syncer_156p25 #(
          .SIM_SPEEDUP(SIM_SPEEDUP)
      ) i_timer_syncer (
          .clk            (clk),
          .rst            (rst),
          //
          .pps_in         (pps_in),
          .tod_sec        (tod_sec),
          .tod_ns         (tod_ns),
          //
          .eth_clk        (eth_clk),
          .eth_rst        (eth_rst),
          //
          .ctrl_clk       (ctrl_clk),
          .ctrl_rst       (ctrl_rst),
          .ctl_systemtimer(ctl_systemtimer),
          .stat_resync_cnt(stat_resync_cnt)
      );

    end else if (FREQ_MODE == 1) begin : g_312p5

      timer_syncer_312p5 #(
          .SIM_SPEEDUP(SIM_SPEEDUP)
      ) i_timer_syncer (
          .clk            (clk),
          .rst            (rst),
          //
          .pps_in         (pps_in),
          .tod_sec        (tod_sec),
          .tod_ns         (tod_ns),
          //
          .eth_clk        (eth_clk),
          .eth_rst        (eth_rst),
          //
          .ctrl_clk       (ctrl_clk),
          .ctrl_rst       (ctrl_rst),
          .ctl_systemtimer(ctl_systemtimer),
          .stat_resync_cnt(stat_resync_cnt)
      );

    end else if (FREQ_MODE == 2) begin : g_390p625

      timer_syncer_390p625 #(
          .SIM_SPEEDUP(SIM_SPEEDUP)
      ) i_timer_syncer (
          .clk            (clk),
          .rst            (rst),
          //
          .pps_in         (pps_in),
          .tod_sec        (tod_sec),
          .tod_ns         (tod_ns),
          //
          .eth_clk        (eth_clk),
          .eth_rst        (eth_rst),
          //
          .ctrl_clk       (ctrl_clk),
          .ctrl_rst       (ctrl_rst),
          .ctl_systemtimer(ctl_systemtimer),
          .stat_resync_cnt(stat_resync_cnt)
      );

    end
  endgenerate

endmodule

`default_nettype wire
