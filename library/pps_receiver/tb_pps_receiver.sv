/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_pps_receiver #(parameter C_CLOCK_FREQUENCY = 125000)();

    // Core clock domain
    //----------------------
    // Clock & Reset
    reg clk = 0;
    reg rst = 1;
    // External 1PPS in
    reg pps_in = 0;
    // 1PPS to Fabric
    wire pps_out;
    // Monitor Clock domain (Maybe asynchronous with core clock)
    //----------------------------------------------------------
    reg aclk    = 0;
    reg aresetn = 0;
    // Status
    wire [31:0] stat_pps_phase ;
    wire        stat_pps_status;
    // IQR
    wire iqr_pps_posedge;


    always #4 clk = ~clk;

    initial #100 rst = 0;

    always #5 aclk = ~aclk;

    initial #100 aresetn = 1;

    initial begin
        #1000;
        forever begin
            #(1000000-100) pps_in = 1;
            #100 pps_in = 0;
        end
    end
        

    pps_receiver #(.C_CLOCK_FREQUENCY(C_CLOCK_FREQUENCY))UUT (.*);


endmodule
