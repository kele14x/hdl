/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module fir_lp_top (
    input  wire        aclk         ,
    input  wire        aresetn      ,
    //
    input  wire [31:0] s_axis_tdata ,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    //
    output wire [31:0] m_axis_tdata ,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);

    wire [31:0] s_axis_tdata_fmt;

    // Data format, from uint16 to int16
    assign s_axis_tdata_fmt = {s_axis_tdata[31:16],
        (s_axis_tdata[15:0] - 16'h8000)};

    fir_lp i_fir_lp (
        .ap_clk       (aclk         ),
        .ap_rst_n     (aresetn      ),
        //
        .ap_start     (1'b1         ),
        .ap_done      (             ),
        .ap_idle      (             ),
        .ap_ready     (             ),
        //
        .din_V_TDATA  (s_axis_tdata_fmt ),
        .din_V_TVALID (s_axis_tvalid),
        .din_V_TREADY (s_axis_tready),
        //
        .dout_V_TDATA (m_axis_tdata ),
        .dout_V_TVALID(m_axis_tvalid),
        .dout_V_TREADY(m_axis_tready)
    );

endmodule

`default_nettype wire
