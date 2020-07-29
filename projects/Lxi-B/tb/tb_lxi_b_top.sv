/*
Copyright (c) 2020 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_lxi_b_top ();

    wire [14:0] DDR_addr;
    wire [2:0] DDR_ba;
    wire DDR_cas_n;
    wire DDR_ck_n;
    wire DDR_ck_p;
    wire DDR_cke;
    wire DDR_cs_n;
    wire [3:0] DDR_dm;
    wire [31:0] DDR_dq;
    wire [3:0] DDR_dqs_n;
    wire [3:0] DDR_dqs_p;
    wire DDR_odt;
    wire DDR_ras_n;
    wire DDR_reset_n;
    wire DDR_we_n;
    wire FIXED_IO_ddr_vrn;
    wire FIXED_IO_ddr_vrp;
    wire [53:0] FIXED_IO_mio;

    wire FIXED_IO_ps_clk;
    wire FIXED_IO_ps_porb;
    wire FIXED_IO_ps_srstb;

    wire [5:0] GX_ADC_SYNC;
    wire [5:0] GX_ANA_POW_EN;
    wire [5:0] GX_RELAY_CTRL;
    wire [5:0] GX_RTD_SPI_CSN;
    wire [5:0] GX_RTD_SPI_SCLK;
    wire [5:0] GX_RTD_SPI_SDI;
    wire [5:0] GX_RTD_SPI_SDO;
    wire [47:0] GX_TC_SPI_CSN;
    wire [5:0] GX_TC_SPI_SCLK;
    wire [5:0] GX_TC_SPI_SDI;
    wire [5:0] GX_TC_SPI_SDO;

    lxi_b_top i_lxi_b_top (
        .DDR_addr         (DDR_addr         ),
        .DDR_ba           (DDR_ba           ),
        .DDR_cas_n        (DDR_cas_n        ),
        .DDR_ck_n         (DDR_ck_n         ),
        .DDR_ck_p         (DDR_ck_p         ),
        .DDR_cke          (DDR_cke          ),
        .DDR_cs_n         (DDR_cs_n         ),
        .DDR_dm           (DDR_dm           ),
        .DDR_dq           (DDR_dq           ),
        .DDR_dqs_n        (DDR_dqs_n        ),
        .DDR_dqs_p        (DDR_dqs_p        ),
        .DDR_odt          (DDR_odt          ),
        .DDR_ras_n        (DDR_ras_n        ),
        .DDR_reset_n      (DDR_reset_n      ),
        .DDR_we_n         (DDR_we_n         ),
        .FIXED_IO_ddr_vrn (FIXED_IO_ddr_vrn ),
        .FIXED_IO_ddr_vrp (FIXED_IO_ddr_vrp ),
        .FIXED_IO_mio     (FIXED_IO_mio     ),
        .FIXED_IO_ps_clk  (FIXED_IO_ps_clk  ),
        .FIXED_IO_ps_porb (FIXED_IO_ps_porb ),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .GX_ADC_SYNC      (GX_ADC_SYNC      ),
        .GX_ANA_POW_EN    (GX_ANA_POW_EN    ),
        .GX_RELAY_CTRL    (GX_RELAY_CTRL    ),
        .GX_RTD_SPI_CSN   (GX_RTD_SPI_CSN   ),
        .GX_RTD_SPI_SCLK  (GX_RTD_SPI_SCLK  ),
        .GX_RTD_SPI_SDI   (GX_RTD_SPI_SDI   ),
        .GX_RTD_SPI_SDO   (GX_RTD_SPI_SDO   ),
        .GX_TC_SPI_CSN    (GX_TC_SPI_CSN    ),
        .GX_TC_SPI_SCLK   (GX_TC_SPI_SCLK   ),
        .GX_TC_SPI_SDI    (GX_TC_SPI_SDI    ),
        .GX_TC_SPI_SDO    (GX_TC_SPI_SDO    )
    );

endmodule

`default_nettype wire
