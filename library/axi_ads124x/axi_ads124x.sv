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
module axi_ads124x (
    // AXI4-Lite Slave Interface
    //===========================
    input  wire        s_axi_aclk    ,
    input  wire        s_axi_aresetn ,
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
    // FPGA Fabric
    //=============
    input  wire        m_axis_aclk   ,
    input  wire        m_axis_aresetn,
    //
    output wire [31:0] m_axis_tdata  ,
    output wire        m_axis_tvalid ,
    input  wire        m_axis_tready ,
    //
    input  wire        pps           ,
    // ADS124x SPI
    //=============
    input  wire        SCK_I         ,
    output wire        SCK_O         ,
    output wire        SCK_T         ,
    input  wire        SS_I          ,
    output wire        SS_O          ,
    output wire        SS_T          ,
    input  wire        IO0_I         ,
    output wire        IO0_O         ,
    output wire        IO0_T         ,
    input  wire        IO1_I         ,
    output wire        IO1_O         ,
    output wire        IO1_T         ,
    // ADS124x GPIO
    output wire        RESET         ,
    output wire        START         ,
    input  wire        DRDY
);

    // TX
    wire [7:0] spitx_axis_tdata ;
    wire       spitx_axis_tvalid;
    wire       spitx_axis_tready;

    // RX
    wire [7:0] spirx_axis_tdata ;
    wire       spirx_axis_tvalid;
    wire       spirx_axis_tready;

    wire stat_rx_overflow;

    // AXI Slave
    axi_ads124x_ipif i_ipif (
        .aclk         (s_axi_aclk   ),
        .aresetn      (s_axi_aresetn),
        //
        .s_axi_awaddr (s_axi_awaddr ),
        .s_axi_awprot (s_axi_awprot ),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        //
        .s_axi_wdata  (s_axi_wdata  ),
        .s_axi_wstrb  (s_axi_wstrb  ),
        .s_axi_wvalid (s_axi_wvalid ),
        .s_axi_wready (s_axi_wready ),
        //
        .s_axi_bresp  (s_axi_bresp  ),
        .s_axi_bvalid (s_axi_bvalid ),
        .s_axi_bready (s_axi_bready ),
        //
        .s_axi_araddr (s_axi_araddr ),
        .s_axi_arprot (s_axi_arprot ),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        //
        .s_axi_rdata  (s_axi_rdata  ),
        .s_axi_rresp  (s_axi_rresp  ),
        .s_axi_rvalid (s_axi_rvalid ),
        .s_axi_rready (s_axi_rready )
    );

    axi_ads124x_ctrl i_ctrl (
        /* AXIS */
        .aclk             (m_axis_aclk      ),
        .aresetn          (m_axis_aresetn   ),
        // SPI send
        .spitx_axis_tdata (spitx_axis_tdata ),
        .spitx_axis_tvalid(spitx_axis_tvalid),
        .spitx_axis_tready(spitx_axis_tready),
        // SPI recv
        .spirx_axis_tdata (spirx_axis_tdata ),
        .spirx_axis_tvalid(spirx_axis_tvalid),
        .spirx_axis_tready(spirx_axis_tready),
        // ADC
        .adc_axis_tdata   (m_axis_tdata     ),
        .adc_axis_tvalid  (m_axis_tvalid    ),
        .adc_axis_tready  (m_axis_tready    ),
        //
        .pps              (pps              ),
        //
        .RESET            (RESET            ),
        .START            (START            ),
        .DRDY             (DRDY             ),
        //
        .ctrl_op_mod      (1'b1             )
        
    );

    axis_spi_master #(.CLK_RATIO(64)) i_axis_spi_master (
        // SPI
        //=====
        .SCK_I           (SCK_I           ),
        .SCK_O           (SCK_O           ),
        .SCK_T           (SCK_T           ),
        .SS_I            (SS_I            ),
        .SS_O            (SS_O            ),
        .SS_T            (SS_T            ),
        .IO0_I           (IO0_I           ),
        .IO0_O           (IO0_O           ),
        .IO0_T           (IO0_T           ),
        .IO1_I           (IO1_I           ),
        .IO1_O           (IO1_O           ),
        .IO1_T           (IO1_T           ),
        // AXIS
        //======
        .aclk            (m_axis_aclk     ),
        .aresetn         (m_axis_aresetn  ),
        // Tx, AXI4 Stream Slave
        .s_axis_tdata    (spitx_axis_tdata     ),
        .s_axis_tvalid   (spitx_axis_tvalid    ),
        .s_axis_tready   (spitx_axis_tready    ),
        // Rx AXI4 Stream Master
        .m_axis_tdata    (spirx_axis_tdata     ),
        .m_axis_tvalid   (spirx_axis_tvalid    ),
        .m_axis_tready   (spirx_axis_tready    ),
        // Status
        //========
        .stat_rx_overflow(stat_rx_overflow)
    );

endmodule

`default_nettype wire
