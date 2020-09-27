/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_v2_top #(
    parameter integer AXI_ADDR_WIDTH      = 16,
    parameter integer AXI_DATA_WIDTH      = 32,
    parameter integer NUM_OF_BOARD        = 6 ,
    parameter integer NUM_OF_TC_PER_BOARD = 8
) (
    // AXI4-Lite Slave I/F
    //====================
    input  var logic                                        aclk             ,
    input  var logic                                        aresetn          ,
    //
    input  var logic [                  AXI_ADDR_WIDTH-1:0] s_axi_awaddr     ,
    input  var logic [                                 2:0] s_axi_awprot     ,
    input  var logic                                        s_axi_awvalid    ,
    output var logic                                        s_axi_awready    ,
    //
    input  var logic [                  AXI_DATA_WIDTH-1:0] s_axi_wdata      ,
    input  var logic [              (AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb      ,
    input  var logic                                        s_axi_wvalid     ,
    output var logic                                        s_axi_wready     ,
    //
    output var logic [                                 1:0] s_axi_bresp      ,
    output var logic                                        s_axi_bvalid     ,
    input  var logic                                        s_axi_bready     ,
    //
    input  var logic [                  AXI_ADDR_WIDTH-1:0] s_axi_araddr     ,
    input  var logic [                                 2:0] s_axi_arprot     ,
    input  var logic                                        s_axi_arvalid    ,
    output var logic                                        s_axi_arready    ,
    //
    output var logic [                  AXI_DATA_WIDTH-1:0] s_axi_rdata      ,
    output var logic [                                 1:0] s_axi_rresp      ,
    output var logic                                        s_axi_rvalid     ,
    input  var logic                                        s_axi_rready     ,
    // IRQ
    output var logic                                        interrupt        ,
    // Time Interface
    //===============
    input  var logic                                        pps_in           ,
    //
    input  var logic [                                31:0] rtc_sec          ,
    input  var logic [                                31:0] rtc_nsec         ,
    // Control
    //========
    input  var logic                                        measure_start    ,
    output var logic                                        measure_ready    ,
    output var logic                                        measure_done     ,
    // AD Board
    //=========
    // There are 6 AD Board connected, each has two SPI interface. One interface
    // is for TC, which is 8-channel AD7124. One is for RTD ,which is 1 channel
    // AD7124.
    //
    input  var logic [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SCLK_i ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SCLK_o ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SCLK_t ,
    input  var logic [NUM_OF_TC_PER_BOARD*NUM_OF_BOARD-1:0] GX_TC_SPI_CSN_i  ,
    output var logic [NUM_OF_TC_PER_BOARD*NUM_OF_BOARD-1:0] GX_TC_SPI_CSN_o  ,
    output var logic [NUM_OF_TC_PER_BOARD*NUM_OF_BOARD-1:0] GX_TC_SPI_CSN_t  ,
    input  var logic [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDO_i  ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDO_o  ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDO_t  ,
    input  var logic [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDI_i  ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDI_o  ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDI_t  ,
    // RTD SPI
    input  var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SCLK_i,
    output var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SCLK_o,
    output var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SCLK_t,
    input  var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_CSN_i ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_CSN_o ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_CSN_t ,
    input  var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDO_i ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDO_o ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDO_t ,
    input  var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDI_i ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDI_o ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDI_t ,
    // GPIO
    output var logic [                    NUM_OF_BOARD-1:0] GX_ADC_SYNC      ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_ANA_POW_EN    ,
    output var logic [                    NUM_OF_BOARD-1:0] GX_RELAY_CTRL
);


    // TC
    localparam TC_CMD_FIFO_ADDRESS_WIDTH  = 4;
    localparam TC_SYNC_FIFO_ADDRESS_WIDTH = 4;
    localparam TC_SDO_FIFO_ADDRESS_WIDTH  = 5;
    localparam TC_SDI_FIFO_ADDRESS_WIDTH  = 5;
    // We need more space in offload block than default 4
    localparam TC_OFFLOAD0_CMD_MEM_ADDRESS_WIDTH = 5;
    localparam TC_OFFLOAD0_SDO_MEM_ADDRESS_WIDTH = 5;
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


    logic        up_wreq ;
    logic [13:0] up_waddr;
    logic [31:0] up_wdata;
    logic        up_wack ;
    //
    logic        up_rreq ;
    logic [13:0] up_raddr;
    logic [31:0] up_rdata;
    logic        up_rack ;

    logic        aux_up_wreq ;
    logic [13:0] aux_up_waddr;
    logic [31:0] aux_up_wdata;
    logic        aux_up_wack ;
    //
    logic        aux_up_rreq ;
    logic [13:0] aux_up_raddr;
    logic [31:0] aux_up_rdata;
    logic        aux_up_rack ;


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


    logic        tc_bram_en  [0:NUM_OF_BOARD-1];
    logic [ 2:0] tc_bram_addr[0:NUM_OF_BOARD-1];
    logic [31:0] tc_bram_dout[0:NUM_OF_BOARD-1];

    logic tc_sync[0:NUM_OF_BOARD-1];

    logic tc_valid[0:NUM_OF_BOARD-1];
    logic tc_ready[0:NUM_OF_BOARD-1];

    logic        rtd_bram_en  [0:NUM_OF_BOARD-1];
    logic [ 3:0] rtd_bram_addr[0:NUM_OF_BOARD-1];
    logic [31:0] rtd_bram_dout[0:NUM_OF_BOARD-1];


    logic ctrl_reset;

    logic        ctrl_measure_immediate ;
    logic        ctrl_measure_continuous;
    logic [31:0] ctrl_measure_count     ;
    logic [ 2:0] stat_measure_state     ;

    logic        ctrl_fifo_read ;
    logic [31:0] stat_fifo_data ;
    logic        stat_fifo_empty;


    (* keep_hierarchy="yes" *)
    up_axi i_up_axi (
        .up_clk        (aclk         ),
        .up_rstn       (aresetn      ),
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
        .up_wreq       (up_wreq      ),
        .up_waddr      (up_waddr     ),
        .up_wdata      (up_wdata     ),
        .up_wack       (up_wack      ),
        //
        .up_rreq       (up_rreq      ),
        .up_raddr      (up_raddr     ),
        .up_rdata      (up_rdata     ),
        .up_rack       (up_rack      )
    );


    (* keep_hierarchy="yes" *)
    axi_ad7124_amap #(.NUM_OF_BOARD(NUM_OF_BOARD)) i_axi_ad7124_amap (
        .up_clk      (aclk        ),
        .up_rstn     (aresetn     ),
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
        .aux_up_wreq (aux_up_wreq ),
        .aux_up_waddr(aux_up_waddr),
        .aux_up_wdata(aux_up_wdata),
        .aux_up_wack (aux_up_wack ),
        .aux_up_rreq (aux_up_rreq ),
        .aux_up_raddr(aux_up_raddr),
        .aux_up_rdata(aux_up_rdata),
        .aux_up_rack (aux_up_rack ),
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


    // Top level register space

    (* keep_hierarchy="yes" *)
    axi_ad7124_aux i_axi_ad7124_aux (
        .up_clk                 (aclk                   ),
        .up_rstn                (aresetn                ),
        //
        .up_wreq                (aux_up_wreq            ),
        .up_waddr               (aux_up_waddr           ),
        .up_wdata               (aux_up_wdata           ),
        .up_wack                (aux_up_wack            ),
        .up_rreq                (aux_up_rreq            ),
        .up_raddr               (aux_up_raddr           ),
        .up_rdata               (aux_up_rdata           ),
        .up_rack                (aux_up_rack            ),
        //
        .ctrl_power_en          (GX_ANA_POW_EN          ),
        .ctrl_relay_ctrl        (GX_RELAY_CTRL          ),
        //
        .ctrl_reset             (ctrl_reset             ),
        //
        .ctrl_measure_immediate (ctrl_measure_immediate ),
        .ctrl_measure_continuous(ctrl_measure_continuous),
        .ctrl_measure_count     (ctrl_measure_count     ),
        .stat_measure_state     (stat_measure_state     ),
        //
        .ctrl_fifo_read         (ctrl_fifo_read         ),
        .stat_fifo_data         (stat_fifo_data         ),
        .stat_fifo_empty        (stat_fifo_empty        )
    );


    // Center FSM

    (* keep_hierarchy="yes" *)
    axi_ad7124_fusion #(.NUM_OF_BOARD(NUM_OF_BOARD)) i_axi_ad7124_fusion (
        .clk                    (aclk                   ),
        .resetn                 (aresetn                ),
        //
        .rtc_sec                (rtc_sec                ),
        .rtc_nsec               (rtc_nsec               ),
        //
        .tc_bram_en             (tc_bram_en             ),
        .tc_bram_addr           (tc_bram_addr           ),
        .tc_bram_dout           (tc_bram_dout           ),
        //
        .tc_sync                (tc_sync                ),
        //
        .tc_valid               (tc_valid               ),
        .tc_ready               (tc_ready               ),
        //
        .rtd_bram_en            (rtd_bram_en            ),
        .rtd_bram_addr          (rtd_bram_addr          ),
        .rtd_bram_dout          (rtd_bram_dout          ),
        //
        .measure_start          (measure_start          ),
        .measure_ready          (measure_ready          ),
        .measure_done           (measure_done           ),
        //
        .ctrl_reset             (ctrl_reset             ),
        //
        .ctrl_measure_immediate (ctrl_measure_immediate ),
        .ctrl_measure_continuous(ctrl_measure_continuous),
        .ctrl_measure_count     (ctrl_measure_count     ),
        .stat_measure_state     (stat_measure_state     ),
        //
        .ctrl_fifo_read         (ctrl_fifo_read         ),
        .stat_fifo_data         (stat_fifo_data         ),
        .stat_fifo_empty        (stat_fifo_empty        ),
        //
        .irq                    (interrupt              )
    );


    generate

        for (genvar i = 0; i < NUM_OF_BOARD; i ++) begin : g_tc

            (* keep_hierarchy="yes" *)
            axi_ad7124_tc_channel #(
                .ID                            (i                                ),
                .CMD_FIFO_ADDRESS_WIDTH        (TC_CMD_FIFO_ADDRESS_WIDTH        ),
                .SYNC_FIFO_ADDRESS_WIDTH       (TC_SYNC_FIFO_ADDRESS_WIDTH       ),
                .SDO_FIFO_ADDRESS_WIDTH        (TC_SDO_FIFO_ADDRESS_WIDTH        ),
                .SDI_FIFO_ADDRESS_WIDTH        (TC_SDI_FIFO_ADDRESS_WIDTH        ),
                .OFFLOAD0_CMD_MEM_ADDRESS_WIDTH(TC_OFFLOAD0_CMD_MEM_ADDRESS_WIDTH),
                .OFFLOAD0_SDO_MEM_ADDRESS_WIDTH(TC_OFFLOAD0_SDO_MEM_ADDRESS_WIDTH),
                .NUM_OF_CS                     (TC_NUM_OF_CS                     )
            ) i_axi_ad7124_tc_channel (
                .up_clk    (aclk                                                  ),
                .up_rstn   (aresetn                                               ),
                .up_wreq   (tc_up_wreq      [i]                                   ),
                .up_waddr  (tc_up_waddr     [i]                                   ),
                .up_wdata  (tc_up_wdata     [i]                                   ),
                .up_wack   (tc_up_wack      [i]                                   ),
                .up_rreq   (tc_up_rreq      [i]                                   ),
                .up_raddr  (tc_up_raddr     [i]                                   ),
                .up_rdata  (tc_up_rdata     [i]                                   ),
                .up_rack   (tc_up_rack      [i]                                   ),
                .irq       (/* Not used */                                        ),
                //
                .bram_en   (tc_bram_en      [i]                                   ),
                .bram_addr (tc_bram_addr    [i]                                   ),
                .bram_dout (tc_bram_dout    [i]                                   ),
                //
                .data_valid(tc_valid        [i]                                   ),
                .data_ready(tc_ready        [i]                                   ),
                //
                .phy_sclk_i(GX_TC_SPI_SCLK_i[i]                                   ),
                .phy_sclk_o(GX_TC_SPI_SCLK_o[i]                                   ),
                .phy_sclk_t(GX_TC_SPI_SCLK_t[i]                                   ),
                .phy_cs_i  (GX_TC_SPI_CSN_i [((i+1)*TC_NUM_OF_CS-1)-:TC_NUM_OF_CS]),
                .phy_cs_o  (GX_TC_SPI_CSN_o [((i+1)*TC_NUM_OF_CS-1)-:TC_NUM_OF_CS]),
                .phy_cs_t  (GX_TC_SPI_CSN_t [((i+1)*TC_NUM_OF_CS-1)-:TC_NUM_OF_CS]),
                .phy_mosi_i(GX_TC_SPI_SDO_i [i]                                   ),
                .phy_mosi_o(GX_TC_SPI_SDO_o [i]                                   ),
                .phy_mosi_t(GX_TC_SPI_SDO_t [i]                                   ),
                .phy_miso_i(GX_TC_SPI_SDI_i [i]                                   ),
                .phy_miso_o(GX_TC_SPI_SDI_o [i]                                   ),
                .phy_miso_t(GX_TC_SPI_SDI_t [i]                                   )
            );

            assign GX_ADC_SYNC[i] = tc_sync[i];

        end

        for (genvar i = 0; i < NUM_OF_BOARD; i ++) begin : g_rtd

            (* keep_hierarchy="yes" *)
            axi_ad7124_rtd_channel #(
                .ID                            (32'h00000100 + i                  ),
                .CMD_FIFO_ADDRESS_WIDTH        (RTD_CMD_FIFO_ADDRESS_WIDTH        ),
                .SYNC_FIFO_ADDRESS_WIDTH       (RTD_SYNC_FIFO_ADDRESS_WIDTH       ),
                .SDO_FIFO_ADDRESS_WIDTH        (RTD_SDO_FIFO_ADDRESS_WIDTH        ),
                .SDI_FIFO_ADDRESS_WIDTH        (RTD_SDI_FIFO_ADDRESS_WIDTH        ),
                .OFFLOAD0_CMD_MEM_ADDRESS_WIDTH(RTD_OFFLOAD0_CMD_MEM_ADDRESS_WIDTH),
                .OFFLOAD0_SDO_MEM_ADDRESS_WIDTH(RTD_OFFLOAD0_SDO_MEM_ADDRESS_WIDTH),
                .NUM_OF_CS                     (RTD_NUM_OF_CS                     )
            ) i_axi_ad7124_rtd_channel (
                .up_clk    (aclk                                                     ),
                .up_rstn   (aresetn                                                  ),
                .up_wreq   (rtd_up_wreq      [i]                                     ),
                .up_waddr  (rtd_up_waddr     [i]                                     ),
                .up_wdata  (rtd_up_wdata     [i]                                     ),
                .up_wack   (rtd_up_wack      [i]                                     ),
                .up_rreq   (rtd_up_rreq      [i]                                     ),
                .up_raddr  (rtd_up_raddr     [i]                                     ),
                .up_rdata  (rtd_up_rdata     [i]                                     ),
                .up_rack   (rtd_up_rack      [i]                                     ),
                .irq       (/* Not used */                                           ),
                //
                .pps_in    (pps_in                                                   ),
                //
                .bram_en   (rtd_bram_en      [i]                                     ),
                .bram_addr (rtd_bram_addr    [i]                                     ),
                .bram_dout (rtd_bram_dout    [i]                                     ),
                //
                .phy_sclk_i(GX_RTD_SPI_SCLK_i[i]                                     ),
                .phy_sclk_o(GX_RTD_SPI_SCLK_o[i]                                     ),
                .phy_sclk_t(GX_RTD_SPI_SCLK_t[i]                                     ),
                .phy_cs_i  (GX_RTD_SPI_CSN_i [((i+1)*RTD_NUM_OF_CS-1)-:RTD_NUM_OF_CS]),
                .phy_cs_o  (GX_RTD_SPI_CSN_o [((i+1)*RTD_NUM_OF_CS-1)-:RTD_NUM_OF_CS]),
                .phy_cs_t  (GX_RTD_SPI_CSN_t [((i+1)*RTD_NUM_OF_CS-1)-:RTD_NUM_OF_CS]),
                .phy_mosi_i(GX_RTD_SPI_SDO_i [i]                                     ),
                .phy_mosi_o(GX_RTD_SPI_SDO_o [i]                                     ),
                .phy_mosi_t(GX_RTD_SPI_SDO_t [i]                                     ),
                .phy_miso_i(GX_RTD_SPI_SDI_i [i]                                     ),
                .phy_miso_o(GX_RTD_SPI_SDI_o [i]                                     ),
                .phy_miso_t(GX_RTD_SPI_SDI_t [i]                                     )
            );

        end
    endgenerate

endmodule

`default_nettype wire
