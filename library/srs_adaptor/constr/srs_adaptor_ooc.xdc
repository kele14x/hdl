# File: srs_adaptor_ooc.xdc
# Brief: Out-of-context constraints for module srs_adaptor
create_clock -name clk_400m -period 2.5 [get_ports clk_400m]
create_clock -name clk_491m52 -period 2.035 [get_ports clk_491m52]
set_clock_groups -asynchronous -group clk_400m -group clk_491m52
