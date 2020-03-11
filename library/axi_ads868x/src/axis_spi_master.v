/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

//=============================================================================
//
// Filename: spi_master.v
//
// Purpose: SPI master core with simple interface, this core was designed
//   to interface other cores easily.
//
// Note:
//   SPI Interface timing:
//
//                             ___     ___     ___     ___     ___
//      SCK   CPOL=0  ________/   \___/   \___/   \___/   \___/   \____________
//                    ________     ___     ___     ___     ___     ____________
//            CPOL=1          \___/   \___/   \___/   \___/   \___/
//
//                    ____                                             ________
//      SS                \___________________________________________/
//
//                         _______ _______ _______ _______ _______
//      MOSI/ CPHA=0  zzzzX___0___X___1___X__...__X___6___X___7___X---Xzzzzzzzz
//      MISO                   _______ _______ _______ _______ _______
//            CPHA=1  zzzz----X___0___X___1___X__...__X___6___X___7___Xzzzzzzzz
//
// Limitation:
//   This core is fixed CPOL = 0 and CPHA = 1. That means both master and salve
//   (this core) will drive MOSI/MISO at rising edge of SCK, and should sample
//   MISO/MOSI at falling edge.
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module axis_spi_master #(parameter CLK_RATIO   = 8) (
    // SPI
    //=====
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_I" *)
    input  wire       SS_I         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_O" *)
    output wire       SS_O         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SS_T" *)
    output wire       SS_T         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_I" *)
    input  wire       SCK_I        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_O" *)
    output wire       SCK_O        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI SCK_T" *)
    output wire       SCK_T        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_I" *)
    input  wire       IO0_I        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_O" *)
    output wire       IO0_O        , // MO
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO0_T" *)
    output wire       IO0_T        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_I" *)
    input  wire       IO1_I        , // MI
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_O" *)
    output wire       IO1_O        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI IO1_T" *)
    output wire       IO1_T        ,
    // Fabric
    //=======
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS:M_AXIS, ASSOCIATED_RESET aresetn, FREQ_HZ 100000000" *)
    input  wire       aclk         ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input  wire       aresetn      ,
    // Tx interface
    //--------------
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
    input  wire [7:0] s_axis_tdata ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
    input  wire       s_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *)
    output wire       s_axis_tready,
    // Rx interface
    //--------------
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
    output wire [7:0] m_axis_tdata ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
    output wire       m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)
    input  wire       m_axis_tready
);

    axis_spi_master_top #(.CLK_RATIO(CLK_RATIO)) inst (
        .SS_I         (SS_I         ),
        .SS_O         (SS_O         ),
        .SS_T         (SS_T         ),
        .SCK_I        (SCK_I        ),
        .SCK_O        (SCK_O        ),
        .SCK_T        (SCK_T        ),
        .IO0_I        (IO0_I        ),
        .IO0_O        (IO0_O        ),
        .IO0_T        (IO0_T        ),
        .IO1_I        (IO1_I        ),
        .IO1_O        (IO1_O        ),
        .IO1_T        (IO1_T        ),
        //
        .aclk         (aclk         ),
        .aresetn      (aresetn      ),
        //
        .s_axis_tdata (s_axis_tdata ),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        //
        .m_axis_tdata (m_axis_tdata ),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

endmodule

`default_nettype wire
