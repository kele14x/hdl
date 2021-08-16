# File: cfr_ooc.xdc
# Brief: Out-of-context constraints for module cfr_ooc
create_clock -name clk -period 2 [get_ports clk]
create_clock -name ctrl_clk -period 10 [get_ports ctrl_clk]
set_clock_groups -asynchronous -group clk -group ctrl_clk
