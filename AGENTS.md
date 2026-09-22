# AGENTS.md

This file provides guidance to the AI agent when working with code in this repository.

## Overview

Multi-IP HDL monorepo (SystemVerilog/Verilog) for radio/transport DSP and networking blocks, verified with cocotb + pytest. Each IP is self-contained under its own directory.

## Module layout

- `<block>`
  - `doc`: `.md` documents
  - `rtl`: `.sv` / `.v` RTL sources
  - `tests`: cocotb `.py` tests
  - `tb`: traditional `.sv` testbenches
  - `<block>.flt`: filelist file

- The `.flt` file lists RTL source paths relative to the module root — no testbench files.

The exception is `hdl_tools`, which is the shared Python module for helper / library. And `tests`, which is tests for `hdl_tools`.

## Python

- Python 3.14, managed with `uv` (see `uv.lock`); run `uv sync` to set up the venv.
- Dependencies: cocotb >=2.1, numpy, pytest.
- Ruff is the formatter/linter.

## SystemVerilog style

- Verilator lint pragmas are used where needed to explicitly list unused signals/parameters.

## Cocotb style

In cocotb tests, drive and sample signals on the **RisingEdge** of the relevant clock in almost all cases: set inputs right after `await RisingEdge(...)` (the DUT captures them on the next edge) and sample outputs after `await RisingEdge()` on the edge of 1 clock afterward where they are expected. In some cases, sampling after `await ValueChange(...)` on a none-clock signal to model a combinational delay. Never use `FallingEdge`, `ReadWrite` or `ReadOnly` for driving or sampling — they are banned.

## Checklist

- `make all` from the repo root runs the whole sweep: `lint`, `test`, `format`, then `ooc`. It keeps going after a failing module, logs each module to `.build_logs/`, and prints one summary — use it after a change that touches shared code.
- `make lint` (Verilator `--lint-only -Wall`) clean for the module and for modules that instantiate changed code.
- `uv run ruff check` and `uv run ruff format` on changed Python files.
- `make test` runs cocotb tests for the module with Verilator first and Questa second; a Verilator failure skips the slower Questa pass. Override with `SIMULATORS="..."` (e.g. `make test SIMULATORS=verilator` for a quick pass), or `SIMULATORS=questa` in a module `Makefile` when the design is not Verilator-clean.
- Run `make format` on modified modules before commit.
- `make ooc` runs out-of-context synthesis in the modules that ship a `synth/*_ooc.tcl` script (`OOC_MODULES` in the root `Makefile`). `make ooc-impl` continues those runs through `opt/place/route`; it is not part of `make all` because it takes much longer.
- Vivado is located from `PATH`, falling back to `/opt/Xilinx/Vivado/*/bin/vivado`; override with `make ooc VIVADO=/path/to/vivado`.
- After a Verilator upgrade, run `make clean` once before `make test`: cached builds under `*/sim_build` embed the old install path and fail with a missing `verilated.h` dependency.

## Scope

- Stay inside the module under modification. Do not extend a fix, refactor, or cleanup to other modules unless they are impacted by the change.

## Git

- **Never auto-commit.** Only create a commit when the user explicitly asks for one.
