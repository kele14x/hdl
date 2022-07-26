SIM = questa

A_WIDTH ?= 16
B_WIDTH ?= 16
P_WIDTH ?= 16
SRA_BITS ?= 15

TOPLEVEL_LANG = verilog
TOPLEVEL = mult

PWD = $(shell pwd)

VERILOG_SOURCES += $(PWD)/../rtl/mult.sv

ifeq ($(SIM),questa)
	SIM_ARGS += -gA_WIDTH=$(A_WIDTH)
	SIM_ARGS += -gB_WIDTH=$(B_WIDTH)
	SIM_ARGS += -gP_WIDTH=$(P_WIDTH)
	SIM_ARGS += -gSRA_BITS=$(SRA_BITS)
endif

MODULE = test_mult

include $(shell cocotb-config --makefiles)/Makefile.sim
