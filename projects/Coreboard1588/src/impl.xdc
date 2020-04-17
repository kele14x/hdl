# Rename Auto-Derived Clocks

# Create clocks that not use MMCM/PLL

# FMC clock
create_clock -name FMC_CLK -period 10 [get_ports FMC_CLK]

# SPI clock
create_clock -name SPI_CLK -period 10 [get_ports FPGA_SPI1_CLK]

# FPGA Configuration Properties
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 40 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
