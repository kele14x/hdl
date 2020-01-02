/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module pps_receiver #(parameter C_CLOCK_FREQUENCY = 125000000) (
    // Core clock domain
    //----------------------
    // Clock & Reset
    input  wire        clk            ,
    input  wire        rst            ,
    // External 1PPS in
    input  wire        pps_in         ,
    // 1PPS to Fabric
    output wire        pps_out        ,
    // Monitor Clock domain (Maybe asynchronous with core clock)
    //----------------------------------------------------------
    input  wire        aclk           ,
    input  wire        aresetn        ,
    // Status
    output wire [31:0] stat_pps_phase ,
    output wire        stat_pps_status,
    // IQR
    output wire        irq_pps_posedge
);

    pps_receiver_top #(
        .C_CLOCK_FREQUENCY(C_CLOCK_FREQUENCY)
    ) inst (
        .clk            (clk            ),
        .rst            (rst            ),
        .pps_in         (pps_in         ),
        .pps_out        (pps_out        ),
        .aclk           (aclk           ),
        .aresetn        (aresetn        ),
        .stat_pps_phase (stat_pps_phase ),
        .stat_pps_status(stat_pps_status),
        .irq_pps_posedge(irq_pps_posedge)
    );

endmodule

`default_nettype wire
