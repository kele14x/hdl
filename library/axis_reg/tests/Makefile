SIM ?= questa

PWD=$(shell pwd)

VERILOG_SOURCES = $(PWD)/../rtl/axis_reg.sv

MODULE := testbench

TOPLEVEL=axis_reg
TOPLEVEL_LANG=verilog

include $(shell cocotb-config --makefiles)/Makefile.sim
