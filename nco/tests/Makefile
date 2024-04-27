SIM ?= questa

PHASE_FRACTION_WIDTH ?= 20
PHASE_ENTRIES ?= 3072
DATA_WIDTH ?= 16
LFSR_INITIAL ?= 20\'hFFFFF
LFSR_POLYNOMIAL ?= 21\'h100005

TOPLEVEL := nco
TOPLEVEL_LANG = verilog

VERILOG_SOURCES += $(PWD)/../rtl/nco.sv
VERILOG_SOURCES += $(PWD)/../rtl/nco_lut.sv
VERILOG_SOURCES += $(PWD)/../../lfsr/rtl/lfsr.sv

ifeq ($(SIM),questa)
	SIM_ARGS += -gPHASE_FRACTION_WIDTH=$(PHASE_FRACTION_WIDTH)
	SIM_ARGS += -gPHASE_ENTRIES=$(PHASE_ENTRIES)
	SIM_ARGS += -gDATA_WIDTH=$(DATA_WIDTH)
	SIM_ARGS += -gLFSR_INITIAL=$(LFSR_INITIAL)
	SIM_ARGS += -gLFSR_POLYNOMIAL=$(LFSR_POLYNOMIAL)
endif

export PYTHONPATH := $(PWD)/../../
MODULE := test_nco

include $(shell cocotb-config --makefiles)/Makefile.sim
