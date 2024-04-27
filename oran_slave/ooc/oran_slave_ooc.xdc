create_clock -name s_axi_aclk -period 10 [get_ports s_axi_aclk]
create_clock -name eth_clk -period 6.4 [get_ports eth_clk]
create_clock -name clk -period 2 [get_ports clk]
