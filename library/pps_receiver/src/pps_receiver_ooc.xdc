

create_clock -name clk  -period  8 [get_ports  clk]
create_clock -name aclk -period 10 [get_ports aclk]

set_max_delay -datapath_only -from [get_clocks clk] -to [get_clocks aclk] 8