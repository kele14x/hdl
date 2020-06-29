/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module dummy_adc_core (
    input  wire        aclk         ,
    input  wire        aresetn      ,
    // AXIS
    input  wire [31:0] s_axis_tdata ,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    // IRQ
    output wire        interrupt    ,
    //
    input  wire [31:0] ctrl_ts      ,
    //
    output wire [31:0] stat_adc_data
);

    reg [31:0] ts_cnt;

    reg ts_tick;

    reg [9:0] irq_ext;

    // Sample time counter
    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
            ts_cnt <= 'd0;
        end else begin
            ts_cnt <= (ts_cnt >= ctrl_ts) ? 'd0 : ts_cnt + 1;
        end
    end

    // Sample tick
    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
            ts_tick <= 1'b0;
        end else begin
            ts_tick <= (ts_cnt >= ctrl_ts);
        end
    end

    // At sample tick, save to register
    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
            stat_adc_data <= 'd0;
        end else if (ts_tick) begin
            stat_adc_data <= s_axis_tdata;
        end
    end

    // At same time, generate a irq
    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
            irq_ext <= 'd0;
        end else if (ts_tick) begin
            irq_ext <= {10{1'b1}};
        end else begin
            irq_ext <= (irq_ext == 0) ? 0 : (irq_ext - 1);
        end
    end

endmodule