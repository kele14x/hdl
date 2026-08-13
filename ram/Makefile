PYTHON ?= uv run python
PYTEST ?= uv run python -m pytest
VERILATOR ?= verilator
VERIBLE_VERILOG_FORMAT ?= verible-verilog-format

REPO_ROOT := $(abspath ..)
MODULE := $(notdir $(CURDIR))
FLT ?= $(MODULE).flt
LINT_TOPS ?= ram_sdp ram_sdp_asym ram_sdp_pipe ram_sp ram_sp_pipe ram_tdp ram_tdp_asym ram_tdp_pipe

RTL_SOURCES = $(shell $(PYTHON) $(REPO_ROOT)/hdl_tools/flt_tool.py $(FLT))

.PHONY: lint test format

lint:
	@for top in $(LINT_TOPS); do \
		$(VERILATOR) --lint-only -Wall --top-module $$top $(RTL_SOURCES) || exit $$?; \
	done

test:
	$(PYTEST) -q tests

format:
	$(VERIBLE_VERILOG_FORMAT) --inplace $(wildcard rtl/*.sv)
