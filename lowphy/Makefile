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

test:
	@if [ ! -d tests ]; then \
		echo "--- cocotb ($(MODULE)): no tests/ directory, skipped ---"; \
		exit 0; \
	fi; \
	for sim in $(SIMULATORS); do \
		echo "--- cocotb ($(MODULE)): $$sim ---"; \
		SIM=$$sim $(PYTEST) -q tests || exit $$?; \
	done

format:
	$(VERIBLE_VERILOG_FORMAT) --inplace $(wildcard rtl/*.sv)

# Out-of-context synthesis / implementation (Vivado).  Synthesis is the fast
# check used by `make ooc`; `make ooc-impl` reuses its checkpoint for
# opt/place/route.
VIVADO ?= $(shell command -v vivado 2>/dev/null || ls -d /opt/Xilinx/Vivado/*/bin/vivado 2>/dev/null | sort -V | tail -1)
VIVADO_FLAGS ?= -mode batch -nojournal
OOC_LOG_DIR ?= vivado_ooc
OOC_SYNTH_TCLS ?= synth/lowphy0_ooc.tcl synth/lowphy1_ooc.tcl
OOC_IMPL_TCLS ?= synth/lowphy0_impl.tcl synth/lowphy1_impl.tcl
OOC_TCLARGS ?=
OOC_IMPL_TCLARGS ?= $(OOC_TCLARGS)

.PHONY: ooc ooc-impl

ooc:
	@test -n "$(VIVADO)" || { echo "vivado not found; pass VIVADO=/path/to/vivado" >&2; exit 1; }
	@mkdir -p $(OOC_LOG_DIR)
	@for tcl in $(OOC_SYNTH_TCLS); do \
		echo "--- ooc: $$tcl ---"; \
		$(VIVADO) $(VIVADO_FLAGS) -log $(OOC_LOG_DIR)/$$(basename $$tcl .tcl).log -source $$tcl $(if $(OOC_TCLARGS),-tclargs $(OOC_TCLARGS)) || exit $$?; \
	done

ooc-impl:
	@test -n "$(VIVADO)" || { echo "vivado not found; pass VIVADO=/path/to/vivado" >&2; exit 1; }
	@mkdir -p $(OOC_LOG_DIR)
	@for tcl in $(OOC_IMPL_TCLS); do \
		echo "--- ooc-impl: $$tcl ---"; \
		$(VIVADO) $(VIVADO_FLAGS) -log $(OOC_LOG_DIR)/$$(basename $$tcl .tcl).log -source $$tcl $(if $(OOC_IMPL_TCLARGS),-tclargs $(OOC_IMPL_TCLARGS)) || exit $$?; \
	done
