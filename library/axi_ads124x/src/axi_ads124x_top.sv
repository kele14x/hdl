/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads124x_top (
    // AXI4-Lite Slave Interface
    //===========================
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
    // FPGA Fabric
    //=============
    output wire [55:0] m_axis_tdata  ,
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


    localparam C_ADDR_WIDTH = 12;
    localparam C_DATA_WIDTH = 32;

    wire [  C_ADDR_WIDTH-3:0] up_wr_addr;
    wire                      up_wr_req ;
    wire [C_DATA_WIDTH/8-1:0] up_wr_be  ;
    wire [  C_DATA_WIDTH-1:0] up_wr_din ;
    wire                      up_wr_ack ;

    wire [  C_ADDR_WIDTH-3:0] up_rd_addr;
    wire                      up_rd_req ;
    wire [  C_DATA_WIDTH-1:0] up_rd_dout;
    wire                      up_rd_ack ;

    wire ctrl_soft_reset;

    wire ctrl_op_mode;

    wire ctrl_ad_start;
    wire ctrl_ad_reset;
    wire stat_ad_drdy;

    wire [31:0] ctrl_spi_txdata;
    wire [ 1:0] ctrl_spi_txbytes;
    wire        ctrl_spi_txvalid;

    wire [31:0] stat_spi_rxdata;
    wire        stat_spi_rxvalid;

    // TX
    wire [7:0] spitx_axis_tdata ;
    wire       spitx_axis_tvalid;
    wire       spitx_axis_tready;

    // RX
    wire [7:0] spirx_axis_tdata ;
    wire       spirx_axis_tvalid;
    wire       spirx_axis_tready;

    // AXI Slave
    axi4l_ipif #(
        .C_ADDR_WIDTH(C_ADDR_WIDTH),
        .C_DATA_WIDTH(C_DATA_WIDTH)
    ) i_ipif (
        .aclk         (aclk   ),
        .aresetn      (aresetn),
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
        .up_wr_addr   (up_wr_addr   ),
        .up_wr_req    (up_wr_req    ),
        .up_wr_be     (up_wr_be     ),
        .up_wr_din    (up_wr_din    ),
        .up_wr_ack    (up_wr_ack    ),
        //
        .up_rd_addr   (up_rd_addr   ),
        .up_rd_req    (up_rd_req    ),
        .up_rd_dout   (up_rd_dout   ),
        .up_rd_ack    (up_rd_ack    )
    );


    axi_ads124x_regs i_regs (
        .clk             (aclk            ),
        .rst             (!aresetn        ),
        //
        .up_wr_addr      (up_wr_addr      ),
        .up_wr_req       (up_wr_req       ),
        .up_wr_din       (up_wr_din       ),
        .up_wr_ack       (up_wr_ack       ),
        //
        .up_rd_addr      (up_rd_addr      ),
        .up_rd_req       (up_rd_req       ),
        .up_rd_dout      (up_rd_dout      ),
        .up_rd_ack       (up_rd_ack       ),
        //
        .ctrl_soft_reset (ctrl_soft_reset ),
        //
        .ctrl_op_mode    (ctrl_op_mode    ),
        //
        .ctrl_ad_start   (ctrl_ad_start   ),
        .ctrl_ad_reset   (ctrl_ad_reset   ),
        .stat_ad_drdy    (stat_ad_drdy    ),
        //
        .ctrl_spi_txbytes(ctrl_spi_txbytes),
        .ctrl_spi_txdata (ctrl_spi_txdata ),
        .ctrl_spi_txvalid(ctrl_spi_txvalid),
        //
        .stat_spi_rxdata (stat_spi_rxdata ),
        .stat_spi_rxvalid(stat_spi_rxvalid)
    );


    axi_ads124x_ctrl i_ctrl (
        /* AXIS */
        .aclk             (aclk             ),
        .aresetn          (aresetn          ),
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
        .ctrl_soft_reset  (ctrl_soft_reset  ),
        //
        .ctrl_op_mode     (ctrl_op_mode     ),
        //
        .ctrl_ad_start    (ctrl_ad_start    ),
        .ctrl_ad_reset    (ctrl_ad_reset    ),
        .stat_ad_drdy     (stat_ad_drdy     ),
        //
        .ctrl_spi_txdata  (ctrl_spi_txdata ),
        .ctrl_spi_txbytes (ctrl_spi_txbytes),
        .ctrl_spi_txvalid (ctrl_spi_txvalid),
        //
        .stat_spi_rxdata  (stat_spi_rxdata  ),
        .stat_spi_rxvalid (stat_spi_rxvalid )
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
        .aclk            (aclk            ),
        .aresetn         (aresetn         ),
        // Tx, AXI4 Stream Slave
        .s_axis_tdata    (spitx_axis_tdata     ),
        .s_axis_tvalid   (spitx_axis_tvalid    ),
        .s_axis_tready   (spitx_axis_tready    ),
        // Rx AXI4 Stream Master
        .m_axis_tdata    (spirx_axis_tdata     ),
        .m_axis_tvalid   (spirx_axis_tvalid    ),
        .m_axis_tready   (spirx_axis_tready    )
    );

endmodule

`default_nettype wire
