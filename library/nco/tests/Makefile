SIM ?= questa

PHASE_WIDTH ?= 32
PHASE_ENTRIES ?= 3072
DATA_WIDTH ?= 16

TOPLEVEL := nco
TOPLEVEL_LANG = verilog

VERILOG_SOURCES += $(PWD)/../rtl/nco.sv
VERILOG_SOURCES += $(PWD)/../rtl/nco_lut.sv
VERILOG_SOURCES += $(PWD)/../../lfsr/rtl/lfsr.sv

MODULE := test_nco

export PYTHONPATH := $(PWD)/../../

include $(shell cocotb-config --makefiles)/Makefile.sim
