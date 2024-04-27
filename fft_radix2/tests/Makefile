SIM ?= questa
TOPLEVEL_LANG = verilog

LOG_FFT_SIZE ?= 10
INPUT_DATA_WIDTH ?= 16
PHASE_WIDTH ?= 16
OUTPUT_DATA_WIDTH ?= 18
HAS_BITREVERSE ?= 1

VERILOG_SOURCES += $(PWD)/../../cmult/rtl/cmult.sv
VERILOG_SOURCES += $(PWD)/../../ram/rtl/ram_sdp.sv
VERILOG_SOURCES += $(PWD)/../../shift_ram/rtl/shift_ram.sv
VERILOG_SOURCES += $(PWD)/../../util/delay.sv
VERILOG_SOURCES += $(PWD)/../rtl/fft_radix2_bf2.sv
VERILOG_SOURCES += $(PWD)/../rtl/fft_radix2_core.sv
VERILOG_SOURCES += $(PWD)/../rtl/fft_radix2_stage.sv
VERILOG_SOURCES += $(PWD)/../rtl/fft_radix2_twiddle_rom.sv
VERILOG_SOURCES += $(PWD)/../rtl/fft_radix2_twiddle.sv
VERILOG_SOURCES += $(PWD)/../rtl/fft_radix2.sv

TOPLEVEL = fft_radix2
SIM_ARGS += -gLOG_FFT_SIZE=$(LOG_FFT_SIZE)
SIM_ARGS += -gINPUT_DATA_WIDTH=$(INPUT_DATA_WIDTH)
SIM_ARGS += -gPHASE_WIDTH=$(PHASE_WIDTH)
SIM_ARGS += -gOUTPUT_DATA_WIDTH=$(OUTPUT_DATA_WIDTH)
SIM_ARGS += -gHAS_BITREVERSE=$(HAS_BITREVERSE)

MODULE = test_fft_radix2

include $(shell cocotb-config --makefiles)/Makefile.sim
