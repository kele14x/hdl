/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module spi_axi_top (
    // SPI
    //=====
    input  wire        SS_I           ,
    output wire        SS_O           ,
    output wire        SS_T           ,
    input  wire        SCK_I          ,
    output wire        SCK_O          ,
    output wire        SCK_T          ,
    input  wire        IO0_I          , // SI
    output wire        IO0_O          ,
    output wire        IO0_T          ,
    input  wire        IO1_I          , // SO
    output wire        IO1_O          ,
    output wire        IO1_T          ,
    // AXI
    //=====
    input  wire        aclk           ,
    input  wire        aresetn        ,
    //
    output wire [31:0] m_axi_awaddr   ,
    output wire [ 2:0] m_axi_awprot   ,
    output wire        m_axi_awvalid  ,
    input  wire        m_axi_awready  ,
    //
    output wire [31:0] m_axi_wdata    ,
    output wire [ 3:0] m_axi_wstrb    ,
    output wire        m_axi_wvalid   ,
    input  wire        m_axi_wready   ,
    //
    input  wire [ 1:0] m_axi_bresp    ,
    input  wire        m_axi_bvalid   ,
    output wire        m_axi_bready   ,
    //
    output wire [31:0] m_axi_araddr   ,
    output wire [ 2:0] m_axi_arprot   ,
    output wire        m_axi_arvalid  ,
    input  wire        m_axi_arready  ,
    //
    input  wire [31:0] m_axi_rdata    ,
    input  wire [ 1:0] m_axi_rresp    ,
    input  wire        m_axi_rvalid   ,
    output wire        m_axi_rready
);

    wire        spi_rx_ss   ;
    wire [7:0]  spi_rx_byte ;
    wire        spi_rx_first;
    wire        spi_rx_valid;

    wire [7:0]  spi_tx_data;
    wire        spi_tx_load;

    wire [11:0] axi_wr_addr;
    wire [31:0] axi_wr_data;
    wire        axi_wr_en  ;

    wire [11:0] axi_rd_addr;
    wire        axi_rd_en  ;
    wire [31:0] axi_rd_data ;

    wire        stat_axi_awoverrun ;
    wire        stat_axi_woverrun  ;
    wire        stat_axi_bresperr  ;
    wire        stat_axi_aroverrun ;
    wire        stat_axi_rresperr  ;


    spi_axi_spiif i_spi_axi_spiif (
        // SPI
        .SCK_I   (SCK_I       ),
        .SCK_O   (SCK_O       ),
        .SCK_T   (SCK_T       ),
        .SS_I    (SS_I        ),
        .SS_O    (SS_O        ),
        .SS_T    (SS_T        ),
        .IO0_I   (IO0_I       ),
        .IO0_O   (IO0_O       ),
        .IO0_T   (IO0_T       ),
        .IO1_I   (IO1_I       ),
        .IO1_O   (IO1_O       ),
        .IO1_T   (IO1_T       ),
        //
        .clk     (aclk        ),
        .rst     (!aresetn    ),
        //
        .rx_ss   (spi_rx_ss   ),
        .rx_byte (spi_rx_byte ),
        .rx_first(spi_rx_first),
        .rx_valid(spi_rx_valid),
        //
        .tx_data (spi_tx_data ),
        .tx_load (spi_tx_load )
    );

    spi_axi_ctrl i_spi_axi_ctrl (
        .clk         (aclk        ),
        .rst         (!aresetn    ),
        //
        .spi_rx_byte (spi_rx_byte ),
        .spi_rx_first(spi_rx_first),
        .spi_rx_valid(spi_rx_valid),
        //
        .spi_tx_data (spi_tx_data ),
        .spi_tx_load (spi_tx_load ),
        //
        .axi_wr_addr (axi_wr_addr ),
        .axi_wr_data (axi_wr_data ),
        .axi_wr_en   (axi_wr_en   ),
        //
        .axi_rd_addr (axi_rd_addr ),
        .axi_rd_en   (axi_rd_en   ),
        .axi_rd_data (axi_rd_data )
    );

    spi_axi_axiff i_spi_axi_axiff (
        //
        .axi_wr_addr       (axi_wr_addr       ),
        .axi_wr_data       (axi_wr_data       ),
        .axi_wr_en         (axi_wr_en         ),
        //
        .axi_rd_addr       (axi_rd_addr       ),
        .axi_rd_en         (axi_rd_en         ),
        .axi_rd_data       (axi_rd_data       ),
        //
        .aclk              (aclk              ),
        .aresetn           (aresetn           ),
        //
        .m_axi_awaddr      (m_axi_awaddr      ),
        .m_axi_awprot      (m_axi_awprot      ),
        .m_axi_awvalid     (m_axi_awvalid     ),
        .m_axi_awready     (m_axi_awready     ),
        .m_axi_wdata       (m_axi_wdata       ),
        .m_axi_wstrb       (m_axi_wstrb       ),
        .m_axi_wvalid      (m_axi_wvalid      ),
        .m_axi_wready      (m_axi_wready      ),
        .m_axi_bresp       (m_axi_bresp       ),
        .m_axi_bvalid      (m_axi_bvalid      ),
        .m_axi_bready      (m_axi_bready      ),
        .m_axi_araddr      (m_axi_araddr      ),
        .m_axi_arprot      (m_axi_arprot      ),
        .m_axi_arvalid     (m_axi_arvalid     ),
        .m_axi_arready     (m_axi_arready     ),
        .m_axi_rdata       (m_axi_rdata       ),
        .m_axi_rresp       (m_axi_rresp       ),
        .m_axi_rvalid      (m_axi_rvalid      ),
        .m_axi_rready      (m_axi_rready      ),
        //
        .stat_axi_awoverrun(stat_axi_awoverrun),
        .stat_axi_woverrun (stat_axi_woverrun ),
        .stat_axi_bresperr (stat_axi_bresperr ),
        .stat_axi_aroverrun(stat_axi_aroverrun),
        .stat_axi_rresperr (stat_axi_rresperr )
    );



endmodule
