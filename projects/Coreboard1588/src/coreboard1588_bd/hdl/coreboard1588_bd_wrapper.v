//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
//Date        : Thu Apr 23 23:33:54 2020
//Host        : Kele20u running 64-bit Ubuntu 18.04.4 LTS
//Command     : generate_target coreboard1588_bd_wrapper.bd
//Design      : coreboard1588_bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module coreboard1588_bd_wrapper
   (A7_CONFIG_QSPI_io0_io,
    A7_CONFIG_QSPI_io1_io,
    A7_CONFIG_QSPI_io2_io,
    A7_CONFIG_QSPI_io3_io,
    A7_CONFIG_QSPI_ss_io,
    A7_GCLK,
    AD1_RST,
    AD2_DRDY,
    AD2_RST,
    AD2_START,
    CH_SEL_A0,
    CH_SEL_A1,
    CH_SEL_A2,
    EN_PCH_A,
    EN_PCH_B,
    EN_TCH_A,
    EN_TCH_B,
    FMC_addr,
    FMC_adv_ldn,
    FMC_ben,
    FMC_ce_n,
    FMC_dq_io,
    FMC_oen,
    FMC_rd_clk,
    FMC_wait,
    FMC_wen,
    FPGA_DAT_FIN,
    FPGA_LED,
    FPGA_MCU_INTR,
    FPGA_MCU_RST,
    FPGA_MCU_SPI_io0_io,
    FPGA_MCU_SPI_io1_io,
    FPGA_MCU_SPI_sck_io,
    FPGA_MCU_SPI_ss_io,
    FPGA_RST,
    FPGA_RUN,
    FPGA_SPI1_io0_io,
    FPGA_SPI1_io1_io,
    FPGA_SPI1_sck_io,
    FPGA_SPI1_ss_io,
    FPGA_SPI2_io0_io,
    FPGA_SPI2_io1_io,
    FPGA_SPI2_sck_io,
    FPGA_SPI2_ss_io,
    FPGA_TEST,
    PTP_CLK_OUT,
    PTP_TRG_FPGA);
  inout A7_CONFIG_QSPI_io0_io;
  inout A7_CONFIG_QSPI_io1_io;
  inout A7_CONFIG_QSPI_io2_io;
  inout A7_CONFIG_QSPI_io3_io;
  inout [0:0]A7_CONFIG_QSPI_ss_io;
  input A7_GCLK;
  output AD1_RST;
  input AD2_DRDY;
  output AD2_RST;
  output AD2_START;
  output CH_SEL_A0;
  output CH_SEL_A1;
  output CH_SEL_A2;
  output EN_PCH_A;
  output EN_PCH_B;
  output EN_TCH_A;
  output EN_TCH_B;
  input [11:0]FMC_addr;
  input FMC_adv_ldn;
  input [1:0]FMC_ben;
  input FMC_ce_n;
  inout [15:0]FMC_dq_io;
  input FMC_oen;
  input FMC_rd_clk;
  output FMC_wait;
  input FMC_wen;
  output FPGA_DAT_FIN;
  output [1:0]FPGA_LED;
  output FPGA_MCU_INTR;
  output [0:0]FPGA_MCU_RST;
  inout FPGA_MCU_SPI_io0_io;
  inout FPGA_MCU_SPI_io1_io;
  inout FPGA_MCU_SPI_sck_io;
  inout FPGA_MCU_SPI_ss_io;
  input FPGA_RST;
  output [0:0]FPGA_RUN;
  inout FPGA_SPI1_io0_io;
  inout FPGA_SPI1_io1_io;
  inout FPGA_SPI1_sck_io;
  inout FPGA_SPI1_ss_io;
  inout FPGA_SPI2_io0_io;
  inout FPGA_SPI2_io1_io;
  inout FPGA_SPI2_sck_io;
  inout FPGA_SPI2_ss_io;
  output [3:0]FPGA_TEST;
  input PTP_CLK_OUT;
  input PTP_TRG_FPGA;

  wire A7_CONFIG_QSPI_io0_i;
  wire A7_CONFIG_QSPI_io0_io;
  wire A7_CONFIG_QSPI_io0_o;
  wire A7_CONFIG_QSPI_io0_t;
  wire A7_CONFIG_QSPI_io1_i;
  wire A7_CONFIG_QSPI_io1_io;
  wire A7_CONFIG_QSPI_io1_o;
  wire A7_CONFIG_QSPI_io1_t;
  wire A7_CONFIG_QSPI_io2_i;
  wire A7_CONFIG_QSPI_io2_io;
  wire A7_CONFIG_QSPI_io2_o;
  wire A7_CONFIG_QSPI_io2_t;
  wire A7_CONFIG_QSPI_io3_i;
  wire A7_CONFIG_QSPI_io3_io;
  wire A7_CONFIG_QSPI_io3_o;
  wire A7_CONFIG_QSPI_io3_t;
  wire [0:0]A7_CONFIG_QSPI_ss_i_0;
  wire [0:0]A7_CONFIG_QSPI_ss_io_0;
  wire [0:0]A7_CONFIG_QSPI_ss_o_0;
  wire A7_CONFIG_QSPI_ss_t;
  wire A7_GCLK;
  wire AD1_RST;
  wire AD2_DRDY;
  wire AD2_RST;
  wire AD2_START;
  wire CH_SEL_A0;
  wire CH_SEL_A1;
  wire CH_SEL_A2;
  wire EN_PCH_A;
  wire EN_PCH_B;
  wire EN_TCH_A;
  wire EN_TCH_B;
  wire [11:0]FMC_addr;
  wire FMC_adv_ldn;
  wire [1:0]FMC_ben;
  wire FMC_ce_n;
  wire [0:0]FMC_dq_i_0;
  wire [1:1]FMC_dq_i_1;
  wire [10:10]FMC_dq_i_10;
  wire [11:11]FMC_dq_i_11;
  wire [12:12]FMC_dq_i_12;
  wire [13:13]FMC_dq_i_13;
  wire [14:14]FMC_dq_i_14;
  wire [15:15]FMC_dq_i_15;
  wire [2:2]FMC_dq_i_2;
  wire [3:3]FMC_dq_i_3;
  wire [4:4]FMC_dq_i_4;
  wire [5:5]FMC_dq_i_5;
  wire [6:6]FMC_dq_i_6;
  wire [7:7]FMC_dq_i_7;
  wire [8:8]FMC_dq_i_8;
  wire [9:9]FMC_dq_i_9;
  wire [0:0]FMC_dq_io_0;
  wire [1:1]FMC_dq_io_1;
  wire [10:10]FMC_dq_io_10;
  wire [11:11]FMC_dq_io_11;
  wire [12:12]FMC_dq_io_12;
  wire [13:13]FMC_dq_io_13;
  wire [14:14]FMC_dq_io_14;
  wire [15:15]FMC_dq_io_15;
  wire [2:2]FMC_dq_io_2;
  wire [3:3]FMC_dq_io_3;
  wire [4:4]FMC_dq_io_4;
  wire [5:5]FMC_dq_io_5;
  wire [6:6]FMC_dq_io_6;
  wire [7:7]FMC_dq_io_7;
  wire [8:8]FMC_dq_io_8;
  wire [9:9]FMC_dq_io_9;
  wire [0:0]FMC_dq_o_0;
  wire [1:1]FMC_dq_o_1;
  wire [10:10]FMC_dq_o_10;
  wire [11:11]FMC_dq_o_11;
  wire [12:12]FMC_dq_o_12;
  wire [13:13]FMC_dq_o_13;
  wire [14:14]FMC_dq_o_14;
  wire [15:15]FMC_dq_o_15;
  wire [2:2]FMC_dq_o_2;
  wire [3:3]FMC_dq_o_3;
  wire [4:4]FMC_dq_o_4;
  wire [5:5]FMC_dq_o_5;
  wire [6:6]FMC_dq_o_6;
  wire [7:7]FMC_dq_o_7;
  wire [8:8]FMC_dq_o_8;
  wire [9:9]FMC_dq_o_9;
  wire [0:0]FMC_dq_t_0;
  wire [1:1]FMC_dq_t_1;
  wire [10:10]FMC_dq_t_10;
  wire [11:11]FMC_dq_t_11;
  wire [12:12]FMC_dq_t_12;
  wire [13:13]FMC_dq_t_13;
  wire [14:14]FMC_dq_t_14;
  wire [15:15]FMC_dq_t_15;
  wire [2:2]FMC_dq_t_2;
  wire [3:3]FMC_dq_t_3;
  wire [4:4]FMC_dq_t_4;
  wire [5:5]FMC_dq_t_5;
  wire [6:6]FMC_dq_t_6;
  wire [7:7]FMC_dq_t_7;
  wire [8:8]FMC_dq_t_8;
  wire [9:9]FMC_dq_t_9;
  wire FMC_oen;
  wire FMC_rd_clk;
  wire FMC_wait;
  wire FMC_wen;
  wire FPGA_DAT_FIN;
  wire [1:0]FPGA_LED;
  wire FPGA_MCU_INTR;
  wire [0:0]FPGA_MCU_RST;
  wire FPGA_MCU_SPI_io0_i;
  wire FPGA_MCU_SPI_io0_io;
  wire FPGA_MCU_SPI_io0_o;
  wire FPGA_MCU_SPI_io0_t;
  wire FPGA_MCU_SPI_io1_i;
  wire FPGA_MCU_SPI_io1_io;
  wire FPGA_MCU_SPI_io1_o;
  wire FPGA_MCU_SPI_io1_t;
  wire FPGA_MCU_SPI_sck_i;
  wire FPGA_MCU_SPI_sck_io;
  wire FPGA_MCU_SPI_sck_o;
  wire FPGA_MCU_SPI_sck_t;
  wire FPGA_MCU_SPI_ss_i;
  wire FPGA_MCU_SPI_ss_io;
  wire FPGA_MCU_SPI_ss_o;
  wire FPGA_MCU_SPI_ss_t;
  wire FPGA_RST;
  wire [0:0]FPGA_RUN;
  wire FPGA_SPI1_io0_i;
  wire FPGA_SPI1_io0_io;
  wire FPGA_SPI1_io0_o;
  wire FPGA_SPI1_io0_t;
  wire FPGA_SPI1_io1_i;
  wire FPGA_SPI1_io1_io;
  wire FPGA_SPI1_io1_o;
  wire FPGA_SPI1_io1_t;
  wire FPGA_SPI1_sck_i;
  wire FPGA_SPI1_sck_io;
  wire FPGA_SPI1_sck_o;
  wire FPGA_SPI1_sck_t;
  wire FPGA_SPI1_ss_i;
  wire FPGA_SPI1_ss_io;
  wire FPGA_SPI1_ss_o;
  wire FPGA_SPI1_ss_t;
  wire FPGA_SPI2_io0_i;
  wire FPGA_SPI2_io0_io;
  wire FPGA_SPI2_io0_o;
  wire FPGA_SPI2_io0_t;
  wire FPGA_SPI2_io1_i;
  wire FPGA_SPI2_io1_io;
  wire FPGA_SPI2_io1_o;
  wire FPGA_SPI2_io1_t;
  wire FPGA_SPI2_sck_i;
  wire FPGA_SPI2_sck_io;
  wire FPGA_SPI2_sck_o;
  wire FPGA_SPI2_sck_t;
  wire FPGA_SPI2_ss_i;
  wire FPGA_SPI2_ss_io;
  wire FPGA_SPI2_ss_o;
  wire FPGA_SPI2_ss_t;
  wire [3:0]FPGA_TEST;
  wire PTP_CLK_OUT;
  wire PTP_TRG_FPGA;

  IOBUF A7_CONFIG_QSPI_io0_iobuf
       (.I(A7_CONFIG_QSPI_io0_o),
        .IO(A7_CONFIG_QSPI_io0_io),
        .O(A7_CONFIG_QSPI_io0_i),
        .T(A7_CONFIG_QSPI_io0_t));
  IOBUF A7_CONFIG_QSPI_io1_iobuf
       (.I(A7_CONFIG_QSPI_io1_o),
        .IO(A7_CONFIG_QSPI_io1_io),
        .O(A7_CONFIG_QSPI_io1_i),
        .T(A7_CONFIG_QSPI_io1_t));
  IOBUF A7_CONFIG_QSPI_io2_iobuf
       (.I(A7_CONFIG_QSPI_io2_o),
        .IO(A7_CONFIG_QSPI_io2_io),
        .O(A7_CONFIG_QSPI_io2_i),
        .T(A7_CONFIG_QSPI_io2_t));
  IOBUF A7_CONFIG_QSPI_io3_iobuf
       (.I(A7_CONFIG_QSPI_io3_o),
        .IO(A7_CONFIG_QSPI_io3_io),
        .O(A7_CONFIG_QSPI_io3_i),
        .T(A7_CONFIG_QSPI_io3_t));
  IOBUF A7_CONFIG_QSPI_ss_iobuf_0
       (.I(A7_CONFIG_QSPI_ss_o_0),
        .IO(A7_CONFIG_QSPI_ss_io[0]),
        .O(A7_CONFIG_QSPI_ss_i_0),
        .T(A7_CONFIG_QSPI_ss_t));
  IOBUF FMC_dq_iobuf_0
       (.I(FMC_dq_o_0),
        .IO(FMC_dq_io[0]),
        .O(FMC_dq_i_0),
        .T(FMC_dq_t_0));
  IOBUF FMC_dq_iobuf_1
       (.I(FMC_dq_o_1),
        .IO(FMC_dq_io[1]),
        .O(FMC_dq_i_1),
        .T(FMC_dq_t_1));
  IOBUF FMC_dq_iobuf_10
       (.I(FMC_dq_o_10),
        .IO(FMC_dq_io[10]),
        .O(FMC_dq_i_10),
        .T(FMC_dq_t_10));
  IOBUF FMC_dq_iobuf_11
       (.I(FMC_dq_o_11),
        .IO(FMC_dq_io[11]),
        .O(FMC_dq_i_11),
        .T(FMC_dq_t_11));
  IOBUF FMC_dq_iobuf_12
       (.I(FMC_dq_o_12),
        .IO(FMC_dq_io[12]),
        .O(FMC_dq_i_12),
        .T(FMC_dq_t_12));
  IOBUF FMC_dq_iobuf_13
       (.I(FMC_dq_o_13),
        .IO(FMC_dq_io[13]),
        .O(FMC_dq_i_13),
        .T(FMC_dq_t_13));
  IOBUF FMC_dq_iobuf_14
       (.I(FMC_dq_o_14),
        .IO(FMC_dq_io[14]),
        .O(FMC_dq_i_14),
        .T(FMC_dq_t_14));
  IOBUF FMC_dq_iobuf_15
       (.I(FMC_dq_o_15),
        .IO(FMC_dq_io[15]),
        .O(FMC_dq_i_15),
        .T(FMC_dq_t_15));
  IOBUF FMC_dq_iobuf_2
       (.I(FMC_dq_o_2),
        .IO(FMC_dq_io[2]),
        .O(FMC_dq_i_2),
        .T(FMC_dq_t_2));
  IOBUF FMC_dq_iobuf_3
       (.I(FMC_dq_o_3),
        .IO(FMC_dq_io[3]),
        .O(FMC_dq_i_3),
        .T(FMC_dq_t_3));
  IOBUF FMC_dq_iobuf_4
       (.I(FMC_dq_o_4),
        .IO(FMC_dq_io[4]),
        .O(FMC_dq_i_4),
        .T(FMC_dq_t_4));
  IOBUF FMC_dq_iobuf_5
       (.I(FMC_dq_o_5),
        .IO(FMC_dq_io[5]),
        .O(FMC_dq_i_5),
        .T(FMC_dq_t_5));
  IOBUF FMC_dq_iobuf_6
       (.I(FMC_dq_o_6),
        .IO(FMC_dq_io[6]),
        .O(FMC_dq_i_6),
        .T(FMC_dq_t_6));
  IOBUF FMC_dq_iobuf_7
       (.I(FMC_dq_o_7),
        .IO(FMC_dq_io[7]),
        .O(FMC_dq_i_7),
        .T(FMC_dq_t_7));
  IOBUF FMC_dq_iobuf_8
       (.I(FMC_dq_o_8),
        .IO(FMC_dq_io[8]),
        .O(FMC_dq_i_8),
        .T(FMC_dq_t_8));
  IOBUF FMC_dq_iobuf_9
       (.I(FMC_dq_o_9),
        .IO(FMC_dq_io[9]),
        .O(FMC_dq_i_9),
        .T(FMC_dq_t_9));
  IOBUF FPGA_MCU_SPI_io0_iobuf
       (.I(FPGA_MCU_SPI_io0_o),
        .IO(FPGA_MCU_SPI_io0_io),
        .O(FPGA_MCU_SPI_io0_i),
        .T(FPGA_MCU_SPI_io0_t));
  IOBUF FPGA_MCU_SPI_io1_iobuf
       (.I(FPGA_MCU_SPI_io1_o),
        .IO(FPGA_MCU_SPI_io1_io),
        .O(FPGA_MCU_SPI_io1_i),
        .T(FPGA_MCU_SPI_io1_t));
  IOBUF FPGA_MCU_SPI_sck_iobuf
       (.I(FPGA_MCU_SPI_sck_o),
        .IO(FPGA_MCU_SPI_sck_io),
        .O(FPGA_MCU_SPI_sck_i),
        .T(FPGA_MCU_SPI_sck_t));
  IOBUF FPGA_MCU_SPI_ss_iobuf
       (.I(FPGA_MCU_SPI_ss_o),
        .IO(FPGA_MCU_SPI_ss_io),
        .O(FPGA_MCU_SPI_ss_i),
        .T(FPGA_MCU_SPI_ss_t));
  IOBUF FPGA_SPI1_io0_iobuf
       (.I(FPGA_SPI1_io0_o),
        .IO(FPGA_SPI1_io0_io),
        .O(FPGA_SPI1_io0_i),
        .T(FPGA_SPI1_io0_t));
  IOBUF FPGA_SPI1_io1_iobuf
       (.I(FPGA_SPI1_io1_o),
        .IO(FPGA_SPI1_io1_io),
        .O(FPGA_SPI1_io1_i),
        .T(FPGA_SPI1_io1_t));
  IOBUF FPGA_SPI1_sck_iobuf
       (.I(FPGA_SPI1_sck_o),
        .IO(FPGA_SPI1_sck_io),
        .O(FPGA_SPI1_sck_i),
        .T(FPGA_SPI1_sck_t));
  IOBUF FPGA_SPI1_ss_iobuf
       (.I(FPGA_SPI1_ss_o),
        .IO(FPGA_SPI1_ss_io),
        .O(FPGA_SPI1_ss_i),
        .T(FPGA_SPI1_ss_t));
  IOBUF FPGA_SPI2_io0_iobuf
       (.I(FPGA_SPI2_io0_o),
        .IO(FPGA_SPI2_io0_io),
        .O(FPGA_SPI2_io0_i),
        .T(FPGA_SPI2_io0_t));
  IOBUF FPGA_SPI2_io1_iobuf
       (.I(FPGA_SPI2_io1_o),
        .IO(FPGA_SPI2_io1_io),
        .O(FPGA_SPI2_io1_i),
        .T(FPGA_SPI2_io1_t));
  IOBUF FPGA_SPI2_sck_iobuf
       (.I(FPGA_SPI2_sck_o),
        .IO(FPGA_SPI2_sck_io),
        .O(FPGA_SPI2_sck_i),
        .T(FPGA_SPI2_sck_t));
  IOBUF FPGA_SPI2_ss_iobuf
       (.I(FPGA_SPI2_ss_o),
        .IO(FPGA_SPI2_ss_io),
        .O(FPGA_SPI2_ss_i),
        .T(FPGA_SPI2_ss_t));
  coreboard1588_bd coreboard1588_bd_i
       (.A7_CONFIG_QSPI_io0_i(A7_CONFIG_QSPI_io0_i),
        .A7_CONFIG_QSPI_io0_o(A7_CONFIG_QSPI_io0_o),
        .A7_CONFIG_QSPI_io0_t(A7_CONFIG_QSPI_io0_t),
        .A7_CONFIG_QSPI_io1_i(A7_CONFIG_QSPI_io1_i),
        .A7_CONFIG_QSPI_io1_o(A7_CONFIG_QSPI_io1_o),
        .A7_CONFIG_QSPI_io1_t(A7_CONFIG_QSPI_io1_t),
        .A7_CONFIG_QSPI_io2_i(A7_CONFIG_QSPI_io2_i),
        .A7_CONFIG_QSPI_io2_o(A7_CONFIG_QSPI_io2_o),
        .A7_CONFIG_QSPI_io2_t(A7_CONFIG_QSPI_io2_t),
        .A7_CONFIG_QSPI_io3_i(A7_CONFIG_QSPI_io3_i),
        .A7_CONFIG_QSPI_io3_o(A7_CONFIG_QSPI_io3_o),
        .A7_CONFIG_QSPI_io3_t(A7_CONFIG_QSPI_io3_t),
        .A7_CONFIG_QSPI_ss_i(A7_CONFIG_QSPI_ss_i_0),
        .A7_CONFIG_QSPI_ss_o(A7_CONFIG_QSPI_ss_o_0),
        .A7_CONFIG_QSPI_ss_t(A7_CONFIG_QSPI_ss_t),
        .A7_GCLK(A7_GCLK),
        .AD1_RST(AD1_RST),
        .AD2_DRDY(AD2_DRDY),
        .AD2_RST(AD2_RST),
        .AD2_START(AD2_START),
        .CH_SEL_A0(CH_SEL_A0),
        .CH_SEL_A1(CH_SEL_A1),
        .CH_SEL_A2(CH_SEL_A2),
        .EN_PCH_A(EN_PCH_A),
        .EN_PCH_B(EN_PCH_B),
        .EN_TCH_A(EN_TCH_A),
        .EN_TCH_B(EN_TCH_B),
        .FMC_addr(FMC_addr),
        .FMC_adv_ldn(FMC_adv_ldn),
        .FMC_ben(FMC_ben),
        .FMC_ce_n(FMC_ce_n),
        .FMC_dq_i({FMC_dq_i_15,FMC_dq_i_14,FMC_dq_i_13,FMC_dq_i_12,FMC_dq_i_11,FMC_dq_i_10,FMC_dq_i_9,FMC_dq_i_8,FMC_dq_i_7,FMC_dq_i_6,FMC_dq_i_5,FMC_dq_i_4,FMC_dq_i_3,FMC_dq_i_2,FMC_dq_i_1,FMC_dq_i_0}),
        .FMC_dq_o({FMC_dq_o_15,FMC_dq_o_14,FMC_dq_o_13,FMC_dq_o_12,FMC_dq_o_11,FMC_dq_o_10,FMC_dq_o_9,FMC_dq_o_8,FMC_dq_o_7,FMC_dq_o_6,FMC_dq_o_5,FMC_dq_o_4,FMC_dq_o_3,FMC_dq_o_2,FMC_dq_o_1,FMC_dq_o_0}),
        .FMC_dq_t({FMC_dq_t_15,FMC_dq_t_14,FMC_dq_t_13,FMC_dq_t_12,FMC_dq_t_11,FMC_dq_t_10,FMC_dq_t_9,FMC_dq_t_8,FMC_dq_t_7,FMC_dq_t_6,FMC_dq_t_5,FMC_dq_t_4,FMC_dq_t_3,FMC_dq_t_2,FMC_dq_t_1,FMC_dq_t_0}),
        .FMC_oen(FMC_oen),
        .FMC_rd_clk(FMC_rd_clk),
        .FMC_wait(FMC_wait),
        .FMC_wen(FMC_wen),
        .FPGA_DAT_FIN(FPGA_DAT_FIN),
        .FPGA_LED(FPGA_LED),
        .FPGA_MCU_INTR(FPGA_MCU_INTR),
        .FPGA_MCU_RST(FPGA_MCU_RST),
        .FPGA_MCU_SPI_io0_i(FPGA_MCU_SPI_io0_i),
        .FPGA_MCU_SPI_io0_o(FPGA_MCU_SPI_io0_o),
        .FPGA_MCU_SPI_io0_t(FPGA_MCU_SPI_io0_t),
        .FPGA_MCU_SPI_io1_i(FPGA_MCU_SPI_io1_i),
        .FPGA_MCU_SPI_io1_o(FPGA_MCU_SPI_io1_o),
        .FPGA_MCU_SPI_io1_t(FPGA_MCU_SPI_io1_t),
        .FPGA_MCU_SPI_sck_i(FPGA_MCU_SPI_sck_i),
        .FPGA_MCU_SPI_sck_o(FPGA_MCU_SPI_sck_o),
        .FPGA_MCU_SPI_sck_t(FPGA_MCU_SPI_sck_t),
        .FPGA_MCU_SPI_ss_i(FPGA_MCU_SPI_ss_i),
        .FPGA_MCU_SPI_ss_o(FPGA_MCU_SPI_ss_o),
        .FPGA_MCU_SPI_ss_t(FPGA_MCU_SPI_ss_t),
        .FPGA_RST(FPGA_RST),
        .FPGA_RUN(FPGA_RUN),
        .FPGA_SPI1_io0_i(FPGA_SPI1_io0_i),
        .FPGA_SPI1_io0_o(FPGA_SPI1_io0_o),
        .FPGA_SPI1_io0_t(FPGA_SPI1_io0_t),
        .FPGA_SPI1_io1_i(FPGA_SPI1_io1_i),
        .FPGA_SPI1_io1_o(FPGA_SPI1_io1_o),
        .FPGA_SPI1_io1_t(FPGA_SPI1_io1_t),
        .FPGA_SPI1_sck_i(FPGA_SPI1_sck_i),
        .FPGA_SPI1_sck_o(FPGA_SPI1_sck_o),
        .FPGA_SPI1_sck_t(FPGA_SPI1_sck_t),
        .FPGA_SPI1_ss_i(FPGA_SPI1_ss_i),
        .FPGA_SPI1_ss_o(FPGA_SPI1_ss_o),
        .FPGA_SPI1_ss_t(FPGA_SPI1_ss_t),
        .FPGA_SPI2_io0_i(FPGA_SPI2_io0_i),
        .FPGA_SPI2_io0_o(FPGA_SPI2_io0_o),
        .FPGA_SPI2_io0_t(FPGA_SPI2_io0_t),
        .FPGA_SPI2_io1_i(FPGA_SPI2_io1_i),
        .FPGA_SPI2_io1_o(FPGA_SPI2_io1_o),
        .FPGA_SPI2_io1_t(FPGA_SPI2_io1_t),
        .FPGA_SPI2_sck_i(FPGA_SPI2_sck_i),
        .FPGA_SPI2_sck_o(FPGA_SPI2_sck_o),
        .FPGA_SPI2_sck_t(FPGA_SPI2_sck_t),
        .FPGA_SPI2_ss_i(FPGA_SPI2_ss_i),
        .FPGA_SPI2_ss_o(FPGA_SPI2_ss_o),
        .FPGA_SPI2_ss_t(FPGA_SPI2_ss_t),
        .FPGA_TEST(FPGA_TEST),
        .PTP_CLK_OUT(PTP_CLK_OUT),
        .PTP_TRG_FPGA(PTP_TRG_FPGA));
endmodule
