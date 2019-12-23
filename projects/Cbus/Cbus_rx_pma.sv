/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_rx_pma (
    // RX PINS
    input  wire        RX_CLK_P           ,
    input  wire        RX_CLK_N           ,
    input  wire        RX_DIN_P           ,
    input  wire        RX_DIN_N           ,
    //
    input  wire        pma_arst           , // Async reset
    output wire        pma_rxclk          ,
    output wire        pma_rxrst          ,
    output wire [ 9:0] pma_rxdata         , // Rx Data
    output wire        pma_rxvalid        , // Rx Valid
    //
    input  wire        ctrl_rxprbscntreset,
    input  wire [ 2:0] ctrl_rxprbssel     ,
    //
    output wire        stat_rxprbserr     ,
    output wire [15:0] stat_rxprbserrcnt
);

    wire rx_clk_ibufds, rx_clk;
    wire rx_din_ibufds, rx_din;

    wire stat_rxisalign ;
    wire stat_rxrealign ;
    wire stat_rxcommadet;

    wire prbs7 ;
    wire prbs15;
    wire prbs23;
    wire prbs31;

    // Rx clock path

    IBUFDS #(
        .DIFF_TERM   ("TRUE"   ),
        .IBUF_LOW_PWR("FALSE"  ),
        .IOSTANDARD  ("LVDS_25")
    ) i_rx_clk_ibufds (
        .I (RX_CLK_P     ),
        .IB(RX_CLK_N     ),
        .O (rx_clk_ibufds)
    );

    BUFMR i_bufmr (
        .I(rx_clk_ibufds),
        .O(rx_clk       )
    );

    assign pma_rxclk = rx_clk;

    // Reset path

    xpm_cdc_sync_rst #(
        .DEST_SYNC_FF  (4),
        .INIT          (1),
        .INIT_SYNC_FF  (0),
        .SIM_ASSERT_CHK(0)
    ) xpm_cdc_sync_rst_inst (
        .src_rst (pma_arst ),
        .dest_clk(rx_clk   ),
        .dest_rst(pma_rxrst)
    );

    // Rx data path

    IBUFDS #(
        .DIFF_TERM   ("TRUE"   ),
        .IBUF_LOW_PWR("FALSE"  ),
        .IOSTANDARD  ("LVDS_25")
    ) i_rx_din_ibufds (
        .I (RX_DIN_P     ),
        .IB(RX_DIN_N     ),
        .O (rx_din_ibufds)
    );

    (* IOB="true" *)
    FDRE #(.INIT(1'b0)) i_fdre (
        .C (rx_clk          ),
        .CE(1'b1            ),
        .R (pma_rxrst       ),
        .D (rx_din_ibufds),
        .Q (rx_din       )
    );

    Cbus_rx_pma_bist i_bist (
        .clk                (rx_clk             ),
        .rst                (pma_rxrst          ),
        //
        .din                (rx_din             ),
        //
        .ctrl_rxprbscntreset(ctrl_rxprbscntreset),
        .ctrl_rxprbssel     (ctrl_rxprbssel     ),
        //
        .stat_rxprbserr     (stat_rxprbserr     ),
        .stat_rxprbserrcnt  (stat_rxprbserrcnt  )
    );

    Cbus_rx_pma_commaalign i_commaalign (
        .clk            (rx_clk         ),
        .rst            (pma_rxrst      ),
        //
        .rx_din         (rx_din         ),
        //
        .pma_rxdata     (pma_rxdata     ),
        .pma_rxvalid    (pma_rxvalid    ),
        //
        .stat_rxcommadet(stat_rxcommadet),
        .stat_rxisalign (stat_rxisalign ),
        .stat_rxrealign (stat_rxrealign )
    );

endmodule
