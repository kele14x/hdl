/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module pps_receiver #(parameter C_CLOCK_FREQUENCY = 25000000) (
    // Core clock domain
    //----------------------
    // Clock & Reset
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF pps_in:pps_out:pps_status:pps_phase, ASSOCIATED_RESET rst, FREQ_HZ 125000000" *)
    input  wire ptp_clk,
    // External 1PPS in
    input  wire pps_in ,
    // 1PPS to Fabric
    output wire pps_out,
    // 1 kHz tick to Fabric
    output wire ts_out
);

    pps_receiver_top #(.C_CLOCK_FREQUENCY(C_CLOCK_FREQUENCY)) inst (
        .ptp_clk(ptp_clk),
        .pps_in (pps_in ),
        .pps_out(pps_out),
        .ts_out (ts_out )
    );

endmodule

`default_nettype wire
