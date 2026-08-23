# Out-of-context clock constraints for puxch_top (Vivado 2026.1)
#   clk           491.52 MHz  -> period 2.034505 ns  (radio/FFT domain)
#   clk_eth_xran  400.00 MHz  -> period 2.500000 ns  (O-RAN eCPRI domain)
#   ctrl_clk      100.00 MHz  -> period 10.000000 ns (CSR domain)

create_clock -name clk          -period 2.034505 [get_ports clk]
create_clock -name clk_eth_xran -period 2.500000 [get_ports clk_eth_xran]
create_clock -name ctrl_clk     -period 10.00000 [get_ports ctrl_clk]

# The clock domains are asynchronous to each other (CDC paths are
# synchronized inside the RTL: cdc_pulse/cdc_array_single etc.).
set_clock_groups -asynchronous \
    -group {clk} \
    -group {clk_eth_xran} \
    -group {ctrl_clk}