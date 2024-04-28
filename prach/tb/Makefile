SIM ?=questa
TOPLEVEL_LANG ?= verilog
WAVES ?= 1

# VERILOG_SOURCES += $(PWD)/../src/cdc_sync.sv
VERILOG_SOURCES += $(PWD)/../src/cmult.sv
VERILOG_SOURCES += $(PWD)/../src/delay.sv
VERILOG_SOURCES += $(PWD)/../src/mult.sv
VERILOG_SOURCES += $(PWD)/../src/prach_buffer.sv
VERILOG_SOURCES += $(PWD)/../src/prach_buffer_ch.sv
VERILOG_SOURCES += $(PWD)/../src/prach_buffer_readout.sv
VERILOG_SOURCES += $(PWD)/../src/prach_c_plane.sv
VERILOG_SOURCES += $(PWD)/../src/prach_conv.sv
VERILOG_SOURCES += $(PWD)/../src/prach_conv_nco.sv
VERILOG_SOURCES += $(PWD)/../src/prach_ddc.sv
VERILOG_SOURCES += $(PWD)/../src/prach_ditfft2.sv
VERILOG_SOURCES += $(PWD)/../src/prach_ditfft2_bf.sv
VERILOG_SOURCES += $(PWD)/../src/prach_ditfft2_twiddler.sv
VERILOG_SOURCES += $(PWD)/../src/prach_ditfft3.sv
VERILOG_SOURCES += $(PWD)/../src/prach_ditfft3_bf1.sv
VERILOG_SOURCES += $(PWD)/../src/prach_ditfft3_bf2.sv
VERILOG_SOURCES += $(PWD)/../src/prach_ditfft3_bf3.sv
VERILOG_SOURCES += $(PWD)/../src/prach_fft.sv
VERILOG_SOURCES += $(PWD)/../src/prach_framer.sv
VERILOG_SOURCES += $(PWD)/../src/prach_framer_buffer.sv
VERILOG_SOURCES += $(PWD)/../src/prach_framer_cdc.sv
VERILOG_SOURCES += $(PWD)/../src/prach_hb1.sv
VERILOG_SOURCES += $(PWD)/../src/prach_hb1_ch.sv
VERILOG_SOURCES += $(PWD)/../src/prach_hb2.sv
VERILOG_SOURCES += $(PWD)/../src/prach_hb2_ch.sv
VERILOG_SOURCES += $(PWD)/../src/prach_hb3.sv
VERILOG_SOURCES += $(PWD)/../src/prach_hb4.sv
VERILOG_SOURCES += $(PWD)/../src/prach_hb5.sv
VERILOG_SOURCES += $(PWD)/../src/prach_mixer.sv
VERILOG_SOURCES += $(PWD)/../src/prach_mixer_ch.sv
# VERILOG_SOURCES += $(PWD)/../src/prach_mux.sv
VERILOG_SOURCES += $(PWD)/../src/prach_nco.sv
VERILOG_SOURCES += $(PWD)/../src/prach_reshape1.sv
VERILOG_SOURCES += $(PWD)/../src/prach_reshape2.sv
VERILOG_SOURCES += $(PWD)/../src/prach_reshape_ch.sv
VERILOG_SOURCES += $(PWD)/../src/prach_resync.sv
VERILOG_SOURCES += $(PWD)/../src/prach_top.sv

VERILOG_SOURCES += $(PWD)/tb_prach_top.sv

TOPLEVEL ?= prach_fft

MODULE ?= test_prach_fft

EXTRA_ARGS ?= "-L altera_mf_ver"

include $(shell cocotb-config --makefiles)/Makefile.sim
