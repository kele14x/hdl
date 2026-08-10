# Out-of-context clock constraints for pdxch_top (Vivado 2026.1)
#   clk          491.52 MHz  -> period 2.034505 ns  (radio/FFT domain)
#   clk_eth_xran 400.00 MHz  -> period 2.500000 ns  (O-RAN eCPRI domain)
# NOTE: ctrl_clk (CSR domain) left unconstrained for OOC resource run.

create_clock -name clk          -period 2.034505 [get_ports clk]
create_clock -name clk_eth_xran -period 2.500000 [get_ports clk_eth_xran]
