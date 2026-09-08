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

- Python 3.13, managed with `uv` (see `uv.lock`); run `uv sync` to set up the venv.
- Dependencies: cocotb >=2.0, numpy, pytest.
- Ruff is the formatter/linter.

## SystemVerilog style

- Verilator lint pragmas are used where needed to explicitly list unused signals/parameters.

## Cocotb style

In cocotb tests, drive and sample signals on the **RisingEdge** of the relevant clock in almost all cases: set inputs right after `await RisingEdge(...)` (the DUT captures them on the next edge) and sample outputs after `await RisingEdge()` on the edge of 1 clock afterward where they are expected. In some cases, sampling after `await ValueChange(...)` on a none-clock signal to model a combinational delay. Never use `FallingEdge`, `ReadWrite` or `ReadOnly` for driving or sampling — they are banned.

## Checklist

- `make lint` (Verilator `--lint-only -Wall`) clean for the module and for modules that instantiate changed code.
- `uv run ruff check` and `uv run ruff format` on changed Python files.
- Run `make test` for cocotb test for modified modules.
- Run `make format` on modified modules before commit.

## Scope

- Stay inside the module under modification. Do not extend a fix, refactor, or cleanup to other modules unless they are impacted by the change.

## Git

- **Never auto-commit.** Only create a commit when the user explicitly asks for one.
