/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module pps_receiver_top #(
    // The frequency of core clock
    parameter C_CLOCK_FREQUENCY = 125000000,
    // The PPS arriving time uncertainty window, if the PPS arrived at last
    // phase - window or last phase + window, it's normal. Or it is out of
    // lock
    parameter C_PPS_DELAY      = 12500
) (
    // Core clock domain
    //----------------------
    // Clock & Reset
    input  var logic clk    ,
    input  var logic rst    ,
    // External 1PPS in
    input  var logic pps_in ,
    // 1PPS to Fabric
    output var logic pps_out
);

    localparam C_COUNTER_WIDTH = $clog2(C_CLOCK_FREQUENCY-1);

    initial begin
        assert (C_COUNTER_WIDTH <= 32) else
            $warning("Core clock frequency too slow, which makes the 1 PPS \
                counter exist 32-bit width");
        assert (C_PPS_DELAY < C_CLOCK_FREQUENCY / 2) else
            $warning("PPS window too large");
    end

    // PPS input CDC
    //==============
    // Standard 2-async FF structure to capture PPS input from external input

    (* ASYNC_REG="true" *)
    var logic pps_cdc_reg1, pps_cdc_reg2;

    var logic pps_d      ;
    var logic pps_posedge;

    always_ff @ (posedge clk) begin
        pps_cdc_reg1 <= pps_in;
        pps_cdc_reg2 <= pps_cdc_reg1;
    end

    always_ff @ (posedge clk) begin
        pps_d <= pps_cdc_reg2;
    end

    assign pps_posedge = {pps_cdc_reg2, pps_d} == 2'b10;


    // PPS Phase
    //=============

    // The free running clock is used to record the PPS arriving time.
    var logic [C_COUNTER_WIDTH-1:0] free_counter    ;
    var logic [C_COUNTER_WIDTH-1:0] last_pha     = 0;

    // `free_counter` is a free running counter that count for 1s at current
    // clock frequency.
    always_ff @ (posedge clk) begin
        free_counter <= (rst || free_counter == C_CLOCK_FREQUENCY-1) ? 'd0 :
            free_counter + 1;
    end

    // Record the counter when PPS arrives
    always_ff @ (posedge clk) begin
        if (rst) begin
            last_pha <= 'd0;
        end else if (pps_posedge) begin
            last_pha <= free_counter;
        end
    end

    // PPS Output
    //===========
    // The internal PPS pulse is a delayed version of PPS input, this is to
    // implement a "holdover" function but not generate 2 PPS if PPS arrives
    // late

    var logic r1, r2;

    // Right boundary
    assign r1 = (free_counter == last_pha + C_PPS_DELAY);
    assign r2 = (free_counter == last_pha + C_PPS_DELAY - C_CLOCK_FREQUENCY);

    always_ff @ (posedge clk) begin
        if (rst) begin
            pps_out <= 1'b0;
        end else begin
            pps_out <= r1 || r2;
        end
    end

endmodule

`default_nettype wire
