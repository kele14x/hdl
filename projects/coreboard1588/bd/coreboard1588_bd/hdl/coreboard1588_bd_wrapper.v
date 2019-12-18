//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2700185 Thu Oct 24 18:46:05 MDT 2019
//Date        : Wed Dec 18 15:33:55 2019
//Host        : CN-00002823 running 64-bit major release  (build 9200)
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
    FPGA_MCU_INTR_interrupt,
    FPGA_RST);
  inout A7_CONFIG_QSPI_io0_io;
  inout A7_CONFIG_QSPI_io1_io;
  inout A7_CONFIG_QSPI_io2_io;
  inout A7_CONFIG_QSPI_io3_io;
  inout [0:0]A7_CONFIG_QSPI_ss_io;
  input A7_GCLK;
  output FPGA_MCU_INTR_interrupt;
  input FPGA_RST;

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
  wire FPGA_MCU_INTR_interrupt;
  wire FPGA_RST;

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
        .FPGA_MCU_INTR_interrupt(FPGA_MCU_INTR_interrupt),
        .FPGA_RST(FPGA_RST));
endmodule
