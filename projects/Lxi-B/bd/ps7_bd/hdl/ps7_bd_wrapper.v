//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.1 (win64) Build 2902540 Wed May 27 19:54:49 MDT 2020
//Date        : Wed Jul 22 10:47:03 2020
//Host        : CN-00002823 running 64-bit major release  (build 9200)
//Command     : generate_target ps7_bd_wrapper.bd
//Design      : ps7_bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ps7_bd_wrapper
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    GX_ADC_SYNC,
    GX_ANA_POW_EN,
    GX_RELAY_CTRL,
    GX_RTD_SPI_CSN_tri_io,
    GX_RTD_SPI_SCLK_tri_io,
    GX_RTD_SPI_SDI_tri_io,
    GX_RTD_SPI_SDO_tri_io,
    GX_TC_SPI_CSN_tri_io,
    GX_TC_SPI_SCLK_tri_io,
    GX_TC_SPI_SDI_tri_io,
    GX_TC_SPI_SDO_tri_io);
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  output [5:0]GX_ADC_SYNC;
  output [5:0]GX_ANA_POW_EN;
  output [5:0]GX_RELAY_CTRL;
  inout [5:0]GX_RTD_SPI_CSN_tri_io;
  inout [5:0]GX_RTD_SPI_SCLK_tri_io;
  inout [5:0]GX_RTD_SPI_SDI_tri_io;
  inout [5:0]GX_RTD_SPI_SDO_tri_io;
  inout [47:0]GX_TC_SPI_CSN_tri_io;
  inout [5:0]GX_TC_SPI_SCLK_tri_io;
  inout [5:0]GX_TC_SPI_SDI_tri_io;
  inout [5:0]GX_TC_SPI_SDO_tri_io;

  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire [5:0]GX_ADC_SYNC;
  wire [5:0]GX_ANA_POW_EN;
  wire [5:0]GX_RELAY_CTRL;
  wire [0:0]GX_RTD_SPI_CSN_tri_i_0;
  wire [1:1]GX_RTD_SPI_CSN_tri_i_1;
  wire [2:2]GX_RTD_SPI_CSN_tri_i_2;
  wire [3:3]GX_RTD_SPI_CSN_tri_i_3;
  wire [4:4]GX_RTD_SPI_CSN_tri_i_4;
  wire [5:5]GX_RTD_SPI_CSN_tri_i_5;
  wire [0:0]GX_RTD_SPI_CSN_tri_io_0;
  wire [1:1]GX_RTD_SPI_CSN_tri_io_1;
  wire [2:2]GX_RTD_SPI_CSN_tri_io_2;
  wire [3:3]GX_RTD_SPI_CSN_tri_io_3;
  wire [4:4]GX_RTD_SPI_CSN_tri_io_4;
  wire [5:5]GX_RTD_SPI_CSN_tri_io_5;
  wire [0:0]GX_RTD_SPI_CSN_tri_o_0;
  wire [1:1]GX_RTD_SPI_CSN_tri_o_1;
  wire [2:2]GX_RTD_SPI_CSN_tri_o_2;
  wire [3:3]GX_RTD_SPI_CSN_tri_o_3;
  wire [4:4]GX_RTD_SPI_CSN_tri_o_4;
  wire [5:5]GX_RTD_SPI_CSN_tri_o_5;
  wire [0:0]GX_RTD_SPI_CSN_tri_t_0;
  wire [1:1]GX_RTD_SPI_CSN_tri_t_1;
  wire [2:2]GX_RTD_SPI_CSN_tri_t_2;
  wire [3:3]GX_RTD_SPI_CSN_tri_t_3;
  wire [4:4]GX_RTD_SPI_CSN_tri_t_4;
  wire [5:5]GX_RTD_SPI_CSN_tri_t_5;
  wire [0:0]GX_RTD_SPI_SCLK_tri_i_0;
  wire [1:1]GX_RTD_SPI_SCLK_tri_i_1;
  wire [2:2]GX_RTD_SPI_SCLK_tri_i_2;
  wire [3:3]GX_RTD_SPI_SCLK_tri_i_3;
  wire [4:4]GX_RTD_SPI_SCLK_tri_i_4;
  wire [5:5]GX_RTD_SPI_SCLK_tri_i_5;
  wire [0:0]GX_RTD_SPI_SCLK_tri_io_0;
  wire [1:1]GX_RTD_SPI_SCLK_tri_io_1;
  wire [2:2]GX_RTD_SPI_SCLK_tri_io_2;
  wire [3:3]GX_RTD_SPI_SCLK_tri_io_3;
  wire [4:4]GX_RTD_SPI_SCLK_tri_io_4;
  wire [5:5]GX_RTD_SPI_SCLK_tri_io_5;
  wire [0:0]GX_RTD_SPI_SCLK_tri_o_0;
  wire [1:1]GX_RTD_SPI_SCLK_tri_o_1;
  wire [2:2]GX_RTD_SPI_SCLK_tri_o_2;
  wire [3:3]GX_RTD_SPI_SCLK_tri_o_3;
  wire [4:4]GX_RTD_SPI_SCLK_tri_o_4;
  wire [5:5]GX_RTD_SPI_SCLK_tri_o_5;
  wire [0:0]GX_RTD_SPI_SCLK_tri_t_0;
  wire [1:1]GX_RTD_SPI_SCLK_tri_t_1;
  wire [2:2]GX_RTD_SPI_SCLK_tri_t_2;
  wire [3:3]GX_RTD_SPI_SCLK_tri_t_3;
  wire [4:4]GX_RTD_SPI_SCLK_tri_t_4;
  wire [5:5]GX_RTD_SPI_SCLK_tri_t_5;
  wire [0:0]GX_RTD_SPI_SDI_tri_i_0;
  wire [1:1]GX_RTD_SPI_SDI_tri_i_1;
  wire [2:2]GX_RTD_SPI_SDI_tri_i_2;
  wire [3:3]GX_RTD_SPI_SDI_tri_i_3;
  wire [4:4]GX_RTD_SPI_SDI_tri_i_4;
  wire [5:5]GX_RTD_SPI_SDI_tri_i_5;
  wire [0:0]GX_RTD_SPI_SDI_tri_io_0;
  wire [1:1]GX_RTD_SPI_SDI_tri_io_1;
  wire [2:2]GX_RTD_SPI_SDI_tri_io_2;
  wire [3:3]GX_RTD_SPI_SDI_tri_io_3;
  wire [4:4]GX_RTD_SPI_SDI_tri_io_4;
  wire [5:5]GX_RTD_SPI_SDI_tri_io_5;
  wire [0:0]GX_RTD_SPI_SDI_tri_o_0;
  wire [1:1]GX_RTD_SPI_SDI_tri_o_1;
  wire [2:2]GX_RTD_SPI_SDI_tri_o_2;
  wire [3:3]GX_RTD_SPI_SDI_tri_o_3;
  wire [4:4]GX_RTD_SPI_SDI_tri_o_4;
  wire [5:5]GX_RTD_SPI_SDI_tri_o_5;
  wire [0:0]GX_RTD_SPI_SDI_tri_t_0;
  wire [1:1]GX_RTD_SPI_SDI_tri_t_1;
  wire [2:2]GX_RTD_SPI_SDI_tri_t_2;
  wire [3:3]GX_RTD_SPI_SDI_tri_t_3;
  wire [4:4]GX_RTD_SPI_SDI_tri_t_4;
  wire [5:5]GX_RTD_SPI_SDI_tri_t_5;
  wire [0:0]GX_RTD_SPI_SDO_tri_i_0;
  wire [1:1]GX_RTD_SPI_SDO_tri_i_1;
  wire [2:2]GX_RTD_SPI_SDO_tri_i_2;
  wire [3:3]GX_RTD_SPI_SDO_tri_i_3;
  wire [4:4]GX_RTD_SPI_SDO_tri_i_4;
  wire [5:5]GX_RTD_SPI_SDO_tri_i_5;
  wire [0:0]GX_RTD_SPI_SDO_tri_io_0;
  wire [1:1]GX_RTD_SPI_SDO_tri_io_1;
  wire [2:2]GX_RTD_SPI_SDO_tri_io_2;
  wire [3:3]GX_RTD_SPI_SDO_tri_io_3;
  wire [4:4]GX_RTD_SPI_SDO_tri_io_4;
  wire [5:5]GX_RTD_SPI_SDO_tri_io_5;
  wire [0:0]GX_RTD_SPI_SDO_tri_o_0;
  wire [1:1]GX_RTD_SPI_SDO_tri_o_1;
  wire [2:2]GX_RTD_SPI_SDO_tri_o_2;
  wire [3:3]GX_RTD_SPI_SDO_tri_o_3;
  wire [4:4]GX_RTD_SPI_SDO_tri_o_4;
  wire [5:5]GX_RTD_SPI_SDO_tri_o_5;
  wire [0:0]GX_RTD_SPI_SDO_tri_t_0;
  wire [1:1]GX_RTD_SPI_SDO_tri_t_1;
  wire [2:2]GX_RTD_SPI_SDO_tri_t_2;
  wire [3:3]GX_RTD_SPI_SDO_tri_t_3;
  wire [4:4]GX_RTD_SPI_SDO_tri_t_4;
  wire [5:5]GX_RTD_SPI_SDO_tri_t_5;
  wire [0:0]GX_TC_SPI_CSN_tri_i_0;
  wire [1:1]GX_TC_SPI_CSN_tri_i_1;
  wire [10:10]GX_TC_SPI_CSN_tri_i_10;
  wire [11:11]GX_TC_SPI_CSN_tri_i_11;
  wire [12:12]GX_TC_SPI_CSN_tri_i_12;
  wire [13:13]GX_TC_SPI_CSN_tri_i_13;
  wire [14:14]GX_TC_SPI_CSN_tri_i_14;
  wire [15:15]GX_TC_SPI_CSN_tri_i_15;
  wire [16:16]GX_TC_SPI_CSN_tri_i_16;
  wire [17:17]GX_TC_SPI_CSN_tri_i_17;
  wire [18:18]GX_TC_SPI_CSN_tri_i_18;
  wire [19:19]GX_TC_SPI_CSN_tri_i_19;
  wire [2:2]GX_TC_SPI_CSN_tri_i_2;
  wire [20:20]GX_TC_SPI_CSN_tri_i_20;
  wire [21:21]GX_TC_SPI_CSN_tri_i_21;
  wire [22:22]GX_TC_SPI_CSN_tri_i_22;
  wire [23:23]GX_TC_SPI_CSN_tri_i_23;
  wire [24:24]GX_TC_SPI_CSN_tri_i_24;
  wire [25:25]GX_TC_SPI_CSN_tri_i_25;
  wire [26:26]GX_TC_SPI_CSN_tri_i_26;
  wire [27:27]GX_TC_SPI_CSN_tri_i_27;
  wire [28:28]GX_TC_SPI_CSN_tri_i_28;
  wire [29:29]GX_TC_SPI_CSN_tri_i_29;
  wire [3:3]GX_TC_SPI_CSN_tri_i_3;
  wire [30:30]GX_TC_SPI_CSN_tri_i_30;
  wire [31:31]GX_TC_SPI_CSN_tri_i_31;
  wire [32:32]GX_TC_SPI_CSN_tri_i_32;
  wire [33:33]GX_TC_SPI_CSN_tri_i_33;
  wire [34:34]GX_TC_SPI_CSN_tri_i_34;
  wire [35:35]GX_TC_SPI_CSN_tri_i_35;
  wire [36:36]GX_TC_SPI_CSN_tri_i_36;
  wire [37:37]GX_TC_SPI_CSN_tri_i_37;
  wire [38:38]GX_TC_SPI_CSN_tri_i_38;
  wire [39:39]GX_TC_SPI_CSN_tri_i_39;
  wire [4:4]GX_TC_SPI_CSN_tri_i_4;
  wire [40:40]GX_TC_SPI_CSN_tri_i_40;
  wire [41:41]GX_TC_SPI_CSN_tri_i_41;
  wire [42:42]GX_TC_SPI_CSN_tri_i_42;
  wire [43:43]GX_TC_SPI_CSN_tri_i_43;
  wire [44:44]GX_TC_SPI_CSN_tri_i_44;
  wire [45:45]GX_TC_SPI_CSN_tri_i_45;
  wire [46:46]GX_TC_SPI_CSN_tri_i_46;
  wire [47:47]GX_TC_SPI_CSN_tri_i_47;
  wire [5:5]GX_TC_SPI_CSN_tri_i_5;
  wire [6:6]GX_TC_SPI_CSN_tri_i_6;
  wire [7:7]GX_TC_SPI_CSN_tri_i_7;
  wire [8:8]GX_TC_SPI_CSN_tri_i_8;
  wire [9:9]GX_TC_SPI_CSN_tri_i_9;
  wire [0:0]GX_TC_SPI_CSN_tri_io_0;
  wire [1:1]GX_TC_SPI_CSN_tri_io_1;
  wire [10:10]GX_TC_SPI_CSN_tri_io_10;
  wire [11:11]GX_TC_SPI_CSN_tri_io_11;
  wire [12:12]GX_TC_SPI_CSN_tri_io_12;
  wire [13:13]GX_TC_SPI_CSN_tri_io_13;
  wire [14:14]GX_TC_SPI_CSN_tri_io_14;
  wire [15:15]GX_TC_SPI_CSN_tri_io_15;
  wire [16:16]GX_TC_SPI_CSN_tri_io_16;
  wire [17:17]GX_TC_SPI_CSN_tri_io_17;
  wire [18:18]GX_TC_SPI_CSN_tri_io_18;
  wire [19:19]GX_TC_SPI_CSN_tri_io_19;
  wire [2:2]GX_TC_SPI_CSN_tri_io_2;
  wire [20:20]GX_TC_SPI_CSN_tri_io_20;
  wire [21:21]GX_TC_SPI_CSN_tri_io_21;
  wire [22:22]GX_TC_SPI_CSN_tri_io_22;
  wire [23:23]GX_TC_SPI_CSN_tri_io_23;
  wire [24:24]GX_TC_SPI_CSN_tri_io_24;
  wire [25:25]GX_TC_SPI_CSN_tri_io_25;
  wire [26:26]GX_TC_SPI_CSN_tri_io_26;
  wire [27:27]GX_TC_SPI_CSN_tri_io_27;
  wire [28:28]GX_TC_SPI_CSN_tri_io_28;
  wire [29:29]GX_TC_SPI_CSN_tri_io_29;
  wire [3:3]GX_TC_SPI_CSN_tri_io_3;
  wire [30:30]GX_TC_SPI_CSN_tri_io_30;
  wire [31:31]GX_TC_SPI_CSN_tri_io_31;
  wire [32:32]GX_TC_SPI_CSN_tri_io_32;
  wire [33:33]GX_TC_SPI_CSN_tri_io_33;
  wire [34:34]GX_TC_SPI_CSN_tri_io_34;
  wire [35:35]GX_TC_SPI_CSN_tri_io_35;
  wire [36:36]GX_TC_SPI_CSN_tri_io_36;
  wire [37:37]GX_TC_SPI_CSN_tri_io_37;
  wire [38:38]GX_TC_SPI_CSN_tri_io_38;
  wire [39:39]GX_TC_SPI_CSN_tri_io_39;
  wire [4:4]GX_TC_SPI_CSN_tri_io_4;
  wire [40:40]GX_TC_SPI_CSN_tri_io_40;
  wire [41:41]GX_TC_SPI_CSN_tri_io_41;
  wire [42:42]GX_TC_SPI_CSN_tri_io_42;
  wire [43:43]GX_TC_SPI_CSN_tri_io_43;
  wire [44:44]GX_TC_SPI_CSN_tri_io_44;
  wire [45:45]GX_TC_SPI_CSN_tri_io_45;
  wire [46:46]GX_TC_SPI_CSN_tri_io_46;
  wire [47:47]GX_TC_SPI_CSN_tri_io_47;
  wire [5:5]GX_TC_SPI_CSN_tri_io_5;
  wire [6:6]GX_TC_SPI_CSN_tri_io_6;
  wire [7:7]GX_TC_SPI_CSN_tri_io_7;
  wire [8:8]GX_TC_SPI_CSN_tri_io_8;
  wire [9:9]GX_TC_SPI_CSN_tri_io_9;
  wire [0:0]GX_TC_SPI_CSN_tri_o_0;
  wire [1:1]GX_TC_SPI_CSN_tri_o_1;
  wire [10:10]GX_TC_SPI_CSN_tri_o_10;
  wire [11:11]GX_TC_SPI_CSN_tri_o_11;
  wire [12:12]GX_TC_SPI_CSN_tri_o_12;
  wire [13:13]GX_TC_SPI_CSN_tri_o_13;
  wire [14:14]GX_TC_SPI_CSN_tri_o_14;
  wire [15:15]GX_TC_SPI_CSN_tri_o_15;
  wire [16:16]GX_TC_SPI_CSN_tri_o_16;
  wire [17:17]GX_TC_SPI_CSN_tri_o_17;
  wire [18:18]GX_TC_SPI_CSN_tri_o_18;
  wire [19:19]GX_TC_SPI_CSN_tri_o_19;
  wire [2:2]GX_TC_SPI_CSN_tri_o_2;
  wire [20:20]GX_TC_SPI_CSN_tri_o_20;
  wire [21:21]GX_TC_SPI_CSN_tri_o_21;
  wire [22:22]GX_TC_SPI_CSN_tri_o_22;
  wire [23:23]GX_TC_SPI_CSN_tri_o_23;
  wire [24:24]GX_TC_SPI_CSN_tri_o_24;
  wire [25:25]GX_TC_SPI_CSN_tri_o_25;
  wire [26:26]GX_TC_SPI_CSN_tri_o_26;
  wire [27:27]GX_TC_SPI_CSN_tri_o_27;
  wire [28:28]GX_TC_SPI_CSN_tri_o_28;
  wire [29:29]GX_TC_SPI_CSN_tri_o_29;
  wire [3:3]GX_TC_SPI_CSN_tri_o_3;
  wire [30:30]GX_TC_SPI_CSN_tri_o_30;
  wire [31:31]GX_TC_SPI_CSN_tri_o_31;
  wire [32:32]GX_TC_SPI_CSN_tri_o_32;
  wire [33:33]GX_TC_SPI_CSN_tri_o_33;
  wire [34:34]GX_TC_SPI_CSN_tri_o_34;
  wire [35:35]GX_TC_SPI_CSN_tri_o_35;
  wire [36:36]GX_TC_SPI_CSN_tri_o_36;
  wire [37:37]GX_TC_SPI_CSN_tri_o_37;
  wire [38:38]GX_TC_SPI_CSN_tri_o_38;
  wire [39:39]GX_TC_SPI_CSN_tri_o_39;
  wire [4:4]GX_TC_SPI_CSN_tri_o_4;
  wire [40:40]GX_TC_SPI_CSN_tri_o_40;
  wire [41:41]GX_TC_SPI_CSN_tri_o_41;
  wire [42:42]GX_TC_SPI_CSN_tri_o_42;
  wire [43:43]GX_TC_SPI_CSN_tri_o_43;
  wire [44:44]GX_TC_SPI_CSN_tri_o_44;
  wire [45:45]GX_TC_SPI_CSN_tri_o_45;
  wire [46:46]GX_TC_SPI_CSN_tri_o_46;
  wire [47:47]GX_TC_SPI_CSN_tri_o_47;
  wire [5:5]GX_TC_SPI_CSN_tri_o_5;
  wire [6:6]GX_TC_SPI_CSN_tri_o_6;
  wire [7:7]GX_TC_SPI_CSN_tri_o_7;
  wire [8:8]GX_TC_SPI_CSN_tri_o_8;
  wire [9:9]GX_TC_SPI_CSN_tri_o_9;
  wire [0:0]GX_TC_SPI_CSN_tri_t_0;
  wire [1:1]GX_TC_SPI_CSN_tri_t_1;
  wire [10:10]GX_TC_SPI_CSN_tri_t_10;
  wire [11:11]GX_TC_SPI_CSN_tri_t_11;
  wire [12:12]GX_TC_SPI_CSN_tri_t_12;
  wire [13:13]GX_TC_SPI_CSN_tri_t_13;
  wire [14:14]GX_TC_SPI_CSN_tri_t_14;
  wire [15:15]GX_TC_SPI_CSN_tri_t_15;
  wire [16:16]GX_TC_SPI_CSN_tri_t_16;
  wire [17:17]GX_TC_SPI_CSN_tri_t_17;
  wire [18:18]GX_TC_SPI_CSN_tri_t_18;
  wire [19:19]GX_TC_SPI_CSN_tri_t_19;
  wire [2:2]GX_TC_SPI_CSN_tri_t_2;
  wire [20:20]GX_TC_SPI_CSN_tri_t_20;
  wire [21:21]GX_TC_SPI_CSN_tri_t_21;
  wire [22:22]GX_TC_SPI_CSN_tri_t_22;
  wire [23:23]GX_TC_SPI_CSN_tri_t_23;
  wire [24:24]GX_TC_SPI_CSN_tri_t_24;
  wire [25:25]GX_TC_SPI_CSN_tri_t_25;
  wire [26:26]GX_TC_SPI_CSN_tri_t_26;
  wire [27:27]GX_TC_SPI_CSN_tri_t_27;
  wire [28:28]GX_TC_SPI_CSN_tri_t_28;
  wire [29:29]GX_TC_SPI_CSN_tri_t_29;
  wire [3:3]GX_TC_SPI_CSN_tri_t_3;
  wire [30:30]GX_TC_SPI_CSN_tri_t_30;
  wire [31:31]GX_TC_SPI_CSN_tri_t_31;
  wire [32:32]GX_TC_SPI_CSN_tri_t_32;
  wire [33:33]GX_TC_SPI_CSN_tri_t_33;
  wire [34:34]GX_TC_SPI_CSN_tri_t_34;
  wire [35:35]GX_TC_SPI_CSN_tri_t_35;
  wire [36:36]GX_TC_SPI_CSN_tri_t_36;
  wire [37:37]GX_TC_SPI_CSN_tri_t_37;
  wire [38:38]GX_TC_SPI_CSN_tri_t_38;
  wire [39:39]GX_TC_SPI_CSN_tri_t_39;
  wire [4:4]GX_TC_SPI_CSN_tri_t_4;
  wire [40:40]GX_TC_SPI_CSN_tri_t_40;
  wire [41:41]GX_TC_SPI_CSN_tri_t_41;
  wire [42:42]GX_TC_SPI_CSN_tri_t_42;
  wire [43:43]GX_TC_SPI_CSN_tri_t_43;
  wire [44:44]GX_TC_SPI_CSN_tri_t_44;
  wire [45:45]GX_TC_SPI_CSN_tri_t_45;
  wire [46:46]GX_TC_SPI_CSN_tri_t_46;
  wire [47:47]GX_TC_SPI_CSN_tri_t_47;
  wire [5:5]GX_TC_SPI_CSN_tri_t_5;
  wire [6:6]GX_TC_SPI_CSN_tri_t_6;
  wire [7:7]GX_TC_SPI_CSN_tri_t_7;
  wire [8:8]GX_TC_SPI_CSN_tri_t_8;
  wire [9:9]GX_TC_SPI_CSN_tri_t_9;
  wire [0:0]GX_TC_SPI_SCLK_tri_i_0;
  wire [1:1]GX_TC_SPI_SCLK_tri_i_1;
  wire [2:2]GX_TC_SPI_SCLK_tri_i_2;
  wire [3:3]GX_TC_SPI_SCLK_tri_i_3;
  wire [4:4]GX_TC_SPI_SCLK_tri_i_4;
  wire [5:5]GX_TC_SPI_SCLK_tri_i_5;
  wire [0:0]GX_TC_SPI_SCLK_tri_io_0;
  wire [1:1]GX_TC_SPI_SCLK_tri_io_1;
  wire [2:2]GX_TC_SPI_SCLK_tri_io_2;
  wire [3:3]GX_TC_SPI_SCLK_tri_io_3;
  wire [4:4]GX_TC_SPI_SCLK_tri_io_4;
  wire [5:5]GX_TC_SPI_SCLK_tri_io_5;
  wire [0:0]GX_TC_SPI_SCLK_tri_o_0;
  wire [1:1]GX_TC_SPI_SCLK_tri_o_1;
  wire [2:2]GX_TC_SPI_SCLK_tri_o_2;
  wire [3:3]GX_TC_SPI_SCLK_tri_o_3;
  wire [4:4]GX_TC_SPI_SCLK_tri_o_4;
  wire [5:5]GX_TC_SPI_SCLK_tri_o_5;
  wire [0:0]GX_TC_SPI_SCLK_tri_t_0;
  wire [1:1]GX_TC_SPI_SCLK_tri_t_1;
  wire [2:2]GX_TC_SPI_SCLK_tri_t_2;
  wire [3:3]GX_TC_SPI_SCLK_tri_t_3;
  wire [4:4]GX_TC_SPI_SCLK_tri_t_4;
  wire [5:5]GX_TC_SPI_SCLK_tri_t_5;
  wire [0:0]GX_TC_SPI_SDI_tri_i_0;
  wire [1:1]GX_TC_SPI_SDI_tri_i_1;
  wire [2:2]GX_TC_SPI_SDI_tri_i_2;
  wire [3:3]GX_TC_SPI_SDI_tri_i_3;
  wire [4:4]GX_TC_SPI_SDI_tri_i_4;
  wire [5:5]GX_TC_SPI_SDI_tri_i_5;
  wire [0:0]GX_TC_SPI_SDI_tri_io_0;
  wire [1:1]GX_TC_SPI_SDI_tri_io_1;
  wire [2:2]GX_TC_SPI_SDI_tri_io_2;
  wire [3:3]GX_TC_SPI_SDI_tri_io_3;
  wire [4:4]GX_TC_SPI_SDI_tri_io_4;
  wire [5:5]GX_TC_SPI_SDI_tri_io_5;
  wire [0:0]GX_TC_SPI_SDI_tri_o_0;
  wire [1:1]GX_TC_SPI_SDI_tri_o_1;
  wire [2:2]GX_TC_SPI_SDI_tri_o_2;
  wire [3:3]GX_TC_SPI_SDI_tri_o_3;
  wire [4:4]GX_TC_SPI_SDI_tri_o_4;
  wire [5:5]GX_TC_SPI_SDI_tri_o_5;
  wire [0:0]GX_TC_SPI_SDI_tri_t_0;
  wire [1:1]GX_TC_SPI_SDI_tri_t_1;
  wire [2:2]GX_TC_SPI_SDI_tri_t_2;
  wire [3:3]GX_TC_SPI_SDI_tri_t_3;
  wire [4:4]GX_TC_SPI_SDI_tri_t_4;
  wire [5:5]GX_TC_SPI_SDI_tri_t_5;
  wire [0:0]GX_TC_SPI_SDO_tri_i_0;
  wire [1:1]GX_TC_SPI_SDO_tri_i_1;
  wire [2:2]GX_TC_SPI_SDO_tri_i_2;
  wire [3:3]GX_TC_SPI_SDO_tri_i_3;
  wire [4:4]GX_TC_SPI_SDO_tri_i_4;
  wire [5:5]GX_TC_SPI_SDO_tri_i_5;
  wire [0:0]GX_TC_SPI_SDO_tri_io_0;
  wire [1:1]GX_TC_SPI_SDO_tri_io_1;
  wire [2:2]GX_TC_SPI_SDO_tri_io_2;
  wire [3:3]GX_TC_SPI_SDO_tri_io_3;
  wire [4:4]GX_TC_SPI_SDO_tri_io_4;
  wire [5:5]GX_TC_SPI_SDO_tri_io_5;
  wire [0:0]GX_TC_SPI_SDO_tri_o_0;
  wire [1:1]GX_TC_SPI_SDO_tri_o_1;
  wire [2:2]GX_TC_SPI_SDO_tri_o_2;
  wire [3:3]GX_TC_SPI_SDO_tri_o_3;
  wire [4:4]GX_TC_SPI_SDO_tri_o_4;
  wire [5:5]GX_TC_SPI_SDO_tri_o_5;
  wire [0:0]GX_TC_SPI_SDO_tri_t_0;
  wire [1:1]GX_TC_SPI_SDO_tri_t_1;
  wire [2:2]GX_TC_SPI_SDO_tri_t_2;
  wire [3:3]GX_TC_SPI_SDO_tri_t_3;
  wire [4:4]GX_TC_SPI_SDO_tri_t_4;
  wire [5:5]GX_TC_SPI_SDO_tri_t_5;

  IOBUF GX_RTD_SPI_CSN_tri_iobuf_0
       (.I(GX_RTD_SPI_CSN_tri_o_0),
        .IO(GX_RTD_SPI_CSN_tri_io[0]),
        .O(GX_RTD_SPI_CSN_tri_i_0),
        .T(GX_RTD_SPI_CSN_tri_t_0));
  IOBUF GX_RTD_SPI_CSN_tri_iobuf_1
       (.I(GX_RTD_SPI_CSN_tri_o_1),
        .IO(GX_RTD_SPI_CSN_tri_io[1]),
        .O(GX_RTD_SPI_CSN_tri_i_1),
        .T(GX_RTD_SPI_CSN_tri_t_1));
  IOBUF GX_RTD_SPI_CSN_tri_iobuf_2
       (.I(GX_RTD_SPI_CSN_tri_o_2),
        .IO(GX_RTD_SPI_CSN_tri_io[2]),
        .O(GX_RTD_SPI_CSN_tri_i_2),
        .T(GX_RTD_SPI_CSN_tri_t_2));
  IOBUF GX_RTD_SPI_CSN_tri_iobuf_3
       (.I(GX_RTD_SPI_CSN_tri_o_3),
        .IO(GX_RTD_SPI_CSN_tri_io[3]),
        .O(GX_RTD_SPI_CSN_tri_i_3),
        .T(GX_RTD_SPI_CSN_tri_t_3));
  IOBUF GX_RTD_SPI_CSN_tri_iobuf_4
       (.I(GX_RTD_SPI_CSN_tri_o_4),
        .IO(GX_RTD_SPI_CSN_tri_io[4]),
        .O(GX_RTD_SPI_CSN_tri_i_4),
        .T(GX_RTD_SPI_CSN_tri_t_4));
  IOBUF GX_RTD_SPI_CSN_tri_iobuf_5
       (.I(GX_RTD_SPI_CSN_tri_o_5),
        .IO(GX_RTD_SPI_CSN_tri_io[5]),
        .O(GX_RTD_SPI_CSN_tri_i_5),
        .T(GX_RTD_SPI_CSN_tri_t_5));
  IOBUF GX_RTD_SPI_SCLK_tri_iobuf_0
       (.I(GX_RTD_SPI_SCLK_tri_o_0),
        .IO(GX_RTD_SPI_SCLK_tri_io[0]),
        .O(GX_RTD_SPI_SCLK_tri_i_0),
        .T(GX_RTD_SPI_SCLK_tri_t_0));
  IOBUF GX_RTD_SPI_SCLK_tri_iobuf_1
       (.I(GX_RTD_SPI_SCLK_tri_o_1),
        .IO(GX_RTD_SPI_SCLK_tri_io[1]),
        .O(GX_RTD_SPI_SCLK_tri_i_1),
        .T(GX_RTD_SPI_SCLK_tri_t_1));
  IOBUF GX_RTD_SPI_SCLK_tri_iobuf_2
       (.I(GX_RTD_SPI_SCLK_tri_o_2),
        .IO(GX_RTD_SPI_SCLK_tri_io[2]),
        .O(GX_RTD_SPI_SCLK_tri_i_2),
        .T(GX_RTD_SPI_SCLK_tri_t_2));
  IOBUF GX_RTD_SPI_SCLK_tri_iobuf_3
       (.I(GX_RTD_SPI_SCLK_tri_o_3),
        .IO(GX_RTD_SPI_SCLK_tri_io[3]),
        .O(GX_RTD_SPI_SCLK_tri_i_3),
        .T(GX_RTD_SPI_SCLK_tri_t_3));
  IOBUF GX_RTD_SPI_SCLK_tri_iobuf_4
       (.I(GX_RTD_SPI_SCLK_tri_o_4),
        .IO(GX_RTD_SPI_SCLK_tri_io[4]),
        .O(GX_RTD_SPI_SCLK_tri_i_4),
        .T(GX_RTD_SPI_SCLK_tri_t_4));
  IOBUF GX_RTD_SPI_SCLK_tri_iobuf_5
       (.I(GX_RTD_SPI_SCLK_tri_o_5),
        .IO(GX_RTD_SPI_SCLK_tri_io[5]),
        .O(GX_RTD_SPI_SCLK_tri_i_5),
        .T(GX_RTD_SPI_SCLK_tri_t_5));
  IOBUF GX_RTD_SPI_SDI_tri_iobuf_0
       (.I(GX_RTD_SPI_SDI_tri_o_0),
        .IO(GX_RTD_SPI_SDI_tri_io[0]),
        .O(GX_RTD_SPI_SDI_tri_i_0),
        .T(GX_RTD_SPI_SDI_tri_t_0));
  IOBUF GX_RTD_SPI_SDI_tri_iobuf_1
       (.I(GX_RTD_SPI_SDI_tri_o_1),
        .IO(GX_RTD_SPI_SDI_tri_io[1]),
        .O(GX_RTD_SPI_SDI_tri_i_1),
        .T(GX_RTD_SPI_SDI_tri_t_1));
  IOBUF GX_RTD_SPI_SDI_tri_iobuf_2
       (.I(GX_RTD_SPI_SDI_tri_o_2),
        .IO(GX_RTD_SPI_SDI_tri_io[2]),
        .O(GX_RTD_SPI_SDI_tri_i_2),
        .T(GX_RTD_SPI_SDI_tri_t_2));
  IOBUF GX_RTD_SPI_SDI_tri_iobuf_3
       (.I(GX_RTD_SPI_SDI_tri_o_3),
        .IO(GX_RTD_SPI_SDI_tri_io[3]),
        .O(GX_RTD_SPI_SDI_tri_i_3),
        .T(GX_RTD_SPI_SDI_tri_t_3));
  IOBUF GX_RTD_SPI_SDI_tri_iobuf_4
       (.I(GX_RTD_SPI_SDI_tri_o_4),
        .IO(GX_RTD_SPI_SDI_tri_io[4]),
        .O(GX_RTD_SPI_SDI_tri_i_4),
        .T(GX_RTD_SPI_SDI_tri_t_4));
  IOBUF GX_RTD_SPI_SDI_tri_iobuf_5
       (.I(GX_RTD_SPI_SDI_tri_o_5),
        .IO(GX_RTD_SPI_SDI_tri_io[5]),
        .O(GX_RTD_SPI_SDI_tri_i_5),
        .T(GX_RTD_SPI_SDI_tri_t_5));
  IOBUF GX_RTD_SPI_SDO_tri_iobuf_0
       (.I(GX_RTD_SPI_SDO_tri_o_0),
        .IO(GX_RTD_SPI_SDO_tri_io[0]),
        .O(GX_RTD_SPI_SDO_tri_i_0),
        .T(GX_RTD_SPI_SDO_tri_t_0));
  IOBUF GX_RTD_SPI_SDO_tri_iobuf_1
       (.I(GX_RTD_SPI_SDO_tri_o_1),
        .IO(GX_RTD_SPI_SDO_tri_io[1]),
        .O(GX_RTD_SPI_SDO_tri_i_1),
        .T(GX_RTD_SPI_SDO_tri_t_1));
  IOBUF GX_RTD_SPI_SDO_tri_iobuf_2
       (.I(GX_RTD_SPI_SDO_tri_o_2),
        .IO(GX_RTD_SPI_SDO_tri_io[2]),
        .O(GX_RTD_SPI_SDO_tri_i_2),
        .T(GX_RTD_SPI_SDO_tri_t_2));
  IOBUF GX_RTD_SPI_SDO_tri_iobuf_3
       (.I(GX_RTD_SPI_SDO_tri_o_3),
        .IO(GX_RTD_SPI_SDO_tri_io[3]),
        .O(GX_RTD_SPI_SDO_tri_i_3),
        .T(GX_RTD_SPI_SDO_tri_t_3));
  IOBUF GX_RTD_SPI_SDO_tri_iobuf_4
       (.I(GX_RTD_SPI_SDO_tri_o_4),
        .IO(GX_RTD_SPI_SDO_tri_io[4]),
        .O(GX_RTD_SPI_SDO_tri_i_4),
        .T(GX_RTD_SPI_SDO_tri_t_4));
  IOBUF GX_RTD_SPI_SDO_tri_iobuf_5
       (.I(GX_RTD_SPI_SDO_tri_o_5),
        .IO(GX_RTD_SPI_SDO_tri_io[5]),
        .O(GX_RTD_SPI_SDO_tri_i_5),
        .T(GX_RTD_SPI_SDO_tri_t_5));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_0
       (.I(GX_TC_SPI_CSN_tri_o_0),
        .IO(GX_TC_SPI_CSN_tri_io[0]),
        .O(GX_TC_SPI_CSN_tri_i_0),
        .T(GX_TC_SPI_CSN_tri_t_0));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_1
       (.I(GX_TC_SPI_CSN_tri_o_1),
        .IO(GX_TC_SPI_CSN_tri_io[1]),
        .O(GX_TC_SPI_CSN_tri_i_1),
        .T(GX_TC_SPI_CSN_tri_t_1));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_10
       (.I(GX_TC_SPI_CSN_tri_o_10),
        .IO(GX_TC_SPI_CSN_tri_io[10]),
        .O(GX_TC_SPI_CSN_tri_i_10),
        .T(GX_TC_SPI_CSN_tri_t_10));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_11
       (.I(GX_TC_SPI_CSN_tri_o_11),
        .IO(GX_TC_SPI_CSN_tri_io[11]),
        .O(GX_TC_SPI_CSN_tri_i_11),
        .T(GX_TC_SPI_CSN_tri_t_11));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_12
       (.I(GX_TC_SPI_CSN_tri_o_12),
        .IO(GX_TC_SPI_CSN_tri_io[12]),
        .O(GX_TC_SPI_CSN_tri_i_12),
        .T(GX_TC_SPI_CSN_tri_t_12));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_13
       (.I(GX_TC_SPI_CSN_tri_o_13),
        .IO(GX_TC_SPI_CSN_tri_io[13]),
        .O(GX_TC_SPI_CSN_tri_i_13),
        .T(GX_TC_SPI_CSN_tri_t_13));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_14
       (.I(GX_TC_SPI_CSN_tri_o_14),
        .IO(GX_TC_SPI_CSN_tri_io[14]),
        .O(GX_TC_SPI_CSN_tri_i_14),
        .T(GX_TC_SPI_CSN_tri_t_14));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_15
       (.I(GX_TC_SPI_CSN_tri_o_15),
        .IO(GX_TC_SPI_CSN_tri_io[15]),
        .O(GX_TC_SPI_CSN_tri_i_15),
        .T(GX_TC_SPI_CSN_tri_t_15));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_16
       (.I(GX_TC_SPI_CSN_tri_o_16),
        .IO(GX_TC_SPI_CSN_tri_io[16]),
        .O(GX_TC_SPI_CSN_tri_i_16),
        .T(GX_TC_SPI_CSN_tri_t_16));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_17
       (.I(GX_TC_SPI_CSN_tri_o_17),
        .IO(GX_TC_SPI_CSN_tri_io[17]),
        .O(GX_TC_SPI_CSN_tri_i_17),
        .T(GX_TC_SPI_CSN_tri_t_17));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_18
       (.I(GX_TC_SPI_CSN_tri_o_18),
        .IO(GX_TC_SPI_CSN_tri_io[18]),
        .O(GX_TC_SPI_CSN_tri_i_18),
        .T(GX_TC_SPI_CSN_tri_t_18));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_19
       (.I(GX_TC_SPI_CSN_tri_o_19),
        .IO(GX_TC_SPI_CSN_tri_io[19]),
        .O(GX_TC_SPI_CSN_tri_i_19),
        .T(GX_TC_SPI_CSN_tri_t_19));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_2
       (.I(GX_TC_SPI_CSN_tri_o_2),
        .IO(GX_TC_SPI_CSN_tri_io[2]),
        .O(GX_TC_SPI_CSN_tri_i_2),
        .T(GX_TC_SPI_CSN_tri_t_2));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_20
       (.I(GX_TC_SPI_CSN_tri_o_20),
        .IO(GX_TC_SPI_CSN_tri_io[20]),
        .O(GX_TC_SPI_CSN_tri_i_20),
        .T(GX_TC_SPI_CSN_tri_t_20));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_21
       (.I(GX_TC_SPI_CSN_tri_o_21),
        .IO(GX_TC_SPI_CSN_tri_io[21]),
        .O(GX_TC_SPI_CSN_tri_i_21),
        .T(GX_TC_SPI_CSN_tri_t_21));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_22
       (.I(GX_TC_SPI_CSN_tri_o_22),
        .IO(GX_TC_SPI_CSN_tri_io[22]),
        .O(GX_TC_SPI_CSN_tri_i_22),
        .T(GX_TC_SPI_CSN_tri_t_22));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_23
       (.I(GX_TC_SPI_CSN_tri_o_23),
        .IO(GX_TC_SPI_CSN_tri_io[23]),
        .O(GX_TC_SPI_CSN_tri_i_23),
        .T(GX_TC_SPI_CSN_tri_t_23));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_24
       (.I(GX_TC_SPI_CSN_tri_o_24),
        .IO(GX_TC_SPI_CSN_tri_io[24]),
        .O(GX_TC_SPI_CSN_tri_i_24),
        .T(GX_TC_SPI_CSN_tri_t_24));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_25
       (.I(GX_TC_SPI_CSN_tri_o_25),
        .IO(GX_TC_SPI_CSN_tri_io[25]),
        .O(GX_TC_SPI_CSN_tri_i_25),
        .T(GX_TC_SPI_CSN_tri_t_25));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_26
       (.I(GX_TC_SPI_CSN_tri_o_26),
        .IO(GX_TC_SPI_CSN_tri_io[26]),
        .O(GX_TC_SPI_CSN_tri_i_26),
        .T(GX_TC_SPI_CSN_tri_t_26));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_27
       (.I(GX_TC_SPI_CSN_tri_o_27),
        .IO(GX_TC_SPI_CSN_tri_io[27]),
        .O(GX_TC_SPI_CSN_tri_i_27),
        .T(GX_TC_SPI_CSN_tri_t_27));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_28
       (.I(GX_TC_SPI_CSN_tri_o_28),
        .IO(GX_TC_SPI_CSN_tri_io[28]),
        .O(GX_TC_SPI_CSN_tri_i_28),
        .T(GX_TC_SPI_CSN_tri_t_28));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_29
       (.I(GX_TC_SPI_CSN_tri_o_29),
        .IO(GX_TC_SPI_CSN_tri_io[29]),
        .O(GX_TC_SPI_CSN_tri_i_29),
        .T(GX_TC_SPI_CSN_tri_t_29));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_3
       (.I(GX_TC_SPI_CSN_tri_o_3),
        .IO(GX_TC_SPI_CSN_tri_io[3]),
        .O(GX_TC_SPI_CSN_tri_i_3),
        .T(GX_TC_SPI_CSN_tri_t_3));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_30
       (.I(GX_TC_SPI_CSN_tri_o_30),
        .IO(GX_TC_SPI_CSN_tri_io[30]),
        .O(GX_TC_SPI_CSN_tri_i_30),
        .T(GX_TC_SPI_CSN_tri_t_30));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_31
       (.I(GX_TC_SPI_CSN_tri_o_31),
        .IO(GX_TC_SPI_CSN_tri_io[31]),
        .O(GX_TC_SPI_CSN_tri_i_31),
        .T(GX_TC_SPI_CSN_tri_t_31));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_32
       (.I(GX_TC_SPI_CSN_tri_o_32),
        .IO(GX_TC_SPI_CSN_tri_io[32]),
        .O(GX_TC_SPI_CSN_tri_i_32),
        .T(GX_TC_SPI_CSN_tri_t_32));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_33
       (.I(GX_TC_SPI_CSN_tri_o_33),
        .IO(GX_TC_SPI_CSN_tri_io[33]),
        .O(GX_TC_SPI_CSN_tri_i_33),
        .T(GX_TC_SPI_CSN_tri_t_33));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_34
       (.I(GX_TC_SPI_CSN_tri_o_34),
        .IO(GX_TC_SPI_CSN_tri_io[34]),
        .O(GX_TC_SPI_CSN_tri_i_34),
        .T(GX_TC_SPI_CSN_tri_t_34));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_35
       (.I(GX_TC_SPI_CSN_tri_o_35),
        .IO(GX_TC_SPI_CSN_tri_io[35]),
        .O(GX_TC_SPI_CSN_tri_i_35),
        .T(GX_TC_SPI_CSN_tri_t_35));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_36
       (.I(GX_TC_SPI_CSN_tri_o_36),
        .IO(GX_TC_SPI_CSN_tri_io[36]),
        .O(GX_TC_SPI_CSN_tri_i_36),
        .T(GX_TC_SPI_CSN_tri_t_36));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_37
       (.I(GX_TC_SPI_CSN_tri_o_37),
        .IO(GX_TC_SPI_CSN_tri_io[37]),
        .O(GX_TC_SPI_CSN_tri_i_37),
        .T(GX_TC_SPI_CSN_tri_t_37));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_38
       (.I(GX_TC_SPI_CSN_tri_o_38),
        .IO(GX_TC_SPI_CSN_tri_io[38]),
        .O(GX_TC_SPI_CSN_tri_i_38),
        .T(GX_TC_SPI_CSN_tri_t_38));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_39
       (.I(GX_TC_SPI_CSN_tri_o_39),
        .IO(GX_TC_SPI_CSN_tri_io[39]),
        .O(GX_TC_SPI_CSN_tri_i_39),
        .T(GX_TC_SPI_CSN_tri_t_39));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_4
       (.I(GX_TC_SPI_CSN_tri_o_4),
        .IO(GX_TC_SPI_CSN_tri_io[4]),
        .O(GX_TC_SPI_CSN_tri_i_4),
        .T(GX_TC_SPI_CSN_tri_t_4));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_40
       (.I(GX_TC_SPI_CSN_tri_o_40),
        .IO(GX_TC_SPI_CSN_tri_io[40]),
        .O(GX_TC_SPI_CSN_tri_i_40),
        .T(GX_TC_SPI_CSN_tri_t_40));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_41
       (.I(GX_TC_SPI_CSN_tri_o_41),
        .IO(GX_TC_SPI_CSN_tri_io[41]),
        .O(GX_TC_SPI_CSN_tri_i_41),
        .T(GX_TC_SPI_CSN_tri_t_41));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_42
       (.I(GX_TC_SPI_CSN_tri_o_42),
        .IO(GX_TC_SPI_CSN_tri_io[42]),
        .O(GX_TC_SPI_CSN_tri_i_42),
        .T(GX_TC_SPI_CSN_tri_t_42));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_43
       (.I(GX_TC_SPI_CSN_tri_o_43),
        .IO(GX_TC_SPI_CSN_tri_io[43]),
        .O(GX_TC_SPI_CSN_tri_i_43),
        .T(GX_TC_SPI_CSN_tri_t_43));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_44
       (.I(GX_TC_SPI_CSN_tri_o_44),
        .IO(GX_TC_SPI_CSN_tri_io[44]),
        .O(GX_TC_SPI_CSN_tri_i_44),
        .T(GX_TC_SPI_CSN_tri_t_44));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_45
       (.I(GX_TC_SPI_CSN_tri_o_45),
        .IO(GX_TC_SPI_CSN_tri_io[45]),
        .O(GX_TC_SPI_CSN_tri_i_45),
        .T(GX_TC_SPI_CSN_tri_t_45));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_46
       (.I(GX_TC_SPI_CSN_tri_o_46),
        .IO(GX_TC_SPI_CSN_tri_io[46]),
        .O(GX_TC_SPI_CSN_tri_i_46),
        .T(GX_TC_SPI_CSN_tri_t_46));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_47
       (.I(GX_TC_SPI_CSN_tri_o_47),
        .IO(GX_TC_SPI_CSN_tri_io[47]),
        .O(GX_TC_SPI_CSN_tri_i_47),
        .T(GX_TC_SPI_CSN_tri_t_47));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_5
       (.I(GX_TC_SPI_CSN_tri_o_5),
        .IO(GX_TC_SPI_CSN_tri_io[5]),
        .O(GX_TC_SPI_CSN_tri_i_5),
        .T(GX_TC_SPI_CSN_tri_t_5));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_6
       (.I(GX_TC_SPI_CSN_tri_o_6),
        .IO(GX_TC_SPI_CSN_tri_io[6]),
        .O(GX_TC_SPI_CSN_tri_i_6),
        .T(GX_TC_SPI_CSN_tri_t_6));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_7
       (.I(GX_TC_SPI_CSN_tri_o_7),
        .IO(GX_TC_SPI_CSN_tri_io[7]),
        .O(GX_TC_SPI_CSN_tri_i_7),
        .T(GX_TC_SPI_CSN_tri_t_7));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_8
       (.I(GX_TC_SPI_CSN_tri_o_8),
        .IO(GX_TC_SPI_CSN_tri_io[8]),
        .O(GX_TC_SPI_CSN_tri_i_8),
        .T(GX_TC_SPI_CSN_tri_t_8));
  IOBUF GX_TC_SPI_CSN_tri_iobuf_9
       (.I(GX_TC_SPI_CSN_tri_o_9),
        .IO(GX_TC_SPI_CSN_tri_io[9]),
        .O(GX_TC_SPI_CSN_tri_i_9),
        .T(GX_TC_SPI_CSN_tri_t_9));
  IOBUF GX_TC_SPI_SCLK_tri_iobuf_0
       (.I(GX_TC_SPI_SCLK_tri_o_0),
        .IO(GX_TC_SPI_SCLK_tri_io[0]),
        .O(GX_TC_SPI_SCLK_tri_i_0),
        .T(GX_TC_SPI_SCLK_tri_t_0));
  IOBUF GX_TC_SPI_SCLK_tri_iobuf_1
       (.I(GX_TC_SPI_SCLK_tri_o_1),
        .IO(GX_TC_SPI_SCLK_tri_io[1]),
        .O(GX_TC_SPI_SCLK_tri_i_1),
        .T(GX_TC_SPI_SCLK_tri_t_1));
  IOBUF GX_TC_SPI_SCLK_tri_iobuf_2
       (.I(GX_TC_SPI_SCLK_tri_o_2),
        .IO(GX_TC_SPI_SCLK_tri_io[2]),
        .O(GX_TC_SPI_SCLK_tri_i_2),
        .T(GX_TC_SPI_SCLK_tri_t_2));
  IOBUF GX_TC_SPI_SCLK_tri_iobuf_3
       (.I(GX_TC_SPI_SCLK_tri_o_3),
        .IO(GX_TC_SPI_SCLK_tri_io[3]),
        .O(GX_TC_SPI_SCLK_tri_i_3),
        .T(GX_TC_SPI_SCLK_tri_t_3));
  IOBUF GX_TC_SPI_SCLK_tri_iobuf_4
       (.I(GX_TC_SPI_SCLK_tri_o_4),
        .IO(GX_TC_SPI_SCLK_tri_io[4]),
        .O(GX_TC_SPI_SCLK_tri_i_4),
        .T(GX_TC_SPI_SCLK_tri_t_4));
  IOBUF GX_TC_SPI_SCLK_tri_iobuf_5
       (.I(GX_TC_SPI_SCLK_tri_o_5),
        .IO(GX_TC_SPI_SCLK_tri_io[5]),
        .O(GX_TC_SPI_SCLK_tri_i_5),
        .T(GX_TC_SPI_SCLK_tri_t_5));
  IOBUF GX_TC_SPI_SDI_tri_iobuf_0
       (.I(GX_TC_SPI_SDI_tri_o_0),
        .IO(GX_TC_SPI_SDI_tri_io[0]),
        .O(GX_TC_SPI_SDI_tri_i_0),
        .T(GX_TC_SPI_SDI_tri_t_0));
  IOBUF GX_TC_SPI_SDI_tri_iobuf_1
       (.I(GX_TC_SPI_SDI_tri_o_1),
        .IO(GX_TC_SPI_SDI_tri_io[1]),
        .O(GX_TC_SPI_SDI_tri_i_1),
        .T(GX_TC_SPI_SDI_tri_t_1));
  IOBUF GX_TC_SPI_SDI_tri_iobuf_2
       (.I(GX_TC_SPI_SDI_tri_o_2),
        .IO(GX_TC_SPI_SDI_tri_io[2]),
        .O(GX_TC_SPI_SDI_tri_i_2),
        .T(GX_TC_SPI_SDI_tri_t_2));
  IOBUF GX_TC_SPI_SDI_tri_iobuf_3
       (.I(GX_TC_SPI_SDI_tri_o_3),
        .IO(GX_TC_SPI_SDI_tri_io[3]),
        .O(GX_TC_SPI_SDI_tri_i_3),
        .T(GX_TC_SPI_SDI_tri_t_3));
  IOBUF GX_TC_SPI_SDI_tri_iobuf_4
       (.I(GX_TC_SPI_SDI_tri_o_4),
        .IO(GX_TC_SPI_SDI_tri_io[4]),
        .O(GX_TC_SPI_SDI_tri_i_4),
        .T(GX_TC_SPI_SDI_tri_t_4));
  IOBUF GX_TC_SPI_SDI_tri_iobuf_5
       (.I(GX_TC_SPI_SDI_tri_o_5),
        .IO(GX_TC_SPI_SDI_tri_io[5]),
        .O(GX_TC_SPI_SDI_tri_i_5),
        .T(GX_TC_SPI_SDI_tri_t_5));
  IOBUF GX_TC_SPI_SDO_tri_iobuf_0
       (.I(GX_TC_SPI_SDO_tri_o_0),
        .IO(GX_TC_SPI_SDO_tri_io[0]),
        .O(GX_TC_SPI_SDO_tri_i_0),
        .T(GX_TC_SPI_SDO_tri_t_0));
  IOBUF GX_TC_SPI_SDO_tri_iobuf_1
       (.I(GX_TC_SPI_SDO_tri_o_1),
        .IO(GX_TC_SPI_SDO_tri_io[1]),
        .O(GX_TC_SPI_SDO_tri_i_1),
        .T(GX_TC_SPI_SDO_tri_t_1));
  IOBUF GX_TC_SPI_SDO_tri_iobuf_2
       (.I(GX_TC_SPI_SDO_tri_o_2),
        .IO(GX_TC_SPI_SDO_tri_io[2]),
        .O(GX_TC_SPI_SDO_tri_i_2),
        .T(GX_TC_SPI_SDO_tri_t_2));
  IOBUF GX_TC_SPI_SDO_tri_iobuf_3
       (.I(GX_TC_SPI_SDO_tri_o_3),
        .IO(GX_TC_SPI_SDO_tri_io[3]),
        .O(GX_TC_SPI_SDO_tri_i_3),
        .T(GX_TC_SPI_SDO_tri_t_3));
  IOBUF GX_TC_SPI_SDO_tri_iobuf_4
       (.I(GX_TC_SPI_SDO_tri_o_4),
        .IO(GX_TC_SPI_SDO_tri_io[4]),
        .O(GX_TC_SPI_SDO_tri_i_4),
        .T(GX_TC_SPI_SDO_tri_t_4));
  IOBUF GX_TC_SPI_SDO_tri_iobuf_5
       (.I(GX_TC_SPI_SDO_tri_o_5),
        .IO(GX_TC_SPI_SDO_tri_io[5]),
        .O(GX_TC_SPI_SDO_tri_i_5),
        .T(GX_TC_SPI_SDO_tri_t_5));
  ps7_bd ps7_bd_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .GX_ADC_SYNC(GX_ADC_SYNC),
        .GX_ANA_POW_EN(GX_ANA_POW_EN),
        .GX_RELAY_CTRL(GX_RELAY_CTRL),
        .GX_RTD_SPI_CSN_tri_i({GX_RTD_SPI_CSN_tri_i_5,GX_RTD_SPI_CSN_tri_i_4,GX_RTD_SPI_CSN_tri_i_3,GX_RTD_SPI_CSN_tri_i_2,GX_RTD_SPI_CSN_tri_i_1,GX_RTD_SPI_CSN_tri_i_0}),
        .GX_RTD_SPI_CSN_tri_o({GX_RTD_SPI_CSN_tri_o_5,GX_RTD_SPI_CSN_tri_o_4,GX_RTD_SPI_CSN_tri_o_3,GX_RTD_SPI_CSN_tri_o_2,GX_RTD_SPI_CSN_tri_o_1,GX_RTD_SPI_CSN_tri_o_0}),
        .GX_RTD_SPI_CSN_tri_t({GX_RTD_SPI_CSN_tri_t_5,GX_RTD_SPI_CSN_tri_t_4,GX_RTD_SPI_CSN_tri_t_3,GX_RTD_SPI_CSN_tri_t_2,GX_RTD_SPI_CSN_tri_t_1,GX_RTD_SPI_CSN_tri_t_0}),
        .GX_RTD_SPI_SCLK_tri_i({GX_RTD_SPI_SCLK_tri_i_5,GX_RTD_SPI_SCLK_tri_i_4,GX_RTD_SPI_SCLK_tri_i_3,GX_RTD_SPI_SCLK_tri_i_2,GX_RTD_SPI_SCLK_tri_i_1,GX_RTD_SPI_SCLK_tri_i_0}),
        .GX_RTD_SPI_SCLK_tri_o({GX_RTD_SPI_SCLK_tri_o_5,GX_RTD_SPI_SCLK_tri_o_4,GX_RTD_SPI_SCLK_tri_o_3,GX_RTD_SPI_SCLK_tri_o_2,GX_RTD_SPI_SCLK_tri_o_1,GX_RTD_SPI_SCLK_tri_o_0}),
        .GX_RTD_SPI_SCLK_tri_t({GX_RTD_SPI_SCLK_tri_t_5,GX_RTD_SPI_SCLK_tri_t_4,GX_RTD_SPI_SCLK_tri_t_3,GX_RTD_SPI_SCLK_tri_t_2,GX_RTD_SPI_SCLK_tri_t_1,GX_RTD_SPI_SCLK_tri_t_0}),
        .GX_RTD_SPI_SDI_tri_i({GX_RTD_SPI_SDI_tri_i_5,GX_RTD_SPI_SDI_tri_i_4,GX_RTD_SPI_SDI_tri_i_3,GX_RTD_SPI_SDI_tri_i_2,GX_RTD_SPI_SDI_tri_i_1,GX_RTD_SPI_SDI_tri_i_0}),
        .GX_RTD_SPI_SDI_tri_o({GX_RTD_SPI_SDI_tri_o_5,GX_RTD_SPI_SDI_tri_o_4,GX_RTD_SPI_SDI_tri_o_3,GX_RTD_SPI_SDI_tri_o_2,GX_RTD_SPI_SDI_tri_o_1,GX_RTD_SPI_SDI_tri_o_0}),
        .GX_RTD_SPI_SDI_tri_t({GX_RTD_SPI_SDI_tri_t_5,GX_RTD_SPI_SDI_tri_t_4,GX_RTD_SPI_SDI_tri_t_3,GX_RTD_SPI_SDI_tri_t_2,GX_RTD_SPI_SDI_tri_t_1,GX_RTD_SPI_SDI_tri_t_0}),
        .GX_RTD_SPI_SDO_tri_i({GX_RTD_SPI_SDO_tri_i_5,GX_RTD_SPI_SDO_tri_i_4,GX_RTD_SPI_SDO_tri_i_3,GX_RTD_SPI_SDO_tri_i_2,GX_RTD_SPI_SDO_tri_i_1,GX_RTD_SPI_SDO_tri_i_0}),
        .GX_RTD_SPI_SDO_tri_o({GX_RTD_SPI_SDO_tri_o_5,GX_RTD_SPI_SDO_tri_o_4,GX_RTD_SPI_SDO_tri_o_3,GX_RTD_SPI_SDO_tri_o_2,GX_RTD_SPI_SDO_tri_o_1,GX_RTD_SPI_SDO_tri_o_0}),
        .GX_RTD_SPI_SDO_tri_t({GX_RTD_SPI_SDO_tri_t_5,GX_RTD_SPI_SDO_tri_t_4,GX_RTD_SPI_SDO_tri_t_3,GX_RTD_SPI_SDO_tri_t_2,GX_RTD_SPI_SDO_tri_t_1,GX_RTD_SPI_SDO_tri_t_0}),
        .GX_TC_SPI_CSN_tri_i({GX_TC_SPI_CSN_tri_i_47,GX_TC_SPI_CSN_tri_i_46,GX_TC_SPI_CSN_tri_i_45,GX_TC_SPI_CSN_tri_i_44,GX_TC_SPI_CSN_tri_i_43,GX_TC_SPI_CSN_tri_i_42,GX_TC_SPI_CSN_tri_i_41,GX_TC_SPI_CSN_tri_i_40,GX_TC_SPI_CSN_tri_i_39,GX_TC_SPI_CSN_tri_i_38,GX_TC_SPI_CSN_tri_i_37,GX_TC_SPI_CSN_tri_i_36,GX_TC_SPI_CSN_tri_i_35,GX_TC_SPI_CSN_tri_i_34,GX_TC_SPI_CSN_tri_i_33,GX_TC_SPI_CSN_tri_i_32,GX_TC_SPI_CSN_tri_i_31,GX_TC_SPI_CSN_tri_i_30,GX_TC_SPI_CSN_tri_i_29,GX_TC_SPI_CSN_tri_i_28,GX_TC_SPI_CSN_tri_i_27,GX_TC_SPI_CSN_tri_i_26,GX_TC_SPI_CSN_tri_i_25,GX_TC_SPI_CSN_tri_i_24,GX_TC_SPI_CSN_tri_i_23,GX_TC_SPI_CSN_tri_i_22,GX_TC_SPI_CSN_tri_i_21,GX_TC_SPI_CSN_tri_i_20,GX_TC_SPI_CSN_tri_i_19,GX_TC_SPI_CSN_tri_i_18,GX_TC_SPI_CSN_tri_i_17,GX_TC_SPI_CSN_tri_i_16,GX_TC_SPI_CSN_tri_i_15,GX_TC_SPI_CSN_tri_i_14,GX_TC_SPI_CSN_tri_i_13,GX_TC_SPI_CSN_tri_i_12,GX_TC_SPI_CSN_tri_i_11,GX_TC_SPI_CSN_tri_i_10,GX_TC_SPI_CSN_tri_i_9,GX_TC_SPI_CSN_tri_i_8,GX_TC_SPI_CSN_tri_i_7,GX_TC_SPI_CSN_tri_i_6,GX_TC_SPI_CSN_tri_i_5,GX_TC_SPI_CSN_tri_i_4,GX_TC_SPI_CSN_tri_i_3,GX_TC_SPI_CSN_tri_i_2,GX_TC_SPI_CSN_tri_i_1,GX_TC_SPI_CSN_tri_i_0}),
        .GX_TC_SPI_CSN_tri_o({GX_TC_SPI_CSN_tri_o_47,GX_TC_SPI_CSN_tri_o_46,GX_TC_SPI_CSN_tri_o_45,GX_TC_SPI_CSN_tri_o_44,GX_TC_SPI_CSN_tri_o_43,GX_TC_SPI_CSN_tri_o_42,GX_TC_SPI_CSN_tri_o_41,GX_TC_SPI_CSN_tri_o_40,GX_TC_SPI_CSN_tri_o_39,GX_TC_SPI_CSN_tri_o_38,GX_TC_SPI_CSN_tri_o_37,GX_TC_SPI_CSN_tri_o_36,GX_TC_SPI_CSN_tri_o_35,GX_TC_SPI_CSN_tri_o_34,GX_TC_SPI_CSN_tri_o_33,GX_TC_SPI_CSN_tri_o_32,GX_TC_SPI_CSN_tri_o_31,GX_TC_SPI_CSN_tri_o_30,GX_TC_SPI_CSN_tri_o_29,GX_TC_SPI_CSN_tri_o_28,GX_TC_SPI_CSN_tri_o_27,GX_TC_SPI_CSN_tri_o_26,GX_TC_SPI_CSN_tri_o_25,GX_TC_SPI_CSN_tri_o_24,GX_TC_SPI_CSN_tri_o_23,GX_TC_SPI_CSN_tri_o_22,GX_TC_SPI_CSN_tri_o_21,GX_TC_SPI_CSN_tri_o_20,GX_TC_SPI_CSN_tri_o_19,GX_TC_SPI_CSN_tri_o_18,GX_TC_SPI_CSN_tri_o_17,GX_TC_SPI_CSN_tri_o_16,GX_TC_SPI_CSN_tri_o_15,GX_TC_SPI_CSN_tri_o_14,GX_TC_SPI_CSN_tri_o_13,GX_TC_SPI_CSN_tri_o_12,GX_TC_SPI_CSN_tri_o_11,GX_TC_SPI_CSN_tri_o_10,GX_TC_SPI_CSN_tri_o_9,GX_TC_SPI_CSN_tri_o_8,GX_TC_SPI_CSN_tri_o_7,GX_TC_SPI_CSN_tri_o_6,GX_TC_SPI_CSN_tri_o_5,GX_TC_SPI_CSN_tri_o_4,GX_TC_SPI_CSN_tri_o_3,GX_TC_SPI_CSN_tri_o_2,GX_TC_SPI_CSN_tri_o_1,GX_TC_SPI_CSN_tri_o_0}),
        .GX_TC_SPI_CSN_tri_t({GX_TC_SPI_CSN_tri_t_47,GX_TC_SPI_CSN_tri_t_46,GX_TC_SPI_CSN_tri_t_45,GX_TC_SPI_CSN_tri_t_44,GX_TC_SPI_CSN_tri_t_43,GX_TC_SPI_CSN_tri_t_42,GX_TC_SPI_CSN_tri_t_41,GX_TC_SPI_CSN_tri_t_40,GX_TC_SPI_CSN_tri_t_39,GX_TC_SPI_CSN_tri_t_38,GX_TC_SPI_CSN_tri_t_37,GX_TC_SPI_CSN_tri_t_36,GX_TC_SPI_CSN_tri_t_35,GX_TC_SPI_CSN_tri_t_34,GX_TC_SPI_CSN_tri_t_33,GX_TC_SPI_CSN_tri_t_32,GX_TC_SPI_CSN_tri_t_31,GX_TC_SPI_CSN_tri_t_30,GX_TC_SPI_CSN_tri_t_29,GX_TC_SPI_CSN_tri_t_28,GX_TC_SPI_CSN_tri_t_27,GX_TC_SPI_CSN_tri_t_26,GX_TC_SPI_CSN_tri_t_25,GX_TC_SPI_CSN_tri_t_24,GX_TC_SPI_CSN_tri_t_23,GX_TC_SPI_CSN_tri_t_22,GX_TC_SPI_CSN_tri_t_21,GX_TC_SPI_CSN_tri_t_20,GX_TC_SPI_CSN_tri_t_19,GX_TC_SPI_CSN_tri_t_18,GX_TC_SPI_CSN_tri_t_17,GX_TC_SPI_CSN_tri_t_16,GX_TC_SPI_CSN_tri_t_15,GX_TC_SPI_CSN_tri_t_14,GX_TC_SPI_CSN_tri_t_13,GX_TC_SPI_CSN_tri_t_12,GX_TC_SPI_CSN_tri_t_11,GX_TC_SPI_CSN_tri_t_10,GX_TC_SPI_CSN_tri_t_9,GX_TC_SPI_CSN_tri_t_8,GX_TC_SPI_CSN_tri_t_7,GX_TC_SPI_CSN_tri_t_6,GX_TC_SPI_CSN_tri_t_5,GX_TC_SPI_CSN_tri_t_4,GX_TC_SPI_CSN_tri_t_3,GX_TC_SPI_CSN_tri_t_2,GX_TC_SPI_CSN_tri_t_1,GX_TC_SPI_CSN_tri_t_0}),
        .GX_TC_SPI_SCLK_tri_i({GX_TC_SPI_SCLK_tri_i_5,GX_TC_SPI_SCLK_tri_i_4,GX_TC_SPI_SCLK_tri_i_3,GX_TC_SPI_SCLK_tri_i_2,GX_TC_SPI_SCLK_tri_i_1,GX_TC_SPI_SCLK_tri_i_0}),
        .GX_TC_SPI_SCLK_tri_o({GX_TC_SPI_SCLK_tri_o_5,GX_TC_SPI_SCLK_tri_o_4,GX_TC_SPI_SCLK_tri_o_3,GX_TC_SPI_SCLK_tri_o_2,GX_TC_SPI_SCLK_tri_o_1,GX_TC_SPI_SCLK_tri_o_0}),
        .GX_TC_SPI_SCLK_tri_t({GX_TC_SPI_SCLK_tri_t_5,GX_TC_SPI_SCLK_tri_t_4,GX_TC_SPI_SCLK_tri_t_3,GX_TC_SPI_SCLK_tri_t_2,GX_TC_SPI_SCLK_tri_t_1,GX_TC_SPI_SCLK_tri_t_0}),
        .GX_TC_SPI_SDI_tri_i({GX_TC_SPI_SDI_tri_i_5,GX_TC_SPI_SDI_tri_i_4,GX_TC_SPI_SDI_tri_i_3,GX_TC_SPI_SDI_tri_i_2,GX_TC_SPI_SDI_tri_i_1,GX_TC_SPI_SDI_tri_i_0}),
        .GX_TC_SPI_SDI_tri_o({GX_TC_SPI_SDI_tri_o_5,GX_TC_SPI_SDI_tri_o_4,GX_TC_SPI_SDI_tri_o_3,GX_TC_SPI_SDI_tri_o_2,GX_TC_SPI_SDI_tri_o_1,GX_TC_SPI_SDI_tri_o_0}),
        .GX_TC_SPI_SDI_tri_t({GX_TC_SPI_SDI_tri_t_5,GX_TC_SPI_SDI_tri_t_4,GX_TC_SPI_SDI_tri_t_3,GX_TC_SPI_SDI_tri_t_2,GX_TC_SPI_SDI_tri_t_1,GX_TC_SPI_SDI_tri_t_0}),
        .GX_TC_SPI_SDO_tri_i({GX_TC_SPI_SDO_tri_i_5,GX_TC_SPI_SDO_tri_i_4,GX_TC_SPI_SDO_tri_i_3,GX_TC_SPI_SDO_tri_i_2,GX_TC_SPI_SDO_tri_i_1,GX_TC_SPI_SDO_tri_i_0}),
        .GX_TC_SPI_SDO_tri_o({GX_TC_SPI_SDO_tri_o_5,GX_TC_SPI_SDO_tri_o_4,GX_TC_SPI_SDO_tri_o_3,GX_TC_SPI_SDO_tri_o_2,GX_TC_SPI_SDO_tri_o_1,GX_TC_SPI_SDO_tri_o_0}),
        .GX_TC_SPI_SDO_tri_t({GX_TC_SPI_SDO_tri_t_5,GX_TC_SPI_SDO_tri_t_4,GX_TC_SPI_SDO_tri_t_3,GX_TC_SPI_SDO_tri_t_2,GX_TC_SPI_SDO_tri_t_1,GX_TC_SPI_SDO_tri_t_0}));
endmodule
