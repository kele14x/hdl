# Running the regression

From the repository root:

```sh
make test                         # All RTL blocks and shared Python tests
make test MODULES="ptp oran_slave" # Selected blocks, plus shared Python tests
make test-python                  # Shared Python helper/runner tests only
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

`PYTEST` and `PYTHON` remain overridable. The default uses the project's uv
environment. Direct pytest invocation of cocotb tests requires an explicit
`SIM`, for example:

```sh
SIM=questa uv run python -m pytest ptp/tests -q
```

## Basic top-level tests

| Block / top | Smoke checks |
| --- | --- |
| `oran_slave` / `oran_top` | Initialize all clock domains and array inputs; check version, TX MAC register defaults/readback, idle TX, and configuration reset/recovery. |
| `ptp` / `ptp_lite` | Check a complete expected Sync frame, including Ethernet/PTP headers, timestamp-request metadata, keep/last, and stability under output backpressure; repeat after reset. The clock-frequency parameter is reduced to bound runtime. |
| `fh` / `fh` | Version, scratch and MAC configuration reads/writes, idle TX, and reset/recovery across all clock domains. |
| `pps_top` / `pps_top` | Version, configuration reads/writes, visible system-timer progress, and reset/recovery. |
| `lowphy` / `lowphy0`, `lowphy1` | Existing register/control-plane smoke now runs both tops by default; `LOWPHY_TOP=lowphy0` or `lowphy1` selects one. |

The four new smoke tests have bounded simulation timeouts and use RisingEdge
for driving/sampling. They complement existing module tests. O-RAN and FH
traffic scoreboards and broader PTP/PPS corner cases remain future regression
work; control-plane smoke alone is not full datapath verification. `ptp_lite`
is the active top in `ptp.flt`; the legacy `ptp` AXI top and its wrapper remain
outside that filelist and this smoke test.

The existing Python helper tests in `tests/` run once per root test stage,
independently of the simulator list and even when `MODULES` is narrowed.
Runner tests use temporary repositories to check discovery, continued
execution after a failure, helper-test failure propagation, and rejection of
missing/empty tests or simulator selections.

## Validation of this change (2026-09-22)

The complete `make all` sweep finished, including both default simulators
(Questa only for Low-PHY), formatting, and synthesis. It returned nonzero
and accurately reported six failing test blocks; it did not stop the
remaining blocks or Python tests.

- Lint: all 39 RTL blocks passed.
- New top smoke tests: O-RAN, PTP, FH, and PPS passed on Verilator and Questa.
- Low-PHY: register tests and both top variants passed on Questa.
- Common: all 16 cases passed on each simulator.
- Shared Python helpers and runner tests: all 14 cases passed.
- Formatting: all 39 targets completed. Incidental whitespace-only changes
  in unrelated RTL were removed from the patch afterward.
- OOC synthesis: `fft`, `lowphy`, `pdxch`, `prach`, and `puxch` passed.
- Ruff check/format on changed Python files, shell syntax, and diff whitespace
  checks passed.

The O-RAN test exposed an elaboration error in its initialized control memory.
Its clocked write process now uses plain `always`, because `always_ff` cannot
share a variable with the existing initialization process. O-RAN lint and
both simulator smoke runs passed after the fix.

The following failures remain in existing, unchanged test/RTL logic. All six
blocks passed their Verilator pass and failed in Questa:

| Block | Observed failure | Log |
| --- | --- | --- |
| `axis_fifo` | Packet checker converts an unknown `m_axis_tvalid` to an integer at 4 ns, during startup. | [.build_logs/test-axis_fifo.log](../.build_logs/test-axis_fifo.log) |
| `axis_fifo_alt` | Same startup packet-checker failure. | [.build_logs/test-axis_fifo_alt.log](../.build_logs/test-axis_fifo_alt.log) |
| `axis_switch` | Broadcast backpressure checker converts an unknown payload to an integer. | [.build_logs/test-axis_switch.log](../.build_logs/test-axis_switch.log) |
| `cdc` | Handshake data/order and readiness assertions fail in three configurations; a pulse configuration also reads an unknown value. | [.build_logs/test-cdc.log](../.build_logs/test-cdc.log) |
| `coe` | Questa rejects `ecpri_framer_trans.seqid_reg` being assigned by initialization and `always_ff` processes. | [.build_logs/test-coe.log](../.build_logs/test-coe.log) |
| `ecpri` | Same `seqid_reg` elaboration error affects three runners. | [.build_logs/test-ecpri.log](../.build_logs/test-ecpri.log) |

These failures are recorded rather than skipped or suppressed. The suite is
not yet a fully passing regression baseline.
