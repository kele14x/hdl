/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_phy (
    // TX PINS
    output wire        TX_CLK_P           ,
    output wire        TX_CLK_N           ,
    output wire        TX_DOUT_P          ,
    output wire        TX_DOUT_N          ,
    // RX PINS
    input  wire        RX_CLK_P           ,
    input  wire        RX_CLK_N           ,
    input  wire        RX_DIN_P           ,
    input  wire        RX_DIN_N           ,
    //
    input  wire        tx_core_clk        ,
    input  wire        rx_core_clk        ,
    //
    input  wire        tx_reset           ,
    input  wire        rx_reset           ,
    //
    input  wire [ 7:0] pcs_txdata         , // Tx Data
    input  wire        pcs_txcharisk      , // Tx Char is Key
    input  wire [ 3:0] pcs_txseq          , // Tx Sequence
    //
    output wire [ 7:0] pcs_rxdata         , // Rx Data
    output wire        pcs_rxcharisk      , // Rx Char is Key
    output wire        pcs_rxdisperr      , // Rx Disp Error
    output wire        pcs_rxnotintable   , // Rx Not in Table
    output wire        pcs_rxvalid        , // Rx Valid
    //
    input  wire        ctrl_txpolarity    ,
    input  wire [ 2:0] ctrl_txprbssel     ,
    input  wire [ 3:0] ctrl_txprbsforceerr,
    //
    input  wire        ctrl_rxprbscntreset,
    input  wire [ 2:0] ctrl_rxprbssel     ,
    //
    output wire        stat_rxprbserr     ,
    output wire [15:0] stat_rxprbserrcnt
);

    wire       pma_txclk ;
    wire       pma_txrst ;
    wire [9:0] pma_txdata;
    wire [3:0] pma_txseq ;

    wire       pma_arst   ;
    wire       pma_rxclk  ;
    wire       pma_rxrst  ;
    wire [9:0] pma_rxdata ;
    wire       pma_rxvalid;

    // TX PMA & PCS

    Cbus_tx_pma i_tx_pma (
        .TX_CLK_P           (TX_CLK_P           ),
        .TX_CLK_N           (TX_CLK_N           ),
        .TX_DOUT_P          (TX_DOUT_P          ),
        .TX_DOUT_N          (TX_DOUT_N          ),
        //
        .pma_txclk          (pma_txclk          ),
        .pma_txrst          (pma_txrst          ),
        .pma_txdata         (pma_txdata         ),
        .pma_txseq          (pma_txseq          ),
        //
        .ctrl_txpolarity    (ctrl_txpolarity    ),
        .ctrl_txprbssel     (ctrl_txprbssel     ),
        .ctrl_txprbsforceerr(ctrl_txprbsforceerr)
    );

    Cbus_tx_pcs i_tx_pcs (
        .pma_txclk    (pma_txclk    ),
        .pma_txrst    (pma_txrst    ),
        .pma_txdata   (pma_txdata   ),
        .pma_txseq    (pma_txseq    ),
        //
        .pcs_txclk    (tx_core_clk  ),
        .pcs_txrst    (tx_reset     ),
        .pcs_txdata   (pcs_txdata   ),
        .pcs_txcharisk(pcs_txcharisk),
        .pcs_txseq    (pcs_txseq    )

    );

    // RX PMA & PCS

    Cbus_rx_pma i_rx_pma (
        .RX_CLK_P           (RX_CLK_P           ),
        .RX_CLK_N           (RX_CLK_N           ),
        .RX_DIN_P           (RX_DIN_P           ),
        .RX_DIN_N           (RX_DIN_N           ),
        //
        .pma_arst           (pma_arst           ),
        .pma_rxclk          (pma_rxclk          ),
        .pma_rxrst          (pma_rxrst          ),
        .pma_rxdata         (pma_rxdata         ),
        .pma_rxvalid        (pma_rxvalid        ),
        //
        .ctrl_rxprbscntreset(ctrl_rxprbscntreset),
        .ctrl_rxprbssel     (ctrl_rxprbssel     ),
        //
        .stat_rxprbserr     (stat_rxprbserr     ),
        .stat_rxprbserrcnt  (stat_rxprbserrcnt  )
    );

    Cbus_rx_pcs i_rx_pcs (
        .pma_arst        (pma_arst        ),
        .pma_rxclk       (pma_rxclk       ),
        .pma_rxrst       (pma_rxrst       ),
        .pma_rxdata      (pma_rxdata      ),
        .pma_rxvalid     (pma_rxvalid     ),
        //
        .pcs_rxclk       (rx_core_clk     ),
        .pcs_rxrst       (rx_reset        ),
        .pcs_rxdata      (pcs_rxdata      ),
        .pcs_rxcharisk   (pcs_rxcharisk   ),
        .pcs_rxdisperr   (pcs_rxdisperr   ),
        .pcs_rxnotintable(pcs_rxnotintable),
        .pcs_rxvalid     (pcs_rxvalid     )
    );

endmodule // Cbus_pcs_pma
