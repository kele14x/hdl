# File: eth_pkt_fifo_ooc.xdc
# Brief: Out-of-context constraints for module eth_pkt_fifo
create_clock -name clk -period 2 [get_ports aclk]
