/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_rtc_regs #(parameter ADDR_WIDTH = 14) (
    //==========
    input  var logic                  up_clk            ,
    input  var logic                  up_rstn           ,
    //
    input  var logic                  up_wreq           ,
    input  var logic [ADDR_WIDTH-1:0] up_waddr          ,
    input  var logic [          31:0] up_wdata          ,
    output var logic                  up_wack           ,
    //
    input  var logic                  up_rreq           ,
    input  var logic [ADDR_WIDTH-1:0] up_raddr          ,
    output var logic [          31:0] up_rdata          ,
    output var logic                  up_rack           ,
    //=========
    output var logic                  ctrl_get          ,
    input  var logic [          31:0] stat_get_sec      ,
    input  var logic [          29:0] stat_get_nsec     ,
    //
    output var logic                  ctrl_set          ,
    output var logic [          31:0] ctrl_set_sec      ,
    output var logic [          29:0] ctrl_set_nsec     ,
    //
    output var logic                  ctrl_adj          ,
    output var logic [          31:0] ctrl_adj_nsec     , // signed
    //
    output var logic [           7:0] ctrl_inc_nsec     ,
    output var logic [          23:0] ctrl_inc_nsec_frac
);

    //  addr       reg
    //--------------------------
    //  02    scratch
    //  16    ctrl_get
    //  17    stat_get_sec
    //  18    stat_get_nsec
    //  19    ctrl_set
    //  20    ctrl_set_sec
    //  21    ctrl_set_nsec
    //  22    ctrl_adj_nsec
    //  23    ctrl_inc_nsec, ctrl_inc_nsec_frac


    reg [31:0] scratch    = 'h0;


    // Write

    // scratch at 2
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            scratch <= 'h00;
        end else if (up_wreq && up_waddr == 'd2) begin
            scratch <= up_wdata;
        end
    end

    // ctrl_get at 16
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_get <= 'b0;
        end else if (up_wreq && up_waddr == 'd16) begin
            ctrl_get <= up_wdata[0];
        end else begin
            ctrl_get <= 1'b0;
        end
    end

    // ctrl_set at 19
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_set <= 'b0;
        end else if (up_wreq && up_waddr == 'd19) begin
            ctrl_set <= up_wdata[0];
        end else begin
            ctrl_set <= 1'b0;
        end
    end

    // ctrl_set_sec at 20
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_set_sec <= 'b0;
        end else if (up_wreq && up_waddr == 'd20) begin
            ctrl_set_sec <= up_wdata;
        end
    end

    // ctrl_set_nsec at 21
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_set_nsec <= 'b0;
        end else if (up_wreq && up_waddr == 'd21) begin
            ctrl_set_nsec <= up_wdata[29:0];
        end
    end

    // ctrl_adj_nsec at 22
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_adj_nsec <= 'b0;
            ctrl_adj <= 1'b0;
        end else if (up_wreq && up_waddr == 'd22) begin
            ctrl_adj_nsec <= up_wdata;
            ctrl_adj <= 1'b1;
        end else begin
            ctrl_adj <= 1'b0;
        end
    end

    // ctrl_inc_nsec, ctrl_inc_nsec_frac at 23
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            {ctrl_inc_nsec, ctrl_inc_nsec_frac} <= {8'd8, 24'b0};
        end else if (up_wreq && up_waddr == 'd23) begin
            {ctrl_inc_nsec, ctrl_inc_nsec_frac} <= up_wdata;
        end
    end

    // Read out
    //=========

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_rdata <= 'b0;
        end else if (up_rreq) begin
            case (up_raddr)
                'd02    : up_rdata <= scratch;
                'd17    : up_rdata <= stat_get_sec;
                'd18    : up_rdata <= {2'b0, stat_get_nsec};
                'd20    : up_rdata <= ctrl_set_sec;
                'd21    : up_rdata <= {2'b0, ctrl_set_nsec};
                'd22    : up_rdata <= ctrl_adj_nsec;
                'd23    : up_rdata <= {ctrl_inc_nsec, ctrl_inc_nsec_frac};
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
