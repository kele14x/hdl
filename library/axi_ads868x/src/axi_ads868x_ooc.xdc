# Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
# All rights reserved.

create_clock -name aclk -period 8 [get_ports aclk]
set_property HD.CLK_SRC BUFGCTRL_X0Y0 [get_ports aclk]
