PYTHON ?= uv run python
PYTEST ?= uv run python -m pytest
VERILATOR ?= verilator

REPO_ROOT := $(abspath ..)
MODULE := $(notdir $(CURDIR))
FLT ?= $(MODULE).flt
LINT_TOPS ?= ram_sdp ram_sdp_asym ram_sdp_pipe ram_sp ram_sp_pipe

RTL_SOURCES = $(shell $(PYTHON) $(REPO_ROOT)/tools/flt_tool.py $(FLT))

.PHONY: lint test

lint:
	@for top in $(LINT_TOPS); do \
		$(VERILATOR) --lint-only -Wall --top-module $$top $(RTL_SOURCES) || exit $$?; \
	done

test:
	$(PYTEST) -q tests
