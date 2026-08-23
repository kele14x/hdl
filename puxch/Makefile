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

RTL_SOURCES = $(shell $(PYTHON) $(REPO_ROOT)/hdl_tools/flt_tool.py $(FLT))

.PHONY: lint test tb format

lint:
	@for top in $(LINT_TOPS); do \
		$(VERILATOR) $(VERILATOR_FLAGS) --top-module $$top $(RTL_SOURCES) || exit $$?; \
	done

test:
	$(PYTEST) -q tests

tb:
	@mkdir -p $(TB_BUILD_DIR)
	$(VERILATOR) --binary --timing -Wno-fatal --top-module $(TB_TOP) \
		$(RTL_SOURCES) $(TB) --Mdir $(TB_BUILD_DIR)
	$(TB_BUILD_DIR)/V$(TB_TOP)

format:
	$(VERIBLE_VERILOG_FORMAT) --inplace $(wildcard rtl/*.sv)
