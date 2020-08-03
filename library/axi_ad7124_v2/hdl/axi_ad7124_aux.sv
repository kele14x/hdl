/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_aux #(parameter ID = 0) (
    input  wire        up_clk         ,
    input  wire        up_rstn        ,
    //
    input  wire        up_wreq        ,
    input  wire [13:0] up_waddr       ,
    input  wire [31:0] up_wdata       ,
    output reg         up_wack        ,
    //
    input  wire        up_rreq        ,
    input  wire [13:0] up_raddr       ,
    output reg  [31:0] up_rdata       ,
    output reg         up_rack        ,
    //
    output reg         ctrl_power_en  , // 1 = Power on, 0 = Power off
    output reg         ctrl_relay_ctrl  // 1 = Calibration, 0 = Normal op
);

    localparam [31:0] PCORE_VERSION = 32'h20200722;


    reg [31:0] up_scratch = 'h0;

    // Write

    // up_scratch at 0x02
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_scratch <= 'h00;
        end else if (up_wreq && up_waddr == 'h02) begin
            up_scratch <= up_wdata;
        end
    end

    // ctrl_power_en at 0x10
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_power_en <= 'b0;
        end else if (up_wreq && up_waddr == 'h10) begin
            ctrl_power_en <= up_wdata[0];
        end
    end

    // ctrl_relay_ctrl at 0x11
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_relay_ctrl <= 'b0;
        end else if (up_wreq && up_waddr == 'h11) begin
            ctrl_relay_ctrl <= up_wdata[0];
        end
    end

    /* up_wack */

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_wack <= 1'b0;
        end else begin
            up_wack <= up_wreq;
        end
    end


    // Read out

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_rdata <= 'b0;
        end else if (up_rreq) begin
            case (up_raddr)
                'h00    : up_rdata <= PCORE_VERSION;
                'h01    : up_rdata <= ID;
                'h02    : up_rdata <= up_scratch;
                'h10    : up_rdata <= {31'b0, ctrl_power_en};
                'h11    : up_rdata <= {31'b0, ctrl_relay_ctrl};
                default : up_rdata <= 32'h00000000;
            endcase
        end
    end

    /* up_rack */

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_rack <= 1'b0;
        end else begin
            up_rack <= up_rreq;
        end
    end

endmodule
