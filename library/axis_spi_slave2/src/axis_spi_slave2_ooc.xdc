# Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
# All rights reserved.

create_clock -name aclk -period 10 [get_ports aclk]
set_property HD.CLK_SRC BUFGCTRL_X0Y16 [get_ports aclk]

create_clock -name spi_clk -period 60 [get_ports SCK_I]
set_property HD.CLK_SRC BUFGCTRL_X0Y17 [get_ports SCK_I]

set_clock_groups -asynchronous -group [get_clocks aclk] -group [get_clocks spi_clk]
