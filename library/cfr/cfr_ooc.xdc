#*******************************************************************************
#  Copyright (C) 2020  kele14x
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#*******************************************************************************

# File: cfr_ooc.xdc
# Brief: Out-of-context constraints for module cfr_ooc
create_clock -name clk -period 2 [get_ports clk]
create_clock -name aclk -period 2 [get_ports aclk]
set_clock_groups -asynchronous -group clk -group aclk
