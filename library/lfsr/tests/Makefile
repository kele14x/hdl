SIM ?= questa

PWD = $(shell pwd)

BIT_WIDTH ?= 8
INITIAL ?= 8\'b11111111
POLYNOMIAL ?= 8\'b00000011
STRUCTURE ?= \"FIBONACCI\"
GATE_TYPE ?= \"XOR\"
PARALLEL_OUTPUT ?= 1


TOPLEVEL := lfsr
TOPLEVEL_LANG = verilog

VERILOG_SOURCES += $(PWD)/../rtl/lfsr.sv

ifeq ($(SIM),questa)
	SIM_ARGS += -gBIT_WIDTH=$(BIT_WIDTH)
	SIM_ARGS += -gINITIAL=$(INITIAL)
	SIM_ARGS += -gPOLYNOMIAL=$(POLYNOMIAL)
	SIM_ARGS += -gSTRUCTURE=$(STRUCTURE)
	SIM_ARGS += -gGATE_TYPE=$(GATE_TYPE)
	SIM_ARGS += -gPARALLEL_OUTPUT=$(PARALLEL_OUTPUT)
endif

export PYTHONPATH := $(PWD)/../../
MODULE := test_lfsr

include $(shell cocotb-config --makefiles)/Makefile.sim
