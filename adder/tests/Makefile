SIM = questa

A_WIDTH ?= 8
B_WIDTH ?= 8
P_WIDTH ?= 9
SRA_BITS ?= 0

TOPLEVEL_LANG = verilog
TOPLEVEL = adder

PWD = $(shell pwd)

VERILOG_SOURCES += $(PWD)/../rtl/adder.sv

# VSIM_ARGS += -onfinish stop

ifeq ($(SIM),icarus)
	COMPILE_ARGS += -Padder.A_WIDTH=$(A_WIDTH)
	COMPILE_ARGS += -Padder.B_WIDTH=$(B_WIDTH)
	COMPILE_ARGS += -Padder.P_WIDTH=$(P_WIDTH)
	COMPILE_ARGS += -Padder.SRA_BITS=$(SRA_BITS)
endif

MODULE = test_adder

include $(shell cocotb-config --makefiles)/Makefile.sim
