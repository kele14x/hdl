PYTHON ?= python3
PYTEST ?= uv run pytest
VERILATOR ?= verilator
VERILATOR_FLAGS ?= --lint-only -Wall

REPO_ROOT := $(abspath ..)
MODULE := $(notdir $(CURDIR))
FLT ?= $(MODULE).flt
LINT_TOPS ?= lowphy0 lowphy1

RTL_SOURCES := $(shell $(PYTHON) $(REPO_ROOT)/tools/flt_tool.py $(FLT))
RTL_DIRS := $(sort $(dir $(RTL_SOURCES)))
REPO_RTL_DIRS := $(wildcard $(REPO_ROOT)/*/rtl)
VERILATOR_INCLUDES := $(addprefix -I,$(sort $(RTL_DIRS) $(REPO_RTL_DIRS)))
VERILATOR_LIB_DIRS := $(foreach dir,$(sort $(RTL_DIRS) $(REPO_RTL_DIRS)),-y $(dir))
LINT_SOURCES ?=

.PHONY: lint test

lint:
	@for top in $(LINT_TOPS); do \
		$(VERILATOR) $(VERILATOR_FLAGS) --top-module $$top $(VERILATOR_INCLUDES) $(VERILATOR_LIB_DIRS) $(LINT_SOURCES) rtl/$$top.sv || exit $$?; \
	done

test:
	PYTHONPATH="$(REPO_ROOT):$(PYTHONPATH)" $(PYTEST) -q tests
