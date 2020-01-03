/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

//=============================================================================
//
// Filename: spi_master.v
//
// Purpose: SPI master core with simple interface, this core was designed
//   to interface other cores easily.
//
// Note:
//   SPI Interface timing:
//
//                             ___     ___     ___     ___     ___
//      SCK   CPOL=0  ________/   \___/   \___/   \___/   \___/   \____________
//                    ________     ___     ___     ___     ___     ____________
//            CPOL=1          \___/   \___/   \___/   \___/   \___/
//
//                    ____                                             ________
//      SS                \___________________________________________/
//
//                         _______ _______ _______ _______ _______
//      MOSI/ CPHA=0  zzzzX___0___X___1___X__...__X___6___X___7___X---Xzzzzzzzz
//      MISO                   _______ _______ _______ _______ _______
//            CPHA=1  zzzz----X___0___X___1___X__...__X___6___X___7___Xzzzzzzzz
//
// Limitation:
//   This core is fixed CPOL = 0 and CPHA = 1. That means both master and salve
//   (this core) will drive MOSI/MISO at rising edge of SCK, and should sample
//   MISO/MOSI at falling edge.
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module spi_master #(parameter CLK_RATIO   = 8) (
    // SPI
    //=====
    input  wire       SCK_I       ,
    output wire       SCK_O       ,
    output wire       SCK_T       ,
    input  wire       SS_I        ,
    output wire       SS_O        ,
    output wire       SS_T        ,
    input  wire       IO0_I       ,
    output wire       IO0_O       , // MO
    output wire       IO0_T       ,
    input  wire       IO1_I       , // MI
    output wire       IO1_O       ,
    output wire       IO1_T       ,
    // Fabric
    //=======
    input  wire       clk         ,
    input  wire       rst         ,
    // Tx interface
    //--------------
    input  wire [7:0] spi_tx_data ,
    input  wire       spi_tx_valid,
    output wire       spi_tx_ready,
    // Rx interface
    //--------------
    output wire [7:0] spi_rx_data ,
    output wire       spi_rx_valid
);

    spi_master_top #(.CLK_RATIO(CLK_RATIO)) inst (
        .SCK_I       (SCK_I       ),
        .SCK_O       (SCK_O       ),
        .SCK_T       (SCK_T       ),
        .SS_I        (SS_I        ),
        .SS_O        (SS_O        ),
        .SS_T        (SS_T        ),
        .IO0_I       (IO0_I       ),
        .IO0_O       (IO0_O       ),
        .IO0_T       (IO0_T       ),
        .IO1_I       (IO1_I       ),
        .IO1_O       (IO1_O       ),
        .IO1_T       (IO1_T       ),
        .clk         (clk         ),
        .rst         (rst         ),
        .spi_tx_data (spi_tx_data ),
        .spi_tx_valid(spi_tx_valid),
        .spi_tx_ready(spi_tx_ready),
        .spi_rx_data (spi_rx_data ),
        .spi_rx_valid(spi_rx_valid)
    );

endmodule

`default_nettype wire
