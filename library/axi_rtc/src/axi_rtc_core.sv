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
    input  var logic        clk               ,
    input  var logic        rst               ,
    // PPS Out
    output var logic        pps_out           ,
    //
    output var logic [31:0] rtc_sec           ,
    output var logic [31:0] rtc_nsec          ,
    // Control ports
    //--------------
    input  var logic        ctrl_get          ,
    output var logic [31:0] stat_get_sec      ,
    output var logic [29:0] stat_get_nsec     ,
    //
    input  var logic        ctrl_set          ,
    input  var logic [31:0] ctrl_set_sec      ,
    input  var logic [29:0] ctrl_set_nsec     ,
    //
    input  var logic        ctrl_adj          ,
    input  var logic [31:0] ctrl_adj_nsec     , // signed
    //
    input  var logic [ 7:0] ctrl_inc_nsec     ,
    input  var logic [23:0] ctrl_inc_nsec_frac
);


    // Nanosecond increment accumulator
    //---------------------------------
    // Binary value, fi(0,8,24)
    // We only accumlate sub-nanosecond part, since nanosecond part will be
    // added to `nsec_cnt`;

    logic [ 7:0] nsec_inc;
    logic [23:0] nsec_inc_frac;

    always_ff @ (posedge clk) begin
        if (rst) begin
            {nsec_inc, nsec_inc_frac} <= 0;
        end else begin
            {nsec_inc, nsec_inc_frac} <= nsec_inc_frac + { ctrl_inc_nsec, ctrl_inc_nsec_frac };
        end
    end

    // Nanosecond counter
    //-------------------
    // Real nanosecond value range from 0 to 999999999

    // Nanosecond to add at this tick, assume this value will less than 10^9
    logic signed [31:0] nsec_cnt_adder;

    always_ff @ (posedge clk) begin
        if (rst) begin
            nsec_cnt_adder <= 'd0;
        end else if (ctrl_adj) begin
            nsec_cnt_adder = nsec_inc + $signed(ctrl_adj_nsec);
        end else begin
            nsec_cnt_adder = nsec_inc;
        end
    end

    // To handle the counter rollover, we need to add the increment, then
    // compare it with 10**9. To avoid do two add operation in cascade path,
    // we will do two add in parallel, then follow a MUX

    // Normal adder
    logic signed [31:0] nsec_cnt_adder_d;
    // Rollover adder
    logic signed [31:0] nsec_cnt_adder_r;


    always_ff @ (posedge clk) begin
        if (rst) begin
            nsec_cnt_adder_d <= 'd0;
        end else begin
            nsec_cnt_adder_d <= nsec_cnt_adder;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            nsec_cnt_adder_r <= 'd0;
        end else begin
            nsec_cnt_adder_r <= nsec_cnt_adder - 10**9;
        end
    end

    // Nanosecond counter in action

    logic [31:0] nsec_cnt;

    logic signed [31:0] nsec_cnt_next_a;
    logic signed [31:0] nsec_cnt_next_b;

    // Next tick value if not rollover
    always_comb begin
        nsec_cnt_next_a = nsec_cnt + nsec_cnt_adder_d;
    end

    // Next tick value if rollover, if negative new know it's invalid
    always_comb begin
        nsec_cnt_next_b = nsec_cnt + nsec_cnt_adder_r;
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            nsec_cnt <= 'd0;
        end else if (ctrl_set) begin
            nsec_cnt <= ctrl_set_nsec;
        end else if (nsec_cnt_next_b[31]) begin
            nsec_cnt <= nsec_cnt_next_a;
        end else begin
            nsec_cnt <= nsec_cnt_next_b;
        end
    end

    // Second counter
    //-------------------
    // Real second value range from 0 to 2^32-1

    logic sec_adder;
    logic [31:0] sec_cnt ; // Sample tick s

    always_ff @ (posedge clk) begin
        if (rst) begin
            sec_adder <= 1'b0;
        end else begin
            sec_adder = ~nsec_cnt_next_b[31];
        end
    end

    // Second counter
    // Real second value range from 0 to maximum, it should be enough for use
    always_ff @ (posedge clk) begin
        if (rst) begin
            sec_cnt <= 'd0;
        end else if (ctrl_set) begin
            sec_cnt <= ctrl_set_sec;
        end else if (sec_adder) begin
            sec_cnt <= sec_cnt + 1;
        end else begin
            sec_cnt <= sec_cnt;
        end
    end


    // Time output
    //============

    logic [31:0] nsec_cnt_d;

    always_ff @ (posedge clk) begin
        if (rst) begin
            nsec_cnt_d <= 'd0;
        end else begin
            nsec_cnt_d <= nsec_cnt;
        end
    end

    assign rtc_sec  = sec_cnt;
    assign rtc_nsec = nsec_cnt_d;


    // Time readout
    //=============

    always_ff @ (posedge clk) begin
        if (rst) begin
            stat_get_sec <= 'd0;
        end else if (ctrl_get) begin
            stat_get_sec <= sec_cnt;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            stat_get_nsec <= 'd0;
        end else if (ctrl_get) begin
            stat_get_nsec <= nsec_cnt_d;
        end
    end


    // PPS output
    //============

    // Internal PPS generation
    always_ff @ (posedge clk) begin
        if (rst) begin
            pps_out <= 1'b0;
        end else begin
            pps_out <= sec_adder;
        end
    end

endmodule

`default_nettype wire
