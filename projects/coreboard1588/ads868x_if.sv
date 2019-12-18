/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

//==============================================================================
//
//       ____                                                     _____
//  SS       \___________________________________________________/
//                ___     ___     ___     ___     ___     ___
//  SCK  ________/   \___/   \___/   \___/   \___/   \___/   \_________
//                _______ _______ _______ _______ _______ _______
//  MOSI zzzz----X___0___X__...__X___15__X__ 16__X__...__X___31__Xzzzzz
//                                        _______ _______ _______
//  MISO zzzz----\_______________________X__ 16__X__...__X___31__Xzzzzz
//
//==============================================================================

(* keep_hierarchy="yes" *)
module ads868x_if (
    /* AXI4-Lite Slave Interface */
    //=============================
    input  wire        aclk          ,
    input  wire        aresetn       ,
    //
    input  wire [31:0] s_axi_awaddr  ,
    input  wire [ 2:0] s_axi_awprot  ,
    input  wire        s_axi_awvalid ,
    output wire        s_axi_awready ,
    //
    input  wire [31:0] s_axi_wdata   ,
    input  wire [ 3:0] s_axi_wstrb   ,
    input  wire        s_axi_wvalid  ,
    output wire        s_axi_wready  ,
    //
    output wire [ 1:0] s_axi_bresp   ,
    output wire        s_axi_bvalid  ,
    input  wire        s_axi_bready  ,
    //
    input  wire [31:0] s_axi_araddr  ,
    input  wire [ 2:0] s_axi_arprot  ,
    input  wire        s_axi_arvalid ,
    output wire        s_axi_arready ,
    //
    output wire [31:0] s_axi_rdata   ,
    output wire [ 1:0] s_axi_rresp   ,
    output wire        s_axi_rvalid  ,
    input  wire        s_axi_rready  ,
    /* ADS868x Samples */
    //=============================
    input  wire        clk_125m      ,
    input  wire        rst_125m      ,
    //
    input  wire        sync_1pps     ,
    //
    output wire [31:0] adc_tdata     ,
    output wire        adc_tvalid    ,
    /* ADS868x */
    //=============================
    output wire        SCK           ,
    output wire        SS_N          ,
    output wire        MOSI_Z        ,
    input  wire        MISO          ,
    //
    output wire        RST_PD_N      ,
    /* Analog MUX */
    //=============================
    output wire        CH_SEL_A0     ,
    output wire        CH_SEL_A1     ,
    output wire        CH_SEL_A2     ,
    //
    output wire        EN_TCH_A      ,
    output wire        EN_PCH_A      ,
    output wire        EN_TCH_B      ,
    output wire        EN_PCH_B
);

    // TX
    wire [31:0] spi_tx_data ;
    wire [ 4:0] spi_tx_bits ;
    wire        spi_tx_valid;
    wire        spi_tx_ready;

    // RX
    wire [31:0] spi_rx_data ;
    wire [ 4:0] spi_rx_bits ;
    wire        spi_rx_valid;

    // AXI Slave
    (* keep_hierarchy="yes" *)
    axi_lite_ipif i_axi_lite_ipif (
        .S_AXI_ACLK   (      aclk   ),
        .S_AXI_ARESETN(      aresetn),
        //
        .S_AXI_AWADDR (s_axi_awaddr ),
        .S_AXI_AWVALID(s_axi_awvalid),
        .S_AXI_AWREADY(s_axi_awready),
        //
        .S_AXI_WDATA  (s_axi_wdata  ),
        .S_AXI_WSTRB  (s_axi_wstrb  ),
        .S_AXI_WVALID (s_axi_wvalid ),
        .S_AXI_WREADY (s_axi_wready ),
        //
        .S_AXI_BRESP  (s_axi_bresp  ),
        .S_AXI_BVALID (s_axi_bvalid ),
        .S_AXI_BREADY (s_axi_bready ),
        //
        .S_AXI_ARADDR (s_axi_araddr ),
        .S_AXI_ARVALID(s_axi_arvalid),
        .S_AXI_ARREADY(s_axi_arready),
        //
        .S_AXI_RDATA  (s_axi_rdata  ),
        .S_AXI_RRESP  (s_axi_rresp  ),
        .S_AXI_RVALID (s_axi_rvalid ),
        .S_AXI_RREADY (s_axi_rready ),
        // Controls to the IP/IPIF modules
        .Bus2IP_Clk   (             ),
        .Bus2IP_Resetn(             ),
        .Bus2IP_Addr  (             ),
        .Bus2IP_RNW   (             ),
        .Bus2IP_BE    (             ),
        .Bus2IP_CS    (             ),
        .Bus2IP_RdCE  (             ),
        .Bus2IP_WrCE  (             ),
        .Bus2IP_Data  (             ),
        .IP2Bus_Data  (             ),
        .IP2Bus_WrAck (             ),
        .IP2Bus_RdAck (             ),
        .IP2Bus_Error (             )
    );

    ads868x_ctrl i_ads868x_ctrl (
        /* AXIS */
        .clk_125m    (clk_125m ),
        .rst_125m    (rst_125m ),
        //
        .sync_1pps   (sync_1pps),
        // SPI send
        .spi_tx_data (spi_tx_data ),
        .spi_tx_bits (spi_tx_bits ),
        .spi_tx_valid(spi_tx_valid),
        // SPI recv
        .spi_rx_data (),
        .spi_rx_bits (),
        .spi_rx_valid()
    );

    ads868x_spi i_ads868x_spi (
        /* SPI */
        .SCK          (SCK               ),
        .SS_N         (SS_N              ),
        .MOSI_Z       (MOSI_Z            ),
        .MISO         (MISO              ),
        /* AXIS */
        .clk_125m     (clk_125m          ),
        .rst_125m     (rst_125m          ),
        // Tx, AXI4 Stream Slave
        .tx_data      (spi_tx_data       ),
        .tx_bits      (spi_tx_bits       ),
        .tx_valid     (spi_tx_valid      ),
        .tx_ready     (spi_tx_ready      ),
        // Rx AXI4 Stream Master
        .rx_data      (spi_rx_data       ),
        .rx_bits      (spi_rx_bits       ),
        .rx_valid     (spi_rx_valid      )
    );

endmodule
