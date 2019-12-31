
create_clock -period 10.000 -name aclk -waveform {0.000 5.000} [get_ports aclk]
set_property HD.CLK_SRC BUFGCTRL_X0Y0 [get_ports aclk]
