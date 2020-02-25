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
//                     _______ _______ _______ _______ _______
//  MOSI/ CPHA=0  zzzzX___0___X___1___X__...__X___6___X___7___Xxxxxzzzzzzzzzz
//  MISO                  _______ _______ _______ _______ _______
//        CPHA=1  zzzzxxxxX___0___X___1___X__...__X___6___X___7___Xzzzzzzzzzz
//
// This core is fixed CPOL = 0 and CPHA = 1. That is FPGA will drive SO at
// rising edge of SCK, and will sample SI at failing edge of SCK.
//==============================================================================

module axis_spi_slave2 #(
    parameter C_DATA_WIDTH = 8 // 8, 16, 24, 32
) (
    // SPI
    //=====
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_I" *)
    input  wire                    SS_I          ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_O" *)
    output wire                    SS_O          ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_T" *)
    output wire                    SS_T          ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_I" *)
    input  wire                    SCK_I         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_O" *)
    output wire                    SCK_O         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_T" *)
    output wire                    SCK_T         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_I" *)
    input  wire                    IO0_I         , // SI
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_O" *)
    output wire                    IO0_O         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_T" *)
    output wire                    IO0_T         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_I" *)
    input  wire                    IO1_I         , // SO
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_O" *)
    output wire                    IO1_O         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_T" *)
    output wire                    IO1_T         ,
    //=====
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF axis_rx:axis_tx, ASSOCIATED_RESET aresetn, FREQ_HZ 100000000" *)
    input  wire                    aclk          ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire                    aresetn       ,
    // Rx i/f, beat at each bit
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 axis_rx TDATA" *)
    output wire [C_DATA_WIDTH-1:0] axis_rx_tdata ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 axis_rx TVALID" *)
    output wire                    axis_rx_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 axis_rx TREADY" *)
    input  wire                    axis_rx_tready,
    // Tx i/f, beat at each word
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 axis_tx TDATA" *)
    input  wire [C_DATA_WIDTH-1:0] axis_tx_tdata ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 axis_tx TVALID" *)
    input  wire                    axis_tx_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 axis_tx TREADY" *)
    output wire                    axis_tx_tready
);

    axis_spi_slave2_top #(
        .C_DATA_WIDTH(C_DATA_WIDTH)
    ) inst (
        .SS_I          (SS_I          ),
        .SS_O          (SS_O          ),
        .SS_T          (SS_T          ),
        .SCK_I         (SCK_I         ),
        .SCK_O         (SCK_O         ),
        .SCK_T         (SCK_T         ),
        .IO0_I         (IO0_I         ),
        .IO0_O         (IO0_O         ),
        .IO0_T         (IO0_T         ),
        .IO1_I         (IO1_I         ),
        .IO1_O         (IO1_O         ),
        .IO1_T         (IO1_T         ),
        //
        .aclk          (aclk          ),
        .aresetn       (aresetn       ),
        //
        .axis_rx_tdata (axis_rx_tdata ),
        .axis_rx_tvalid(axis_rx_tvalid),
        .axis_rx_tready(axis_rx_tready),
        //
        .axis_tx_tdata (axis_tx_tdata ),
        .axis_tx_tvalid(axis_tx_tvalid),
        .axis_tx_tready(axis_tx_tready)
    );

endmodule

`default_nettype wire
