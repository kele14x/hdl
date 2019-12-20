# Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
# All rights reserved.

#
create_clock -name axi_clk -period 10 [get_ports aclk]
set_property HD.CLK_SRC BUFGCTRL_X0Y16 [get_ports aclk]
