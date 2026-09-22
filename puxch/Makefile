PYTHON ?= uv run python
PYTEST ?= uv run python -m pytest
VERILATOR ?= verilator
VERIBLE_VERILOG_FORMAT ?= verible-verilog-format
VERILATOR_FLAGS ?= --lint-only -Wall
TB ?= tb/tb_puxch_top.sv
TB_TOP ?= tb_puxch_top
TB_BUILD_DIR ?= sim_build/tb/verilator

REPO_ROOT := $(abspath ..)
MODULE := $(notdir $(CURDIR))
FLT ?= $(MODULE).flt
LINT_TOPS ?= $(MODULE)

SIMULATORS ?= verilator questa

RTL_SOURCES = $(shell $(PYTHON) $(REPO_ROOT)/hdl_tools/flt_tool.py $(FLT))

.PHONY: lint test tb format

lint:
	@for top in $(LINT_TOPS); do \
		$(VERILATOR) $(VERILATOR_FLAGS) --top-module $$top $(RTL_SOURCES) || exit $$?; \
	done

include $(REPO_ROOT)/scripts/cocotb.mk

tb:
	@mkdir -p $(TB_BUILD_DIR)
	$(VERILATOR) --binary --timing -Wno-fatal --top-module $(TB_TOP) \
		$(RTL_SOURCES) $(TB) --Mdir $(TB_BUILD_DIR)
	$(TB_BUILD_DIR)/V$(TB_TOP)

format:
	$(VERIBLE_VERILOG_FORMAT) --inplace $(wildcard rtl/*.sv)

# Out-of-context synthesis / implementation (Vivado).  Synthesis is the fast
# check used by `make ooc`; `make ooc-impl` reuses its checkpoint for
# opt/place/route.
VIVADO ?= $(shell command -v vivado 2>/dev/null || ls -d /opt/Xilinx/Vivado/*/bin/vivado 2>/dev/null | sort -V | tail -1)
VIVADO_FLAGS ?= -mode batch -nojournal
OOC_LOG_DIR ?= vivado_ooc
OOC_SYNTH_TCLS ?= synth/puxch_ooc.tcl
OOC_IMPL_TCLS ?= synth/puxch_impl.tcl
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
