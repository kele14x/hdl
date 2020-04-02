# Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd
# All rights reserved.

# IO Standard
set_property IOSTANDARD LVCMOS33 [get_ports *]

# LEDs
##
set_property PACKAGE_PIN A3 [get_ports {FPGA_LED[0]}]
set_property PACKAGE_PIN C2 [get_ports {FPGA_LED[1]}]

# FPGA Test
set_property PACKAGE_PIN R1 [get_ports {FPGA_TEST[0]}]
set_property PACKAGE_PIN V1 [get_ports {FPGA_TEST[1]}]
set_property PACKAGE_PIN U1 [get_ports {FPGA_TEST[2]}]
set_property PACKAGE_PIN T1 [get_ports {FPGA_TEST[3]}]

# MCU FPGA Interface
## GPIO
set_property PACKAGE_PIN R18 [get_ports FPGA_RST]
set_property PACKAGE_PIN P18 [get_ports FPGA_MCU_RST]
set_property PACKAGE_PIN U18 [get_ports FPGA_RUN]
set_property PACKAGE_PIN C17 [get_ports FPGA_DAT_FIN]

## SPI
set_property PACKAGE_PIN C5 [get_ports FPGA_MCU_SPI_CLK]
set_property PACKAGE_PIN E2 [get_ports FPGA_MCU_SPI_CS]
set_property PACKAGE_PIN E1 [get_ports FPGA_MCU_SPI_MOSI]
set_property PACKAGE_PIN C1 [get_ports FPGA_MCU_SPI_MISO]

## FMC
set_property PACKAGE_PIN T5 [get_ports FMC_CLK]
set_property PACKAGE_PIN M3 [get_ports FMC_A[0]]
set_property PACKAGE_PIN M2 [get_ports FMC_A[1]]
set_property PACKAGE_PIN L5 [get_ports FMC_A[2]]
set_property PACKAGE_PIN K5 [get_ports FMC_A[3]]
set_property PACKAGE_PIN K6 [get_ports FMC_A[4]]
set_property PACKAGE_PIN N5 [get_ports FMC_A[5]]
set_property PACKAGE_PIN K3 [get_ports FMC_A[6]]
set_property PACKAGE_PIN L4 [get_ports FMC_A[7]]
set_property PACKAGE_PIN L3 [get_ports FMC_A[8]]
set_property PACKAGE_PIN N2 [get_ports FMC_A[9]]
set_property PACKAGE_PIN M4 [get_ports FMC_A[10]]
set_property PACKAGE_PIN P2 [get_ports FMC_A[11]]

set_property PACKAGE_PIN U8	[get_ports FMC_D[0]]
set_property PACKAGE_PIN V6	[get_ports FMC_D[1]]
set_property PACKAGE_PIN U4	[get_ports FMC_D[10]]
set_property PACKAGE_PIN V2	[get_ports FMC_D[11]]
set_property PACKAGE_PIN T4	[get_ports FMC_D[12]]
set_property PACKAGE_PIN V4	[get_ports FMC_D[13]]
set_property PACKAGE_PIN V5	[get_ports FMC_D[15]]
set_property PACKAGE_PIN P4	[get_ports FMC_D[14]]
set_property PACKAGE_PIN U7	[get_ports FMC_D[2]]
set_property PACKAGE_PIN V9	[get_ports FMC_D[3]]
set_property PACKAGE_PIN R2	[get_ports FMC_D[4]]
set_property PACKAGE_PIN P3	[get_ports FMC_D[5]]
set_property PACKAGE_PIN R3	[get_ports FMC_D[6]]
set_property PACKAGE_PIN U2	[get_ports FMC_D[7]]
set_property PACKAGE_PIN U3	[get_ports FMC_D[8]]
set_property PACKAGE_PIN T3	[get_ports FMC_D[9]]

set_property PACKAGE_PIN M1	[get_ports FMC_NBL[0]]
set_property PACKAGE_PIN L1	[get_ports FMC_NBL[1]]
set_property PACKAGE_PIN R5	[get_ports FMC_NE]
set_property PACKAGE_PIN R8	[get_ports FMC_NWAIT]
set_property PACKAGE_PIN N1	[get_ports FMC_NL]
set_property PACKAGE_PIN V7	[get_ports FMC_NOE]
set_property PACKAGE_PIN U6	[get_ports FMC_NWE]

# FPGA Global Clock
set_property PACKAGE_PIN F4 [get_ports A7_GCLK]

# PHY
set_property PACKAGE_PIN E3 [get_ports PTP_CLK_OUT]
set_property PACKAGE_PIN A6 [get_ports PTP_TRG_FPGA]

# QSPI
set_property PACKAGE_PIN M14 [get_ports {A7_CONFIG_DQ[3]}]
set_property PACKAGE_PIN L14 [get_ports {A7_CONFIG_DQ[2]}]
set_property PACKAGE_PIN K18 [get_ports {A7_CONFIG_DQ[1]}]
set_property PACKAGE_PIN K17 [get_ports {A7_CONFIG_DQ[0]}]
set_property PACKAGE_PIN L13 [get_ports A7_CONFIG_FCS_B]

# ADS8684

set_property PACKAGE_PIN J18 [get_ports FPGA_SPI1_CS]
set_property PACKAGE_PIN G18 [get_ports FPGA_SPI1_CLK]
set_property PACKAGE_PIN E18 [get_ports FPGA_SPI1_MOSI]
set_property PACKAGE_PIN F18 [get_ports FPGA_SPI1_MISO]

set_property PACKAGE_PIN B18 [get_ports AD1_RST]

set_property PACKAGE_PIN D18 [get_ports {CH_SEL_A[0]}]
set_property PACKAGE_PIN A16 [get_ports {CH_SEL_A[1]}]
set_property PACKAGE_PIN A18 [get_ports {CH_SEL_A[2]}]

set_property PACKAGE_PIN A15 [get_ports EN_TCH_A]
set_property PACKAGE_PIN A14 [get_ports EN_PCH_A]
set_property PACKAGE_PIN B14 [get_ports EN_TCH_B]
set_property PACKAGE_PIN A13 [get_ports EN_PCH_B]

# FPGA Configuration Properties
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 40 [current_design]

