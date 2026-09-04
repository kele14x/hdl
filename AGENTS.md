# AGENTS.md

This file provides guidance to the AI agent when working with code in this repository.

## Overview

Multi-IP HDL monorepo (SystemVerilog/Verilog) for radio/transport DSP and networking blocks, verified with cocotb + pytest. Each IP is self-contained under its own directory.

## Module layout

Each IP follows `<block>/{rtl|src}/*.sv|*.v`, `<block>/tests/` (cocotb `.py` tests), `<block>/tb/` (traditional `.sv` testbenches), and a `<block>/<block>.flt` filelist. The `.flt` file lists RTL source paths relative to the module root — no testbench files.

## Python / tooling

- Python 3.13, managed with `uv` (see `uv.lock`); run `uv sync` to set up the venv.
- Ruff is the formatter/linter (no explicit config — defaults apply). Test scripts start with `#!/usr/bin/env python3` and keep the executable bit (ruff `EXE001`).
- Dependencies: cocotb >=2.0, numpy, pytest.

## SystemVerilog style

- 2-space indentation; LF line endings; final newline required.
- Wrap modules with `` `default_nettype none `` ... `` `default_nettype wire `` and `` `timescale 1 ns / 1 ps ``.
- `generate` keyword is **required** and `genvar` must be declared inside the loop.
- Parameters use `parameter int`; signed ports use `wire signed [W-1:0]`. 1-bit mode flags are `parameter int FOO = 0` and used with explicit comparisons (`if (FOO != 0)`), not as booleans; derived constants use `localparam int`.
- Include design-rule checks as `initial begin : drc_check ... assert(...) else $error(...); end` blocks.
- Runtime invariant guards are module-scope concurrent assertions: `assert property (@(posedge clk) disable iff (!rstn) ...) else $error(...);` (Verilator rejects concurrent assertions inside `initial`/`always` blocks).
- A reset is usually synchronized and active high. Use `cdc_async_rst` when deriving a reset for another clock domain.
- Verilator lint pragmas (e.g. `/* verilator lint_off UNUSEDPARAM */`) are used where needed.

## Testing

All cocotb tests use the **pytest + cocotb runner** pattern in `<module>/tests/test_*.py`. Run with `python <module>/tests/test_<name>.py` or `pytest <module>/tests/test_<name>.py`. The `SIM` env var must be set explicitly (e.g. `SIM=verilator` or `SIM=questa`); there is no default. Parameters are passed via the `parameters={}` dict to `runner.build()`; parametrized build cases are listed inline as a `CASES` list in the test file and fed to `@pytest.mark.parametrize` (no external case files). Build and run artifacts go under `<module>/sim_build/` (alongside the `.flt` file) so they stay available for debugging.

In cocotb tests, drive and sample signals on the **RisingEdge** of the relevant clock in almost all cases: set inputs right after `await RisingEdge(...)` (the DUT captures them on the next edge) and sample outputs after `await RisingEdge()` on the edge of 1 clock afterward where they are expected. In some cases, sampling after `await ValueChange(...)` on a none-clock signal to model a combinational delay. Never use `FallingEdge`, `ReadWrite` or `ReadOnly` for driving or sampling — they are banned.

Traditional SystemVerilog testbenches (`tb_*.sv`) live in `<module>/tb/`.

### cocotb testbench style

- Build testbenches from the shared agents in `hdl_tools` (`axis.py`, `axi4lite.py`, `handshake.py`) instead of hand-rolled drivers/monitors. Typical shape: an active source agent drives randomized transactions, a sink agent drives `*tready`/`*ready` from a random backpressure policy, and passive monitors on both sides feed a scoreboard comparing sent vs. received transactions.
- Random stimulus uses fixed seeds (`np.random.default_rng(<seed>)`, `random.Random(<seed>)`) so failures are reproducible.
- Protocol checks run as background coroutines via `cocotb.start_soon(...)` (e.g. packet-mode `tvalid` must stay asserted within a packet); stimulus sends are wrapped in `with_timeout(...)`.
- The `CASES` matrix covers mode/width/latency corners. Each case builds into `sim_build/<case_name>/` (`build_dir`/`test_dir`) and passes its parameters to the cocotb process via `extra_env`; the test module reads them back with `os.environ.get(..., default)` because the runner and the simulator are separate Python processes.
- Runner calls use `sources=` (not the deprecated `verilog_sources=`) with `always=True, waves=True`.
- cocotb >=2.0 API only: `Clock(..., unit="ns")` (not `units=`), `task.cancel()` (not `kill()`).

## Verification checklist

- `make lint` (Verilator `--lint-only -Wall`) clean for the module and for modules that instantiate changed code.
- Run the full parametrized pytest suite and check the simulation log for cocotb/Verilator warnings, not just the pytest summary.
- `uv run ruff check` and `uv run ruff format` on changed Python files.
- After touching shared libraries (`hdl_tools`, `common`), re-run the regressions of modules that use them.
- Directed corner cases (e.g. forcing a FIFO full) belong in the suite as deterministic scenarios, not one-off scripts.

## Scope

- Stay inside the module the user named. Do not extend a fix, refactor, or cleanup to other modules without explicit authorization.
- Investigating other modules to attribute a root cause is fine, but stop at the finding: report it and let the user decide. Do not edit, revert, or delete outside the requested scope.
- Wider regressions implied by a shared-library change (`hdl_tools`, `common`) may surface failures elsewhere — name the affected modules and ask before touching them.

## Git

- **Never auto-commit.** Only create a commit when the user explicitly asks for one.
- Commit messages are lowercase and concise (e.g. `add prach`, `fix fft`, `refactor test`); no conventional-commit prefixes.
