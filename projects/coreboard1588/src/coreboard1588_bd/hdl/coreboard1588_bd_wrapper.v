//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
//Date        : Tue Mar  3 01:16:29 2020
//Host        : Kele19e running 64-bit major release  (build 9200)
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
    FPGA_LED,
    FPGA_MCU_INTR_interrupt,
    FPGA_MCU_RST,
    FPGA_MCU_SPI_io0_io,
    FPGA_MCU_SPI_io1_io,
    FPGA_MCU_SPI_sck_io,
    FPGA_MCU_SPI_ss_io,
    FPGA_RST,
    FPGA_RUN,
    FPGA_TEST,
    PTP_CLK_OUT,
    PTP_TRG_FPGA);
  inout A7_CONFIG_QSPI_io0_io;
  inout A7_CONFIG_QSPI_io1_io;
  inout A7_CONFIG_QSPI_io2_io;
  inout A7_CONFIG_QSPI_io3_io;
  inout [0:0]A7_CONFIG_QSPI_ss_io;
  input A7_GCLK;
  output [1:0]FPGA_LED;
  output FPGA_MCU_INTR_interrupt;
  output [0:0]FPGA_MCU_RST;
  inout FPGA_MCU_SPI_io0_io;
  inout FPGA_MCU_SPI_io1_io;
  inout FPGA_MCU_SPI_sck_io;
  inout FPGA_MCU_SPI_ss_io;
  input FPGA_RST;
  output [0:0]FPGA_RUN;
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
  wire [1:0]FPGA_LED;
  wire FPGA_MCU_INTR_interrupt;
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
        .FPGA_LED(FPGA_LED),
        .FPGA_MCU_INTR_interrupt(FPGA_MCU_INTR_interrupt),
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
        .FPGA_TEST(FPGA_TEST),
        .PTP_CLK_OUT(PTP_CLK_OUT),
        .PTP_TRG_FPGA(PTP_TRG_FPGA));
endmodule
