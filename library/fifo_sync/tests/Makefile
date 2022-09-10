SIM = questa

TOPLEVEL_LANG = verilog
TOPLEVEL = fifo_sync

PWD = $(shell pwd)

VERILOG_SOURCES += $(PWD)/../rtl/fifo_sync.sv
VERILOG_SOURCES += $(PWD)/../../ram/ram_sdp.sv

MODULE = test_fifo_sync

include $(shell cocotb-config --makefiles)/Makefile.sim
