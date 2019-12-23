# Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
# All rights reserved.

create_clock -name s_axi_aclk  -period 10 [get_ports s_axi_aclk ]
create_clock -name m_axis_aclk -period 8  [get_ports m_axis_aclk]
