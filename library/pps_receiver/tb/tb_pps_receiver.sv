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
    var logic clk = 0;
    var logic rst = 1;
    // External 1PPS in
    var logic pps_in = 0;
    // 1PPS to Fabric
    var logic pps_out;
    // Monitor Clock domain (Maybe asynchronous with core clock)
    //----------------------------------------------------------
    var logic aclk    = 0;
    var logic aresetn = 0;
    // Status
    var logic [31:0] stat_pps_phase ;
    var logic        stat_pps_status;
    // IQR
    var logic irq_pps_posedge;

    always #4 clk = !clk;

    initial #100 rst = 0;

    always #5 aclk = !aclk;

    initial #100 aresetn = 1;

    const int taget_interval = 1000000;

    // PPS generation, to speed up simulation, we set the PPS interval to 1 ms.
    initial begin
        int jitter, last_jitter;
        real interval;
        last_jitter = 0;
        $srandom(0);
        forever begin
            $display("PPS pulse at %f", $realtime);
            pps_in = 1;
            #100 pps_in = 0;
            jitter = $urandom_range(8000) * 2 - 8000;
            interval = taget_interval + $itor(-last_jitter + jitter) /1000;
            #(interval - 100);
            last_jitter = jitter;
            
            
        end
    end


    pps_receiver #(.C_CLOCK_FREQUENCY(C_CLOCK_FREQUENCY)) UUT (.*);


endmodule
