# Top-level regression entry point for the HDL monorepo.
#
# Every stage runs in each module that provides it, and a failing module never
# stops the remaining modules: `make all` finishes the whole sweep and then
# prints one summary.  Full per-module logs live in .build_logs/.
#
#   make all          lint + test + format + ooc
#   make help         list targets, overrides, and examples
#   make lint         verilator --lint-only in every module
#   make test         cocotb tests in every module plus shared Python tests
#   make unit         shared Python helper and regression-runner tests only
#   make format       verible-verilog-format in every module
#   make ooc          vivado out-of-context synthesis (modules that have it)
#   make clean        remove per-module cocotb builds and Vivado OOC results
#
# Overridable variables:
#   STAGES="lint test format ooc"   stages run by `make all`
#   SIMULATORS="verilator questa"   cocotb simulators used by `make test`
#   MODULES="adder gain ..."        modules used by lint / test / format
#   OOC_MODULES="fft ..."           modules with an OOC synthesis script
#   VIVADO=/path/to/vivado          vivado executable used by ooc
#
# Examples:
#   make all
#   make lint
#   make test SIMULATORS=verilator          # fast pass only
#   make all STAGES="lint test"             # skip format and OOC
#   make ooc OOC_MODULES="prach"
# For implementation, invoke an OOC Tcl directly with -stage impl in -tclargs.

# Discover RTL, not Makefiles: a new IP without build integration must fail.
MODULES := $(patsubst %/rtl/,%,$(wildcard */rtl/))
PYTEST ?= uv run python -m pytest

# Only these modules ship a runnable out-of-context script.  Modules without
# one are silently skipped by `make ooc`.
OOC_MODULES ?= fft lowphy pdxch prach puxch

STAGES ?= lint test format ooc

export HDL_MODULES := $(MODULES)
export HDL_OOC_MODULES := $(OOC_MODULES)

.DEFAULT_GOAL := all

.PHONY: all help lint test unit format ooc clean

help:
	@printf '%s\n' \
		'Usage: make [target] [VARIABLE=value ...]' \
		'' \
		'Targets:' \
		'  all           Run lint, test, format, and OOC synthesis (default)' \
		'  help          Show this help' \
		'  lint          Run Verilator lint in every module' \
		'  test          Run module cocotb tests and shared Python tests' \
		'  unit          Run shared Python helper and regression-runner tests only' \
		'  format        Run verible-verilog-format in every module' \
		'  ooc           Run Vivado out-of-context synthesis only' \
		'  clean         Remove per-module cocotb builds and Vivado OOC results' \
		'' \
		'Overrides:' \
		'  STAGES="lint test format ooc"  Stages run by all' \
		'  SIMULATORS="verilator questa" Cocotb simulators used by test' \
		'  MODULES="adder gain ..."      Modules used by lint / test / format' \
		'  OOC_MODULES="fft ..."         Modules used by ooc' \
		'  VIVADO=/path/to/vivado        Vivado executable for ooc' \
		'  PYTEST="uv run python -m pytest"  Command used for Python tests' \
		'' \
		'Examples:' \
		'  make test SIMULATORS=verilator' \
		'  make lint MODULES="adder gain"' \
		'  make all STAGES="lint test"' \
		'  make ooc OOC_MODULES="prach"' \
		'' \
		'For implementation, invoke an OOC Tcl directly with -stage impl in -tclargs.' \
		'Regression stages continue after module failures; logs are in .build_logs/.'

all:
	@scripts/run_targets.sh $(STAGES)

lint:
	@scripts/run_targets.sh lint

test:
	@scripts/run_targets.sh test

unit:
	$(PYTEST) -q tests

format:
	@scripts/run_targets.sh format

ooc:
	@scripts/run_targets.sh ooc

clean:
	rm -rf */sim_build */vivado_ooc
