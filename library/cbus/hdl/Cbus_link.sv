/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_link (
    // PHY Pins
    input  wire       RX_CLK_P     ,
    input  wire       RX_CLK_N     ,
    input  wire       RX_DIN_P     ,
    input  wire       RX_DIN_N     ,
    //
    output wire       TX_CLK_P     ,
    output wire       TX_CLK_N     ,
    output wire       TX_DOUT_P    ,
    output wire       TX_DOUT_N    ,
    /* Fabric Port */
    // Clock & Reset
    input  wire       tx_core_clk  , // 125 MHz
    input  wire       rx_core_clk  ,
    //
    input  wire       tx_reset     ,
    input  wire       rx_reset     ,
    // TX AXIS
    input  wire [7:0] s_axis_tdata ,
    input  wire       s_axis_tvalid,
    input  wire       s_axis_tlast ,
    output wire       s_axis_tready,
    // RX AIXS
    output wire [7:0] m_axis_tdata ,
    output wire       m_axis_tvalid,
    output wire       m_axis_tlast
);

    wire [7:0] pcs_txdata   ;
    wire       pcs_txcharisk;
    wire [3:0] pcs_txseq    ;

    wire [7:0] pcs_rxdata      ;
    wire       pcs_rxcharisk   ;
    wire       pcs_rxdisperr   ;
    wire       pcs_rxnotintable;
    wire       pcs_rxvalid     ;

    Cbus_mac i_mac (
        .tx_core_clk     (tx_core_clk     ),
        .rx_core_clk     (rx_core_clk     ),
        //
        .tx_reset        (tx_reset        ),
        .rx_reset        (rx_reset        ),
        //
        .s_axis_tdata    (s_axis_tdata    ),
        .s_axis_tvalid   (s_axis_tvalid   ),
        .s_axis_tlast    (s_axis_tlast    ),
        .s_axis_tready   (s_axis_tready   ),
        //
        .m_axis_tdata    (m_axis_tdata    ),
        .m_axis_tvalid   (m_axis_tvalid   ),
        .m_axis_tlast    (m_axis_tlast    ),
        //
        .pcs_txdata      (pcs_txdata      ),
        .pcs_txcharisk   (pcs_txcharisk   ),
        .pcs_txseq       (pcs_txseq       ),
        //
        .pcs_rxdata      (pcs_rxdata      ),
        .pcs_rxcharisk   (pcs_rxcharisk   ),
        .pcs_rxdisperr   (pcs_rxdisperr   ),
        .pcs_rxnotintable(pcs_rxnotintable),
        .pcs_rxvalid     (pcs_rxvalid     )
    );


    Cbus_phy i_phy (
        .TX_CLK_P        (TX_CLK_P        ),
        .TX_CLK_N        (TX_CLK_N        ),
        .TX_DOUT_P       (TX_DOUT_P       ),
        .TX_DOUT_N       (TX_DOUT_N       ),
        //
        .RX_CLK_P        (RX_CLK_P        ),
        .RX_CLK_N        (RX_CLK_N        ),
        .RX_DIN_P        (RX_DIN_P        ),
        .RX_DIN_N        (RX_DIN_N        ),
        //
        .tx_core_clk     (tx_core_clk     ),
        .rx_core_clk     (rx_core_clk     ),
        //
        .tx_reset        (tx_reset        ),
        .rx_reset        (rx_reset        ),
        //
        .pcs_txdata      (pcs_txdata      ),
        .pcs_txcharisk   (pcs_txcharisk   ),
        .pcs_txseq       (pcs_txseq       ),
        //
        .pcs_rxdata      (pcs_rxdata      ),
        .pcs_rxcharisk   (pcs_rxcharisk   ),
        .pcs_rxdisperr   (pcs_rxdisperr   ),
        .pcs_rxnotintable(pcs_rxnotintable),
        .pcs_rxvalid     (pcs_rxvalid     )
    );

endmodule
