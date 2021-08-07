#!/usr/bin/bash
source /opt/Xilinx/Vivado/2021.1/settings64.sh
vivado -mode batch -source build.tcl -nolog -nojou
