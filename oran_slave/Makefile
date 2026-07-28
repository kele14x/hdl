PYTHON ?= uv run python
PYTEST ?= uv run python -m pytest
VERILATOR ?= verilator
VERILATOR_FLAGS ?= --lint-only -Wall

REPO_ROOT := $(abspath ..)
MODULE := $(notdir $(CURDIR))
FLT ?= $(MODULE).flt
LINT_TOPS ?= oran_top

RTL_SOURCES = $(shell $(PYTHON) $(REPO_ROOT)/tools/flt_tool.py $(FLT))

.PHONY: lint test

lint:
	@for top in $(LINT_TOPS); do \
		$(VERILATOR) $(VERILATOR_FLAGS) --top-module $$top $(RTL_SOURCES) || exit $$?; \
	done

test:
	$(PYTEST) -q tests
