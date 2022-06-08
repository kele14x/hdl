# Default

SIM ?= icarus

# Module parameters

BIT_WIDTH ?= 8
INITIAL ?= 8\'b11111111
POLYNOMIAL ?= 8\'b01101001
STRUCTURE ?= \"FIBONACCI\"
GATE_TYPE ?= \"XOR\"
PARALLEL_OUTPUT ?= 1\'b0

# Source files

TOPLEVEL := lfsr
TOPLEVEL_LANG = verilog

VERILOG_SOURCES += $(PWD)/../rtl/lfsr.v

# Tools

ifeq ($(SIM),icarus)
	COMPILE_ARGS += -Plfsr.BIT_WIDTH=$(BIT_WIDTH) -Plfsr.INITIAL=$(INITIAL) -Plfsr.POLYNOMIAL=$(POLYNOMIAL) -Plfsr.STRUCTURE=$(STRUCTURE) -Plfsr.GATE_TYPE=$(GATE_TYPE) -Plfsr.PARALLEL_OUTPUT=$(PARALLEL_OUTPUT)
endif

# Test

MODULE := test_lfsr

include $(shell cocotb-config --makefiles)/Makefile.sim
