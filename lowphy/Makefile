PYTHON ?= uv run python
PYTEST ?= uv run python -m pytest
VERILATOR ?= verilator
VERIBLE_VERILOG_FORMAT ?= verible-verilog-format
VERILATOR_FLAGS ?= --lint-only -Wall

REPO_ROOT := $(abspath ..)
MODULE := $(notdir $(CURDIR))
FLT ?= $(MODULE).flt
LINT_TOPS ?= lowphy0 lowphy1

# The full-top smoke test trips puxch_buffer's PRB-range assertion during the
# Verilator 2-state power-on transient (clocks run before reset is applied, so
# Verilator sees reset low with zero-initialised state instead of X).  Keep
# lowphy on Questa until that assertion is made power-on safe.
SIMULATORS ?= questa

RTL_SOURCES = $(shell $(PYTHON) $(REPO_ROOT)/hdl_tools/flt_tool.py $(FLT))

.PHONY: lint test format

lint:
	@for top in $(LINT_TOPS); do \
		$(VERILATOR) $(VERILATOR_FLAGS) --top-module $$top $(RTL_SOURCES) || exit $$?; \
	done

include $(REPO_ROOT)/scripts/cocotb.mk

format:
	$(VERIBLE_VERILOG_FORMAT) --inplace $(wildcard rtl/*.sv)

# Out-of-context synthesis only (Vivado), including regression runs.
# For opt/place/route, invoke the OOC Tcl directly with -stage impl.
VIVADO ?= $(shell command -v vivado 2>/dev/null || ls -d /opt/Xilinx/Vivado/*/bin/vivado 2>/dev/null | sort -V | tail -1)
VIVADO_FLAGS ?= -mode batch -nojournal
OOC_LOG_DIR ?= vivado_ooc
OOC_SYNTH_TCLS ?= synth/lowphy0_ooc.tcl synth/lowphy1_ooc.tcl
OOC_TCLARGS ?=

.PHONY: ooc

ooc:
	@test -n "$(VIVADO)" || { echo "vivado not found; pass VIVADO=/path/to/vivado" >&2; exit 1; }
	@mkdir -p $(OOC_LOG_DIR)
	@for tcl in $(OOC_SYNTH_TCLS); do \
		echo "--- ooc: $$tcl ---"; \
		$(VIVADO) $(VIVADO_FLAGS) -log $(OOC_LOG_DIR)/$$(basename $$tcl .tcl).log -source $$tcl -tclargs $(OOC_TCLARGS) -stage synth || exit $$?; \
	done
