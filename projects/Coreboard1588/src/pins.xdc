# Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd 
# All rights reserved.

# IO Standard
set_property IOSTANDARD LVCMOS33 [get_ports]

# LEDs
##
set_property PACKAGE_PIN A3 [get_ports FPGA_LED[0]]
set_property PACKAGE_PIN C2 [get_ports FPGA_LED[1]]

# FPGA Test
set_property PACKAGE_PIN R1 [get_ports FPGA_TEST[0]]
set_property PACKAGE_PIN V1 [get_ports FPGA_TEST[1]]
set_property PACKAGE_PIN U1 [get_ports FPGA_TEST[2]]
set_property PACKAGE_PIN T1 [get_ports FPGA_TEST[3]]

# MCU FPGA Interface
## GPIO
set_property PACKAGE_PIN R18 [get_ports FPGA_RST]
set_property PACKAGE_PIN P18 [get_ports FPGA_MCU_RST]
set_property PACKAGE_PIN U18 [get_ports FPGA_RUN]
 
## SPI
set_property PACKAGE_PIN C5 [get_ports FPGA_MCU_SPI_CLK]
set_property PACKAGE_PIN E2 [get_ports FPGA_MCU_SPI_CS]
set_property PACKAGE_PIN E1 [get_ports FPGA_MCU_SPI_MOSI]
set_property PACKAGE_PIN C1 [get_ports FPGA_MCU_SPI_MISO]

# FPGA Global Clock
set_property PACKAGE_PIN F4 [get_ports A7_GCLK]

# PHY
set_property PACKAGE_PIN E3 [get_ports PTP_CLK_OUT]
set_property PACKAGE_PIN A6 [get_ports PTP_TRG_FPGA]

# QSPI
set_property PACKAGE_PIN M14 [get_ports A7_CONFIG_DQ[3]]
set_property PACKAGE_PIN L14 [get_ports A7_CONFIG_DQ[2]]
set_property PACKAGE_PIN K18 [get_ports A7_CONFIG_DQ[1]]
set_property PACKAGE_PIN K17 [get_ports A7_CONFIG_DQ[0]]
set_property PACKAGE_PIN L13 [get_ports A7_CONFIG_FCS_B]

# FPGA Configuration Properties
set_property CONFIG_VOLTAGE  3.3   [current_design]
set_property CFGBVS          VCCO  [current_design]
set_property CONFIG_MODE     SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH      4      [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE        40     [current_design]
