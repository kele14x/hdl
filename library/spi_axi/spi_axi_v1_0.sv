/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module spi_axi_v1_0 (
    // SPI
    //=====
    input  wire        SCK_I        ,
    output wire        SCK_O        ,
    output wire        SCK_T        ,
    input  wire        SS_I         ,
    output wire        SS_O         ,
    output wire        SS_T         ,
    input  wire        IO0_I        , // SI
    output wire        IO0_O        ,
    output wire        IO0_T        ,
    input  wire        IO1_I        , // SO
    output wire        IO1_O        ,
    output wire        IO1_T        ,
    // AXI4 Lite Master
    //=================
    input  wire        aclk         ,
    input  wire        aresetn      ,
    //
    output wire [31:0] m_axi_awaddr ,
    output wire [ 2:0] m_axi_awprot ,
    output wire        m_axi_awvalid,
    input  wire        m_axi_awready,
    //
    output wire [31:0] m_axi_wdata  ,
    output wire [ 3:0] m_axi_wstrb  ,
    output wire        m_axi_wvalid ,
    input  wire        m_axi_wready ,
    //
    input  wire [ 1:0] m_axi_bresp  ,
    input  wire        m_axi_bvalid ,
    output wire        m_axi_bready ,
    //
    output wire [31:0] m_axi_araddr ,
    output wire [ 2:0] m_axi_arprot ,
    output wire        m_axi_arvalid,
    input  wire        m_axi_arready,
    //
    input  wire [31:0] m_axi_rdata  ,
    input  wire [ 1:0] m_axi_rresp  ,
    input  wire        m_axi_rvalid ,
    output wire        m_axi_rready
);

	spi_axi inst(.*);

endmodule

`default_nettype wire
