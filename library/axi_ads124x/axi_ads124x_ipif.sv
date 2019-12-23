/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads124x_ipif (
    input  wire        aclk         ,
    input  wire        aresetn      ,
    //
    input  wire [31:0] s_axi_awaddr ,
    input  wire [ 2:0] s_axi_awprot ,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    //
    input  wire [31:0] s_axi_wdata  ,
    input  wire [ 3:0] s_axi_wstrb  ,
    input  wire        s_axi_wvalid ,
    output wire        s_axi_wready ,
    //
    output wire [ 1:0] s_axi_bresp  ,
    output wire        s_axi_bvalid ,
    input  wire        s_axi_bready ,
    //
    input  wire [31:0] s_axi_araddr ,
    input  wire [ 2:0] s_axi_arprot ,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata  ,
    output wire [ 1:0] s_axi_rresp  ,
    output wire        s_axi_rvalid ,
    input  wire        s_axi_rready
);

endmodule : axi_ads124x_ipif

`default_nettype wire
