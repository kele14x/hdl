# Copyright (c) 2020 Chengdu JinZhiLi Technology Co., Ltd.
# All rights reserved.

# Configuration

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Pin Location

#set_property PACKAGE_PIN G15 [get_ports rst_0]
#set_property PACKAGE_PIN H22 [get_ports PL_LED_TEST_0]

## RTD SPI

set_property PACKAGE_PIN AB1  [get_ports GX_ADC_SYNC[0]]
set_property PACKAGE_PIN H15  [get_ports GX_ADC_SYNC[1]]
set_property PACKAGE_PIN W6   [get_ports GX_ADC_SYNC[2]]
set_property PACKAGE_PIN R16  [get_ports GX_ADC_SYNC[3]]
set_property PACKAGE_PIN V17  [get_ports GX_ADC_SYNC[4]]
set_property PACKAGE_PIN AA13 [get_ports GX_ADC_SYNC[5]]

set_property PACKAGE_PIN AB11 [get_ports GX_ANA_POW_EN[0]]
set_property PACKAGE_PIN J16  [get_ports GX_ANA_POW_EN[1]]
set_property PACKAGE_PIN V8   [get_ports GX_ANA_POW_EN[2]]
set_property PACKAGE_PIN R19  [get_ports GX_ANA_POW_EN[3]]
set_property PACKAGE_PIN V22  [get_ports GX_ANA_POW_EN[4]]
set_property PACKAGE_PIN W21  [get_ports GX_ANA_POW_EN[5]]

set_property PACKAGE_PIN Y10 [get_ports GX_RELAY_CTRL[0]]
set_property PACKAGE_PIN K15 [get_ports GX_RELAY_CTRL[1]]
set_property PACKAGE_PIN U9  [get_ports GX_RELAY_CTRL[2]]
set_property PACKAGE_PIN R20 [get_ports GX_RELAY_CTRL[3]]
set_property PACKAGE_PIN W22 [get_ports GX_RELAY_CTRL[4]]
set_property PACKAGE_PIN U19 [get_ports GX_RELAY_CTRL[5]]

set_property PULLDOWN true [get_ports GX_RELAY_CTRL[0]]
set_property PULLDOWN true [get_ports GX_RELAY_CTRL[1]]
set_property PULLDOWN true [get_ports GX_RELAY_CTRL[2]]
set_property PULLDOWN true [get_ports GX_RELAY_CTRL[3]]
set_property PULLDOWN true [get_ports GX_RELAY_CTRL[4]]
set_property PULLDOWN true [get_ports GX_RELAY_CTRL[5]]

set_property PACKAGE_PIN AA4  [get_ports GX_RTD_SPI_SCLK[0]]
set_property PACKAGE_PIN J18  [get_ports GX_RTD_SPI_SCLK[1]]
set_property PACKAGE_PIN U10  [get_ports GX_RTD_SPI_SCLK[2]]
set_property PACKAGE_PIN N18  [get_ports GX_RTD_SPI_SCLK[3]]
set_property PACKAGE_PIN AA21 [get_ports GX_RTD_SPI_SCLK[4]]
set_property PACKAGE_PIN U15  [get_ports GX_RTD_SPI_SCLK[5]]

set_property PACKAGE_PIN AB9  [get_ports GX_RTD_SPI_CSN[0]]
set_property PACKAGE_PIN R15  [get_ports GX_RTD_SPI_CSN[1]]
set_property PACKAGE_PIN AA11 [get_ports GX_RTD_SPI_CSN[2]]
set_property PACKAGE_PIN R21  [get_ports GX_RTD_SPI_CSN[3]]
set_property PACKAGE_PIN AB15 [get_ports GX_RTD_SPI_CSN[4]]
set_property PACKAGE_PIN V13  [get_ports GX_RTD_SPI_CSN[5]]

