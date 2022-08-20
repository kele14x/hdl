# Default

SIM ?= icarus

# Module parameters

HAS_PHASE_GEN ?= 0
PHASE_WIDTH ?= 16
DATA_WIDTH ?= 16
INIT_PINC ?= 0
INIT_POFF ?= 0
NEGATIVE_COS ?= 0
NEGATIVE_SIN ?= 0

# Source files

TOPLEVEL := dds
TOPLEVEL_LANG = verilog

VERILOG_SOURCES += $(PWD)/../rtl/dds.v
VERILOG_SOURCES += $(PWD)/../rtl/dds_lut.v
VERILOG_SOURCES += $(PWD)/../rtl/dds_lut_block.v
VERILOG_SOURCES += $(PWD)/../rtl/dds_lut_fabric.v
VERILOG_SOURCES += $(PWD)/../rtl/dds_phase_gen.v
VERILOG_SOURCES += $(PWD)/../rtl/dds_rom.v

# Tools

ifeq ($(SIM),icarus)
	COMPILE_ARGS += -Pdds.HAS_PHASE_GEN=$(HAS_PHASE_GEN) -Pdds.PHASE_WIDTH=$(PHASE_WIDTH) -Pdds.DATA_WIDTH=$(DATA_WIDTH) -Pdds.INIT_PINC=$(INIT_PINC) -Pdds.INIT_POFF=$(INIT_POFF) -Pdds.NEGATIVE_COS=$(NEGATIVE_COS) -Pdds.NEGATIVE_SIN=$(NEGATIVE_SIN)
endif

# Test

MODULE := test_dds

include $(shell cocotb-config --makefiles)/Makefile.sim
