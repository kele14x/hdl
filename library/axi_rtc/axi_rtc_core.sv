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

module axi_rtc_core #(parameter  CLOCK_FREQUENCY = 125000000) (
    input  var logic        clk              ,
    input  var logic        rst              ,
    // PPS Out
    output var logic        pps_out          ,
    //
    output var logic [31:0] rtc_sec          ,
    output var logic [31:0] rtc_nsec         ,
    //
    input  var logic        ctrl_rtc_tick    ,
    input  var logic        ctrl_timeset     ,
    input  var logic [31:0] ctrl_timeset_sec ,
    input  var logic [31:0] ctrl_timeset_nsec,
    //
    output var logic [31:0] stat_rtc_sec     ,
    output var logic [31:0] stat_rtc_nsec
);

    // Time counter
    //==============

    localparam NSEC_INC = 10**9 / CLOCK_FREQUENCY ;
    localparam NSEC_MAX   = 10**9 - NSEC_INC;

    reg [31:0] sec_cnt    ; // Sample tick s
    reg [31:0] nsec_cnt; // Sample tick ns

    // Nanosecond counter
    // Real nanosecond value range from 0 to last tick
    always @ (posedge clk) begin
        if (rst) begin
            nsec_cnt <= 'd0;
        end else if (ctrl_timeset) begin
            // Set time
            nsec_cnt <= ctrl_timeset_nsec;
        end else begin
            // Normal mode
            nsec_cnt <= ((nsec_cnt >= NSEC_MAX) ? 0 : (nsec_cnt + NSEC_INC));
        end
    end

    // Second counter
    // Real second value range from 0 to maximum, it should be enough for use
    always @ (posedge clk) begin
        if (rst) begin
            sec_cnt <= 'd0;
        end else if (ctrl_timeset) begin
            // Set time
            sec_cnt <= ctrl_timeset_sec;
        end else begin
            // Normal mode
            sec_cnt <= (nsec_cnt >= NSEC_MAX) ? sec_cnt + 1 : sec_cnt;
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
