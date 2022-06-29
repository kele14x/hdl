SIM ?= icarus
TOPLEVEL_LANG = verilog

FFT_SIZE ?= 16
INPUT_DATA_WIDTH ?= 16
PHASE_WIDTH ?= 16
OUTPUT_DATA_WIDTH ?= 21
HAS_BITREVERSE ?= 0

VERILOG_SOURCES += $(PWD)/iverilog_dump.v
VERILOG_SOURCES += $(PWD)/../rtl/fft.v
VERILOG_SOURCES += $(PWD)/../rtl/fft_bf2.v
VERILOG_SOURCES += $(PWD)/../rtl/fft_bitreverse.v
VERILOG_SOURCES += $(PWD)/../rtl/fft_core.v
VERILOG_SOURCES += $(PWD)/../rtl/fft_stage.v
VERILOG_SOURCES += $(PWD)/../rtl/fft_twiddle_rom.v
VERILOG_SOURCES += $(PWD)/../../cmult/rtl/cmult.v
VERILOG_SOURCES += $(PWD)/../../ram/ram_sdp.v
VERILOG_SOURCES += $(PWD)/../../shift_ram/rtl/shift_ram.v
VERILOG_SOURCES += $(PWD)/../../util/delay.v
VERILOG_SOURCES += $(PWD)/../../util/shift_regs.v

TOPLEVEL = fft
COMPILE_ARGS += -Pfft.FFT_SIZE=$(FFT_SIZE)
COMPILE_ARGS += -Pfft.INPUT_DATA_WIDTH=$(INPUT_DATA_WIDTH)
COMPILE_ARGS += -Pfft.PHASE_WIDTH=$(PHASE_WIDTH)
COMPILE_ARGS += -Pfft.OUTPUT_DATA_WIDTH=$(OUTPUT_DATA_WIDTH)
COMPILE_ARGS += -Pfft.HAS_BITREVERSE=$(HAS_BITREVERSE)

MODULE = test_fft

include $(shell cocotb-config --makefiles)/Makefile.sim
