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
    output wire       EN_PCH_B
);


    coreboard1588_bd_wrapper i_coreboard1588_bd_wrapper (
        // QSPI
        //======
        .A7_CONFIG_QSPI_io0_io  (A7_CONFIG_DQ[0]  ),
        .A7_CONFIG_QSPI_io1_io  (A7_CONFIG_DQ[1]  ),
        .A7_CONFIG_QSPI_io2_io  (A7_CONFIG_DQ[2]  ),
        .A7_CONFIG_QSPI_io3_io  (A7_CONFIG_DQ[3]  ),
        .A7_CONFIG_QSPI_ss_io   (A7_CONFIG_FCS_B  ),
        // FPGA Global Clock
        //===================
        .A7_GCLK                (A7_GCLK          ),
        // LED
        //====
        .FPGA_LED               (FPGA_LED         ),
        // MCU
        //=====
        // SPI
        //------
        .FPGA_MCU_SPI_io0_io    (FPGA_MCU_SPI_MOSI),
        .FPGA_MCU_SPI_io1_io    (FPGA_MCU_SPI_MISO),
        .FPGA_MCU_SPI_sck_io    (FPGA_MCU_SPI_CLK ),
        .FPGA_MCU_SPI_ss_io     (FPGA_MCU_SPI_CS  ),
        // GPIO
        //-----
        .FPGA_RST               (FPGA_RST         ),
        .FPGA_MCU_INTR_interrupt(/* Open */       ),
        .FPGA_MCU_RST           (FPGA_MCU_RST     ),
        .FPGA_RUN               (FPGA_RUN         ),
        .FPGA_DAT_FIN           (FPGA_DAT_FIN     ),
        // FMC
        //----
        .FMC_addr               (FMC_A            ),
        .FMC_adv_ldn            (FMC_NL           ),
        .FMC_ben                (FMC_NBL          ),
        .FMC_cre                (FMC_NE           ),
        .FMC_dq_io              (FMC_D            ),
        .FMC_oen                (FMC_NOE          ),
        .FMC_rd_clk             (FMC_CLK          ),
        .FMC_wait               (FMC_NWAIT        ),
        .FMC_wen                (FMC_NWE          ),
        // TEST
            //=====
        .FPGA_TEST              (FPGA_TEST        ),
        // PTP
        //====
        .PTP_CLK_OUT            (PTP_CLK_OUT      ),
        // AdS868x
        //========
        .FPGA_SPI1_ss_io        (FPGA_SPI1_CS    ),
        .FPGA_SPI1_sck_io       (FPGA_SPI1_CLK   ),
        .FPGA_SPI1_io0_io       (FPGA_SPI1_MOSI  ),
        .FPGA_SPI1_io1_io       (FPGA_SPI1_MISO  ),
        //
        .AD1_RST                (AD1_RST         ),
        //
        .CH_SEL_A0              (CH_SEL_A[0]     ),
        .CH_SEL_A1              (CH_SEL_A[1]     ),
        .CH_SEL_A2              (CH_SEL_A[2]     ),
        //
        .EN_TCH_A               (EN_TCH_A        ),
        .EN_PCH_A               (EN_PCH_A        ),
        .EN_TCH_B               (EN_TCH_B        ),
        .EN_PCH_B               (EN_PCH_B        )
    );

endmodule

`default_nettype wire
