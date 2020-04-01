/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus #(parameter SYS_W = 1) (
    // Upper Pins
    input  wire             UPPER_RX_CLK_P ,
    input  wire             UPPER_RX_CLK_N ,
    input  wire [SYS_W-1:0] UPPER_RX_DIN_P ,
    input  wire [SYS_W-1:0] UPPER_RX_DIN_N ,
    //
    output wire             UPPER_TX_CLK_P ,
    output wire             UPPER_TX_CLK_N ,
    output wire [SYS_W-1:0] UPPER_TX_DOUT_P,
    output wire [SYS_W-1:0] UPPER_TX_DOUT_N,
    // Lower Pins
    input  wire             LOWER_RX_CLK_P ,
    input  wire             LOWER_RX_CLK_N ,
    input  wire [SYS_W-1:0] LOWER_RX_DIN_P ,
    input  wire [SYS_W-1:0] LOWER_RX_DIN_N ,
    //
    output wire             LOWER_TX_CLK_P ,
    output wire             LOWER_TX_CLK_N ,
    output wire [SYS_W-1:0] LOWER_TX_DOUT_P,
    output wire [SYS_W-1:0] LOWER_TX_DOUT_N,
    // Fabric Port
    input  wire             tx_core_clk    , // 125 MHz
    input  wire             rx_core_clk    ,
    //
    input  wire             tx_reset       ,
    input  wire             rx_reset       ,
    // TX AXIS
    input  wire [      7:0] s_axis_tdata   ,
    input  wire             s_axis_tvalid  ,
    input  wire             s_axis_tlast   ,
    output wire             s_axis_tready  ,
    // RX AXIS
    output wire [      7:0] m_axis_tdata   ,
    output wire             m_axis_tvalid  ,
    output wire             m_axis_tlast   ,
    input  wire             m_axis_tready
);

    // TODO: L2 Packet Router

    Cbus_link #(.SYS_W(SYS_W)) i_upper_half (
        .TX_CLK_P     (UPPER_TX_CLK_P ),
        .TX_CLK_N     (UPPER_TX_CLK_N ),
        .TX_DOUT_P    (UPPER_TX_DOUT_P),
        .TX_DOUT_N    (UPPER_TX_DOUT_N),
        //
        .RX_CLK_P     (UPPER_RX_CLK_P ),
        .RX_CLK_N     (UPPER_RX_CLK_N ),
        .RX_DIN_P     (UPPER_RX_DIN_P ),
        .RX_DIN_N     (UPPER_RX_DIN_N ),
        //
        .tx_core_clk  (tx_core_clk    ),
        .rx_core_clk  (rx_core_clk    ),
        //
        .tx_reset     (tx_reset       ),
        .rx_reset     (rx_reset       ),
        // TODO: Sim temp
        .s_axis_tdata (s_axis_tdata   ),
        .s_axis_tvalid(s_axis_tvalid  ),
        .s_axis_tlast (s_axis_tlast   ),
        .s_axis_tready(s_axis_tready  ),
        //
        .m_axis_tdata (               ),
        .m_axis_tvalid(               ),
        .m_axis_tlast (               )
    );



    Cbus_link #(.SYS_W(SYS_W)) i_lower_half (
        .TX_CLK_P     (LOWER_TX_CLK_P ),
        .TX_CLK_N     (LOWER_TX_CLK_N ),
        .TX_DOUT_P    (LOWER_TX_DOUT_P),
        .TX_DOUT_N    (LOWER_TX_DOUT_N),
        //
        .RX_CLK_P     (LOWER_RX_CLK_P ),
        .RX_CLK_N     (LOWER_RX_CLK_N ),
        .RX_DIN_P     (LOWER_RX_DIN_P ),
        .RX_DIN_N     (LOWER_RX_DIN_N ),
        //
        .tx_core_clk  (tx_core_clk    ),
        .rx_core_clk  (rx_core_clk    ),
        //
        .tx_reset     (tx_reset       ),
        .rx_reset     (rx_reset       ),
        //
        .s_axis_tdata (               ),
        .s_axis_tvalid(               ),
        .s_axis_tlast (               ),
        .s_axis_tready(               ),
        //
        .m_axis_tdata (               ),
        .m_axis_tvalid(               ),
        .m_axis_tlast (               )
    );



endmodule
