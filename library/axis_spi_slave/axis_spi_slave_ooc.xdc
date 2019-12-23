#=============================================================================
#
# Copyright (C) 2019 Kele
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#=============================================================================

create_clock -period 8.000 -name aclk [get_ports aclk]
create_clock -period 62.000 -name sck [get_ports SCK]

set_max_delay -datapath_only -from [get_clocks aclk] -to [get_clocks sck] 8.000
set_max_delay -datapath_only -from [get_clocks sck] -to [get_clocks aclk] 8.000
