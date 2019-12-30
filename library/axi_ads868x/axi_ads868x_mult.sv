/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads868x_mult (
    input  wire        aclk         ,
    input  wire        aresetn      ,
    //
    input  wire [15:0] s_axis_tdata ,
    input  wire        s_axis_tvalid,
    output reg         s_axis_tready,
    //
    output reg  [31:0] m_axis_tdata ,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    //
    input  wire [15:0] ctrl_mult_coe
);

    reg signed [15:0] a, b;
    reg signed [31:0] m, p;

    reg vd, vdd, vd3;

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axis_tready <= 1'b0;
        end else begin
            s_axis_tready <= 1'b1;
        end
    end

    always_ff @ (posedge aclk) begin
        if (s_axis_tvalid) begin
            a <= s_axis_tdata;
        end
    end

    always_ff @ (posedge aclk) begin
        b <= ctrl_mult_coe;
    end

    always_ff @ (posedge aclk) begin
        m <= a * b;
    end

    always_ff @ (posedge aclk) begin
        p <= m;
    end

    always_ff @ (posedge aclk) begin
        vd <= s_axis_tvalid;
        vdd <= vd;
        vd3 <= vdd;
    end

    always_ff @ (posedge aclk) begin
        if (vd3) begin
            m_axis_tdata <= p;
        end
    end

    always_ff @(posedge aclk) begin
        m_axis_tvalid <= vd3;
    end

endmodule

`default_nettype none
