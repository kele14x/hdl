/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads868x #(parameter C_ADDR_WIDTH = 10) (
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
    output wire [55:0] m_axis_tdata  ,
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
