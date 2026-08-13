PYTHON ?= uv run python
PYTEST ?= uv run python -m pytest
VERILATOR ?= verilator
VERIBLE_VERILOG_FORMAT ?= verible-verilog-format

REPO_ROOT := $(abspath ..)
MODULE := $(notdir $(CURDIR))
FLT ?= $(MODULE).flt
LINT_TOPS ?= cdc_array_single cdc_async_rst cdc_gray cdc_handshake_f cdc_pulse cdc_single cdc_sync_rst

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
