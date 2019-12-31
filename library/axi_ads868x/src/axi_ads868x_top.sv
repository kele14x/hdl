/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads868x_top (
    // AXI4-Lite
    //===========
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
    // Fabric
    //========
    input  wire        m_axis_aclk   ,
    input  wire        m_axis_aresetn,
    //
    output wire [31:0] m_axis_tdata  ,
    output wire        m_axis_tvalid ,
    input  wire        m_axis_tready ,
    //
    input  wire        pps           ,
    // ADS868x
    //=========
    input  wire        SCK_I         ,
    output wire        SCK_O         ,
    output wire        SCK_T         ,
    input  wire        SS_I          ,
    output wire        SS_O          ,
    output wire        SS_T          ,
    input  wire        IO0_I         ,
    output wire        IO0_O         , // MO
    output wire        IO0_T         ,
    input  wire        IO1_I         , // MI
    output wire        IO1_O         ,
    output wire        IO1_T         ,
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
    wire [7:0] spi_tx_tdata ;
    wire       spi_tx_tvalid;
    wire       spi_tx_tready;

    // RX
    wire [7:0] spi_rx_tdata ;
    wire       spi_rx_tvalid;
    wire       spi_rx_tready;

    // ADC
    wire [15:0] adc_tdata;
    wire        adc_tvalid;
    wire        adc_tready;

    // AXI Slave

    wire [ 9:0] up_wr_addr;
    wire        up_wr_req ;
    wire [ 3:0] up_wr_be  ;
    wire [31:0] up_wr_data;
    wire        up_wr_ack ;
    //
    wire [ 9:0] up_rd_addr;
    wire        up_rd_req ;
    wire [31:0] up_rd_data;
    wire        up_rd_ack ;

    wire ctrl_soft_reset;

    wire [3:0] ctrl_ext_mux_en;

    wire [15:0] ctrl_mult_coe;

    axi4l_ipif i_ipif (
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
        .wr_addr      (up_wr_addr   ),
        .wr_req       (up_wr_req    ),
        .wr_be        (up_wr_be     ),
        .wr_data      (up_wr_data   ),
        .wr_ack       (up_wr_ack    ),
        //
        .rd_addr      (up_rd_addr   ),
        .rd_req       (up_rd_req    ),
        .rd_data      (up_rd_data   ),
        .rd_ack       (up_rd_ack    )
    );


    axi_ads868x_regs i_regs (
        .up_clk         (s_axi_aclk     ),
        .up_rstn        (s_axi_aresetn  ),
        //
        .up_wr_addr     (up_wr_addr     ),
        .up_wr_req      (up_wr_req      ),
        .up_wr_be       (up_wr_be       ),
        .up_wr_data     (up_wr_data     ),
        .up_wr_ack      (up_wr_ack      ),
        //
        .up_rd_addr     (up_rd_addr     ),
        .up_rd_req      (up_rd_req      ),
        .up_rd_data     (up_rd_data     ),
        .up_rd_ack      (up_rd_ack      ),
        //
        .clk            (m_axis_aclk    ),
        .rst            (!m_axis_aresetn),
        //
        .ctrl_soft_reset(ctrl_soft_reset),
        //
        .ctrl_ext_mux_en(ctrl_ext_mux_en)
    );


    axi_ads868x_ctrl i_ctrl (
        //
        .aclk         (m_axis_aclk   ),
        .aresetn      (m_axis_aresetn),
        //
        .pps          (pps           ),
        // SPI
        //-----
        // SPI send
        .spi_tx_tdata (spi_tx_tdata  ),
        .spi_tx_tvalid(spi_tx_tvalid ),
        .spi_tx_tready(spi_tx_tready ),
        // SPI recv
        .spi_rx_tdata (spi_rx_tdata  ),
        .spi_rx_tvalid(spi_rx_tvalid ),
        .spi_rx_tready(spi_rx_tready ),
        //
        .adc_tdata    (adc_tdata     ),
        .adc_tvalid   (adc_tvalid    ),
        .adc_tready   (adc_tready    ),
        //
        .CH_SEL_A0    (CH_SEL_A0     ),
        .CH_SEL_A1    (CH_SEL_A1     ),
        .CH_SEL_A2    (CH_SEL_A2     )
    );

    axi_ads868x_mult i_axi_ads868x_mult (
        .aclk         (m_axis_aclk   ),
        .aresetn      (m_axis_aresetn),
        //
        .s_axis_tdata (adc_tdata     ),
        .s_axis_tvalid(adc_tvalid    ),
        .s_axis_tready(adc_tready    ),
        //
        .m_axis_tdata (m_axis_tdata  ),
        .m_axis_tvalid(m_axis_tvalid ),
        .m_axis_tready(m_axis_tready ),
        //
        .ctrl_mult_coe(ctrl_mult_coe )
    );



    axis_spi_master #(.CLK_RATIO(8)) i_spi (
        //
        .SCK_I           (SCK_I         ),
        .SCK_O           (SCK_O         ),
        .SCK_T           (SCK_T         ),
        .SS_I            (SS_I          ),
        .SS_O            (SS_O          ),
        .SS_T            (SS_T          ),
        .IO0_I           (IO0_I         ),
        .IO0_O           (IO0_O         ),
        .IO0_T           (IO0_T         ),
        .IO1_I           (IO1_I         ),
        .IO1_O           (IO1_O         ),
        .IO1_T           (IO1_T         ),
        //
        .aclk            (m_axis_aclk   ),
        .aresetn         (m_axis_aresetn),
        //
        .s_axis_tdata    (spi_tx_tdata  ),
        .s_axis_tvalid   (spi_tx_tvalid ),
        .s_axis_tready   (spi_tx_tready ),
        //
        .m_axis_tdata    (spi_rx_tdata  ),
        .m_axis_tvalid   (spi_rx_tvalid ),
        .m_axis_tready   (spi_rx_tready ),
        //
        .stat_rx_overflow(              )
    );


    assign {EN_PCH_B, EN_TCH_B, EN_PCH_A, EN_TCH_A} = ctrl_ext_mux_en;

endmodule

`default_nettype wire
