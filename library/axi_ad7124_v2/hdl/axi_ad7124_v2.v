/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ad7124_v2 #(
    parameter integer AXI_ADDR_WIDTH      = 32,
    parameter integer AXI_DATA_WIDTH      = 32,
    parameter integer NUM_OF_BOARD        = 6 ,
    parameter integer NUM_OF_TC_PER_BOARD = 8
) (
    // AXI4-Lite Slave I/F
    //====================
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET aresetn" *)
    input  wire                                        aclk             ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire                                        aresetn          ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input  wire [                  AXI_ADDR_WIDTH-1:0] s_axi_awaddr     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
    input  wire [                                 2:0] s_axi_awprot     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
    input  wire                                        s_axi_awvalid    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
    output wire                                        s_axi_awready    ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input  wire [                  AXI_DATA_WIDTH-1:0] s_axi_wdata      ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
    input  wire [              (AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb      ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
    input  wire                                        s_axi_wvalid     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
    output wire                                        s_axi_wready     ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
    output wire [                                 1:0] s_axi_bresp      ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
    output wire                                        s_axi_bvalid     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
    input  wire                                        s_axi_bready     ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input  wire [                  AXI_ADDR_WIDTH-1:0] s_axi_araddr     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
    input  wire [                                 2:0] s_axi_arprot     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input  wire                                        s_axi_arvalid    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
    output wire                                        s_axi_arready    ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output wire [                  AXI_DATA_WIDTH-1:0] s_axi_rdata      ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output wire [                                 1:0] s_axi_rresp      ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output wire                                        s_axi_rvalid     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input  wire                                        s_axi_rready     ,
    // IRQ
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 interrupt INTERRUPT" *)
    (* X_INTERFACE_PARAMETER = "SENSITIVITY EDGE_RISING" *)
    output wire                                        interrupt        ,
    // BRAM I/F
    //=========
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM CLK" *)
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL" *)
    output wire                                        bram_clk         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM RST" *)
    output wire                                        bram_rst         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM EN" *)
    output wire                                        bram_en          ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM WE" *)
    output wire [                                 3:0] bram_we          ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM ADDR" *)
    output wire [                                12:0] bram_addr        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM DIN" *)
    output wire [                                31:0] bram_wrdata      ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM DOUT" *)
    input  wire [                                31:0] bram_rddata      ,
    // AD Board
    //=========
    // There are 6 AD Board connected, each has two SPI interface. One interface
    // is for TC, which is 8-channel AD7124. One is for RTD ,which is 1 channel
    // AD7124.
    //
    // GX Board
    //---------
    // TC SPI
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_SCLK TRI_I" *)
    input  wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SCLK_i ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_SCLK TRI_O" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SCLK_o ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_SCLK TRI_T" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SCLK_t ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_CSN TRI_I" *)
    input  wire [NUM_OF_TC_PER_BOARD*NUM_OF_BOARD-1:0] GX_TC_SPI_CSN_i  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_CSN TRI_O" *)
    output wire [NUM_OF_TC_PER_BOARD*NUM_OF_BOARD-1:0] GX_TC_SPI_CSN_o  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_CSN TRI_T" *)
    output wire [NUM_OF_TC_PER_BOARD*NUM_OF_BOARD-1:0] GX_TC_SPI_CSN_t  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_SDO TRI_I" *)
    input  wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDO_i  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_SDO TRI_O" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDO_o  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_SDO TRI_T" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDO_t  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_SDI TRI_I" *)
    input  wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDI_i  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_SDI TRI_O" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDI_o  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_TC_SPI_SDI TRI_T" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_TC_SPI_SDI_t  ,
    // RTD SPI
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_SCLK TRI_I" *)
    input  wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SCLK_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_SCLK TRI_O" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SCLK_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_SCLK TRI_T" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SCLK_t,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_CSN TRI_I" *)
    input  wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_CSN_i ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_CSN TRI_O" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_CSN_o ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_CSN TRI_T" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_CSN_t ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_SDO TRI_I" *)
    input  wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDO_i ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_SDO TRI_O" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDO_o ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_SDO TRI_T" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDO_t ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_SDI TRI_I" *)
    input  wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDI_i ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_SDI TRI_O" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDI_o ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 GX_RTD_SPI_SDI TRI_T" *)
    output wire [                    NUM_OF_BOARD-1:0] GX_RTD_SPI_SDI_t ,
    // GPIO
    output wire [                    NUM_OF_BOARD-1:0] GX_ADC_SYNC      ,
    output wire [                    NUM_OF_BOARD-1:0] GX_ANA_POW_EN    ,
    output wire [                    NUM_OF_BOARD-1:0] GX_RELAY_CTRL
);


    axi_ad7124_v2_top #(
        .AXI_ADDR_WIDTH     (AXI_ADDR_WIDTH     ),
        .AXI_DATA_WIDTH     (AXI_DATA_WIDTH     ),
        .NUM_OF_BOARD       (NUM_OF_BOARD       ),
        .NUM_OF_TC_PER_BOARD(NUM_OF_TC_PER_BOARD)
    ) i_axi_ad7124_v2_top (
        .aclk             (aclk             ),
        .aresetn          (aresetn          ),
        //
        .s_axi_awaddr     (s_axi_awaddr     ),
        .s_axi_awprot     (s_axi_awprot     ),
        .s_axi_awvalid    (s_axi_awvalid    ),
        .s_axi_awready    (s_axi_awready    ),
        //
        .s_axi_wdata      (s_axi_wdata      ),
        .s_axi_wstrb      (s_axi_wstrb      ),
        .s_axi_wvalid     (s_axi_wvalid     ),
        .s_axi_wready     (s_axi_wready     ),
        //
        .s_axi_bresp      (s_axi_bresp      ),
        .s_axi_bvalid     (s_axi_bvalid     ),
        .s_axi_bready     (s_axi_bready     ),
        //
        .s_axi_araddr     (s_axi_araddr     ),
        .s_axi_arprot     (s_axi_arprot     ),
        .s_axi_arvalid    (s_axi_arvalid    ),
        .s_axi_arready    (s_axi_arready    ),
        //
        .s_axi_rdata      (s_axi_rdata      ),
        .s_axi_rresp      (s_axi_rresp      ),
        .s_axi_rvalid     (s_axi_rvalid     ),
        .s_axi_rready     (s_axi_rready     ),
        //
        .interrupt        (interrupt        ),
        //BRAM
        //====
        .bram_clk         (bram_clk         ),
        .bram_rst         (bram_rst         ),
        .bram_en          (bram_en          ),
        .bram_we          (bram_we          ),
        .bram_addr        (bram_addr        ),
        .bram_wrdata      (bram_wrdata      ),
        .bram_rddata      (bram_rddata      ),
        // AD Board
        //=========
        .GX_TC_SPI_SCLK_i (GX_TC_SPI_SCLK_i ),
        .GX_TC_SPI_SCLK_o (GX_TC_SPI_SCLK_o ),
        .GX_TC_SPI_SCLK_t (GX_TC_SPI_SCLK_t ),
        .GX_TC_SPI_CSN_i  (GX_TC_SPI_CSN_i  ),
        .GX_TC_SPI_CSN_o  (GX_TC_SPI_CSN_o  ),
        .GX_TC_SPI_CSN_t  (GX_TC_SPI_CSN_t  ),
        .GX_TC_SPI_SDO_i  (GX_TC_SPI_SDO_i  ),
        .GX_TC_SPI_SDO_o  (GX_TC_SPI_SDO_o  ),
        .GX_TC_SPI_SDO_t  (GX_TC_SPI_SDO_t  ),
        .GX_TC_SPI_SDI_i  (GX_TC_SPI_SDI_i  ),
        .GX_TC_SPI_SDI_o  (GX_TC_SPI_SDI_o  ),
        .GX_TC_SPI_SDI_t  (GX_TC_SPI_SDI_t  ),
        //
        .GX_RTD_SPI_SCLK_i(GX_RTD_SPI_SCLK_i),
        .GX_RTD_SPI_SCLK_o(GX_RTD_SPI_SCLK_o),
        .GX_RTD_SPI_SCLK_t(GX_RTD_SPI_SCLK_t),
        .GX_RTD_SPI_CSN_i (GX_RTD_SPI_CSN_i ),
        .GX_RTD_SPI_CSN_o (GX_RTD_SPI_CSN_o ),
        .GX_RTD_SPI_CSN_t (GX_RTD_SPI_CSN_t ),
        .GX_RTD_SPI_SDO_i (GX_RTD_SPI_SDO_i ),
        .GX_RTD_SPI_SDO_o (GX_RTD_SPI_SDO_o ),
        .GX_RTD_SPI_SDO_t (GX_RTD_SPI_SDO_t ),
        .GX_RTD_SPI_SDI_i (GX_RTD_SPI_SDI_i ),
        .GX_RTD_SPI_SDI_o (GX_RTD_SPI_SDI_o ),
        .GX_RTD_SPI_SDI_t (GX_RTD_SPI_SDI_t ),
        //
        .GX_ADC_SYNC      (GX_ADC_SYNC      ),
        .GX_ANA_POW_EN    (GX_ANA_POW_EN    ),
        .GX_RELAY_CTRL    (GX_RELAY_CTRL    )
    );


endmodule

`default_nettype wire
