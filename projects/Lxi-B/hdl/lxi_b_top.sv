/*
Copyright (c) 2020 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module lxi_b_top (
    // DDR
    inout  wire [14:0] DDR_addr         ,
    inout  wire [ 2:0] DDR_ba           ,
    inout  wire        DDR_cas_n        ,
    inout  wire        DDR_ck_n         ,
    inout  wire        DDR_ck_p         ,
    inout  wire        DDR_cke          ,
    inout  wire        DDR_cs_n         ,
    inout  wire [ 3:0] DDR_dm           ,
    inout  wire [31:0] DDR_dq           ,
    inout  wire [ 3:0] DDR_dqs_n        ,
    inout  wire [ 3:0] DDR_dqs_p        ,
    inout  wire        DDR_odt          ,
    inout  wire        DDR_ras_n        ,
    inout  wire        DDR_reset_n      ,
    inout  wire        DDR_we_n         ,
    // MIO
    inout  wire        FIXED_IO_ddr_vrn ,
    inout  wire        FIXED_IO_ddr_vrp ,
    inout  wire [53:0] FIXED_IO_mio     ,
    inout  wire        FIXED_IO_ps_clk  ,
    inout  wire        FIXED_IO_ps_porb ,
    inout  wire        FIXED_IO_ps_srstb,
    // BNC
    input  wire        PL_RX_BNC        ,
    output wire        PL_TX_BNC        ,
    // ADC
    output wire [ 5:0] GX_ADC_SYNC      ,
    output wire [ 5:0] GX_ANA_POW_EN    ,
    output wire [ 5:0] GX_RELAY_CTRL    ,
    //
    inout  wire [ 5:0] GX_RTD_SPI_CSN   ,
    inout  wire [ 5:0] GX_RTD_SPI_SCLK  ,
    inout  wire [ 5:0] GX_RTD_SPI_SDI   ,
    inout  wire [ 5:0] GX_RTD_SPI_SDO   ,
    //
    inout  wire [47:0] GX_TC_SPI_CSN    ,
    inout  wire [ 5:0] GX_TC_SPI_SCLK   ,
    inout  wire [ 5:0] GX_TC_SPI_SDI    ,
    inout  wire [ 5:0] GX_TC_SPI_SDO    ,
    // LCD
    inout  wire        LCD_LED_EN       ,
    inout  wire        LCD_V0           ,
    inout  wire        LCD_RS           ,
    inout  wire        LCD_RW           ,
    inout  wire        LCD_E            ,
    inout  wire [ 7:0] LCD_DB
);


    ps7_bd_wrapper i_ps7_bd_wrapper (
        .DDR_addr              (DDR_addr         ),
        .DDR_ba                (DDR_ba           ),
        .DDR_cas_n             (DDR_cas_n        ),
        .DDR_ck_n              (DDR_ck_n         ),
        .DDR_ck_p              (DDR_ck_p         ),
        .DDR_cke               (DDR_cke          ),
        .DDR_cs_n              (DDR_cs_n         ),
        .DDR_dm                (DDR_dm           ),
        .DDR_dq                (DDR_dq           ),
        .DDR_dqs_n             (DDR_dqs_n        ),
        .DDR_dqs_p             (DDR_dqs_p        ),
        .DDR_odt               (DDR_odt          ),
        .DDR_ras_n             (DDR_ras_n        ),
        .DDR_reset_n           (DDR_reset_n      ),
        .DDR_we_n              (DDR_we_n         ),
        //
        .FIXED_IO_ddr_vrn      (FIXED_IO_ddr_vrn ),
        .FIXED_IO_ddr_vrp      (FIXED_IO_ddr_vrp ),
        .FIXED_IO_mio          (FIXED_IO_mio     ),
        .FIXED_IO_ps_clk       (FIXED_IO_ps_clk  ),
        .FIXED_IO_ps_porb      (FIXED_IO_ps_porb ),
        .FIXED_IO_ps_srstb     (FIXED_IO_ps_srstb),
        //
        .GX_ADC_SYNC           (GX_ADC_SYNC      ),
        .GX_ANA_POW_EN         (GX_ANA_POW_EN    ),
        .GX_RELAY_CTRL         (GX_RELAY_CTRL    ),
        //
        .GX_RTD_SPI_CSN_tri_io (GX_RTD_SPI_CSN   ),
        .GX_RTD_SPI_SCLK_tri_io(GX_RTD_SPI_SCLK  ),
        .GX_RTD_SPI_SDI_tri_io (GX_RTD_SPI_SDI   ),
        .GX_RTD_SPI_SDO_tri_io (GX_RTD_SPI_SDO   ),
        .GX_TC_SPI_CSN_tri_io  (GX_TC_SPI_CSN    ),
        .GX_TC_SPI_SCLK_tri_io (GX_TC_SPI_SCLK   ),
        .GX_TC_SPI_SDI_tri_io  (GX_TC_SPI_SDI    ),
        .GX_TC_SPI_SDO_tri_io  (GX_TC_SPI_SDO    ),
        //
        .PL_RX_BNC             (PL_RX_BNC        ),
        //
        .lcd_gpio_tri_io       ({LCD_LED_EN,
                                 LCD_V0,
                                 LCD_RS,
                                 LCD_RW,
                                 LCD_E,
                                 LCD_DB}         )
    );

    assign PL_TX_BNC = 1'bz;

endmodule

`default_nettype wire
