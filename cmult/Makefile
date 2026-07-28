PYTHON ?= python3
PYTEST ?= uv run pytest
VERILATOR ?= verilator

REPO_ROOT := $(abspath ..)
MODULE := $(notdir $(CURDIR))
FLT ?= $(MODULE).flt
LINT_TOPS ?= cmult3 cmult4

RTL_SOURCES := $(shell $(PYTHON) $(REPO_ROOT)/tools/flt_tool.py $(FLT))
RTL_DIRS := $(sort $(dir $(RTL_SOURCES)))
REPO_RTL_DIRS := $(wildcard $(REPO_ROOT)/*/rtl)
VERILATOR_INCLUDES := $(addprefix -I,$(sort $(RTL_DIRS) $(REPO_RTL_DIRS)))

.PHONY: lint test

lint:
	@for top in $(LINT_TOPS); do \
		$(VERILATOR) --lint-only -Wall --top-module $$top $(VERILATOR_INCLUDES) $(RTL_SOURCES) || exit $$?; \
	done

test:
	PYTHONPATH="$(REPO_ROOT):$(PYTHONPATH)" $(PYTEST) -q tests
