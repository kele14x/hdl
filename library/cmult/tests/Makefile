SIM = questa 

A_WIDTH ?= 16
B_WIDTH ?= 16
P_WIDTH ?= 16
SRA_BITS ?= 15

TOPLEVEL_LANG = verilog
TOPLEVEL = cmult

VERILOG_SOURCES += $(PWD)/../rtl/cmult.sv

ifeq ($(SIM),icarus)
	COMPILE_ARGS += -Pcmult.A_WIDTH=$(A_WIDTH)
	COMPILE_ARGS += -Pcmult.B_WIDTH=$(B_WIDTH)
	COMPILE_ARGS += -Pcmult.P_WIDTH=$(P_WIDTH)
	COMPILE_ARGS += -Pcmult.SRA_BITS=$(SRA_BITS)
endif

MODULE = test_cmult

include $(shell cocotb-config --makefiles)/Makefile.sim
