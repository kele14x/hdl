/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

//==============================================================================
//
// SPI Interface timing:
//
//                ____                                             __________
//  SS                \___________________________________________/
//                         ___     ___     ___     ___     ___
//  SCK   CPOL=0  ________/   \___/   \___/   \___/   \___/   \______________
//
//  MOSI                   _______ _______ _______ _______ _______
//  MISO  CPHA=1  zzzzxxxxX___0___X___1___X__...__X___6___X___7___Xzzzzzzzzzz
//
// This core is fixed CPOL = 0 and CPHA = 1. That is FPGA will drive SO at
// rising edge of SCK, and will sample SI at failing edge of SCK.
//==============================================================================

module spi_slave #(parameter WIDTH = 8 // 8, 16, 24, 32
) (
    // SPI
    //=====
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_I" *)
    input  wire                       SS_I     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_O" *)
    output wire                       SS_O     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_T" *)
    output wire                       SS_T     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_I" *)
    input  wire                       SCK_I    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_O" *)
    output wire                       SCK_O    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_T" *)
    output wire                       SCK_T    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_I" *)
    input  wire                       IO0_I    , // SI
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_O" *)
    output wire                       IO0_O    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_T" *)
    output wire                       IO0_T    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_I" *)
    input  wire                       IO1_I    , // SO
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_O" *)
    output wire                       IO1_O    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_T" *)
    output wire                       IO1_T    ,
    //=====
    input  wire                       clk      ,
    input  wire                       rst      ,
    // Rx i/f, beat at each bit
    output wire                       rx_ss    ,
    output wire [          WIDTH-1:0] rx_data  ,
    output wire [$clog2(WIDTH-1)-1:0] rx_bitcnt,
    output wire                       rx_valid ,
    // Tx i/f, beat at each word
    input  wire [          WIDTH-1:0] tx_data  ,
    output wire                       tx_load
);

    spi_slave_top #(.WIDTH(WIDTH)) inst (
        .SS_I     (SS_I     ),
        .SS_O     (SS_O     ),
        .SS_T     (SS_T     ),
        .SCK_I    (SCK_I    ),
        .SCK_O    (SCK_O    ),
        .SCK_T    (SCK_T    ),
        .IO0_I    (IO0_I    ),
        .IO0_O    (IO0_O    ),
        .IO0_T    (IO0_T    ),
        .IO1_I    (IO1_I    ),
        .IO1_O    (IO1_O    ),
        .IO1_T    (IO1_T    ),
        //
        .clk      (clk      ),
        .rst      (rst      ),
        //
        .rx_ss    (rx_ss    ),
        .rx_data  (rx_data  ),
        .rx_bitcnt(rx_bitcnt),
        .rx_valid (rx_valid ),
        //
        .tx_data  (tx_data  ),
        .tx_load  (tx_load  )
    );

endmodule

`default_nettype wire
