/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

// * In normal mode: Full local counter, nanosecond rollover each second, and
//   when nanosecond rollover, second filed +1. Also, in this mode, internal 
//   PPS is generated when nanosecond rollover.
// * In PPS mode: Local counter + PPS, nanosecond will not rollover, and when 
//   PPS arrives, second field +1, internal PPS is generated.

module coreboard1588_axi_rtc #(parameter  C_CLOCK_FREQUENCY = 125000000) (
    input  var logic        clk            ,
    input  var logic        rst            ,
    //
    input  var logic        pps_in         ,
    output var logic        pps_out        ,
    //
    output var logic [31:0] rtc_second     ,
    output var logic [31:0] rtc_nanosecond ,
    //
    input  var logic        ctrl_rtc_mode  , // 0 = Normal mode, 1 = PPS mode
    input  var logic [31:0] ctrl_second    ,
    input  var logic [31:0] ctrl_nanosecond,
    input  var logic        ctrl_timeset   ,
    input  var logic        ctrl_timeget   ,
    //
    output var logic [31:0] stat_second    ,
    output var logic [31:0] stat_nanosecond
);

    localparam C_NS_COUNTER_WIDTH = 10**9 / C_CLOCK_FREQUENCY ;
    localparam C_NS_COUNTER_MAX   = 10**9 - C_NS_COUNTER_WIDTH;

    reg [31:0] second_counter    ; // Sample tick s
    reg [31:0] nanosecond_counter; // Sample tick ns

    // Nanosecond counter
    // Real nanosecond value range from 0 to last tick
    always @ (posedge clk) begin
        if (rst) begin
            nanosecond_counter <= 'd0;
        end else begin
            // Auto logic
            if (ctrl_rtc_mode == 1'b0) begin
                // Normal mode
                nanosecond_counter <= ((nanosecond_counter >= C_NS_COUNTER_MAX) ?
                    0 : (nanosecond_counter + C_NS_COUNTER_WIDTH));
            end else begin
                // PPS Mode
                nanosecond_counter <= pps_in ? 0 : (nanosecond_counter + C_NS_COUNTER_WIDTH);
            end
            // Set time
            if (ctrl_timeset) begin
                nanosecond_counter <= ctrl_nanosecond;
            end
        end
    end

    // Second counter
    // Real second value range from 0 to maximum, it should be enough for use
    always @ (posedge clk) begin
        if (rst) begin
            second_counter <= 'd0;
        end else begin
            // Auto logic
            if (ctrl_rtc_mode == 1'b0) begin
                // Normal mode
                second_counter <= (nanosecond_counter >= C_NS_COUNTER_MAX) ?
                    second_counter + 1 : second_counter;
            end else begin
                // PPS mode
                second_counter <= pps_in ? second_counter + 1 : second_counter;
            end
            // Set time
            if (ctrl_timeset) begin
                second_counter <= ctrl_second;
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            stat_nanosecond <= 'd0;
        end else begin
            if (ctrl_timeget) begin
                stat_nanosecond <= nanosecond_counter;
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            stat_second <= 'd0;
        end else begin
            if (ctrl_timeget) begin
                stat_second <= second_counter;
            end
        end
    end

    assign rtc_second = second_counter;

    assign rtc_nanosecond = nanosecond_counter;

    // Internal PPS generation
    always_ff @ (posedge clk) begin
        if (rst) begin
            pps_out <= 1'b0;
        end else begin
            if (ctrl_rtc_mode == 1'b0) begin
                // Normal mode
                pps_out <= (nanosecond_counter >= C_NS_COUNTER_MAX);
            end else begin
                // PPS mode
                pps_out <= pps_in;
            end
        end
    end

endmodule

`default_nettype wire
