/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module coreboard1588 (
    // LEDs
    //=====
    output wire [1:0] FPGA_LED         ,
    // TEST
    //=====
    output wire [3:0] FPGA_TEST        ,
    // MCU FPGA Interface
    //===================
    //   GPIO
    input  wire       FPGA_RST         ,
    output wire       FPGA_RUN         ,
    output wire       FPGA_MCU_RST     ,
    output wire       FPGA_DAT_FIN     ,
    output wire       FPGA_MCU_INTR    ,
    // PPS Intr output
    output wire       FPGA_MCU_GPIO5   ,
    output wire       FPGA_RAM_ADDR0   ,
    //   SPI
    inout  wire       FPGA_MCU_SPI_CLK ,
    inout  wire       FPGA_MCU_SPI_CS  ,
    inout  wire       FPGA_MCU_SPI_MOSI,
    inout  wire       FPGA_MCU_SPI_MISO,
    //   FMC
    input  wire [11:0]FMC_A            ,
    input  wire       FMC_CLK          ,
    input  wire       FMC_NE           ,
    input  wire [ 1:0]FMC_NBL          ,
    output wire       FMC_NWAIT        ,
    input  wire       FMC_NL           ,
    input  wire       FMC_NOE          ,
    input  wire       FMC_NWE          ,
    inout  wire [15:0]FMC_D            ,
    // FPGA Global Clock
    //==================
    input  wire       A7_GCLK          ,
    // Trigger
    //========
    // External trigger from outside device
    input  wire       FPGA_EXT_TRIGGER ,
    // Trigger from MCU (ignore the name)
    input  wire       FPGA_TRIGGER_EN  ,
    // PHY
    //=====
    input  wire       PTP_CLK_OUT      ,
    input  wire       PTP_TRG_FPGA     ,
    // QSPI
    //=====
    inout  wire       A7_CONFIG_FCS_B  ,
    inout  wire [3:0] A7_CONFIG_DQ     ,
    // ADS868x
    //========
    inout  wire       FPGA_SPI1_CLK    ,
    inout  wire       FPGA_SPI1_CS     ,
    inout  wire       FPGA_SPI1_MOSI   ,
    inout  wire       FPGA_SPI1_MISO   ,
    //
    output wire       AD1_RST          ,
    //
    output wire [2:0] CH_SEL_A         ,
    //
    output wire       EN_TCH_A         ,
    output wire       EN_PCH_A         ,
    output wire       EN_TCH_B         ,
    output wire       EN_PCH_B         ,
    // ADS1247
    //========
    inout  wire       FPGA_SPI2_CLK    ,
    inout  wire       FPGA_SPI2_CS     ,
    inout  wire       FPGA_SPI2_MOSI   ,
    inout  wire       FPGA_SPI2_MISO   ,
    //
    input  wire       AD2_DRDY         ,
    output wire       AD2_RST          ,
    output wire       AD2_START
);


    coreboard1588_bd_wrapper i_coreboard1588_bd_wrapper (
        // QSPI
        //======
        .A7_CONFIG_QSPI_io0_io(A7_CONFIG_DQ[0]  ),
        .A7_CONFIG_QSPI_io1_io(A7_CONFIG_DQ[1]  ),
        .A7_CONFIG_QSPI_io2_io(A7_CONFIG_DQ[2]  ),
        .A7_CONFIG_QSPI_io3_io(A7_CONFIG_DQ[3]  ),
        .A7_CONFIG_QSPI_ss_io (A7_CONFIG_FCS_B  ),
        // FPGA Global Clock
        //===================
        .A7_GCLK              (A7_GCLK          ),
        // LED
        //====
        .FPGA_LED             (FPGA_LED         ),
        // MCU
        //=====
        // SPI
        //------
        .FPGA_MCU_SPI_io0_io  (FPGA_MCU_SPI_MOSI),
        .FPGA_MCU_SPI_io1_io  (FPGA_MCU_SPI_MISO),
        .FPGA_MCU_SPI_sck_io  (FPGA_MCU_SPI_CLK ),
        .FPGA_MCU_SPI_ss_io   (FPGA_MCU_SPI_CS  ),
        // GPIO
        //-----
        .FPGA_RST             (FPGA_RST         ),
        .FPGA_MCU_INTR        (FPGA_MCU_INTR    ),
        .FPGA_DAT_FIN         (FPGA_DAT_FIN     ),
        .FPGA_MCU_GPIO5       (FPGA_MCU_GPIO5   ),
        .FPGA_RAM_ADDR0       (FPGA_RAM_ADDR0   ),
        // FMC
        //----
        .FMC_addr             (FMC_A            ),
        .FMC_adv_ldn          (FMC_NL           ),
        .FMC_ben              (FMC_NBL          ),
        .FMC_ce_n             (FMC_NE           ),
        .FMC_dq_io            (FMC_D            ),
        .FMC_oen              (FMC_NOE          ),
        .FMC_rd_clk           (FMC_CLK          ),
        .FMC_wait             (FMC_NWAIT        ),
        .FMC_wen              (FMC_NWE          ),
        // Trigger input
        //=============
        .FPGA_EXT_TRIGGER     (FPGA_EXT_TRIGGER ),
        .FPGA_TRIGGER_EN      (FPGA_TRIGGER_EN  ),
        // PTP
        //====
        .PTP_CLK_OUT          (PTP_CLK_OUT      ),
        .PTP_TRG_FPGA         (PTP_TRG_FPGA     ),
        // ADS868x
        //========
        .FPGA_SPI1_ss_io      (FPGA_SPI1_CS     ),
        .FPGA_SPI1_sck_io     (FPGA_SPI1_CLK    ),
        .FPGA_SPI1_io0_io     (FPGA_SPI1_MOSI   ),
        .FPGA_SPI1_io1_io     (FPGA_SPI1_MISO   ),
        //
        .AD1_RST              (AD1_RST          ),
        //
        .CH_SEL_A0            (CH_SEL_A[0]      ),
        .CH_SEL_A1            (CH_SEL_A[1]      ),
        .CH_SEL_A2            (CH_SEL_A[2]      ),
        //
        .EN_TCH_A             (EN_TCH_A         ),
        .EN_PCH_A             (EN_PCH_A         ),
        .EN_TCH_B             (EN_TCH_B         ),
        .EN_PCH_B             (EN_PCH_B         ),
        // ADS1247
        //========
        .FPGA_SPI2_ss_io      (FPGA_SPI2_CS     ),
        .FPGA_SPI2_sck_io     (FPGA_SPI2_CLK    ),
        .FPGA_SPI2_io0_io     (FPGA_SPI2_MOSI   ),
        .FPGA_SPI2_io1_io     (FPGA_SPI2_MISO   ),
        //
        .AD2_DRDY             (AD2_DRDY         ),
        .AD2_START            (AD2_START        ),
        .AD2_RST              (AD2_RST          )
    );

    assign FPGA_RUN = 1'b1;

    assign FPGA_MCU_RST = 1'bZ;

    assign FPGA_TEST = 4'bZZZZ;

endmodule

`default_nettype wire
