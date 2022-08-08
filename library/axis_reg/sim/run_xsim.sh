#!/bin/sh
xvlog -sv -f axis_reg_compile_list.f -L uvm
xelab tb_axis_reg -relax -s top -timescale 1ns/1ps  
xsim top -runall 
