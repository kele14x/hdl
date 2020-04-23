/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_axi_ads124x ();

    // AXI4-Lite Slave Interface
    //===========================
    logic        aclk          = 0;
    logic        aresetn       = 0;
    //
    logic [31:0] s_axi_awaddr  ;
    logic [ 2:0] s_axi_awprot  ;
    logic        s_axi_awvalid ;
    logic        s_axi_awready ;
    //
    logic [31:0] s_axi_wdata   ;
    logic [ 3:0] s_axi_wstrb   ;
    logic        s_axi_wvalid  ;
    logic        s_axi_wready  ;
    //
    logic [ 1:0] s_axi_bresp   ;
    logic        s_axi_bvalid  ;
    logic        s_axi_bready  ;
    //
    logic [31:0] s_axi_araddr  ;
    logic [ 2:0] s_axi_arprot  ;
    logic        s_axi_arvalid ;
    logic        s_axi_arready ;
    //
    logic [31:0] s_axi_rdata   ;
    logic [ 1:0] s_axi_rresp   ;
    logic        s_axi_rvalid  ;
    logic        s_axi_rready  ;

    // FPGA Fabric
    //=============
    //
    logic [31:0] m_axis_tdata  ;
    logic        m_axis_tvalid ;
    logic        m_axis_tready ;
    //
    logic        pps            = 0;
    // ADS124x SPI
    //=============
    logic        SCK_I         ;
    logic        SCK_O         ;
    logic        SCK_T         ;
    logic        SS_I          ;
    logic        SS_O          ;
    logic        SS_T          ;
    logic        IO0_I         ;
    logic        IO0_O         ;
    logic        IO0_T         ;
    logic        IO1_I         ;
    logic        IO1_O         ;
    logic        IO1_T         ;
    // ADS124x GPIO
    logic        RESET         ;
    logic        START         ;
    logic        DRDY          ;

    always #4 aclk = ~aclk;

    initial #100 aresetn = 1;
     
    axi_ads124x UUT ( .* );

endmodule

`default_nettype wire
