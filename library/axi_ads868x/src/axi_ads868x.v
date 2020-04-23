/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads868x #(parameter C_ADDR_WIDTH = 10) (
    // AXI4-Lite
    //===========
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI:M_AXIS, ASSOCIATED_RESET aresetn, FREQ_HZ 125000000" *)
    input  wire        aclk          ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire        aresetn       ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input  wire [31:0] s_axi_awaddr  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
    input  wire [ 2:0] s_axi_awprot  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
    input  wire        s_axi_awvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
    output wire        s_axi_awready ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input  wire [31:0] s_axi_wdata   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
    input  wire [ 3:0] s_axi_wstrb   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
    input  wire        s_axi_wvalid  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
    output wire        s_axi_wready  ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
    output wire [ 1:0] s_axi_bresp   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
    output wire        s_axi_bvalid  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
    input  wire        s_axi_bready  ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input  wire [31:0] s_axi_araddr  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
    input  wire [ 2:0] s_axi_arprot  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input  wire        s_axi_arvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
    output wire        s_axi_arready ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output wire [31:0] s_axi_rdata   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output wire [ 1:0] s_axi_rresp   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output wire        s_axi_rvalid  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input  wire        s_axi_rready  ,
    // Fabric
    //========
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
    output wire [31:0] m_axis_tdata  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
    output wire        m_axis_tvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)
    input  wire        m_axis_tready ,
    //
    input  wire        pps           ,
    // ADS868x
    //=========
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_I" *)
    input  wire        SCK_I         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_O" *)
    output wire        SCK_O         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_T" *)
    output wire        SCK_T         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_I" *)
    input  wire        SS_I          ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_O" *)
    output wire        SS_O          ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_T" *)
    output wire        SS_T          ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_I" *)
    input  wire        IO0_I         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_O" *)
    output wire        IO0_O         , // MO
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_T" *)
    output wire        IO0_T         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_I" *)
    input  wire        IO1_I         , // MI
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_O" *)
    output wire        IO1_O         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_T" *)
    output wire        IO1_T         ,
    //
    output wire        RST_PD_N      ,
    // Analog MUX
    //============
    output wire        CH_SEL_A0     ,
    output wire        CH_SEL_A1     ,
    output wire        CH_SEL_A2     ,
    //
    output wire        EN_TCH_A      ,
    output wire        EN_PCH_A      ,
    output wire        EN_TCH_B      ,
    output wire        EN_PCH_B
);

    axi_ads868x_top #(
        .C_ADDR_WIDTH(C_ADDR_WIDTH)
    ) inst (
        //
        .aclk          (aclk          ),
        .aresetn       (aresetn       ),
        //
        .s_axi_awaddr  (s_axi_awaddr  ),
        .s_axi_awprot  (s_axi_awprot  ),
        .s_axi_awvalid (s_axi_awvalid ),
        .s_axi_awready (s_axi_awready ),
        //
        .s_axi_wdata   (s_axi_wdata   ),
        .s_axi_wstrb   (s_axi_wstrb   ),
        .s_axi_wvalid  (s_axi_wvalid  ),
        .s_axi_wready  (s_axi_wready  ),
        //
        .s_axi_bresp   (s_axi_bresp   ),
        .s_axi_bvalid  (s_axi_bvalid  ),
        .s_axi_bready  (s_axi_bready  ),
        //
        .s_axi_araddr  (s_axi_araddr  ),
        .s_axi_arprot  (s_axi_arprot  ),
        .s_axi_arvalid (s_axi_arvalid ),
        .s_axi_arready (s_axi_arready ),
        //
        .s_axi_rdata   (s_axi_rdata   ),
        .s_axi_rresp   (s_axi_rresp   ),
        .s_axi_rvalid  (s_axi_rvalid  ),
        .s_axi_rready  (s_axi_rready  ),
        //
        .m_axis_tdata  (m_axis_tdata  ),
        .m_axis_tvalid (m_axis_tvalid ),
        .m_axis_tready (m_axis_tready ),
        //
        .pps           (pps           ),
        //
        .SCK_I         (SCK_I         ),
        .SCK_O         (SCK_O         ),
        .SCK_T         (SCK_T         ),
        .SS_I          (SS_I          ),
        .SS_O          (SS_O          ),
        .SS_T          (SS_T          ),
        .IO0_I         (IO0_I         ),
        .IO0_O         (IO0_O         ),
        .IO0_T         (IO0_T         ),
        .IO1_I         (IO1_I         ),
        .IO1_O         (IO1_O         ),
        .IO1_T         (IO1_T         ),
        //
        .RST_PD_N      (RST_PD_N      ),
        //
        .CH_SEL_A0     (CH_SEL_A0     ),
        .CH_SEL_A1     (CH_SEL_A1     ),
        .CH_SEL_A2     (CH_SEL_A2     ),
        //
        .EN_TCH_A      (EN_TCH_A      ),
        .EN_PCH_A      (EN_PCH_A      ),
        .EN_TCH_B      (EN_TCH_B      ),
        .EN_PCH_B      (EN_PCH_B      )
    );

endmodule

`default_nettype wire
