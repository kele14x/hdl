/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ad7124_v2_top #(
    parameter integer C_AXI_ADDR_WIDTH = 32,
    parameter integer C_AXI_DATA_WIDTH = 32,
    parameter integer C_N_ADC_BOARD    = 6 ,
    parameter integer C_N_TC_CHANNEL   = 8
) (
    // AXI4-Lite Slave I/F
    //====================
    input  wire                            aclk                ,
    input  wire                            aresetn             ,
    //
    input  wire [    C_AXI_ADDR_WIDTH-1:0] s_axi_awaddr        ,
    input  wire [                     2:0] s_axi_awprot        ,
    input  wire                            s_axi_awvalid       ,
    output wire                            s_axi_awready       ,
    //
    input  wire [    C_AXI_DATA_WIDTH-1:0] s_axi_wdata         ,
    input  wire [(C_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb         ,
    input  wire                            s_axi_wvalid        ,
    output wire                            s_axi_wready        ,
    //
    output wire [                     1:0] s_axi_bresp         ,
    output wire                            s_axi_bvalid        ,
    input  wire                            s_axi_bready        ,
    //
    input  wire [    C_AXI_ADDR_WIDTH-1:0] s_axi_araddr        ,
    input  wire [                     2:0] s_axi_arprot        ,
    input  wire                            s_axi_arvalid       ,
    output wire                            s_axi_arready       ,
    //
    output wire [    C_AXI_DATA_WIDTH-1:0] s_axi_rdata         ,
    output wire [                     1:0] s_axi_rresp         ,
    output wire                            s_axi_rvalid        ,
    input  wire                            s_axi_rready        ,
    // IRQ
    output wire                            interrupt           ,
    // AD Board
    //=========
    // There are 6 AD Board connected, each has two SPI interface. One interface
    // is for TC, which is 8-channel AD7124. One is for RTD ,which is 1 channel
    // AD7124.
    //
    inout  wire [               C_N_ADC_BOARD-1:0] GX_TC_SPI_SCLK ,
    inout  wire [C_N_TC_CHANNEL*C_N_ADC_BOARD-1:0] GX_TC_SPI_CSN  ,
    inout  wire [               C_N_ADC_BOARD-1:0] GX_TC_SPI_SDI  ,
    inout  wire [               C_N_ADC_BOARD-1:0] GX_TC_SPI_SDO  ,
    // RTD SPI
    inout  wire [               C_N_ADC_BOARD-1:0] GX_RTD_SPI_SDO ,
    inout  wire [               C_N_ADC_BOARD-1:0] GX_RTD_SPI_CSN ,
    inout  wire [               C_N_ADC_BOARD-1:0] GX_RTD_SPI_SCLK,
    inout  wire [               C_N_ADC_BOARD-1:0] GX_RTD_SPI_SDI ,
    // GPIO
    output wire [               C_N_ADC_BOARD-1:0] GX_ADC_SYNC    ,
    output wire [               C_N_ADC_BOARD-1:0] GX_ANA_POW_EN  ,
    output wire [               C_N_ADC_BOARD-1:0] GX_RELAY_CTRL
);



endmodule
