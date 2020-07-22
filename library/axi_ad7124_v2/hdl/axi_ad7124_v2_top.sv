/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_v2_top #(
    parameter integer AXI_ADDR_WIDTH      = 32,
    parameter integer AXI_DATA_WIDTH      = 32,
    parameter integer NUM_OF_BOARD        = 6 ,
    parameter integer NUM_OF_TC_PER_BOARD = 8
) (
    // AXI4-Lite Slave I/F
    //====================
    input  wire                                        aclk             ,
    input  wire                                        aresetn          ,
    //
    input  wire [                  AXI_ADDR_WIDTH-1:0] s_axi_awaddr     ,
    input  wire [                                 2:0] s_axi_awprot     ,
    input  wire                                        s_axi_awvalid    ,
    output wire                                        s_axi_awready    ,
    //
    input  wire [                  AXI_DATA_WIDTH-1:0] s_axi_wdata      ,
    input  wire [              (AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb      ,
    input  wire                                        s_axi_wvalid     ,
    output wire                                        s_axi_wready     ,
    //
    output wire [                                 1:0] s_axi_bresp      ,
    output wire                                        s_axi_bvalid     ,
    input  wire                                        s_axi_bready     ,
    //
    input  wire [                  AXI_ADDR_WIDTH-1:0] s_axi_araddr     ,
    input  wire [                                 2:0] s_axi_arprot     ,
    input  wire                                        s_axi_arvalid    ,
    output wire                                        s_axi_arready    ,
    //
    output wire [                  AXI_DATA_WIDTH-1:0] s_axi_rdata      ,
    output wire [                                 1:0] s_axi_rresp      ,
    output wire                                        s_axi_rvalid     ,
    input  wire                                        s_axi_rready     ,
    // IRQ
    output wire                                        interrupt        ,
    // BRAM I/F
    //=========
    output wire                                        bram_clk         ,
    output wire                                        bram_rst         ,
    output wire                                        bram_en          ,
    output wire [                                 3:0] bram_we          ,
    output wire [                                12:0] bram_addr        ,
    output wire [                                31:0] bram_wrdata      ,
    input  wire [                                31:0] bram_rddata      ,
    // AD Board
    //=========
    // There are 6 AD Board connected, each has two SPI interface. One interface
    // is for TC, which is 8-channel AD7124. One is for RTD ,which is 1 channel
    // AD7124.
    //
    input  wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SCLK_i ,
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SCLK_o ,
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SCLK_t ,
    input  wire [NUM_OF_TC_PER_BOARD*NUM_OF_BOARD-1:0] GX_TC_SPI_CSN_i  ,
    output wire [NUM_OF_TC_PER_BOARD*NUM_OF_BOARD-1:0] GX_TC_SPI_CSN_o  ,
    output wire [NUM_OF_TC_PER_BOARD*NUM_OF_BOARD-1:0] GX_TC_SPI_CSN_t  ,
    input  wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDO_i  ,
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDO_o  ,
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDO_t  ,
    input  wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDI_i  ,
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDI_o  ,
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDI_t  ,
    // RTD SPI
    input  wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SCLK_i,
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SCLK_o,
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SCLK_t,
    input  wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_CSN_i ,
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_CSN_o ,
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_CSN_t ,
    input  wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDO_i ,
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDO_o ,
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDO_t ,
    input  wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDI_i ,
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDI_o ,
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDI_t ,
    // GPIO
    output wire [                    NUM_OF_BOARD-1:0] GX_ADC_SYNC      ,
    output wire [                    NUM_OF_BOARD-1:0] GX_ANA_POW_EN    ,
    output wire [                    NUM_OF_BOARD-1:0] GX_RELAY_CTRL
);


    // TC
    localparam TC_CMD_FIFO_ADDRESS_WIDTH  = 4;
    localparam TC_SYNC_FIFO_ADDRESS_WIDTH = 4;
    localparam TC_SDO_FIFO_ADDRESS_WIDTH  = 5;
    localparam TC_SDI_FIFO_ADDRESS_WIDTH  = 5;
    //
    localparam TC_OFFLOAD0_CMD_MEM_ADDRESS_WIDTH = 4;
    localparam TC_OFFLOAD0_SDO_MEM_ADDRESS_WIDTH = 4;
    //
    localparam TC_NUM_OF_CS = 8;

    // RTD
    localparam RTD_CMD_FIFO_ADDRESS_WIDTH  = 4;
    localparam RTD_SYNC_FIFO_ADDRESS_WIDTH = 4;
    localparam RTD_SDO_FIFO_ADDRESS_WIDTH  = 5;
    localparam RTD_SDI_FIFO_ADDRESS_WIDTH  = 5;
    //
    localparam RTD_OFFLOAD0_CMD_MEM_ADDRESS_WIDTH = 4;
    localparam RTD_OFFLOAD0_SDO_MEM_ADDRESS_WIDTH = 4;
    //
    localparam RTD_NUM_OF_CS = 1;



    logic        up_clk           ;
    logic        up_rstn          ;

    logic        up_wreq          ;
    logic [13:0] up_waddr         ;
    logic [31:0] up_wdata         ;
    logic        up_wack          ;
    //
    logic        up_rreq          ;
    logic [13:0] up_raddr         ;
    logic [31:0] up_rdata         ;
    logic        up_rack          ;


    logic        tc_up_wreq [0:NUM_OF_BOARD-1];
    logic [13:0] tc_up_waddr[0:NUM_OF_BOARD-1];
    logic [31:0] tc_up_wdata[0:NUM_OF_BOARD-1];
    logic        tc_up_wack [0:NUM_OF_BOARD-1];
    //
    logic        tc_up_rreq [0:NUM_OF_BOARD-1];
    logic [13:0] tc_up_raddr[0:NUM_OF_BOARD-1];
    logic [31:0] tc_up_rdata[0:NUM_OF_BOARD-1];
    logic        tc_up_rack [0:NUM_OF_BOARD-1];


    logic        rtd_up_wreq [0:NUM_OF_BOARD-1];
    logic [13:0] rtd_up_waddr[0:NUM_OF_BOARD-1];
    logic [31:0] rtd_up_wdata[0:NUM_OF_BOARD-1];
    logic        rtd_up_wack [0:NUM_OF_BOARD-1];
    //
    logic        rtd_up_rreq [0:NUM_OF_BOARD-1];
    logic [13:0] rtd_up_raddr[0:NUM_OF_BOARD-1];
    logic [31:0] rtd_up_rdata[0:NUM_OF_BOARD-1];
    logic        rtd_up_rack [0:NUM_OF_BOARD-1];


    logic        tc_sdi_valid[0:NUM_OF_BOARD-1];
    logic        tc_sdi_ready[0:NUM_OF_BOARD-1];
    logic [ 7:0] tc_sdi_data [0:NUM_OF_BOARD-1];

    logic        rtd_sdi_valid[0:NUM_OF_BOARD-1];
    logic        rtd_sdi_ready[0:NUM_OF_BOARD-1];
    logic [ 7:0] rtd_sdi_data [0:NUM_OF_BOARD-1];

    /* Signal mapping */

    assign up_clk  = aclk;
    assign up_rstn = aresetn;


    (* keep_hierarchy="yes" *)
    up_axi i_up_axi (
        .up_clk        (up_clk        ),
        .up_rstn       (up_rstn       ),
        //
        .up_axi_awvalid(s_axi_awvalid),
        .up_axi_awaddr (s_axi_awaddr ),
        .up_axi_awready(s_axi_awready),
        //
        .up_axi_wvalid (s_axi_wvalid ),
        .up_axi_wdata  (s_axi_wdata  ),
        .up_axi_wstrb  (s_axi_wstrb  ),
        .up_axi_wready (s_axi_wready ),
        //
        .up_axi_bvalid (s_axi_bvalid ),
        .up_axi_bresp  (s_axi_bresp  ),
        .up_axi_bready (s_axi_bready ),
        //
        .up_axi_arvalid(s_axi_arvalid),
        .up_axi_araddr (s_axi_araddr ),
        .up_axi_arready(s_axi_arready),
        //
        .up_axi_rvalid (s_axi_rvalid ),
        .up_axi_rresp  (s_axi_rresp  ),
        .up_axi_rdata  (s_axi_rdata  ),
        .up_axi_rready (s_axi_rready ),
        //
        .up_wreq       (up_wreq       ),
        .up_waddr      (up_waddr      ),
        .up_wdata      (up_wdata      ),
        .up_wack       (up_wack       ),
        //
        .up_rreq       (up_rreq       ),
        .up_raddr      (up_raddr      ),
        .up_rdata      (up_rdata      ),
        .up_rack       (up_rack       )
    );


    (* keep_hierarchy="yes" *)
    axi_ad7124_amap i_axi_ad7124_amap (
        .up_clk      (up_clk      ),
        .up_rstn     (up_rstn     ),
        //
        .up_wreq     (up_wreq     ),
        .up_waddr    (up_waddr    ),
        .up_wdata    (up_wdata    ),
        .up_wack     (up_wack     ),
        .up_rreq     (up_rreq     ),
        .up_raddr    (up_raddr    ),
        .up_rdata    (up_rdata    ),
        .up_rack     (up_rack     ),
        //
        .tc_up_wreq  (tc_up_wreq  ),
        .tc_up_waddr (tc_up_waddr ),
        .tc_up_wdata (tc_up_wdata ),
        .tc_up_wack  (tc_up_wack  ),
        .tc_up_rreq  (tc_up_rreq  ),
        .tc_up_raddr (tc_up_raddr ),
        .tc_up_rdata (tc_up_rdata ),
        .tc_up_rack  (tc_up_rack  ),
        //
        .rtd_up_wreq (rtd_up_wreq ),
        .rtd_up_waddr(rtd_up_waddr),
        .rtd_up_wdata(rtd_up_wdata),
        .rtd_up_wack (rtd_up_wack ),
        .rtd_up_rreq (rtd_up_rreq ),
        .rtd_up_raddr(rtd_up_raddr),
        .rtd_up_rdata(rtd_up_rdata),
        .rtd_up_rack (rtd_up_rack )
    );


    (* keep_hierarchy="yes" *)
    axi_ad7124_buf i_axi_ad7124_buf (
        .aclk         (aclk         ),
        .aresetn      (aresetn      ),
        //
        .tc_sdi_valid (tc_sdi_valid ),
        .tc_sdi_ready (tc_sdi_ready ),
        .tc_sdi_data  (tc_sdi_data  ),
        //
        .rtd_sdi_valid(rtd_sdi_valid),
        .rtd_sdi_ready(rtd_sdi_ready),
        .rtd_sdi_data (rtd_sdi_data ),
        //
        .bram_clk     (bram_clk     ),
        .bram_rst     (bram_rst     ),
        .bram_en      (bram_en      ),
        .bram_we      (bram_we      ),
        .bram_addr    (bram_addr    ),
        .bram_wrdata  (bram_wrdata  ),
        .bram_rddata  (bram_rddata  )
    );


    generate
        for (genvar i = 0; i < NUM_OF_BOARD; i ++) begin : g_tc

            (* keep_hierarchy="yes" *)
            axi_ad7124_channel #(
                .ID                            (i                                ),
                .CMD_FIFO_ADDRESS_WIDTH        (TC_CMD_FIFO_ADDRESS_WIDTH        ),
                .SYNC_FIFO_ADDRESS_WIDTH       (TC_SYNC_FIFO_ADDRESS_WIDTH       ),
                .SDO_FIFO_ADDRESS_WIDTH        (TC_SDO_FIFO_ADDRESS_WIDTH        ),
                .SDI_FIFO_ADDRESS_WIDTH        (TC_SDI_FIFO_ADDRESS_WIDTH        ),
                .OFFLOAD0_CMD_MEM_ADDRESS_WIDTH(TC_OFFLOAD0_CMD_MEM_ADDRESS_WIDTH),
                .OFFLOAD0_SDO_MEM_ADDRESS_WIDTH(TC_OFFLOAD0_SDO_MEM_ADDRESS_WIDTH),
                .NUM_OF_CS                     (TC_NUM_OF_CS                     )
            ) i_axi_ad7124_channel (
                .up_clk           (up_clk                                                ),
                .up_rstn          (up_rstn                                               ),
                .up_wreq          (tc_up_wreq      [i]                                   ),
                .up_waddr         (tc_up_waddr     [i]                                   ),
                .up_wdata         (tc_up_wdata     [i]                                   ),
                .up_wack          (tc_up_wack      [i]                                   ),
                .up_rreq          (tc_up_rreq      [i]                                   ),
                .up_raddr         (tc_up_raddr     [i]                                   ),
                .up_rdata         (tc_up_rdata     [i]                                   ),
                .up_rack          (tc_up_rack      [i]                                   ),
                .irq              (/* Not used */                                        ),
                .offload_sdi_valid(tc_sdi_valid    [i]                                   ),
                .offload_sdi_ready(tc_sdi_ready    [i]                                   ),
                .offload_sdi_data (tc_sdi_data     [i]                                   ),
                .phy_sclk_i       (GX_TC_SPI_SCLK_i[i]                                   ),
                .phy_sclk_o       (GX_TC_SPI_SCLK_o[i]                                   ),
                .phy_sclk_t       (GX_TC_SPI_SCLK_t[i]                                   ),
                .phy_cs_i         (GX_TC_SPI_CSN_i [((i+1)*TC_NUM_OF_CS-1)-:TC_NUM_OF_CS]),
                .phy_cs_o         (GX_TC_SPI_CSN_o [((i+1)*TC_NUM_OF_CS-1)-:TC_NUM_OF_CS]),
                .phy_cs_t         (GX_TC_SPI_CSN_t [((i+1)*TC_NUM_OF_CS-1)-:TC_NUM_OF_CS]),
                .phy_mosi_i       (GX_TC_SPI_SDO_i [i]                                   ),
                .phy_mosi_o       (GX_TC_SPI_SDO_o [i]                                   ),
                .phy_mosi_t       (GX_TC_SPI_SDO_t [i]                                   ),
                .phy_miso_i       (GX_TC_SPI_SDI_i [i]                                   ),
                .phy_miso_o       (GX_TC_SPI_SDI_o [i]                                   ),
                .phy_miso_t       (GX_TC_SPI_SDI_t [i]                                   )
            );

        end

        for (genvar i = 0; i < NUM_OF_BOARD; i ++) begin : g_rtd

            (* keep_hierarchy="yes" *)
            axi_ad7124_channel #(
                .ID                            (32'h00000100 + i                  ),
                .CMD_FIFO_ADDRESS_WIDTH        (RTD_CMD_FIFO_ADDRESS_WIDTH        ),
                .SYNC_FIFO_ADDRESS_WIDTH       (RTD_SYNC_FIFO_ADDRESS_WIDTH       ),
                .SDO_FIFO_ADDRESS_WIDTH        (RTD_SDO_FIFO_ADDRESS_WIDTH        ),
                .SDI_FIFO_ADDRESS_WIDTH        (RTD_SDI_FIFO_ADDRESS_WIDTH        ),
                .OFFLOAD0_CMD_MEM_ADDRESS_WIDTH(RTD_OFFLOAD0_CMD_MEM_ADDRESS_WIDTH),
                .OFFLOAD0_SDO_MEM_ADDRESS_WIDTH(RTD_OFFLOAD0_SDO_MEM_ADDRESS_WIDTH),
                .NUM_OF_CS                     (RTD_NUM_OF_CS                     )
            ) i_axi_ad7124_channel (
                .up_clk           (up_clk                                                   ),
                .up_rstn          (up_rstn                                                  ),
                .up_wreq          (rtd_up_wreq      [i]                                     ),
                .up_waddr         (rtd_up_waddr     [i]                                     ),
                .up_wdata         (rtd_up_wdata     [i]                                     ),
                .up_wack          (rtd_up_wack      [i]                                     ),
                .up_rreq          (rtd_up_rreq      [i]                                     ),
                .up_raddr         (rtd_up_raddr     [i]                                     ),
                .up_rdata         (rtd_up_rdata     [i]                                     ),
                .up_rack          (rtd_up_rack      [i]                                     ),
                .irq              (/* Not used */                                           ),
                .offload_sdi_valid(rtd_sdi_valid    [i]                                     ),
                .offload_sdi_ready(rtd_sdi_ready    [i]                                     ),
                .offload_sdi_data (rtd_sdi_data     [i]                                     ),
                .phy_sclk_i       (GX_RTD_SPI_SCLK_i[i]                                     ),
                .phy_sclk_o       (GX_RTD_SPI_SCLK_o[i]                                     ),
                .phy_sclk_t       (GX_RTD_SPI_SCLK_t[i]                                     ),
                .phy_cs_i         (GX_RTD_SPI_CSN_i [((i+1)*RTD_NUM_OF_CS-1)-:RTD_NUM_OF_CS]),
                .phy_cs_o         (GX_RTD_SPI_CSN_o [((i+1)*RTD_NUM_OF_CS-1)-:RTD_NUM_OF_CS]),
                .phy_cs_t         (GX_RTD_SPI_CSN_t [((i+1)*RTD_NUM_OF_CS-1)-:RTD_NUM_OF_CS]),
                .phy_mosi_i       (GX_RTD_SPI_SDO_i [i]                                     ),
                .phy_mosi_o       (GX_RTD_SPI_SDO_o [i]                                     ),
                .phy_mosi_t       (GX_RTD_SPI_SDO_t [i]                                     ),
                .phy_miso_i       (GX_RTD_SPI_SDI_i [i]                                     ),
                .phy_miso_o       (GX_RTD_SPI_SDI_o [i]                                     ),
                .phy_miso_t       (GX_RTD_SPI_SDI_t [i]                                     )
            );

        end
    endgenerate

endmodule
