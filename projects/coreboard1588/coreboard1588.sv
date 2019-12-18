/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module coreboard1588 (
    // MCU FPGA Interface
    //===================
    //   GPIO
    input  wire FPGA_RST         ,
    //   SPI
    input  wire FPGA_MCU_SPI_CLK ,
    input  wire FPGA_MCU_SPI_CS  ,
    input  wire FPGA_MCU_SPI_MOSI,
    inout  wire FPGA_MCU_SPI_MISO,
    // FPGA Global Clock
    //==================
    input  wire A7_GCLK          ,
    // PHY
    //=====
    input  wire PTP_CLK_OUT      ,
    input  wire PTP_TRG_FPGA     ,
    // QSPI
    //=====
    inout  wire A7_CONFIG_FCS_B  ,
    inout  wire A7_CONFIG_DQ0    ,
    inout  wire A7_CONFIG_DQ1    ,
    inout  wire A7_CONFIG_DQ2    ,
    inout  wire A7_CONFIG_DQ3    ,
    // ADS868x
    //========
    output wire FPGA_SPI1_CLK    ,
    output wire FPGA_SPI1_CS     ,
    inout  wire FPGA_SPI1_MOSI   ,
    input  wire FPGA_SPI1_MISO   ,
    //
    output wire AD1_RST          ,
    //
    output wire CH_SEL_A0        ,
    output wire CH_SEL_A1        ,
    output wire CH_SEL_A2        ,
    //
    output wire EN_TCH_A         ,
    output wire EN_PCH_A         ,
    output wire EN_TCH_B         ,
    output wire EN_PCH_B
);


    coreboard1588_bd_wrapper i_coreboard1588_bd_wrapper (
        // QSPI
        //======
        .A7_CONFIG_QSPI_io0_io  (A7_CONFIG_DQ0  ),
        .A7_CONFIG_QSPI_io1_io  (A7_CONFIG_DQ1  ),
        .A7_CONFIG_QSPI_io2_io  (A7_CONFIG_DQ2  ),
        .A7_CONFIG_QSPI_io3_io  (A7_CONFIG_DQ3  ),
        .A7_CONFIG_QSPI_ss_io   (A7_CONFIG_FCS_B),
        // FPGA Global Clock
        //===================
        .A7_GCLK                (A7_GCLK        ),
        // MCU
        //=====
        .FPGA_RST               (FPGA_RST       ),
        .FPGA_MCU_INTR_interrupt(/* Open */     )
    );

endmodule

`default_nettype wire
