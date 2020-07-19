//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.1 (win64) Build 2902540 Wed May 27 19:54:49 MDT 2020
//Date        : Sun Jul 19 22:43:58 2020
//Host        : Kele20e running 64-bit major release  (build 9200)
//Command     : generate_target system_wrapper.bd
//Design      : system_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module system_wrapper
   (DDR_0_addr,
    DDR_0_ba,
    DDR_0_cas_n,
    DDR_0_ck_n,
    DDR_0_ck_p,
    DDR_0_cke,
    DDR_0_cs_n,
    DDR_0_dm,
    DDR_0_dq,
    DDR_0_dqs_n,
    DDR_0_dqs_p,
    DDR_0_odt,
    DDR_0_ras_n,
    DDR_0_reset_n,
    DDR_0_we_n,
    FIXED_IO_0_ddr_vrn,
    FIXED_IO_0_ddr_vrp,
    FIXED_IO_0_mio,
    FIXED_IO_0_ps_clk,
    FIXED_IO_0_ps_porb,
    FIXED_IO_0_ps_srstb,
    G0_Relay_Ctrl_0,
    G1_ANA_POW_EN_0,
    G1_ANA_POW_EN_1_0,
    G1_ANA_POW_EN_2_0,
    G1_ANA_POW_EN_3_0,
    G1_ANA_POW_EN_4_0,
    G1_ANA_POW_EN_5_0,
    G1_Relay_Ctrl_0,
    G2_Relay_Ctrl_0,
    G3_Relay_Ctrl_0,
    G4_Relay_Ctrl_0,
    G5_Relay_Ctrl_0,
    PL_LED_TEST_0,
    RTD_cs_n_0,
    RTD_cs_n_1_0,
    RTD_cs_n_2_0,
    RTD_cs_n_3_0,
    RTD_cs_n_4_0,
    RTD_cs_n_5_0,
    RTD_sclk_0,
    RTD_sclk_1_0,
    RTD_sclk_2_0,
    RTD_sclk_3_0,
    RTD_sclk_4_0,
    RTD_sclk_5_0,
    RTD_sdi_0,
    RTD_sdi_1_0,
    RTD_sdi_2_0,
    RTD_sdi_3_0,
    RTD_sdi_4_0,
    RTD_sdi_5_0,
    RTD_sdo_0,
    RTD_sdo_1_0,
    RTD_sdo_2_0,
    RTD_sdo_3_0,
    RTD_sdo_4_0,
    RTD_sdo_5_0,
    SYNC_0,
    SYNC_1_0,
    SYNC_2_0,
    SYNC_3_0,
    SYNC_4_0,
    SYNC_5_0,
    TC_cs_n_0,
    TC_cs_n_1_0,
    TC_cs_n_2_0,
    TC_cs_n_3_0,
    TC_cs_n_4_0,
    TC_cs_n_5_0,
    TC_sclk_0,
    TC_sclk_1_0,
    TC_sclk_2_0,
    TC_sclk_3_0,
    TC_sclk_4_0,
    TC_sclk_5_0,
    TC_sdi_0,
    TC_sdi_1_0,
    TC_sdi_2_0,
    TC_sdi_3_0,
    TC_sdi_4_0,
    TC_sdi_5_0,
    TC_sdo_0,
    TC_sdo_1_0,
    TC_sdo_2_0,
    TC_sdo_3_0,
    TC_sdo_4_0,
    TC_sdo_5_0,
    rst_0);
  inout [14:0]DDR_0_addr;
  inout [2:0]DDR_0_ba;
  inout DDR_0_cas_n;
  inout DDR_0_ck_n;
  inout DDR_0_ck_p;
  inout DDR_0_cke;
  inout DDR_0_cs_n;
  inout [3:0]DDR_0_dm;
  inout [31:0]DDR_0_dq;
  inout [3:0]DDR_0_dqs_n;
  inout [3:0]DDR_0_dqs_p;
  inout DDR_0_odt;
  inout DDR_0_ras_n;
  inout DDR_0_reset_n;
  inout DDR_0_we_n;
  inout FIXED_IO_0_ddr_vrn;
  inout FIXED_IO_0_ddr_vrp;
  inout [53:0]FIXED_IO_0_mio;
  inout FIXED_IO_0_ps_clk;
  inout FIXED_IO_0_ps_porb;
  inout FIXED_IO_0_ps_srstb;
  output G0_Relay_Ctrl_0;
  output G1_ANA_POW_EN_0;
  output G1_ANA_POW_EN_1_0;
  output G1_ANA_POW_EN_2_0;
  output G1_ANA_POW_EN_3_0;
  output G1_ANA_POW_EN_4_0;
  output G1_ANA_POW_EN_5_0;
  output G1_Relay_Ctrl_0;
  output G2_Relay_Ctrl_0;
  output G3_Relay_Ctrl_0;
  output G4_Relay_Ctrl_0;
  output G5_Relay_Ctrl_0;
  output PL_LED_TEST_0;
  output RTD_cs_n_0;
  output RTD_cs_n_1_0;
  output RTD_cs_n_2_0;
  output RTD_cs_n_3_0;
  output RTD_cs_n_4_0;
  output RTD_cs_n_5_0;
  output RTD_sclk_0;
  output RTD_sclk_1_0;
  output RTD_sclk_2_0;
  output RTD_sclk_3_0;
  output RTD_sclk_4_0;
  output RTD_sclk_5_0;
  output RTD_sdi_0;
  output RTD_sdi_1_0;
  output RTD_sdi_2_0;
  output RTD_sdi_3_0;
  output RTD_sdi_4_0;
  output RTD_sdi_5_0;
  input RTD_sdo_0;
  input RTD_sdo_1_0;
  input RTD_sdo_2_0;
  input RTD_sdo_3_0;
  input RTD_sdo_4_0;
  input RTD_sdo_5_0;
  output SYNC_0;
  output SYNC_1_0;
  output SYNC_2_0;
  output SYNC_3_0;
  output SYNC_4_0;
  output SYNC_5_0;
  output [7:0]TC_cs_n_0;
  output [7:0]TC_cs_n_1_0;
  output [7:0]TC_cs_n_2_0;
  output [7:0]TC_cs_n_3_0;
  output [7:0]TC_cs_n_4_0;
  output [7:0]TC_cs_n_5_0;
  output TC_sclk_0;
  output TC_sclk_1_0;
  output TC_sclk_2_0;
  output TC_sclk_3_0;
  output TC_sclk_4_0;
  output TC_sclk_5_0;
  output TC_sdi_0;
  output TC_sdi_1_0;
  output TC_sdi_2_0;
  output TC_sdi_3_0;
  output TC_sdi_4_0;
  output TC_sdi_5_0;
  input TC_sdo_0;
  input TC_sdo_1_0;
  input TC_sdo_2_0;
  input TC_sdo_3_0;
  input TC_sdo_4_0;
  input TC_sdo_5_0;
  input rst_0;

  wire [14:0]DDR_0_addr;
  wire [2:0]DDR_0_ba;
  wire DDR_0_cas_n;
  wire DDR_0_ck_n;
  wire DDR_0_ck_p;
  wire DDR_0_cke;
  wire DDR_0_cs_n;
  wire [3:0]DDR_0_dm;
  wire [31:0]DDR_0_dq;
  wire [3:0]DDR_0_dqs_n;
  wire [3:0]DDR_0_dqs_p;
  wire DDR_0_odt;
  wire DDR_0_ras_n;
  wire DDR_0_reset_n;
  wire DDR_0_we_n;
  wire FIXED_IO_0_ddr_vrn;
  wire FIXED_IO_0_ddr_vrp;
  wire [53:0]FIXED_IO_0_mio;
  wire FIXED_IO_0_ps_clk;
  wire FIXED_IO_0_ps_porb;
  wire FIXED_IO_0_ps_srstb;
  wire G0_Relay_Ctrl_0;
  wire G1_ANA_POW_EN_0;
  wire G1_ANA_POW_EN_1_0;
  wire G1_ANA_POW_EN_2_0;
  wire G1_ANA_POW_EN_3_0;
  wire G1_ANA_POW_EN_4_0;
  wire G1_ANA_POW_EN_5_0;
  wire G1_Relay_Ctrl_0;
  wire G2_Relay_Ctrl_0;
  wire G3_Relay_Ctrl_0;
  wire G4_Relay_Ctrl_0;
  wire G5_Relay_Ctrl_0;
  wire PL_LED_TEST_0;
  wire RTD_cs_n_0;
  wire RTD_cs_n_1_0;
  wire RTD_cs_n_2_0;
  wire RTD_cs_n_3_0;
  wire RTD_cs_n_4_0;
  wire RTD_cs_n_5_0;
  wire RTD_sclk_0;
  wire RTD_sclk_1_0;
  wire RTD_sclk_2_0;
  wire RTD_sclk_3_0;
  wire RTD_sclk_4_0;
  wire RTD_sclk_5_0;
  wire RTD_sdi_0;
  wire RTD_sdi_1_0;
  wire RTD_sdi_2_0;
  wire RTD_sdi_3_0;
  wire RTD_sdi_4_0;
  wire RTD_sdi_5_0;
  wire RTD_sdo_0;
  wire RTD_sdo_1_0;
  wire RTD_sdo_2_0;
  wire RTD_sdo_3_0;
  wire RTD_sdo_4_0;
  wire RTD_sdo_5_0;
  wire SYNC_0;
  wire SYNC_1_0;
  wire SYNC_2_0;
  wire SYNC_3_0;
  wire SYNC_4_0;
  wire SYNC_5_0;
  wire [7:0]TC_cs_n_0;
  wire [7:0]TC_cs_n_1_0;
  wire [7:0]TC_cs_n_2_0;
  wire [7:0]TC_cs_n_3_0;
  wire [7:0]TC_cs_n_4_0;
  wire [7:0]TC_cs_n_5_0;
  wire TC_sclk_0;
  wire TC_sclk_1_0;
  wire TC_sclk_2_0;
  wire TC_sclk_3_0;
  wire TC_sclk_4_0;
  wire TC_sclk_5_0;
  wire TC_sdi_0;
  wire TC_sdi_1_0;
  wire TC_sdi_2_0;
  wire TC_sdi_3_0;
  wire TC_sdi_4_0;
  wire TC_sdi_5_0;
  wire TC_sdo_0;
  wire TC_sdo_1_0;
  wire TC_sdo_2_0;
  wire TC_sdo_3_0;
  wire TC_sdo_4_0;
  wire TC_sdo_5_0;
  wire rst_0;

  system system_i
       (.DDR_0_addr(DDR_0_addr),
        .DDR_0_ba(DDR_0_ba),
        .DDR_0_cas_n(DDR_0_cas_n),
        .DDR_0_ck_n(DDR_0_ck_n),
        .DDR_0_ck_p(DDR_0_ck_p),
        .DDR_0_cke(DDR_0_cke),
        .DDR_0_cs_n(DDR_0_cs_n),
        .DDR_0_dm(DDR_0_dm),
        .DDR_0_dq(DDR_0_dq),
        .DDR_0_dqs_n(DDR_0_dqs_n),
        .DDR_0_dqs_p(DDR_0_dqs_p),
        .DDR_0_odt(DDR_0_odt),
        .DDR_0_ras_n(DDR_0_ras_n),
        .DDR_0_reset_n(DDR_0_reset_n),
        .DDR_0_we_n(DDR_0_we_n),
        .FIXED_IO_0_ddr_vrn(FIXED_IO_0_ddr_vrn),
        .FIXED_IO_0_ddr_vrp(FIXED_IO_0_ddr_vrp),
        .FIXED_IO_0_mio(FIXED_IO_0_mio),
        .FIXED_IO_0_ps_clk(FIXED_IO_0_ps_clk),
        .FIXED_IO_0_ps_porb(FIXED_IO_0_ps_porb),
        .FIXED_IO_0_ps_srstb(FIXED_IO_0_ps_srstb),
        .G0_Relay_Ctrl_0(G0_Relay_Ctrl_0),
        .G1_ANA_POW_EN_0(G1_ANA_POW_EN_0),
        .G1_ANA_POW_EN_1_0(G1_ANA_POW_EN_1_0),
        .G1_ANA_POW_EN_2_0(G1_ANA_POW_EN_2_0),
        .G1_ANA_POW_EN_3_0(G1_ANA_POW_EN_3_0),
        .G1_ANA_POW_EN_4_0(G1_ANA_POW_EN_4_0),
        .G1_ANA_POW_EN_5_0(G1_ANA_POW_EN_5_0),
        .G1_Relay_Ctrl_0(G1_Relay_Ctrl_0),
        .G2_Relay_Ctrl_0(G2_Relay_Ctrl_0),
        .G3_Relay_Ctrl_0(G3_Relay_Ctrl_0),
        .G4_Relay_Ctrl_0(G4_Relay_Ctrl_0),
        .G5_Relay_Ctrl_0(G5_Relay_Ctrl_0),
        .PL_LED_TEST_0(PL_LED_TEST_0),
        .RTD_cs_n_0(RTD_cs_n_0),
        .RTD_cs_n_1_0(RTD_cs_n_1_0),
        .RTD_cs_n_2_0(RTD_cs_n_2_0),
        .RTD_cs_n_3_0(RTD_cs_n_3_0),
        .RTD_cs_n_4_0(RTD_cs_n_4_0),
        .RTD_cs_n_5_0(RTD_cs_n_5_0),
        .RTD_sclk_0(RTD_sclk_0),
        .RTD_sclk_1_0(RTD_sclk_1_0),
        .RTD_sclk_2_0(RTD_sclk_2_0),
        .RTD_sclk_3_0(RTD_sclk_3_0),
        .RTD_sclk_4_0(RTD_sclk_4_0),
        .RTD_sclk_5_0(RTD_sclk_5_0),
        .RTD_sdi_0(RTD_sdi_0),
        .RTD_sdi_1_0(RTD_sdi_1_0),
        .RTD_sdi_2_0(RTD_sdi_2_0),
        .RTD_sdi_3_0(RTD_sdi_3_0),
        .RTD_sdi_4_0(RTD_sdi_4_0),
        .RTD_sdi_5_0(RTD_sdi_5_0),
        .RTD_sdo_0(RTD_sdo_0),
        .RTD_sdo_1_0(RTD_sdo_1_0),
        .RTD_sdo_2_0(RTD_sdo_2_0),
        .RTD_sdo_3_0(RTD_sdo_3_0),
        .RTD_sdo_4_0(RTD_sdo_4_0),
        .RTD_sdo_5_0(RTD_sdo_5_0),
        .SYNC_0(SYNC_0),
        .SYNC_1_0(SYNC_1_0),
        .SYNC_2_0(SYNC_2_0),
        .SYNC_3_0(SYNC_3_0),
        .SYNC_4_0(SYNC_4_0),
        .SYNC_5_0(SYNC_5_0),
        .TC_cs_n_0(TC_cs_n_0),
        .TC_cs_n_1_0(TC_cs_n_1_0),
        .TC_cs_n_2_0(TC_cs_n_2_0),
        .TC_cs_n_3_0(TC_cs_n_3_0),
        .TC_cs_n_4_0(TC_cs_n_4_0),
        .TC_cs_n_5_0(TC_cs_n_5_0),
        .TC_sclk_0(TC_sclk_0),
        .TC_sclk_1_0(TC_sclk_1_0),
        .TC_sclk_2_0(TC_sclk_2_0),
        .TC_sclk_3_0(TC_sclk_3_0),
        .TC_sclk_4_0(TC_sclk_4_0),
        .TC_sclk_5_0(TC_sclk_5_0),
        .TC_sdi_0(TC_sdi_0),
        .TC_sdi_1_0(TC_sdi_1_0),
        .TC_sdi_2_0(TC_sdi_2_0),
        .TC_sdi_3_0(TC_sdi_3_0),
        .TC_sdi_4_0(TC_sdi_4_0),
        .TC_sdi_5_0(TC_sdi_5_0),
        .TC_sdo_0(TC_sdo_0),
        .TC_sdo_1_0(TC_sdo_1_0),
        .TC_sdo_2_0(TC_sdo_2_0),
        .TC_sdo_3_0(TC_sdo_3_0),
        .TC_sdo_4_0(TC_sdo_4_0),
        .TC_sdo_5_0(TC_sdo_5_0),
        .rst_0(rst_0));
endmodule
