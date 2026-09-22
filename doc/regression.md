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

## Latest regression and OOC follow-up (2026-09-22)

Command: `make all` with the default module and simulator selections. The
run used Python 3.14.7, cocotb 2.1.0, pytest 9.1.1, Verilator 5.052,
Questa Altera Starter FPGA Edition 2025.3, and Vivado 2024.2.

The original attempt completed lint, tests, and formatting, but stopped
during `lowphy1` OOC synthesis at 19:17 without a recorded cause or final
`make all` exit status. Lint logs are from 18:25, tests from 18:26–19:12,
and formatting from 19:12 (all times UTC+08:00).

The remaining OOC targets were rerun separately at 20:16–20:28:

```sh
make ooc OOC_MODULES="lowphy pdxch prach puxch"
```

This command returned zero: all four modules passed, including both
Low-PHY variants. The aggregate output was captured in
[.build_logs/ooc-rerun-20260922-2015.log](../.build_logs/ooc-rerun-20260922-2015.log).
The existing `fft` pass from 19:12–19:13 was retained, not rerun.

The runner overwrites logs per target/module and normally prints its summary
only to the console. The four previous OOC logs were backed up under
`.build_logs/ooc-before-rerun-20260922-9u0CA5/` before this rerun. These results
complete the synthesis coverage separately; they are not a new `make all` run.

- Lint: all 39 RTL blocks passed.
- Tests: 35 of 39 RTL blocks passed; four failed in Questa. Verilator
  reported 235 passed pytest runner cases across 38 blocks; Questa reported
  229 passed and 9 failed across 39 blocks. No skips were reported. Low-PHY
  uses Questa only. These counts are runner cases, not individual cocotb tests.
- FIFO regressions: `axis_fifo` passed all 16 configurations and
  `axis_fifo_alt` passed all 8 configurations on each simulator.
- New top smoke tests: O-RAN, PTP, FH, and PPS passed on Verilator and Questa.
- Low-PHY: register tests and both top variants passed on Questa.
- Common: all 16 cases passed on each simulator.
- Shared Python helpers and runner tests: all 14 cases passed.
- Formatting: all 39 targets completed.

OOC synthesis evidence:

| Block / top | Latest available result | Log |
| --- | --- | --- |
| `fft` | Passed in the original attempt (19:12–19:13); not rerun. | [.build_logs/ooc-fft.log](../.build_logs/ooc-fft.log) |
| `lowphy` / `lowphy0` | Passed in the follow-up (20:16–20:19). | [.build_logs/ooc-lowphy.log](../.build_logs/ooc-lowphy.log) |
| `lowphy` / `lowphy1` | Passed in the follow-up (20:19–20:23). | [.build_logs/ooc-lowphy.log](../.build_logs/ooc-lowphy.log) |
| `pdxch` | Passed in the follow-up (20:23–20:25). | [.build_logs/ooc-pdxch.log](../.build_logs/ooc-pdxch.log) |
| `prach` | Passed in the follow-up (20:25–20:26). | [.build_logs/ooc-prach.log](../.build_logs/ooc-prach.log) |
| `puxch` | Passed in the follow-up (20:26–20:28). | [.build_logs/ooc-puxch.log](../.build_logs/ooc-puxch.log) |

All six top-level synthesis runs reported zero errors and zero critical
warnings; ordinary warnings remain. This validates synthesis, not placement,
routing, or timing closure. The OOC hierarchies cover PRACH's `axis_fifo_alt`
and shared `delay_lutram` instances, but do not instantiate standalone
`axis_fifo` or cover every FIFO parameter combination. No synthesis regression
was observed in the covered designs with the current working-tree changes.

The earlier O-RAN smoke-test work fixed an elaboration error in its initialized
control memory. Its clocked write process uses plain `always`, because
`always_ff` cannot share a variable with the existing initialization process.
O-RAN lint and both simulator smoke runs remain passing.

The FIFO startup failures are fixed in the testbenches. The packet checkers
previously sampled `m_axis_tvalid` at the first rising edge (4 ns), before
reset initialized it, causing Questa to reject conversion of `X` to an
integer. Both suites now start their checkers after the existing reset and
settling sequence, before either AXI agent starts traffic. The alternate
FIFO's discard tracker starts at the same point. No RTL change or unknown
value suppression is needed.

The following failures remain in existing, unchanged test/RTL logic. All four
blocks passed their Verilator pass and failed in Questa:

| Block | Observed failure | Log |
| --- | --- | --- |
| `axis_switch` | Broadcast backpressure checker converts an unknown payload to an integer. | [.build_logs/test-axis_switch.log](../.build_logs/test-axis_switch.log) |
| `cdc` | Handshake data/order and readiness assertions fail in three configurations; a pulse configuration also reads an unknown value. | [.build_logs/test-cdc.log](../.build_logs/test-cdc.log) |
| `coe` | Questa rejects `ecpri_framer_trans.seqid_reg` being assigned by initialization and `always_ff` processes. | [.build_logs/test-coe.log](../.build_logs/test-coe.log) |
| `ecpri` | Same `seqid_reg` elaboration error affects three runners. | [.build_logs/test-ecpri.log](../.build_logs/test-ecpri.log) |

These failures are recorded rather than skipped or suppressed. OOC synthesis
is now complete, but the suite is not yet a fully passing regression baseline
because four blocks still fail in Questa; simulation was not rerun during
this OOC follow-up.
