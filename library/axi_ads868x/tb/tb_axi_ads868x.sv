/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_axi_ads868x ();

    // AXI4-Lite
    //===========
    logic aclk    = 0;
    logic aresetn = 0;
    //
    logic [31:0] s_axi_awaddr  = 0;
    logic [ 2:0] s_axi_awprot  = 0;
    logic        s_axi_awvalid = 0;
    logic        s_axi_awready = 0;
    //
    logic [31:0] s_axi_wdata  = 0;
    logic [ 3:0] s_axi_wstrb  = 0;
    logic        s_axi_wvalid = 0;
    logic        s_axi_wready = 0;
    //
    logic [1:0]  s_axi_bresp  = 0;
    logic        s_axi_bvalid = 0;
    logic        s_axi_bready = 0;
    //
    logic [31:0] s_axi_araddr  = 0;
    logic [ 2:0] s_axi_arprot  = 0;
    logic        s_axi_arvalid = 0;
    logic        s_axi_arready = 0;
    //
    logic [31:0] s_axi_rdata  = 0;
    logic [ 1:0] s_axi_rresp  = 0;
    logic        s_axi_rvalid = 0;
    logic        s_axi_rready = 0;

    // Fabric
    //========
    //
    logic [31:0] m_axis_tdata  = 0;
    logic        m_axis_tvalid = 0;
    logic        m_axis_tready = 0;
    //
    logic pps = 0;

    // ADS868x
    //=========
    logic SCK_I = 0;
    logic SCK_O = 0;
    logic SCK_T = 0;
    logic SS_I  = 0;
    logic SS_O  = 0;
    logic SS_T  = 0;
    logic IO0_I = 0;
    logic IO0_O = 0; // MO
    logic IO0_T = 0;
    logic IO1_I = 0; // MI
    logic IO1_O = 0;
    logic IO1_T = 0;
    //
    logic RST_PD_N = 0;

    // Analog MUX
    //=============================
    logic CH_SEL_A0 = 0;
    logic CH_SEL_A1 = 0;
    logic CH_SEL_A2 = 0;
    //
    logic EN_TCH_A = 0;
    logic EN_PCH_A = 0;
    logic EN_TCH_B = 0;
    logic EN_PCH_B = 0;

    always #4 aclk = !aclk;

    initial begin
        $display("Simulation starts.");
        aresetn = 0;
        #100;
        aresetn = 1;
        $display("Resetn donw.");

        #100000;
        $display("Simulation ends.");
    end

    axi_ads868x UUT ( .* );

endmodule

`default_nettype wire
