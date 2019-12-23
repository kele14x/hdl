/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_tx_pma (
    // TX PINS
    output wire       TX_CLK_P           ,
    output wire       TX_CLK_N           ,
    output wire       TX_DOUT_P          ,
    output wire       TX_DOUT_N          ,
    // PCS -> PMA
    input  wire       pma_txclk          ,
    input  wire       pma_txrst          ,
    input  wire [9:0] pma_txdata         ,
    input  wire [3:0] pma_txseq          ,
    //
    input  wire       ctrl_txpolarity    ,
    input  wire [2:0] ctrl_txprbssel     ,
    input  wire [3:0] ctrl_txprbsforceerr
);

    wire din, tx_clk_oddr;
    wire tx_dout, tx_dout_fdre;

    // pma_txclk forward path

    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT        (1'b0       ),
        .SRTYPE      ("SYNC"     )
    ) i_tx_clk_oddr (
        .C (pma_txclk  ),
        .R (pma_txrst  ),
        .S (1'b0       ),
        .CE(1'b1       ),
        .D1(1'b1       ),
        .D2(1'b0       ),
        .Q (tx_clk_oddr)
    );

    OBUFDS #(
        .IOSTANDARD("LVDS_25"),
        .SLEW      ("FAST"   )
    ) i_tx_clk_obufds (
        .I (tx_clk_oddr),
        .O (TX_CLK_P   ),
        .OB(TX_CLK_N   )
    );

    // TX_DOUT path

    assign din = pma_txdata[pma_txseq];

    Cbus_tx_pma_bist i_bist (
        .clk                (pma_txclk          ),
        .rst                (pma_txrst          ),
        .din                (din                ),
        .dout               (tx_dout            ),
        .ctrl_txpolarity    (ctrl_txpolarity    ),
        .ctrl_txprbssel     (ctrl_txprbssel     ),
        .ctrl_txprbsforceerr(ctrl_txprbsforceerr)
    );

    (* IOB="true" *)
    FDRE #(.INIT(1'b0)) i_tx_dout_fdre (
        .C (pma_txclk   ),
        .R (pma_txrst   ),
        .CE(1'b1        ),
        .D (tx_dout     ),
        .Q (tx_dout_fdre)
    );

    OBUFDS #(
        .IOSTANDARD("LVDS_25"),
        .SLEW      ("FAST"   )
    ) i_tx_dout_obufds (
        .I (tx_dout_fdre),
        .O (TX_DOUT_P   ),
        .OB(TX_DOUT_N   )
    );

endmodule
