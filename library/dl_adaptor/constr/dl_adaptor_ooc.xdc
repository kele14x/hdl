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

# File: dl_adaptor_ooc.xdc
# Brief: Out-of-context constraints for module dl_adaptor
create_clock -name clk_400m -period 2.5 [get_ports clk_400m]
create_clock -name clk_491m52 -period 2.035 [get_ports clk_491m52]
set_clock_groups -asynchronous -group clk_400m -group clk_491m52
