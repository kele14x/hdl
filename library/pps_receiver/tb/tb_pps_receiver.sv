/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_pps_receiver;

    parameter C_CLOCK_FREQUENCY = 25000;

    // Core clock domain
    //----------------------
    // Clock & Reset
    var logic ptp_clk = 0;

    // External 1PPS in
    var logic pps_in = 0;
    // 1PPS to Fabric
    var logic pps_out;
    var logic ts_out;

    always #20 ptp_clk = !ptp_clk;


    // Target PPS interval in ps
    const real TARGET_INTERVAL = 10**9;
    // Jitter assume +-50ppm
    const int JITTER_NOMINAL = TARGET_INTERVAL * 50 / 1000000;

    // PPS generation, to speed up simulation, we set the PPS interval to 1 ms.
    initial begin
        int jitter, last_jitter;
        real interval;
        last_jitter = 0;
        $srandom(0);
        
        forever begin
            pps_in = 1;
            #100 pps_in = 0;
            interval = TARGET_INTERVAL;
            #(interval/1000 - 200);
        end
        
        forever begin
            $display("PPS pulse at %f", $realtime);
            pps_in = 1;
            #100 pps_in = 0;
            jitter = $urandom_range(JITTER_NOMINAL) * 2 - JITTER_NOMINAL;
            interval = TARGET_INTERVAL - last_jitter + jitter;
            #(interval/1000 - 100);
            last_jitter = jitter;
        end
    end

    pps_receiver #(
        .C_CLOCK_FREQUENCY(C_CLOCK_FREQUENCY)
    ) UUT (.*);


endmodule
