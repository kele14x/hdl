/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_rtc_regs #(
    parameter ID         = 0 ,
    parameter ADDR_WIDTH = 14
) (
    //==========
    input  var logic                  up_clk           ,
    input  var logic                  up_rstn          ,
    //
    input  var logic                  up_wreq          ,
    input  var logic [ADDR_WIDTH-1:0] up_waddr         ,
    input  var logic [          31:0] up_wdata         ,
    output var logic                  up_wack          ,
    //
    input  var logic                  up_rreq          ,
    input  var logic [ADDR_WIDTH-1:0] up_raddr         ,
    output var logic [          31:0] up_rdata         ,
    output var logic                  up_rack          ,
    //=========
    output var logic                  ctrl_rtc_tick    ,
    output var logic                  ctrl_timeset     ,
    output var logic [          31:0] ctrl_timeset_sec ,
    output var logic [          31:0] ctrl_timeset_nsec,
    //
    input  var logic [          31:0] stat_rtc_sec     ,
    input  var logic [          31:0] stat_rtc_nsec
);


    localparam [31:0] PCORE_VERSION = 32'h20200803;


    //  addr       reg
    //--------------------------
    //  0x0000    PCORE_VERSION
    //  0x0001    ID
    //  0x0002    up_scratch
    //  0x0010    ctrl_rtc_tick
    //  0x0011    ctrl_timeset
    //  0x0012    ctrl_timeset_sec
    //  0x0013    ctrl_timeset_nsec
    //  0x0020    stat_rtc_sec
    //  0x0021    stat_rtc_nsec


    reg [31:0] up_scratch    = 'h0;


    // Write

    // up_scratch at 0x02
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_scratch <= 'h00;
        end else if (up_wreq && up_waddr == 'h02) begin
            up_scratch <= up_wdata;
        end
    end

    // ctrl_rtc_tick at 0x10
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_rtc_tick <= 'b0;
        end else if (up_wreq && up_waddr == 'h10) begin
            ctrl_rtc_tick <= up_wdata[0];
        end else begin
            ctrl_rtc_tick <= 1'b0;
        end
    end

    // ctrl_timeset at 0x11
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_timeset <= 'b0;
        end else if (up_wreq && up_waddr == 'h11) begin
            ctrl_timeset <= up_wdata[0];
        end else begin
            ctrl_timeset <= 1'b0;
        end
    end

    // ctrl_timeset_sec at 0x12
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_timeset_sec <= 'b0;
        end else if (up_wreq && up_waddr == 'h12) begin
            ctrl_timeset_sec <= up_wdata;
        end
    end

    // ctrl_timeset_nsec at 0x13
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_timeset_nsec <= 'b0;
        end else if (up_wreq && up_waddr == 'h13) begin
            ctrl_timeset_nsec <= up_wdata;
        end
    end


    // Read out
    //=========

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_rdata <= 'b0;
        end else if (up_rreq) begin
            case (up_raddr)
                'h00    : up_rdata <= PCORE_VERSION;
                'h01    : up_rdata <= ID;
                'h02    : up_rdata <= up_scratch;
                'h12    : up_rdata <= ctrl_timeset_sec;
                'h13    : up_rdata <= ctrl_timeset_nsec;
                'h20    : up_rdata <= stat_rtc_sec;
                'h21    : up_rdata <= stat_rtc_nsec;
                default : up_rdata <= 32'h00000000;
            endcase
        end
    end


    // ACK Logic
    //==========

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_wack <= 1'b0;
        end else begin
            up_wack <= up_wreq;
        end
    end

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_rack <= 1'b0;
        end else begin
            up_rack <= up_rreq;
        end
    end

endmodule

`default_nettype wire