set_property PACKAGE_PIN Y5  [get_ports GX_RTD_SPI_SDO[0]]
set_property PACKAGE_PIN J17 [get_ports GX_RTD_SPI_SDO[1]]
set_property PACKAGE_PIN W12 [get_ports GX_RTD_SPI_SDO[2]]
set_property PACKAGE_PIN N17 [get_ports GX_RTD_SPI_SDO[3]]
set_property PACKAGE_PIN Y21 [get_ports GX_RTD_SPI_SDO[4]]
set_property PACKAGE_PIN V14 [get_ports GX_RTD_SPI_SDO[5]]

set_property PACKAGE_PIN W7   [get_ports GX_RTD_SPI_SDI[0]]
set_property PACKAGE_PIN P18  [get_ports GX_RTD_SPI_SDI[1]]
set_property PACKAGE_PIN R7   [get_ports GX_RTD_SPI_SDI[2]]
set_property PACKAGE_PIN T16  [get_ports GX_RTD_SPI_SDI[3]]
set_property PACKAGE_PIN AB14 [get_ports GX_RTD_SPI_SDI[4]]
set_property PACKAGE_PIN U14  [get_ports GX_RTD_SPI_SDI[5]]

## TC SPI

set_property PACKAGE_PIN AA6  [get_ports GX_TC_SPI_SCLK[0]]
set_property PACKAGE_PIN M17  [get_ports GX_TC_SPI_SCLK[1]]
set_property PACKAGE_PIN AB7  [get_ports GX_TC_SPI_SCLK[2]]
set_property PACKAGE_PIN T17  [get_ports GX_TC_SPI_SCLK[3]]
set_property PACKAGE_PIN AA18 [get_ports GX_TC_SPI_SCLK[4]]
set_property PACKAGE_PIN Y13  [get_ports GX_TC_SPI_SCLK[5]]

set_property PACKAGE_PIN Y6   [get_ports GX_TC_SPI_CSN[0]]
set_property PACKAGE_PIN AB4  [get_ports GX_TC_SPI_CSN[1]]
set_property PACKAGE_PIN AA7  [get_ports GX_TC_SPI_CSN[2]]
set_property PACKAGE_PIN W5   [get_ports GX_TC_SPI_CSN[3]]
set_property PACKAGE_PIN AA8  [get_ports GX_TC_SPI_CSN[4]]
set_property PACKAGE_PIN AB2  [get_ports GX_TC_SPI_CSN[5]]
set_property PACKAGE_PIN V4   [get_ports GX_TC_SPI_CSN[6]]
set_property PACKAGE_PIN AB10 [get_ports GX_TC_SPI_CSN[7]]

set_property PACKAGE_PIN L21 [get_ports GX_TC_SPI_CSN[8]]
set_property PACKAGE_PIN L16 [get_ports GX_TC_SPI_CSN[9]]
set_property PACKAGE_PIN K20 [get_ports GX_TC_SPI_CSN[10]]
set_property PACKAGE_PIN P22 [get_ports GX_TC_SPI_CSN[11]]
set_property PACKAGE_PIN J21 [get_ports GX_TC_SPI_CSN[12]]
set_property PACKAGE_PIN K18 [get_ports GX_TC_SPI_CSN[13]]
set_property PACKAGE_PIN J20 [get_ports GX_TC_SPI_CSN[14]]
set_property PACKAGE_PIN N15 [get_ports GX_TC_SPI_CSN[15]]

set_property PACKAGE_PIN V7   [get_ports GX_TC_SPI_CSN[16]]
set_property PACKAGE_PIN AA12 [get_ports GX_TC_SPI_CSN[17]]
set_property PACKAGE_PIN W8   [get_ports GX_TC_SPI_CSN[18]]
set_property PACKAGE_PIN U11  [get_ports GX_TC_SPI_CSN[19]]
set_property PACKAGE_PIN AA9  [get_ports GX_TC_SPI_CSN[20]]
set_property PACKAGE_PIN AB12 [get_ports GX_TC_SPI_CSN[21]]
set_property PACKAGE_PIN U7   [get_ports GX_TC_SPI_CSN[22]]
set_property PACKAGE_PIN W11  [get_ports GX_TC_SPI_CSN[23]]

