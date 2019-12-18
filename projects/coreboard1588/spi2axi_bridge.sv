/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module spi2axi_bridge (
    /* SPI */
    input  wire        SCK          ,
    input  wire        SS_N         ,
    input  wire        MOSI         ,
    inout  wire        MISO_Z       ,
    /* AXI4 Lite Master */
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


    wire [7:0] rx_data ;
    wire       rx_valid;
    wire       rx_ready;

    wire [7:0] tx_data ;
    wire       tx_valid;
    wire       tx_ready;

    spi2axis i_spi2axis (
        /* SPI */
        .SCK          (SCK     ),
        .SS_N         (SS_N    ),
        .MOSI         (MOSI    ),
        .MISO_Z       (MISO_Z  ),
        /* AXIS */
        .aclk         (aclk    ),
        .aresetn      (aresetn ),
        // RX AXIS
        .m_axis_tdata (rx_data ),
        .m_axis_tvalid(rx_valid),
        .m_axis_tready(rx_ready),
        // TX AXIS
        .s_axis_tdata (tx_data ),
        .s_axis_tvalid(tx_valid),
        .s_axis_tready(tx_ready)
    );

    axis2mm i_axis2mm (
        .aclk         (aclk         ),
        .aresetn      (aresetn      ),
        /* AXIS Slave */
        .s_axis_tdata (rx_data      ),
        .s_axis_tvalid(rx_valid     ),
        .s_axis_tready(rx_ready     ),
        /* AXIS Master */
        .m_axis_tdata (tx_data      ),
        .m_axis_tvalid(tx_valid     ),
        .m_axis_tready(tx_ready     ),
        /* AXI */
        .m_axi_awaddr (m_axi_awaddr ),
        .m_axi_awprot (m_axi_awprot ),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        //
        .m_axi_wdata  (m_axi_wdata  ),
        .m_axi_wstrb  (m_axi_wstrb  ),
        .m_axi_wvalid (m_axi_wvalid ),
        .m_axi_wready (m_axi_wready ),
        //
        .m_axi_bresp  (m_axi_bresp  ),
        .m_axi_bvalid (m_axi_bvalid ),
        .m_axi_bready (m_axi_bready ),
        //
        .m_axi_araddr (m_axi_araddr ),
        .m_axi_arprot (m_axi_arprot ),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        //
        .m_axi_rdata  (m_axi_rdata  ),
        .m_axi_rresp  (m_axi_rresp  ),
        .m_axi_rvalid (m_axi_rvalid ),
        .m_axi_rready (m_axi_rready )
    );


endmodule
