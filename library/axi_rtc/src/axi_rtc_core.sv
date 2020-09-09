/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

// * In normal mode: Full local counter, nanosecond rollover each second, and
//   when nanosecond rollover, second filed +1. Also, in this mode, internal
//   PPS is generated when nanosecond rollover.
// * In PPS mode: Local counter + PPS, nanosecond will not rollover, and when
//   PPS arrives, second field +1, internal PPS is generated.

module axi_rtc_core (
    input  var logic        clk            ,
    input  var logic        rst            ,
    // PPS Out
    output var logic        pps_out        ,
    //
    output var logic [31:0] rtc_sec        ,
    output var logic [29:0] rtc_nsec       ,
    //
    input  var logic        ctrl_get       ,
    input  var logic [31:0] stat_get_sec   ,
    input  var logic [29:0] stat_get_nsec  ,
    //
    input  var logic        ctrl_set       ,
    input  var logic [31:0] ctrl_set_sec   ,
    input  var logic [29:0] ctrl_set_nsec  ,
    //
    input  var logic        ctrl_adj       ,
    input  var logic        ctrl_adj_addsub,
    input  var logic [29:0] ctrl_adj_nsec  ,
    //
    input  var logic [ 7:0] ctrl_inc_b4    ,
    input  var logic [ 7:0] ctrl_inc_nsec  ,
    input  var logic [ 7:0] ctrl_inc_alt
);

    // Nanosecond counter
    //-------------------
    // Real nanosecond value range from 0 to 999999999

    logic [29:0] nsec_cnt     ;
    logic [30:0] nsec_cnt_next;

    always @ (posedge clk) begin
        if (rst) begin
            nsec_cnt <= 'd0;
        end else begin
            nsec_cnt <= nsec_cnt_next;
        end
    end

    always_comb begin
        if (ctrl_timeset) begin
            nsec_cnt_next = ctrl_set_nsec;
        end else begin
            nsec_cnt_next = nsec_cnt + ctrl_inc_nsec;

            if (ctrl_adj && ctrl_adj_addsub == 1'b0) begin
                nsec_cnt_next = nsec_cnt_next + ctrl_adj_nsec
            end else if (ctrl_adj && ctrl_adj_addsub == 1'b1) begin
                nsec_cnt_next = nsec_cnt_next + ctrl_adj_nsec
            end

            if (nsec_cnt_next >= 1000000000) begin
                nsec_cnt_next = nsec_cnt_next - 1000000000;
            end
        end
    end

    logic sec_p1;
    logic [31:0] sec_cnt ; // Sample tick s

    // Second counter
    // Real second value range from 0 to maximum, it should be enough for use
    always @ (posedge clk) begin
        if (rst) begin
            sec_cnt <= 'd0;
        end else if (ctrl_timeset) begin
            // Set time
            sec_cnt <= ctrl_timeset_sec;
        end else if (sec_p1) begin
            // Normal mode
            sec_cnt <= sec_cnt + 1;
        end else begin
            sec_cnt <= sec_cnt;
        end
    end


    // Time readout
    //=============

    always_ff @ (posedge clk) begin
        if (rst) begin
            stat_rtc_nsec <= 'd0;
        end else begin
            if (ctrl_rtc_tick) begin
                stat_rtc_nsec <= nsec_cnt;
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            stat_rtc_sec <= 'd0;
        end else begin
            if (ctrl_rtc_tick) begin
                stat_rtc_sec <= sec_cnt;
            end
        end
    end


    // Time output
    //============

    assign rtc_sec = sec_cnt;
    assign rtc_nsec = nsec_cnt;

    // Internal PPS generation
    always_ff @ (posedge clk) begin
        if (rst) begin
            pps_out <= 1'b0;
        end else begin
            pps_out <= (nsec_cnt >= NSEC_MAX);
        end
    end

endmodule

`default_nettype wire
