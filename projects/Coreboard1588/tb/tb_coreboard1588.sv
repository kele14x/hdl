/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_coreboard1588;

    // FPGA Misc

    logic [1:0] FPGA_LED;
    logic [3:0] FPGA_TEST;

    // MCU <-> FPGA

    logic FPGA_RST = 0; // !Active low
    logic FPGA_RUN;
    logic FPGA_MCU_RST;
    logic FPGA_DAT_FIN;

    wire FPGA_MCU_SPI_CLK ;
    wire FPGA_MCU_SPI_CS  ;
    wire FPGA_MCU_SPI_MOSI;
    wire FPGA_MCU_SPI_MISO;

    logic [11:0]FMC_A            ;
    logic       FMC_CLK          ;
    logic       FMC_NE           ;
    logic [ 1:0]FMC_NBL          ;
    logic       FMC_NWAIT        ;
    logic       FMC_NL           ;
    logic       FMC_NOE          ;
    logic       FMC_NWE          ;
    wire  [15:0]FMC_D            ;

    // FPGA GCLK

    logic A7_GCLK = 0;
    
    // PHY

    logic PTP_CLK_OUT;
    logic PTP_TRG_FPGA = 0;
    
    // FPGA <-> QSPI

    wire       A7_CONFIG_FCS_B;
    wire [3:0] A7_CONFIG_DQ;
    
    // ADS868x

    wire FPGA_SPI1_CLK;
    wire FPGA_SPI1_CS;
    wire FPGA_SPI1_MOSI;
    wire FPGA_SPI1_MISO;

    logic AD1_RST;

    logic [2:0] CH_SEL_A;

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

    sim_clk_gen #(
        .CLK_FREQ_HZ (25000000),
        .RST_POLARITY(1       ),
        .RST_CYCLES  (10      )
    ) i_A7_GCLK_GEN (
        .clk(A7_GCLK),
        .rst(       ) 
    );

    sim_clk_gen #(
        .CLK_FREQ_HZ (25000000),
        .RST_POLARITY(1       ),
        .RST_CYCLES  (10      )
    ) i_PTP_CLK_GEN (
        .clk(PTP_CLK_OUT),
        .rst(           ) 
    );

    initial begin
        FPGA_RST = 0;
        #1000;
        FPGA_RST = 1;
        $display("%t: Simulation starts.", $time);
        #100000000;
        $finish;
    end

    final begin
        $display("%t: Simulation ends.", $time);
    end

endmodule

`default_nettype wire
