/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_mac (
    input  wire       tx_core_clk     ,
    input  wire       rx_core_clk     ,
    //
    input  wire       tx_reset        ,
    input  wire       rx_reset        ,
    // TX AXIS
    input  wire [7:0] s_axis_tdata    ,
    input  wire       s_axis_tvalid   ,
    input  wire       s_axis_tlast    ,
    output wire       s_axis_tready   ,
    // RX AXIS
    output wire [7:0] m_axis_tdata    ,
    output wire       m_axis_tvalid   ,
    output wire       m_axis_tlast    ,
    // To TX PCS
    output wire [7:0] pcs_txdata      , // TX Data
    output wire       pcs_txcharisk   , // TX Char is Key
    output wire [3:0] pcs_txseq       , // TX Sequence
    // From RX PCS
    input  wire [7:0] pcs_rxdata      , // RX Data
    input  wire       pcs_rxcharisk   , // RX Char is Key
    input  wire       pcs_rxdisperr   , // RX Disp Error
    input  wire       pcs_rxnotintable, // RX Not in Table
    input  wire       pcs_rxvalid       // RX Valid
);

    Cbus_tx_mac i_tx_mac (
        .tx_clk       (tx_core_clk  ),
        .tx_rst       (tx_reset     ),
        //
        .s_axis_tdata (s_axis_tdata ),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast (s_axis_tlast ),
        .s_axis_tready(s_axis_tready),
        //
        .pcs_txdata   (pcs_txdata   ),
        .pcs_txcharisk(pcs_txcharisk),
        .pcs_txseq    (pcs_txseq    )
    );


endmodule
