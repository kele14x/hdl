SIM = questa

TOPLEVEL_LANG = verilog
TOPLEVEL = dummy_source

PWD = $(shell pwd)

VERILOG_SOURCES += $(PWD)/../../lfsr/rtl/lfsr.sv
VERILOG_SOURCES += $(PWD)/../../mult/rtl/mult.sv
VERILOG_SOURCES += $(PWD)/../../util/shift_regs.sv
VERILOG_SOURCES += $(PWD)/../rtl/dummy_source.sv

MODULE = test_dummy_source

include $(shell cocotb-config --makefiles)/Makefile.sim
