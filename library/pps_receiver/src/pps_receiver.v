/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module pps_receiver #(
    parameter C_CLOCK_FREQUENCY = 125000000,
    parameter C_PPS_DELAY       = 12500
) (
    // Core clock domain
    //----------------------
    // Clock & Reset
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF pps_in:pps_out:pps_status:pps_phase, ASSOCIATED_RESET rst" *)
    input  wire clk    ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input  wire rst    ,
    // External 1PPS in
    (* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 pps_in DATA" *)
    input  wire pps_in ,
    // 1PPS to Fabric
    (* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 pps_out DATA" *)
    output wire pps_out
);

    pps_receiver_top #(
        .C_CLOCK_FREQUENCY(C_CLOCK_FREQUENCY),
        .C_PPS_DELAY      (C_PPS_DELAY      )
    ) inst (
        .clk    (clk    ),
        .rst    (rst    ),
        .pps_in (pps_in ),
        .pps_out(pps_out)
    );

endmodule

`default_nettype wire