set_property PACKAGE_PIN T18 [get_ports GX_TC_SPI_CSN[24]]
set_property PACKAGE_PIN M21 [get_ports GX_TC_SPI_CSN[25]]
set_property PACKAGE_PIN T19 [get_ports GX_TC_SPI_CSN[26]]
set_property PACKAGE_PIN L22 [get_ports GX_TC_SPI_CSN[27]]
set_property PACKAGE_PIN P15 [get_ports GX_TC_SPI_CSN[28]]
set_property PACKAGE_PIN M22 [get_ports GX_TC_SPI_CSN[29]]
set_property PACKAGE_PIN P21 [get_ports GX_TC_SPI_CSN[30]]
set_property PACKAGE_PIN N22 [get_ports GX_TC_SPI_CSN[31]]

set_property PACKAGE_PIN V18  [get_ports GX_TC_SPI_CSN[32]]
set_property PACKAGE_PIN AB21 [get_ports GX_TC_SPI_CSN[33]]
set_property PACKAGE_PIN V19  [get_ports GX_TC_SPI_CSN[34]]
set_property PACKAGE_PIN AB20 [get_ports GX_TC_SPI_CSN[35]]
set_property PACKAGE_PIN Y20  [get_ports GX_TC_SPI_CSN[36]]
set_property PACKAGE_PIN AB19 [get_ports GX_TC_SPI_CSN[37]]
set_property PACKAGE_PIN AA14 [get_ports GX_TC_SPI_CSN[38]]
set_property PACKAGE_PIN AB17 [get_ports GX_TC_SPI_CSN[39]]

set_property PACKAGE_PIN Y15 [get_ports GX_TC_SPI_CSN[40]]
set_property PACKAGE_PIN U22 [get_ports GX_TC_SPI_CSN[41]]
set_property PACKAGE_PIN Y14 [get_ports GX_TC_SPI_CSN[42]]
set_property PACKAGE_PIN T22 [get_ports GX_TC_SPI_CSN[43]]
set_property PACKAGE_PIN W15 [get_ports GX_TC_SPI_CSN[44]]
set_property PACKAGE_PIN T21 [get_ports GX_TC_SPI_CSN[45]]
set_property PACKAGE_PIN W13 [get_ports GX_TC_SPI_CSN[46]]
set_property PACKAGE_PIN U21 [get_ports GX_TC_SPI_CSN[47]]

set_property PACKAGE_PIN AB6  [get_ports GX_TC_SPI_SDO[0]]
set_property PACKAGE_PIN L19  [get_ports GX_TC_SPI_SDO[1]]
set_property PACKAGE_PIN U12  [get_ports GX_TC_SPI_SDO[2]]
set_property PACKAGE_PIN J22  [get_ports GX_TC_SPI_SDO[3]]
set_property PACKAGE_PIN AA22 [get_ports GX_TC_SPI_SDO[4]]
set_property PACKAGE_PIN U16  [get_ports GX_TC_SPI_SDO[5]]

set_property PACKAGE_PIN AB5  [get_ports GX_TC_SPI_SDI[0]]
set_property PACKAGE_PIN L17  [get_ports GX_TC_SPI_SDI[1]]
set_property PACKAGE_PIN V12  [get_ports GX_TC_SPI_SDI[2]]
set_property PACKAGE_PIN K21  [get_ports GX_TC_SPI_SDI[3]]
set_property PACKAGE_PIN AB22 [get_ports GX_TC_SPI_SDI[4]]
set_property PACKAGE_PIN U17  [get_ports GX_TC_SPI_SDI[5]]

# IO Standard

set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 34]];
#set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 35]];

## [EOF]
