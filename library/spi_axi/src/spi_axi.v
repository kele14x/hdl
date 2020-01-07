/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module spi_axi (
    // SPI
    //=====
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_I" *)
    input  wire        SS_I         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_O" *)
    output wire        SS_O         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_T" *)
    output wire        SS_T         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_I" *)
    input  wire        SCK_I        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_O" *)
    output wire        SCK_O        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_T" *)
    output wire        SCK_T        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_I" *)
    input  wire        IO0_I        , // SI
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_O" *)
    output wire        IO0_O        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_T" *)
    output wire        IO0_T        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_I" *)
    input  wire        IO1_I        , // SO
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_O" *)
    output wire        IO1_O        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_T" *)
    output wire        IO1_T        ,
    // AXI4 Lite Master
    //=================
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI_LITE, ASSOCIATED_RESET aresetn" *)
    input  wire        aclk         ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire        aresetn      ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE AWADDR" *)
    output wire [31:0] m_axi_awaddr ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE AWPROT" *)
    output wire [ 2:0] m_axi_awprot ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE AWVALID" *)
    output wire        m_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE AWREADY" *)
    input  wire        m_axi_awready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE WDATA" *)
    output wire [31:0] m_axi_wdata  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE WSTRB" *)
    output wire [ 3:0] m_axi_wstrb  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE WVALID" *)
    output wire        m_axi_wvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE WREADY" *)
    input  wire        m_axi_wready ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE BRESP" *)
    input  wire [ 1:0] m_axi_bresp  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE BVALID" *)
    input  wire        m_axi_bvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE BREADY" *)
    output wire        m_axi_bready ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE ARADDR" *)
    output wire [31:0] m_axi_araddr ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE ARPROT" *)
    output wire [ 2:0] m_axi_arprot ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE ARVALID" *)
    output wire        m_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE ARREADY" *)
    input  wire        m_axi_arready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE RDATA" *)
    input  wire [31:0] m_axi_rdata  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE RRESP" *)
    input  wire [ 1:0] m_axi_rresp  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE RVALID" *)
    input  wire        m_axi_rvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_LITE RREADY" *)
    output wire        m_axi_rready
);

    spi_axi_top inst (
        // SPI
        //=====
        .SS_I          (SS_I          ),
        .SS_O          (SS_O          ),
        .SS_T          (SS_T          ),
        .SCK_I         (SCK_I         ),
        .SCK_O         (SCK_O         ),
        .SCK_T         (SCK_T         ),
        .IO0_I         (IO0_I         ),
        .IO0_O         (IO0_O         ),
        .IO0_T         (IO0_T         ),
        .IO1_I         (IO1_I         ),
        .IO1_O         (IO1_O         ),
        .IO1_T         (IO1_T         ),
        // AXI
        //=====
        .aclk          (aclk          ),
        .aresetn       (aresetn       ),
        //
        .m_axi_awaddr  (m_axi_awaddr  ),
        .m_axi_awprot  (m_axi_awprot  ),
        .m_axi_awvalid (m_axi_awvalid ),
        .m_axi_awready (m_axi_awready ),
        //
        .m_axi_wdata   (m_axi_wdata   ),
        .m_axi_wstrb   (m_axi_wstrb   ),
        .m_axi_wvalid  (m_axi_wvalid  ),
        .m_axi_wready  (m_axi_wready  ),
        //
        .m_axi_bresp   (m_axi_bresp   ),
        .m_axi_bvalid  (m_axi_bvalid  ),
        .m_axi_bready  (m_axi_bready  ),
        //
        .m_axi_araddr  (m_axi_araddr  ),
        .m_axi_arprot  (m_axi_arprot  ),
        .m_axi_arvalid (m_axi_arvalid ),
        .m_axi_arready (m_axi_arready ),
        //
        .m_axi_rdata   (m_axi_rdata   ),
        .m_axi_rresp   (m_axi_rresp   ),
        .m_axi_rvalid  (m_axi_rvalid  ),
        .m_axi_rready  (m_axi_rready  )
    );

endmodule

`default_nettype wire
