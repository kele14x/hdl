# Out-of-context clock constraints for lowphy0 (tool-version agnostic)
#   lowphy0 wrapper: AXI/CSR (s_axi_aclk) + radio (clk) + O-RAN (internal_bus_clk)
#   s_axi_aclk       100.00 MHz  -> period 10.000000 ns (AXI4-Lite / CSR)
#   clk              491.52 MHz  -> period 2.034505 ns  (radio/FFT domain)
#   internal_bus_clk 400.00 MHz  -> period 2.500000 ns  (O-RAN eCPRI domain)

create_clock -name s_axi_aclk      -period 10.00000 [get_ports s_axi_aclk]
create_clock -name clk             -period 2.034505 [get_ports clk]
create_clock -name internal_bus_clk -period 2.500000 [get_ports internal_bus_clk]

# The clock domains are asynchronous to each other (CDC crossings are
# synchronized inside the RTL: cdc_single / cdc_pulse / cdc_handshake_f etc.).
set_clock_groups -asynchronous \
    -group {s_axi_aclk} \
    -group {clk} \
    -group {internal_bus_clk}
