SIM ?= icarus
TOPLEVEL_LANG = verilog

VERILOG_SOURCES += $(PWD)/../rtl/fft.v
VERILOG_SOURCES += $(PWD)/../rtl/fft_bf2.v
VERILOG_SOURCES += $(PWD)/../rtl/fft_stage.v
VERILOG_SOURCES += $(PWD)/../rtl/fft_twiddle_rom.v
VERILOG_SOURCES += $(PWD)/../../cmult/rtl/cmult.v
VERILOG_SOURCES += $(PWD)/../../ram/ram_sdp.v
VERILOG_SOURCES += $(PWD)/../../shift_ram/rtl/shift_ram.v
VERILOG_SOURCES += $(PWD)/../../util/delay.v
VERILOG_SOURCES += $(PWD)/../../util/shift_regs.v

TOPLEVEL = fft

MODULE = test_fft

include $(shell cocotb-config --makefiles)/Makefile.sim
