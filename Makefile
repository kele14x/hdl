# Top-level regression entry point for the HDL monorepo.
#
# Every stage runs in each module that provides it, and a failing module never
# stops the remaining modules: `make all` finishes the whole sweep and then
# prints one summary.  Full per-module logs live in .build_logs/.
#
#   make all          lint + test + format + ooc
#   make lint         verilator --lint-only in every module
#   make test         cocotb tests in every module plus shared Python tests
#   make test-python  shared Python helper and regression-runner tests
#   make format       verible-verilog-format in every module
#   make ooc          vivado out-of-context synthesis (modules that have it)
#   make ooc-impl     vivado out-of-context implementation / place & route
#   make clean        remove per-module cocotb build products
#   make clean-vivado remove per-module vivado_ooc run directories
#
# Overridable variables:
#   STAGES="lint test format ooc"   stages run by `make all`
#   SIMULATORS="verilator questa"   cocotb simulators used by `make test`
#   MODULES="adder gain ..."        modules used by lint / test / format
#   OOC_MODULES="fft ..."           modules with an OOC synthesis script
#   OOC_IMPL_MODULES="fft ..."      modules with an OOC implementation script
#   VIVADO=/path/to/vivado          vivado executable used by ooc / ooc-impl
#
# Examples:
#   make all
#   make lint
#   make test SIMULATORS=verilator          # fast pass only
#   make all STAGES="lint test"             # skip format and OOC
#   make ooc OOC_MODULES="prach"

# Discover RTL, not Makefiles: a new IP without build integration must fail.
MODULES := $(patsubst %/rtl/,%,$(wildcard */rtl/))
PYTEST ?= uv run python -m pytest

# Only these modules ship a runnable out-of-context script.  Modules without
# one are silently skipped by `make ooc` / `make ooc-impl`.
OOC_MODULES ?= fft lowphy pdxch prach puxch
OOC_IMPL_MODULES ?= fft lowphy pdxch prach puxch

STAGES ?= lint test format ooc

export HDL_MODULES := $(MODULES)
export HDL_OOC_MODULES := $(OOC_MODULES)
export HDL_IMPL_MODULES := $(OOC_IMPL_MODULES)

.DEFAULT_GOAL := all

.PHONY: all lint test test-python format ooc ooc-impl clean clean-vivado

all:
	@scripts/run_targets.sh $(STAGES)

lint:
	@scripts/run_targets.sh lint

test:
	@scripts/run_targets.sh test

test-python:
	$(PYTEST) -q tests

format:
	@scripts/run_targets.sh format

ooc:
	@scripts/run_targets.sh ooc

ooc-impl:
	@scripts/run_targets.sh ooc-impl

clean:
	rm -rf */sim_build

clean-vivado:
	rm -rf */vivado_ooc
