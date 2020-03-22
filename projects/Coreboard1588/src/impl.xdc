# Rename Auto-Derived Clocks

# Create clocks that not use MMCM/PLL

# FMC clock
create_clock -name FMC_CLK -period 10 [get_ports FMC_CLK]

# SPI clock
create_clock -name SPI_CLK -period 10 [get_ports FPGA_SPI1_CLK]
