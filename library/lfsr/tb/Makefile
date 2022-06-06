# Default
SIM ?= icarus

TOPLEVEL_LANG = verilog

VERILOG_SOURCES += $(PWD)/../rtl/lfsr.v

ifeq ($(SIM),icarus)
	COMPILE_ARGS += -Plfsr.PARALLEL_OUTPUT=1
endif

# Fix the seed to ensure deterministic tests
export RANDOM_SEED := 123456

TOPLEVEL := lfsr

MODULE := test_lfsr

include $(shell cocotb-config --makefiles)/Makefile.sim
