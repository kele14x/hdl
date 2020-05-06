/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads868x_top #(parameter C_ADDR_WIDTH = 10) (
    // AXI4-Lite
    //===========
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
    // Fabric
    //========
    output wire [31:0] m_axis_tdata  ,
    output wire        m_axis_tvalid ,
    input  wire        m_axis_tready ,
    //
    input  wire        pps           ,
    // ADS868x
    //=========
    // SPI
    //----
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
    // GPIO
    //-----
    output wire        RST_PD_N      ,
    // Analog MUX
    //===========
    // MUX Select
    //-----------
    output wire        CH_SEL_A0     ,
    output wire        CH_SEL_A1     ,
    output wire        CH_SEL_A2     ,
    // MUX Enable
    //-----------
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

    // AXI Slave

    wire [C_ADDR_WIDTH-3:0] up_wr_addr;
    wire                    up_wr_req ;
    wire [             3:0] up_wr_be  ;
    wire [            31:0] up_wr_data;
    wire                    up_wr_ack ;
    //
    wire [C_ADDR_WIDTH-3:0] up_rd_addr;
    wire                    up_rd_req ;
    wire [            31:0] up_rd_data;
    wire                    up_rd_ack ;

    // User control signals

    wire ctrl_soft_reset;
    wire ctrl_power_down;
    wire ctrl_auto_spi;

    wire [2:0] ctrl_ext_mux_sel;
    wire [3:0] ctrl_ext_mux_en;

    wire [31:0] ctrl_spi_txdata;
    wire [ 1:0] ctrl_spi_txbyte;
    wire        ctrl_spi_txvalid;

    wire [31:0] stat_spi_rxdata;
    wire        stat_spi_rxvalid;

    axi4l_ipif #(
        .C_ADDR_WIDTH(C_ADDR_WIDTH)
    ) i_ipif (
        .aclk         (aclk         ),
        .aresetn      (aresetn      ),
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
        .up_wr_din    (up_wr_data   ),
        .up_wr_ack    (up_wr_ack    ),
        //
        .up_rd_addr   (up_rd_addr   ),
        .up_rd_req    (up_rd_req    ),
        .up_rd_dout   (up_rd_data   ),
        .up_rd_ack    (up_rd_ack    )
    );


    axi_ads868x_regs #(
        .C_ADDR_WIDTH(C_ADDR_WIDTH-2)
    ) i_regs (
        .clk             (aclk            ),
        .rst             (!aresetn        ),
        //
        .up_wr_addr      (up_wr_addr      ),
        .up_wr_req       (up_wr_req       ),
        .up_wr_be        (up_wr_be        ),
        .up_wr_data      (up_wr_data      ),
        .up_wr_ack       (up_wr_ack       ),
        //
        .up_rd_addr      (up_rd_addr      ),
        .up_rd_req       (up_rd_req       ),
        .up_rd_data      (up_rd_data      ),
        .up_rd_ack       (up_rd_ack       ),
        //
        .ctrl_soft_reset (ctrl_soft_reset ), // Soft reset chip
        .ctrl_power_down (ctrl_power_down ), // Power down chip
        .ctrl_auto_spi   (ctrl_auto_spi   ), // Auto mode or not
        //
        .ctrl_ext_mux_sel(ctrl_ext_mux_sel), // External MUX selection
        .ctrl_ext_mux_en (ctrl_ext_mux_en ), // External MUX enable
        //
        .ctrl_spi_txdata (ctrl_spi_txdata ), // Data send to chip
        .ctrl_spi_txbyte (ctrl_spi_txbyte ), // Byte send to chip - 1
        .ctrl_spi_txvalid(ctrl_spi_txvalid), // Send it!
        //
        .stat_spi_rxdata (stat_spi_rxdata ), // Data received from chip
        .stat_spi_rxvalid(stat_spi_rxvalid)  // Data is valid
    );


    axi_ads868x_ctrl i_ctrl (
        //
        .aclk            (aclk            ),
        .aresetn         (aresetn         ),
        //
        .pps             (pps             ),
        // SPI
        //-----
        // SPI send
        .spi_tx_tdata    (spi_tx_tdata    ),
        .spi_tx_tvalid   (spi_tx_tvalid   ),
        .spi_tx_tready   (spi_tx_tready   ),
        // SPI recv
        .spi_rx_tdata    (spi_rx_tdata    ),
        .spi_rx_tvalid   (spi_rx_tvalid   ),
        .spi_rx_tready   (spi_rx_tready   ),
        //
        .adc_tdata       (m_axis_tdata    ),
        .adc_tvalid      (m_axis_tvalid   ),
        .adc_tready      (m_axis_tready   ),
        //
        //
        .RST_PD_N        (RST_PD_N        ),
        //
        .CH_SEL_A0       (CH_SEL_A0       ),
        .CH_SEL_A1       (CH_SEL_A1       ),
        .CH_SEL_A2       (CH_SEL_A2       ),
        //
        .EN_TCH_A        (EN_TCH_A        ),
        .EN_PCH_A        (EN_PCH_A        ),
        .EN_TCH_B        (EN_TCH_B        ),
        .EN_PCH_B        (EN_PCH_B        ),
        //
        .ctrl_soft_reset (ctrl_soft_reset ), // Soft reset chip
        .ctrl_power_down (ctrl_power_down ), // Power down chip
        .ctrl_auto_spi   (ctrl_auto_spi   ), // Auto mode or not
        //
        .ctrl_ext_mux_sel(ctrl_ext_mux_sel), // External MUX selection
        .ctrl_ext_mux_en (ctrl_ext_mux_en ), // External MUX enable
        //
        .ctrl_spi_txdata (ctrl_spi_txdata ), // Data send to chip
        .ctrl_spi_txbyte (ctrl_spi_txbyte ), // Byte send to chip - 1
        .ctrl_spi_txvalid(ctrl_spi_txvalid), // Send it!
        //
        .stat_spi_rxdata (stat_spi_rxdata ), // Data received from chip
        .stat_spi_rxvalid(stat_spi_rxvalid)  // Data is valid
    );

    axis_spi_master #(.CLK_RATIO(16)) i_spi (
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
        .aclk            (aclk          ),
        .aresetn         (aresetn       ),
        //
        .s_axis_tdata    (spi_tx_tdata  ),
        .s_axis_tvalid   (spi_tx_tvalid ),
        .s_axis_tready   (spi_tx_tready ),
        //
        .m_axis_tdata    (spi_rx_tdata  ),
        .m_axis_tvalid   (spi_rx_tvalid ),
        .m_axis_tready   (spi_rx_tready )
    );

endmodule

`default_nettype wire
