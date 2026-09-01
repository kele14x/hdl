# Out-of-context clock constraints for prach (tool-version agnostic)
#   prach wrapper: AXI/CSR (s_axi_aclk) + radio (clk) + O-RAN (clk_eth_xran)
#   s_axi_aclk    100.00 MHz  -> period 10.000000 ns (AXI4-Lite / CSR, feeds ctrl_clk)
#   clk           491.52 MHz  -> period 2.034505 ns  (radio/FFT domain)
#   clk_eth_xran  400.00 MHz  -> period 2.500000 ns  (O-RAN eCPRI domain)

create_clock -name s_axi_aclk   -period 10.00000 [get_ports s_axi_aclk]
create_clock -name clk          -period 2.034505 [get_ports clk]
create_clock -name clk_eth_xran -period 2.500000 [get_ports clk_eth_xran]

# The clock domains are asynchronous to each other (CDC paths are
# synchronized inside the RTL: cdc_pulse/cdc_array_single etc.).
set_clock_groups -asynchronous \
    -group {s_axi_aclk} \
    -group {clk} \
    -group {clk_eth_xran}
