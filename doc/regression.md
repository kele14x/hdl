# Running the regression

From the repository root:

```sh
make test                         # All RTL blocks and shared Python tests
make test MODULES="ptp oran_slave" # Selected blocks, plus shared Python tests
make unit                         # Shared Python helper/runner tests only
make all                          # Lint, tests, RTL formatting, OOC synthesis
```

The root discovers block directories from `*/rtl/`. Every discovered block
must provide a Makefile; a missing Makefile is reported as a failure. `common`
has its own Makefile and is included alongside the other blocks.

All block Makefiles include `scripts/cocotb.mk`. Missing `tests/`, an empty
`SIMULATORS` selection, pytest collection errors, and zero collected cases
fail the test target. A failing module does not prevent later modules or the
shared Python tests from running. Full logs are written under `.build_logs/`,
including `test-hdl_tools.log` for the Python tests in `tests/`.

Most blocks run Verilator first, then Questa. A Verilator failure stops that
block before the Questa pass; the remaining blocks still run. Low-PHY keeps
its existing Questa-only default. To override a simulator for a selected block:

```sh
make test MODULES="ptp oran_slave fh pps_top common" SIMULATORS=verilator
```

On a host with only Verilator installed, select `SIMULATORS=verilator`.
This does not validate four-state behavior on Questa.

`PYTEST` and `PYTHON` remain overridable. The default uses the project's uv
environment. Direct pytest invocation of cocotb tests requires an explicit
`SIM`, for example:

```sh
SIM=questa uv run python -m pytest ptp/tests -q
```

The existing Python helper tests in `tests/` run once per root test stage,
independently of the simulator list and even when `MODULES` is narrowed.
Runner tests use temporary repositories to check discovery, continued
execution after a failure, helper-test failure propagation, and rejection of
missing/empty tests or simulator selections.

Open regression issues and coverage work are tracked in
[known_issues.md](known_issues.md#regression-runner-and-cocotb-coverage-gaps).
