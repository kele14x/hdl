# AGENTS.md

This file provides guidance to the AI agent when working with code in this repository.

## Overview

Multi-IP HDL monorepo (SystemVerilog/Verilog) for radio/transport DSP and networking blocks, verified with cocotb + pytest. Each IP is self-contained under its own directory.

## Testing

All cocotb tests use the **pytest + cocotb runner** pattern in `<module>/tests/test_*.py`. Run with `python <module>/tests/test_<name>.py` or `pytest <module>/tests/test_<name>.py`. Default simulator is **verilator**; override via the `SIM` env var (e.g. `SIM=questa`). Parameters are passed via the `parameters={}` dict to `runner.build()`, read from env vars or a sibling `param_sets.json`.

Test helper modules (e.g. `libaxi4l.py`, `libecpri.py`) live alongside the tests in `tests/`.

Traditional SystemVerilog testbenches (`tb_*.sv`) live in `<module>/tb/`.

## Module layout

Each IP follows `<block>/{rtl|src}/*.sv|*.v`, `<block>/tests/` (cocotb `.py` tests), `<block>/tb/` (traditional `.sv` testbenches), and a `<block>/<block>.flt` filelist. The `.flt` file lists RTL source paths relative to the module root — no testbench files.

## SystemVerilog style

- 2-space indentation; LF line endings; final newline required.
- Wrap modules with `` `default_nettype none `` ... `` `default_nettype wire `` and `` `timescale 1 ns / 1 ps ``.
- `generate` keyword is **required** and `genvar` must be declared inside the loop (enforced by `.svlint.toml`).
- Parameters use `parameter int`; signed ports use `wire signed [W-1:0]`.
- Include design-rule checks as `initial begin : drc_check ... assert(...) else $error(...); end` blocks.
- Verilator lint pragmas (e.g. `/* verilator lint_off UNUSEDPARAM */`) are used where needed.

## Conventions

- **Control plane**: AXI4-Lite register modules named `*_regs.v`, instantiated by `*_top.sv` / `*_wrapper.v`.
- **Data plane**: AXI-Stream (`*_tdata`, `*_tkeep`, `*_tvalid`, `*_tlast`, `*_tready`) with explicit clock/reset domains.
- Test source lists include shared primitives from sibling directories explicitly (e.g. `../../lfsr/rtl/lfsr.sv`) rather than via a central project file.

## Python / tooling

- Python 3.13, managed with `uv` (see `uv.lock`); run `uv sync` to set up the venv.
- Ruff is the formatter/linter (no explicit config — defaults apply).
- Dependencies: cocotb >=2.0, numpy, pytest.

## Git

Commit messages are lowercase and concise (e.g. `add prach`, `fix fft`, `refactor test`); no conventional-commit prefixes.
