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

    wire [31:0] reg_out      [0:5];
    wire        reg_out_strb [0:5];

    wire [31:0] reg_in       [0:5];
    wire        reg_in_strb  [0:5];

    wire up_op_mode;
    
    wire up_ad_start, up_ad_reset, up_ad_drdy;

    wire [31:0] up_spi_send;
    wire [ 1:0] up_spi_nbytes;
    wire        up_spi_valid;
    wire [31:0] up_spi_recv;

    // TX
    wire [7:0] spitx_axis_tdata ;
    wire       spitx_axis_tvalid;
    wire       spitx_axis_tready;

    // RX
    wire [7:0] spirx_axis_tdata ;
    wire       spirx_axis_tvalid;
    wire       spirx_axis_tready;

    wire stat_rx_overflow;

    // Address        Detail
    // 0x0000_0000    VERSION
    // 0x0000_0004    CTRL
    // 0x0000_0008    STAT
    // 0x0000_000C    SPICTRL
    // 0x0000_0010    SPISEND
    // 0x0000_0014    SPIRECV

    // AXI Slave
    axi4l_ipif #(
        .C_NUM_REGS (6),
        .C_ADDR_LIST({
            32'h0000_0000,
            32'h0000_0004,
            32'h0000_0008,
            32'h0000_000C,
            32'h0000_0010,
            32'h0000_0014
        })
    ) i_ipif (
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
        .s_axi_rready (s_axi_rready ),
        //
        .reg_out      (reg_out      ),
        .reg_out_strb (reg_out_strb ),
        //
        .reg_in       (reg_in       ),
        .reg_in_strb  (reg_in_strb  )
    );

    // Reg 0x0000_0000

    assign reg_in[0] = 32'h20191226;

    // Reg 0x0000_0004

    assign up_op_mode   = reg_out[1][8];
    assign up_ad_reset  = reg_out[1][4];
    assign up_ad_start  = reg_out[1][0];

    assign reg_in[1][0] = reg_out[1][0];
    assign reg_in[1][4] = reg_out[1][4];
    assign reg_in[1][8] = reg_out[1][8];

    // Reg 0x0000_0008

    assign reg_in[2][0] = up_ad_drdy;

    // Reg 0x0000_000C
    
    assign up_spi_nbytes = reg_out[3][1:0];
    
    assign reg_in[3][1:0] = reg_out[3][1:0];


    // Reg 0x0000_0010
    
    assign up_spi_send = reg_out[4];
    
    assign reg_in[4] = reg_out[4];
    
    // Reg 0x0000_0014
    
    assign reg_in[5] = up_spi_recv;



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
        .up_clk           (s_axi_aclk       ),
        .up_rst           (!s_axi_aresetn   ),
        //
        .up_op_mode       (up_op_mode       ),
        //
        .up_ad_start      (up_ad_start      ),
        .up_ad_reset      (up_ad_reset      ),
        .up_ad_drdy       (up_ad_drdy       ),
        //
        .up_spi_send      (up_spi_send      ),
        .up_spi_nbytes    (up_spi_nbytes    ),
        .up_spi_valid     (up_spi_valid     ),
        .up_spi_recv      (up_spi_recv      )
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
