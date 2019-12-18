/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module timestamp_1pps (
    /* Clock & Reset */
    input  wire clk_125m    ,
    input  wire rst_125m    ,
    /* External 1PPS in */
    input  wire PTP_TRG_FPGA,
    /* 1PPS to Fabric */
    output wire sync_1pps   ,
    /* Status output */
    output wire sta_pps_locked
);

    parameter C_CLOCK_FREQUENCY = 125000000;

    (* IOB="true" *)
    reg pps_iob;
    (* ASYNC_REG="true" *)
    reg  pps_d1, pps_d2;
    reg  pps_d3, pps_d4;
    wire pps_posedge;

    reg [$clog2(C_CLOCK_FREQUENCY-1)-1:0] pha_cnt;
    reg [$clog2(C_CLOCK_FREQUENCY-1)-1:0] last_pha = 0;

    reg [3:0] adv_cnt, late_cnt;

    reg sync_1pps_r, pps_locked;

    always_ff @ (posedge clk_125m) begin
        pps_iob <= PTP_TRG_FPGA;
        pps_d1 <= pps_iob;
        pps_d2 <= pps_d1;
        pps_d3 <= pps_d2;
        pps_d4 <= pps_d3;
    end

    assign pps_posedge = {pps_d3, pps_d4} == 2'b10;

    // `pha_cnt` is a free running counter that count for 1s at current clock 
    // frequency
    always_ff @ (posedge clk_125m)
        pha_cnt <= (rst_125m || pha_cnt == C_CLOCK_FREQUENCY-1) ? 'd0 : pha_cnt + 1;

    always_ff @ (posedge clk_125m)
        if (rst_125m) begin
            adv_cnt <= 'd0;
            late_cnt <= 'd0;
            last_pha <= 'd0;
            pps_locked <= 'b0;
        end else begin
            if (pps_posedge) begin
                if (pha_cnt == last_pha) begin
                    // Current count is equal to last count
                    adv_cnt <= adv_cnt == 0 ? adv_cnt : adv_cnt + 1;
                    late_cnt <= late_cnt == 0 ? late_cnt : late_cnt + 1;
                    pps_locked <= 1'b1;
                end else if (last_pha - pha_cnt == 1 || last_pha - pha_cnt == C_CLOCK_FREQUENCY - 1) begin
                    // Current count is 1 less than last count
                    late_cnt <= late_cnt == 0 ? late_cnt : late_cnt + 1;
                    adv_cnt <= adv_cnt + 1;
                    if (adv_cnt == 15) last_pha <= pha_cnt;
                    pps_locked <= 1'b1;
                end else if (pha_cnt - last_pha == 1 || pha_cnt - last_pha == C_CLOCK_FREQUENCY - 1) begin
                    // Current count is 1 more than last count
                    adv_cnt <= adv_cnt == 0 ? adv_cnt : adv_cnt + 1;
                    late_cnt <= late_cnt + 1;
                    if (late_cnt == 15) last_pha <= pha_cnt;
                    pps_locked <= 1'b1;
                end else begin
                    // Current count is 1 more different than last count
                    adv_cnt <= 0;
                    late_cnt <= 0;
                    last_pha <= pha_cnt;
                    pps_locked <= 1'b0;
                end
            end
        end

    always_ff @ (posedge clk_125m)
        sync_1pps_r <= (pha_cnt == last_pha) && pps_locked;

    assign sync_1pps = sync_1pps_r;

    assign sta_pps_locked = pps_locked;

endmodule
