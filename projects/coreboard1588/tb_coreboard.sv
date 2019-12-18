/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_coreboard1588;

    // MCU <-> FPGA
    logic FPGA_RST = 0; // !Active low
    //
    logic FPGA_MCU_SPI_CLK ;
    logic FPGA_MCU_SPI_CS  ;
    logic FPGA_MCU_SPI_MOSI;
    wire  FPGA_MCU_SPI_MISO;
    
    // FPGA GCLK
    logic A7_GCLK = 0;
    
    // PHY
    logic PTP_CLK_OUT;
    logic PTP_TRG_FPGA;
    
    // FPGA <-> QSPI
    wire  A7_CONFIG_FCS_B;
    wire  A7_CONFIG_DQ0;
    wire  A7_CONFIG_DQ1;
    wire  A7_CONFIG_DQ2;
    wire  A7_CONFIG_DQ3;
    
    // ADS868x
    logic FPGA_SPI1_CLK;
    logic FPGA_SPI1_CS;
    wire  FPGA_SPI1_MOSI;
    logic FPGA_SPI1_MISO;
    //
    logic AD1_RST;
    //
    logic CH_SEL_A0;
    logic CH_SEL_A1;
    logic CH_SEL_A2;
    //
    logic EN_TCH_A;
    logic EN_PCH_A;
    logic EN_TCH_B;
    logic EN_PCH_B;

    // UUT
    //===========

    coreboard1588 DUT ( .* );

    // tb_coreboard1588.DUT.i_coreboard1588_bd_wrapper.coreboard1588_bd_i.axi_vip.inst

    // Simulation cases
    //==================

    always begin
        #10 A7_GCLK = ~A7_GCLK;
    end

    initial begin
        #5000 FPGA_RST = 1;
    end

    initial begin
        $display("%t: Simulation starts.", $time);
        #100000;
        $finish;
    end

    final begin
        $display("%t: Simulation ends.", $time);
    end

endmodule

`default_nettype wire
