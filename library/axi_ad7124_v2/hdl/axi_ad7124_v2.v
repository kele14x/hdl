/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ad7124_v2 #(
    parameter integer C_AXI_ADDR_WIDTH = 32,
    parameter integer C_AXI_DATA_WIDTH = 32,
    parameter integer C_N_ADC_BOARD    = 6 ,
    parameter integer C_N_TC_CHANNEL   = 8
) (
    // AXI4-Lite Slave I/F
    //====================
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET aresetn" *)
    input  wire                                    aclk           ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire                                    aresetn        ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input  wire [            C_AXI_ADDR_WIDTH-1:0] s_axi_awaddr   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
    input  wire [                             2:0] s_axi_awprot   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
    input  wire                                    s_axi_awvalid  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
    output wire                                    s_axi_awready  ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input  wire [            C_AXI_DATA_WIDTH-1:0] s_axi_wdata    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
    input  wire [        (C_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
    input  wire                                    s_axi_wvalid   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
    output wire                                    s_axi_wready   ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
    output wire [                             1:0] s_axi_bresp    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
    output wire                                    s_axi_bvalid   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
    input  wire                                    s_axi_bready   ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input  wire [            C_AXI_ADDR_WIDTH-1:0] s_axi_araddr   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
    input  wire [                             2:0] s_axi_arprot   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input  wire                                    s_axi_arvalid  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AREADY" *)
    output wire                                    s_axi_arready  ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output wire [            C_AXI_DATA_WIDTH-1:0] s_axi_rdata    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output wire [                             1:0] s_axi_rresp    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output wire                                    s_axi_rvalid   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input  wire                                    s_axi_rready   ,
    // IRQ
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 interrupt INTERRUPT" *)
    (* X_INTERFACE_PARAMETER = "SENSITIVITY EDGE_RISING" *)
    output wire                                    interrupt      ,
    // AD Board
    //=========
    // There are 6 AD Board connected, each has two SPI interface. One interface
    // is for TC, which is 8-channel AD7124. One is for RTD ,which is 1 channel
    // AD7124.
    //
    // GX Board
    //---------
    // TC SPI
    inout  wire [               C_N_ADC_BOARD-1:0] GX_TC_SPI_SCLK ,
    inout  wire [C_N_TC_CHANNEL*C_N_ADC_BOARD-1:0] GX_TC_SPI_CSN  ,
    inout  wire [               C_N_ADC_BOARD-1:0] GX_TC_SPI_SDI  ,
    inout  wire [               C_N_ADC_BOARD-1:0] GX_TC_SPI_SDO  ,
    // RTD SPI
    inout  wire [               C_N_ADC_BOARD-1:0] GX_RTD_SPI_SDO ,
    inout  wire [               C_N_ADC_BOARD-1:0] GX_RTD_SPI_CSN ,
    inout  wire [               C_N_ADC_BOARD-1:0] GX_RTD_SPI_SCLK,
    inout  wire [               C_N_ADC_BOARD-1:0] GX_RTD_SPI_SDI ,
    // GPIO
    output wire [               C_N_ADC_BOARD-1:0] GX_ADC_SYNC    ,
    output wire [               C_N_ADC_BOARD-1:0] GX_ANA_POW_EN  ,
    output wire [               C_N_ADC_BOARD-1:0] GX_RELAY_CTRL
);


    axi_ad7124_v2_top #(
        .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
        .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
        .C_N_ADC_BOARD   (C_N_ADC_BOARD   ),
        .C_N_TC_CHANNEL  (C_N_TC_CHANNEL  )
    ) i_axi_ad7124_v2_top (
        .aclk           (aclk           ),
        .aresetn        (aresetn        ),
        //
        .s_axi_awaddr   (s_axi_awaddr   ),
        .s_axi_awprot   (s_axi_awprot   ),
        .s_axi_awvalid  (s_axi_awvalid  ),
        .s_axi_awready  (s_axi_awready  ),
        //
        .s_axi_wdata    (s_axi_wdata    ),
        .s_axi_wstrb    (s_axi_wstrb    ),
        .s_axi_wvalid   (s_axi_wvalid   ),
        .s_axi_wready   (s_axi_wready   ),
        //
        .s_axi_bresp    (s_axi_bresp    ),
        .s_axi_bvalid   (s_axi_bvalid   ),
        .s_axi_bready   (s_axi_bready   ),
        //
        .s_axi_araddr   (s_axi_araddr   ),
        .s_axi_arprot   (s_axi_arprot   ),
        .s_axi_arvalid  (s_axi_arvalid  ),
        .s_axi_arready  (s_axi_arready  ),
        //
        .s_axi_rdata    (s_axi_rdata    ),
        .s_axi_rresp    (s_axi_rresp    ),
        .s_axi_rvalid   (s_axi_rvalid   ),
        .s_axi_rready   (s_axi_rready   ),
        //
        .interrupt      (interrupt      ),
        //
        .GX_TC_SPI_SCLK (GX_TC_SPI_SCLK ),
        .GX_TC_SPI_CSN  (GX_TC_SPI_CSN  ),
        .GX_TC_SPI_SDI  (GX_TC_SPI_SDI  ),
        .GX_TC_SPI_SDO  (GX_TC_SPI_SDO  ),
        //
        .GX_RTD_SPI_SDO (GX_RTD_SPI_SDO ),
        .GX_RTD_SPI_CS_N(GX_RTD_SPI_CSN ),
        .GX_RTD_SPI_SCLK(GX_RTD_SPI_SCLK),
        .GX_RTD_SPI_SDI (GX_RTD_SPI_SDI ),
        //
        .GX_ADC_SYNC    (GX_ADC_SYNC    ),
        .GX_ANA_POW_EN  (GX_ANA_POW_EN  ),
        .GX_RELAY_CTRL  (GX_RELAY_CTRL  )
    );


endmodule

`default_nettype wire
