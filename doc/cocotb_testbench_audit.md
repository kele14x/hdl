# Cocotb testbench audit and suite plan

Audit date: 2026-09-22. Repository HEAD: `dd008a7c`.

This is the pre-change audit snapshot. Discovery, missing-test reporting,
helper-test integration, and initial top-level smoke tests were subsequently
implemented; see [regression.md](regression.md) for the current entry points
and the scope of those tests. The inventory below preserves the original findings.

The repository does not yet have a self-checking sanity/smoke/regression suite covering every RTL module. The most urgent gaps are `oran_slave`, `ptp`, `fh`, and `pps_top`, followed by regression discovery and missing datapath checks in existing tests.

## Scope and interpretation

This audit inventories module declarations under every block's `rtl/` directory, examines cocotb runner targets and test bodies, checks filelists and Makefiles, and collects pytest cases. Packages are excluded from module counts; traditional SystemVerilog testbenches are not counted as cocotb tests.

| Measure | Result |
| --- | ---: |
| IP/block directories containing RTL | 39 |
| RTL module declarations | 212 |
| Packages, excluded from module counts | 5 |
| Modules with an existing direct cocotb target | 92 |
| Modules without a direct cocotb target | 120 |
| Of those 120: possible descendants of tested targets | 50 |
| Of those 120: no static instantiation path from any tested target found | 70 |
| Python files defining cocotb tests | 93 |
| Decorated cocotb test functions | 153 |
| Collected pytest cases, including parameters and Python-only tests | 242 |

“Direct” means a runner can select the module as its HDL top; it does not mean its behavior is thoroughly checked or the test currently passes. The 92 include `lowphy1`, which requires an environment override. The default root Makefile also excludes the three direct targets in `common`.

“Indirect candidate” means static RTL instantiation links lead from a tested top to the module. This is not measured code/functional coverage: generate conditions, parameters, disabled datapaths, and missing scoreboards can leave it unexercised. In particular, `timer_core_491p52` is a static descendant but is not selected by the existing timer test. The inventory at the end explicitly records these limitations.

## Highest-priority findings

| Priority | Area | Evidence and required action |
| --- | --- | --- |
| P0 | Missing tests report success | [ptp/Makefile](../ptp/Makefile) and [oran_slave/Makefile](../oran_slave/Makefile) exit 0 when `tests/` is absent. Both commands were run and printed “skipped” with success. [scripts/run_targets.sh](../scripts/run_targets.sh) labels any zero exit code PASS. Make missing coverage fail or report a distinct, explicitly tracked waiver; do not count it as a tested pass. |
| P0 | `oran_slave`: 0/35 direct | No cocotb test directory and no path from existing cocotb tops found. Start with register/reset checks, Ethernet parsing/framing, compression/decompression, section routing, and one checked DL/UL transaction through `oran_top`. |
| P0 | `ptp`: 0/7 direct | No cocotb test directory; no tested parent found. Add `ptp_lite`, framer, deframer, and controller tests. Decide whether the full AXI top and wrapper remain supported: `ptp.sv`, `ptp_regs.v`, and `ptp_wrapper.v` are absent from all resolved block filelists. |
| P0 | `fh`: 1/12 direct | Only [test_fh_framer_padding.py](../fh/tests/test_fh_framer_padding.py) targets RTL. The full top, deframer, converters, buffering, switch, registers, message framer, and wrapper have no direct or parent test path. |
| P0 | `pps_top`: 2/11 direct | Only delay and expand are tested. The top, register bank, timer, CDC, symbol timer, resync, counter, and checkers have no tested parent path. |
| P1 | `common` is outside root regression | Root [Makefile](../Makefile) discovers only `*/Makefile`; `common` has none. Its 16 collected cases for `delay`, `delay_lutram`, and `type_cast` are omitted. `srl` has indirect candidates through `fifo_srl`/CoE; `util_clk_fwd` and `util_gpio_gw` have none. |
| P1 | Shared Python tests are outside root regression | The nine collected cases in [tests/](../tests/) are not run by the root `make test` module loop. Add a separate helper-test stage. |
| P1 | Existing tests can miss datapath failures | CoE sends/loops traffic but does not compare received payloads. The eCPRI top checks version/scratch registers while its Ethernet input traffic loop is commented out. The eCPRI framer test starts a driver then waits 1,000 cycles without an output scoreboard or completion assertion. |
| P1 | Low-PHY integration is control-plane only | [test_lowphy_smoke.py](../lowphy/tests/test_lowphy_smoke.py) checks register reads/writes. It does not verify DL, UL, or PRACH datapath results. `lowphy1` is selectable with `LOWPHY_TOP=lowphy1` but is not automatically parametrized into the default run. |
| P1 | Timer implementation branch is missed | [test_timer.py](../timer/tests/test_timer.py) sets `SIM_SPEED_UP` but not `FREQ_MODE`. RTL defaults to mode 0, so `timer_core_491p52` has neither a direct test nor an enabled parent-test configuration. Parametrize both implementations. |
| P2 | Orphan/legacy RTL needs a support decision | `nco_lut` is not instantiated and is omitted from `nco.flt` and all other resolved block filelists; current `nco` uses `dds_lut`. `fh_framer_message` is in the filelist but no RTL instantiation was found. Add direct tests if supported, or explicitly classify them as retired. |
| P2 | No shared suite tiers | No repository-wide sanity/smoke/regression pytest markers or Make targets were found. Current `make test` runs the module's entire pytest directory. Define explicit tiers and selection rules. |
| P2 | Existing test style violates AGENTS.md | 18 test files call `FallingEdge`, `ReadOnly`, or `ReadWrite`. These need conversion to the repository's required RisingEdge drive/sample convention when maintaining the suite. |

PTP and O-RAN are not rescued by the existing Low-PHY smoke test: the Low-PHY tops instantiate the radio processing blocks, not those transport/PTP tops.

## Existing test quality and useful starting points

All RTL declarations in `cdc` (7), `ram` (9), `fft` (5), `pdxch` (12), and `puxch` (9) have direct cocotb targets. Most single-module utility IP also has a target. This is useful infrastructure to extend, although direct-target presence is not a functional coverage sign-off.

`prach` has ten direct targets and sixteen further modules reachable in its hierarchy. Its [full-chain test](../prach/tests/test_prach.py) checks resynchronization, DDC activity, FFT output and spectrum, and U-plane framing for a particular F0 scenario. Keep that end-to-end test and add focused reset, parameter, routing, and error cases rather than treating all sixteen descendants as completely untested.

`timer_syncer` already parametrizes all three frequency modes. `axi4l_bram` tests the parent and can exercise the read/write helper modules through it. `dds_lut_rom` is instantiated by tested `dds_lut`. Dedicated tests for every small helper are optional if a documented parent test checks its externally visible behavior and the relevant configurations.

Concrete weak tests that should be strengthened:

- [coe/tests/test_coe.py](../coe/tests/test_coe.py): `test_coe_axi` checks three registers. `test_coe` generates and loops traffic, then waits; it has no receive-data scoreboard. Add exact data/order/count checks and a bounded completion condition.
- [ecpri/tests/test_ecpri.py](../ecpri/tests/test_ecpri.py): `config()` checks version and scratch registers, while `ethernet_slave_driver()` has its packet loop commented out. Add a checked full-top packet path, including CDC and routing.
- [ecpri/tests/test_ecpri_framer.py](../ecpri/tests/test_ecpri_framer.py): no output assertions; the background producer need not finish before the test ends. Join the producer and scoreboard tasks with timeouts, and assert a nonzero expected packet count. Existing eCPRI deframer/transport/padding tests provide more focused checks and should be retained.
- [lowphy/tests/test_lowphy_smoke.py](../lowphy/tests/test_lowphy_smoke.py): retain the register smoke, automatically run both tops, and add a separate datapath smoke with expected outputs.

## Proposed suite contract

The following are proposed additions, not implemented commands or tests.

| Tier | Required behavior | Selection and execution |
| --- | --- | --- |
| Sanity | Every supported module has a declared test owner, valid source closure, successful elaboration, and a bounded reset/idle check. Combinational modules get a small truth-table check instead of reset. All supported public tops and active generate branches are represented. | Proposed `make sanity`; cheapest representative configurations. Include Python helper tests and coverage-manifest validation. |
| Smoke | At least one completed, self-checking useful operation per module or documented parent-test owner. Include reset recovery and one stall/gap where applicable. A timeout, no output, lost transfer, duplicate transfer, or wrong result must fail. | Proposed `make smoke`; deterministic inputs/seeds, small data volume. Run both Low-PHY tops explicitly. |
| Regression | Directed corner cases, parameter matrices, seeded random traffic, repeated/mid-traffic reset, protocol errors, backpressure, clock ratios, wraparound, and numerical boundaries as applicable. Preserve focused unit tests and full-chain checks. | Proposed `make regression`; Verilator first and Questa second where supported. Respect the current Low-PHY Questa-only exception until its documented startup issue is fixed. |

Use one explicit manifest entry per RTL module: source, support status, direct test or parent-test owner, checked behavior, parameter configurations, simulator support, and suite tier. A new module without a manifest entry should fail the inventory check. An indirect entry must identify what assertion/scoreboard observes it; merely compiling a file or instantiating an idle block is insufficient. Retired modules and vendor-dependent wrappers need named waivers with reasons rather than disappearing from the count.

Put tier selection on pytest runner cases and propagate the selected cocotb cases to the simulator. A marker on a runner that launches every cocotb test does not by itself make a fast smoke subset. Register the markers and verify selected tiers collect a nonzero expected set. Keep full regression inclusive of sanity and smoke checks.

Every traffic test should assert the expected transaction count, compare actual outputs to independently computed expectations, and wait for both stimulus completion and scoreboard drain with a timeout. Record random seeds; NumPy `default_rng()` without a seed is not reproducible merely because cocotb logs its own random seed. Keep build/results directories separate by simulator, top, and configuration. Drive and sample with RisingEdge according to AGENTS.md.

| RTL family | Minimum smoke | Regression extensions |
| --- | --- | --- |
| Registers / AXI-Lite | Reset values, scratch read/write, one control output and status input | WSTRB masks, RO behavior, address decode, independent AW/W arrival, response stalls, reset during requests |
| FIFO / RAM / delays / CDC | One known transfer/write-read/pulse; exact ordering and latency | Empty/full and wraparound, simultaneous operations, enables, reset recovery, width/depth variants, asynchronous clock ratios |
| FH / eCPRI / CoE / O-RAN | Known valid frame in each supported direction; check headers, payload, keep/last, routing | VLAN and supported message variants, malformed/truncated frames, sequence handling, backpressure, buffer limits, counters, multi-channel contention |
| PTP / PPS / timers | Reset, valid timestamp/PPS event, expected increment/output pulse | Carry/wrap boundaries, offset/load, missing/early/late PPS, resync, multiple clock domains, all clock modes; accelerated timing where supported |
| DSP / compression / FFT | Impulse/tone/known block against an independent fixed-point model | Zero/extreme values, overflow/rounding, enable/bypass, gaps, widths and scaling, carrier/antenna routing, supported RAT/configuration branches |
| Integration tops / wrappers | Reset plus one checked control and datapath transaction | Both/all public top variants, cross-domain reset, simultaneous traffic, stream packing/port wiring, end-to-end count/order/numerical checks |

## Implementation order

1. Fix discovery and reporting: include `common` and `tests/`, report missing tests distinctly, add the module ownership manifest and tier selection. Preserve existing tests as the initial regression baseline.
2. Add low-cost sanity/smoke tests for PPS, PTP, FH, O-RAN registers and leaf blocks, and the two untested common utility modules. Resolve the four RTL files omitted from filelists before claiming universal elaboration coverage.
3. Add checked full-top paths for FH/PTP/O-RAN/PPS; strengthen CoE and eCPRI output scoreboards. Cover timer mode 1 and automatically run Low-PHY 0 and 1.
4. Expand parameter/error/reset matrices and Low-PHY datapath integration. Close each remaining module entry with a direct test, a behaviorally justified parent test, or an explicit support waiver. Correct the banned trigger usage as the affected tests are maintained.

## Validation performed

- `SIM=questa .venv/bin/python -m pytest --collect-only -q`: 242 cases collected successfully.
- `SIM=verilator .venv/bin/python -m pytest --collect-only -q`: 242 cases collected successfully.
- `make -C ptp test` and `make -C oran_slave test`: both reproduced success-with-no-tests.
- Resolved all block `.flt` files with the existing `hdl_tools.flt_tool.resolve_flt`; identified the four omitted module files listed above.
- Inspected direct target selection, static hierarchy, default parameters, relevant test bodies, and root/module Makefile behavior.

No HDL simulation, lint, synthesis, or full regression was run for this audit. Collection success is not simulation success. No RTL, tests, or build behavior was changed; this report is the deliverable. The pre-existing `.gitignore` edit was left untouched.

## Complete inventory

The following generated tables are a snapshot of the reviewed working tree. “Indirect” is only a static candidate; it must be validated against active parameters and output checks before assigning functional coverage credit.

| Block | RTL modules | Direct targets | Indirect candidates | No test path found |
| --- | ---: | ---: | ---: | ---: |
| `adder` | 1 | 1 | 0 | 0 |
| `axi4l_bram` | 4 | 1 | 3 | 0 |
| `axis_fifo` | 1 | 1 | 0 | 0 |
| `axis_fifo_alt` | 1 | 1 | 0 | 0 |
| `axis_reg` | 1 | 1 | 0 | 0 |
| `axis_switch` | 1 | 1 | 0 | 0 |
| `cdc` | 7 | 7 | 0 | 0 |
| `cmult` | 1 | 1 | 0 | 0 |
| `coe` | 9 | 1 | 7 | 1 |
| `common` | 6 | 3 | 1 | 2 |
| `dds_lut` | 2 | 1 | 1 | 0 |
| `ecpri` | 18 | 5 | 12 | 1 |
| `eth_pkt_fifo` | 1 | 1 | 0 | 0 |
| `fft` | 5 | 5 | 0 | 0 |
| `fh` | 12 | 1 | 0 | 11 |
| `fifo_async` | 1 | 1 | 0 | 0 |
| `fifo_srl` | 1 | 1 | 0 | 0 |
| `fifo_sync` | 1 | 1 | 0 | 0 |
| `gain` | 1 | 1 | 0 | 0 |
| `lfsr` | 1 | 1 | 0 | 0 |
| `lowphy` | 6 | 3 | 1 | 2 |
| `mixer` | 1 | 1 | 0 | 0 |
| `mult` | 1 | 1 | 0 | 0 |
| `nco` | 2 | 1 | 0 | 1 |
| `oran_slave` | 35 | 0 | 0 | 35 |
| `pdxch` | 12 | 12 | 0 | 0 |
| `phase_comp` | 1 | 1 | 0 | 0 |
| `power_meter` | 1 | 1 | 0 | 0 |
| `pps_top` | 11 | 2 | 0 | 9 |
| `prach` | 26 | 10 | 16 | 0 |
| `ptp` | 7 | 0 | 0 | 7 |
| `pulse_delay` | 1 | 1 | 0 | 0 |
| `puxch` | 9 | 9 | 0 | 0 |
| `ram` | 9 | 9 | 0 | 0 |
| `shift_ram` | 1 | 1 | 0 | 0 |
| `skid_buffer` | 1 | 1 | 0 | 0 |
| `symbol_timer` | 1 | 1 | 0 | 0 |
| `timer` | 7 | 1 | 5 | 1 |
| `timer_syncer` | 5 | 1 | 4 | 0 |
| **Total** | **212** | **92** | **50** | **70** |

Each row below names an actual RTL module, including modules that have no direct test. Parent candidates name a tested top, not a guarantee that the descendant is active.

| RTL module | Classification | Existing test / candidate parent / caveat |
| --- | --- | --- |
| [adder](../adder/rtl/adder.sv) | Direct | [test_adder.py](../adder/tests/test_adder.py) |
| [axi4l_bram](../axi4l_bram/rtl/axi4l_bram.sv) | Direct | [test_axi4l_bram.py](../axi4l_bram/tests/test_axi4l_bram.py) |
| [axi4l_bram_r](../axi4l_bram/rtl/axi4l_bram_r.sv) | Indirect | Candidate parent: `axi4l_bram`. |
| [axi4l_bram_w](../axi4l_bram/rtl/axi4l_bram_w.sv) | Indirect | Candidate parent: `axi4l_bram`. |
| [axi4l_bram_wr](../axi4l_bram/rtl/axi4l_bram_wr.sv) | Indirect | Candidate parent: `axi4l_bram`. |
| [axis_fifo](../axis_fifo/rtl/axis_fifo.sv) | Direct | [test_axis_fifo.py](../axis_fifo/tests/test_axis_fifo.py) |
| [axis_fifo_alt](../axis_fifo_alt/rtl/axis_fifo_alt.sv) | Direct | [test_axis_fifo_alt.py](../axis_fifo_alt/tests/test_axis_fifo_alt.py) |
| [axis_reg](../axis_reg/rtl/axis_reg.sv) | Direct | [test_axis_reg.py](../axis_reg/tests/test_axis_reg.py) |
| [axis_switch](../axis_switch/rtl/axis_switch.sv) | Direct | [test_axis_switch.py](../axis_switch/tests/test_axis_switch.py) |
| [cdc_array_single](../cdc/rtl/cdc_array_single.sv) | Direct | [test_cdc_array_single.py](../cdc/tests/test_cdc_array_single.py) |
| [cdc_async_rst](../cdc/rtl/cdc_async_rst.sv) | Direct | [test_cdc_async_rst.py](../cdc/tests/test_cdc_async_rst.py) |
| [cdc_gray](../cdc/rtl/cdc_gray.sv) | Direct | [test_cdc_gray.py](../cdc/tests/test_cdc_gray.py) |
| [cdc_handshake_f](../cdc/rtl/cdc_handshake_f.sv) | Direct | [test_cdc_handshake_f.py](../cdc/tests/test_cdc_handshake_f.py) |
| [cdc_pulse](../cdc/rtl/cdc_pulse.sv) | Direct | [test_cdc_pulse.py](../cdc/tests/test_cdc_pulse.py) |
| [cdc_single](../cdc/rtl/cdc_single.sv) | Direct | [test_cdc_single.py](../cdc/tests/test_cdc_single.py) |
| [cdc_sync_rst](../cdc/rtl/cdc_sync_rst.sv) | Direct | [test_cdc_sync_rst.py](../cdc/tests/test_cdc_sync_rst.py) |
| [cmult](../cmult/rtl/cmult.sv) | Direct | [test_cmult.py](../cmult/tests/test_cmult.py) |
| [coe](../coe/rtl/coe.sv) | Direct | [test_coe.py](../coe/tests/test_coe.py) Register assertions; traffic loopback lacks receive scoreboard. |
| [coe_deframer](../coe/rtl/coe_deframer.sv) | Indirect | Candidate parent: `coe`. |
| [coe_deframer_data](../coe/rtl/coe_deframer_data.sv) | Indirect | Candidate parent: `coe`. |
| [coe_deframer_hdr](../coe/rtl/coe_deframer_hdr.sv) | Indirect | Candidate parent: `coe`. |
| [coe_framer](../coe/rtl/coe_framer.sv) | Indirect | Candidate parent: `coe`. |
| [coe_framer_data](../coe/rtl/coe_framer_data.sv) | Indirect | Candidate parent: `coe`. |
| [coe_framer_hdr](../coe/rtl/coe_framer_hdr.sv) | Indirect | Candidate parent: `coe`. |
| [coe_regs](../coe/rtl/coe_regs.v) | Indirect | Candidate parent: `coe`. |
| [coe_wrapper](../coe/rtl/coe_wrapper.v) | None found | Add a test/checked parent path, or document a support waiver. |
| [delay](../common/rtl/delay.sv) | Direct | [test_delay.py](../common/tests/test_delay.py) **Omitted by root make test.** |
| [delay_lutram](../common/rtl/delay_lutram.sv) | Direct | [test_delay_lutram.py](../common/tests/test_delay_lutram.py) **Omitted by root make test.** |
| [srl](../common/rtl/srl.sv) | Indirect | Candidate parent: `fifo_srl`, `pulse_delay`, `puxch_buffer`. |
| [type_cast](../common/rtl/type_cast.sv) | Direct | [test_type_cast.py](../common/tests/test_type_cast.py) **Omitted by root make test.** |
| [util_clk_fwd](../common/rtl/util_clk_fwd.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [util_gpio_gw](../common/rtl/util_gpio_gw.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [dds_lut](../dds_lut/rtl/dds_lut.sv) | Direct | [test_dds_lut.py](../dds_lut/tests/test_dds_lut.py) |
| [dds_lut_rom](../dds_lut/rtl/dds_lut_rom.sv) | Indirect | Candidate parent: `dds_lut`, `fft_twiddle`, `mixer`. |
| [ecpri](../ecpri/rtl/ecpri.sv) | Direct | [test_ecpri.py](../ecpri/tests/test_ecpri.py) Top traffic stimulus is commented out; register checks only. |
| [ecpri_deframer](../ecpri/rtl/ecpri_deframer.sv) | Direct | [test_ecpri_deframer.py](../ecpri/tests/test_ecpri_deframer.py) |
| [ecpri_deframer_common](../ecpri/rtl/ecpri_deframer_common.sv) | Indirect | Candidate parent: `ecpri_deframer`, `coe`, `ecpri`. |
| [ecpri_deframer_demux](../ecpri/rtl/ecpri_deframer_demux.sv) | Indirect | Candidate parent: `ecpri_deframer`, `coe`, `ecpri`. |
| [ecpri_deframer_eth](../ecpri/rtl/ecpri_deframer_eth.sv) | Indirect | Candidate parent: `ecpri_deframer`, `coe`, `ecpri`. |
| [ecpri_deframer_iq](../ecpri/rtl/ecpri_deframer_iq.sv) | Indirect | Candidate parent: `ecpri_deframer`, `coe`, `ecpri`. |
| [ecpri_deframer_odm](../ecpri/rtl/ecpri_deframer_odm.sv) | Indirect | Candidate parent: `ecpri_deframer`, `coe`, `ecpri`. |
| [ecpri_framer](../ecpri/rtl/ecpri_framer.sv) | Direct | [test_ecpri_framer.py](../ecpri/tests/test_ecpri_framer.py) Stimulus exists; output scoreboard/completion assertion missing. |
| [ecpri_framer_buffer](../ecpri/rtl/ecpri_framer_buffer.sv) | Indirect | Candidate parent: `ecpri_framer`, `coe`, `ecpri`. |
| [ecpri_framer_odm](../ecpri/rtl/ecpri_framer_odm.sv) | Indirect | Candidate parent: `ecpri_framer`, `coe`, `ecpri`. |
| [ecpri_framer_padding](../ecpri/rtl/ecpri_framer_padding.sv) | Direct | [test_ecpri_framer_padding.py](../ecpri/tests/test_ecpri_framer_padding.py) |
| [ecpri_framer_trans](../ecpri/rtl/ecpri_framer_trans.sv) | Direct | [test_ecpri_framer_trans.py](../ecpri/tests/test_ecpri_framer_trans.py) |
| [ecpri_framer_trans_reg](../ecpri/rtl/ecpri_framer_trans_reg.sv) | Indirect | Candidate parent: `ecpri_framer_trans`, `ecpri_framer`, `coe`. |
| [ecpri_if](../ecpri/rtl/ecpri_if.sv) | Indirect | Candidate parent: `coe`, `ecpri`. |
| [ecpri_odm](../ecpri/rtl/ecpri_odm.sv) | Indirect | Candidate parent: `coe`, `ecpri`. |
| [ecpri_regs](../ecpri/rtl/ecpri_regs.v) | Indirect | Candidate parent: `ecpri`. |
| [ecpri_statistics](../ecpri/rtl/ecpri_statistics.sv) | Indirect | Candidate parent: `coe`, `ecpri`. |
| [ecpri_wrapper](../ecpri/rtl/ecpri_wrapper.v) | None found | Add a test/checked parent path, or document a support waiver. |
| [eth_pkt_fifo](../eth_pkt_fifo/rtl/eth_pkt_fifo.sv) | Direct | [test_eth_pkt_fifo.py](../eth_pkt_fifo/tests/test_eth_pkt_fifo.py) |
| [fft](../fft/rtl/fft.sv) | Direct | [test_fft_model.py](../fft/tests/test_fft_model.py) |
| [fft_bf2](../fft/rtl/fft_bf2.sv) | Direct | [test_fft_primitives.py](../fft/tests/test_fft_primitives.py) |
| [fft_ct](../fft/rtl/fft_ct.sv) | Direct | [test_fft_primitives.py](../fft/tests/test_fft_primitives.py) |
| [fft_stage](../fft/rtl/fft_stage.sv) | Direct | [test_fft_primitives.py](../fft/tests/test_fft_primitives.py) |
| [fft_twiddle](../fft/rtl/fft_twiddle.sv) | Direct | [test_fft_primitives.py](../fft/tests/test_fft_primitives.py) |
| [fh](../fh/rtl/fh.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [fh_deframer](../fh/rtl/fh_deframer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [fh_deframer_64to32](../fh/rtl/fh_deframer_64to32.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [fh_deframer_buffer](../fh/rtl/fh_deframer_buffer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [fh_deframer_demux](../fh/rtl/fh_deframer_demux.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [fh_framer](../fh/rtl/fh_framer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [fh_framer_32to64](../fh/rtl/fh_framer_32to64.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [fh_framer_message](../fh/rtl/fh_framer_message.sv) | None found | Add a test/checked parent path, or document a support waiver. Listed source; no RTL instantiation found. |
| [fh_framer_padding](../fh/rtl/fh_framer_padding.sv) | Direct | [test_fh_framer_padding.py](../fh/tests/test_fh_framer_padding.py) |
| [fh_regs](../fh/rtl/fh_regs.v) | None found | Add a test/checked parent path, or document a support waiver. |
| [fh_switch](../fh/rtl/fh_switch.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [fh_wrapper](../fh/rtl/fh_wrapper.v) | None found | Add a test/checked parent path, or document a support waiver. |
| [fifo_async](../fifo_async/rtl/fifo_async.sv) | Direct | [test_fifo_async.py](../fifo_async/tests/test_fifo_async.py) |
| [fifo_srl](../fifo_srl/rtl/fifo_srl.sv) | Direct | [test_fifo_srl.py](../fifo_srl/tests/test_fifo_srl.py) |
| [fifo_sync](../fifo_sync/rtl/fifo_sync.sv) | Direct | [test_fifo_sync.py](../fifo_sync/tests/test_fifo_sync.py) |
| [gain](../gain/rtl/gain.sv) | Direct | [test_gain.py](../gain/tests/test_gain.py) |
| [lfsr](../lfsr/rtl/lfsr.sv) | Direct | [test_lfsr.py](../lfsr/tests/test_lfsr.py) |
| [lowphy0](../lowphy/rtl/lowphy0.sv) | Direct | [test_lowphy_smoke.py](../lowphy/tests/test_lowphy_smoke.py) Control-plane smoke only. |
| [lowphy0_wrapper](../lowphy/rtl/lowphy0_wrapper.v) | None found | Add a test/checked parent path, or document a support waiver. |
| [lowphy1](../lowphy/rtl/lowphy1.sv) | Direct | [test_lowphy_smoke.py](../lowphy/tests/test_lowphy_smoke.py) Requires `LOWPHY_TOP=lowphy1`; absent from default run; control-plane smoke only. |
| [lowphy1_wrapper](../lowphy/rtl/lowphy1_wrapper.v) | None found | Add a test/checked parent path, or document a support waiver. |
| [lowphy_band](../lowphy/rtl/lowphy_band.sv) | Indirect | Candidate parent: `lowphy0`, `lowphy1`. Parent smoke checks registers only; no datapath scoreboard. |
| [lowphy_regs](../lowphy/rtl/lowphy_regs.v) | Direct | [test_lowphy_regs.py](../lowphy/tests/test_lowphy_regs.py) |
| [mixer](../mixer/rtl/mixer.sv) | Direct | [test_mixer.py](../mixer/tests/test_mixer.py) |
| [mult](../mult/rtl/mult.sv) | Direct | [test_mult.py](../mult/tests/test_mult.py) |
| [nco](../nco/rtl/nco.sv) | Direct | [test_nco.py](../nco/tests/test_nco.py) |
| [nco_lut](../nco/rtl/nco_lut.sv) | None found | Add a test/checked parent path, or document a support waiver. Uninstantiated; absent from all resolved block filelists. |
| [oran_deframer](../oran_slave/rtl/oran_deframer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_dl_ss](../oran_slave/rtl/oran_deframer_dl_ss.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_dl_ss_adaptor](../oran_slave/rtl/oran_deframer_dl_ss_adaptor.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_dl_ss_buffer](../oran_slave/rtl/oran_deframer_dl_ss_buffer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_dl_ss_decomp](../oran_slave/rtl/oran_deframer_dl_ss_decomp.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_dl_ss_decomp_exp](../oran_slave/rtl/oran_deframer_dl_ss_decomp_exp.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_dl_ss_decomp_gearbox](../oran_slave/rtl/oran_deframer_dl_ss_decomp_gearbox.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_dl_ss_hdr_buffer](../oran_slave/rtl/oran_deframer_dl_ss_hdr_buffer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_dl_ss_mgr](../oran_slave/rtl/oran_deframer_dl_ss_mgr.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_dl_ss_readout](../oran_slave/rtl/oran_deframer_dl_ss_readout.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_dl_ss_symnum](../oran_slave/rtl/oran_deframer_dl_ss_symnum.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_eth](../oran_slave/rtl/oran_deframer_eth.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_eth_common](../oran_slave/rtl/oran_deframer_eth_common.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_eth_filter](../oran_slave/rtl/oran_deframer_eth_filter.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_eth_odm](../oran_slave/rtl/oran_deframer_eth_odm.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_eth_parser](../oran_slave/rtl/oran_deframer_eth_parser.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_deframer_switch](../oran_slave/rtl/oran_deframer_switch.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer](../oran_slave/rtl/oran_framer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_eth](../oran_slave/rtl/oran_framer_eth.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_switch](../oran_slave/rtl/oran_framer_switch.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_ul_ss](../oran_slave/rtl/oran_framer_ul_ss.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_ul_ss_adaptor](../oran_slave/rtl/oran_framer_ul_ss_adaptor.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_ul_ss_app](../oran_slave/rtl/oran_framer_ul_ss_app.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_ul_ss_buffer](../oran_slave/rtl/oran_framer_ul_ss_buffer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_ul_ss_comp](../oran_slave/rtl/oran_framer_ul_ss_comp.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_ul_ss_comp_exp](../oran_slave/rtl/oran_framer_ul_ss_comp_exp.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_ul_ss_comp_gearbox](../oran_slave/rtl/oran_framer_ul_ss_comp_gearbox.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_ul_ss_ctrl](../oran_slave/rtl/oran_framer_ul_ss_ctrl.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_ul_ss_section](../oran_slave/rtl/oran_framer_ul_ss_section.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_framer_ul_ss_trans](../oran_slave/rtl/oran_framer_ul_ss_trans.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_if](../oran_slave/rtl/oran_if.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_slave_regs](../oran_slave/rtl/oran_slave_regs.v) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_statistics](../oran_slave/rtl/oran_statistics.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_switch](../oran_slave/rtl/oran_switch.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [oran_top](../oran_slave/rtl/oran_top.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [pdxch](../pdxch/rtl/pdxch.sv) | Direct | [test_pdxch.py](../pdxch/tests/test_pdxch.py), [test_pdxch_axis_array.py](../pdxch/tests/test_pdxch_axis_array.py), [test_pdxch_lte.py](../pdxch/tests/test_pdxch_lte.py) |
| [pdxch_bfp_gearbox](../pdxch/rtl/pdxch_bfp_gearbox.sv) | Direct | [test_pdxch_bfp_gearbox.py](../pdxch/tests/test_pdxch_bfp_gearbox.py) |
| [pdxch_block2stream](../pdxch/rtl/pdxch_block2stream.sv) | Direct | [test_pdxch_block2stream.py](../pdxch/tests/test_pdxch_block2stream.py) |
| [pdxch_channel](../pdxch/rtl/pdxch_channel.sv) | Direct | [test_pdxch_channel.py](../pdxch/tests/test_pdxch_channel.py) |
| [pdxch_conv](../pdxch/rtl/pdxch_conv.sv) | Direct | [test_pdxch_conv.py](../pdxch/tests/test_pdxch_conv.py) |
| [pdxch_conv_nco](../pdxch/rtl/pdxch_conv_nco.sv) | Direct | [test_pdxch_conv_nco.py](../pdxch/tests/test_pdxch_conv_nco.py) |
| [pdxch_fdv_buffer](../pdxch/rtl/pdxch_fdv_buffer.sv) | Direct | [test_pdxch_fdv_buffer.py](../pdxch/tests/test_pdxch_fdv_buffer.py) |
| [pdxch_fdv_buffer_map](../pdxch/rtl/pdxch_fdv_buffer_map.sv) | Direct | [test_pdxch_fdv_buffer_map.py](../pdxch/tests/test_pdxch_fdv_buffer_map.py) |
| [pdxch_fdv_buffer_readout](../pdxch/rtl/pdxch_fdv_buffer_readout.sv) | Direct | [test_pdxch_fdv_buffer_readout.py](../pdxch/tests/test_pdxch_fdv_buffer_readout.py) |
| [pdxch_fdv_buffer_write](../pdxch/rtl/pdxch_fdv_buffer_write.sv) | Direct | [test_pdxch_fdv_buffer_write.py](../pdxch/tests/test_pdxch_fdv_buffer_write.py) |
| [pdxch_regs](../pdxch/rtl/pdxch_regs.v) | Direct | [test_pdxch_regs.py](../pdxch/tests/test_pdxch_regs.py) |
| [pdxch_top](../pdxch/rtl/pdxch_top.sv) | Direct | [test_pdxch_config_matrix.py](../pdxch/tests/test_pdxch_config_matrix.py), [test_pdxch_fdv_top_lane.py](../pdxch/tests/test_pdxch_fdv_top_lane.py) |
| [phase_comp](../phase_comp/rtl/phase_comp.sv) | Direct | [test_pdxch_phase_comp_alignment.py](../pdxch/tests/test_pdxch_phase_comp_alignment.py), [test_phase_comp.py](../phase_comp/tests/test_phase_comp.py) |
| [power_meter](../power_meter/rtl/power_meter.sv) | Direct | [test_power_meter.py](../power_meter/tests/test_power_meter.py) |
| [pps_checker](../pps_top/rtl/pps_checker.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [pps_counter](../pps_top/rtl/pps_counter.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [pps_delay](../pps_top/rtl/pps_delay.sv) | Direct | [test_pps_delay.py](../pps_top/tests/test_pps_delay.py) |
| [pps_expand](../pps_top/rtl/pps_expand.sv) | Direct | [test_pps_expand.py](../pps_top/tests/test_pps_expand.py) |
| [pps_resync](../pps_top/rtl/pps_resync.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [pps_symbol_timer](../pps_top/rtl/pps_symbol_timer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [pps_timer](../pps_top/rtl/pps_timer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [pps_timer_cdc](../pps_top/rtl/pps_timer_cdc.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [pps_top](../pps_top/rtl/pps_top.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [pps_top_regs](../pps_top/rtl/pps_top_regs.v) | None found | Add a test/checked parent path, or document a support waiver. |
| [pps_ts_checker](../pps_top/rtl/pps_ts_checker.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [prach](../prach/rtl/prach.sv) | Direct | [test_prach.py](../prach/tests/test_prach.py) |
| [prach_bfp_compress](../prach/rtl/prach_bfp_compress.sv) | Direct | [test_prach_bfp_compress.py](../prach/tests/test_prach_bfp_compress.py) |
| [prach_bfp_gearbox](../prach/rtl/prach_bfp_gearbox.sv) | Direct | [test_prach_bfp_gearbox.py](../prach/tests/test_prach_bfp_gearbox.py) |
| [prach_channel](../prach/rtl/prach_channel.sv) | Indirect | Candidate parent: `prach`, `lowphy0`, `lowphy1`. |
| [prach_conv](../prach/rtl/prach_conv.sv) | Indirect | Candidate parent: `prach_ddc`, `prach`, `lowphy0`. |
| [prach_conv_nco](../prach/rtl/prach_conv_nco.sv) | Indirect | Candidate parent: `prach_ddc`, `prach`, `lowphy0`. |
| [prach_ctrl](../prach/rtl/prach_ctrl.sv) | Direct | [test_prach_ctrl.py](../prach/tests/test_prach_ctrl.py) |
| [prach_ddc](../prach/rtl/prach_ddc.sv) | Direct | [test_prach_ddc.py](../prach/tests/test_prach_ddc.py) |
| [prach_fft](../prach/rtl/prach_fft.sv) | Direct | [test_prach_fft.py](../prach/tests/test_prach_fft.py) |
| [prach_fft_ditfft2](../prach/rtl/prach_fft_ditfft2.sv) | Indirect | Candidate parent: `prach_fft`, `prach`, `lowphy0`. |
| [prach_fft_ditfft2_bf](../prach/rtl/prach_fft_ditfft2_bf.sv) | Direct | [test_prach_fft_ditfft2_bf.py](../prach/tests/test_prach_fft_ditfft2_bf.py) |
| [prach_fft_ditfft2_rom](../prach/rtl/prach_fft_ditfft2_rom.sv) | Indirect | Candidate parent: `prach_fft`, `prach`, `lowphy0`. |
| [prach_fft_ditfft2_twiddler](../prach/rtl/prach_fft_ditfft2_twiddler.sv) | Indirect | Candidate parent: `prach_fft`, `prach`, `lowphy0`. |
| [prach_fft_ditfft3](../prach/rtl/prach_fft_ditfft3.sv) | Indirect | Candidate parent: `prach_fft`, `prach`, `lowphy0`. |
| [prach_fft_ditfft3_bf1](../prach/rtl/prach_fft_ditfft3_bf1.sv) | Indirect | Candidate parent: `prach_fft`, `prach`, `lowphy0`. |
| [prach_fft_ditfft3_bf2](../prach/rtl/prach_fft_ditfft3_bf2.sv) | Indirect | Candidate parent: `prach_fft`, `prach`, `lowphy0`. |
| [prach_fft_ditfft3_bf3](../prach/rtl/prach_fft_ditfft3_bf3.sv) | Indirect | Candidate parent: `prach_fft`, `prach`, `lowphy0`. |
| [prach_framer](../prach/rtl/prach_framer.sv) | Indirect | Candidate parent: `prach`, `lowphy0`, `lowphy1`. |
| [prach_framer_buffer](../prach/rtl/prach_framer_buffer.sv) | Direct | [test_prach_framer_buffer.py](../prach/tests/test_prach_framer_buffer.py) |
| [prach_hb2](../prach/rtl/prach_hb2.sv) | Indirect | Candidate parent: `prach_ddc`, `prach`, `lowphy0`. |
| [prach_hb4](../prach/rtl/prach_hb4.sv) | Direct | [test_prach_hb4.py](../prach/tests/test_prach_hb4.py) |
| [prach_regs](../prach/rtl/prach_regs.v) | Indirect | Candidate parent: `prach`. |
| [prach_reshape](../prach/rtl/prach_reshape.sv) | Indirect | Candidate parent: `prach_ddc`, `prach`, `lowphy0`. |
| [prach_resync](../prach/rtl/prach_resync.sv) | Indirect | Candidate parent: `prach`, `lowphy0`, `lowphy1`. |
| [prach_stream2block](../prach/rtl/prach_stream2block.sv) | Direct | [test_prach_stream2block.py](../prach/tests/test_prach_stream2block.py) |
| [prach_top](../prach/rtl/prach_top.sv) | Indirect | Candidate parent: `prach`, `lowphy0`, `lowphy1`. |
| [ptp](../ptp/rtl/ptp.sv) | None found | Add a test/checked parent path, or document a support waiver. Absent from all resolved block filelists. |
| [ptp_ctrl](../ptp/rtl/ptp_ctrl.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [ptp_deframer](../ptp/rtl/ptp_deframer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [ptp_framer](../ptp/rtl/ptp_framer.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [ptp_lite](../ptp/rtl/ptp_lite.sv) | None found | Add a test/checked parent path, or document a support waiver. |
| [ptp_regs](../ptp/rtl/ptp_regs.v) | None found | Add a test/checked parent path, or document a support waiver. Absent from all resolved block filelists. |
| [ptp_wrapper](../ptp/rtl/ptp_wrapper.v) | None found | Add a test/checked parent path, or document a support waiver. Absent from all resolved block filelists. |
| [pulse_delay](../pulse_delay/rtl/pulse_delay.sv) | Direct | [test_pulse_delay.py](../pulse_delay/tests/test_pulse_delay.py) |
| [puxch](../puxch/rtl/puxch.sv) | Direct | [test_puxch.py](../puxch/tests/test_puxch.py) |
| [puxch_bfp_comp](../puxch/rtl/puxch_bfp_comp.sv) | Direct | [test_puxch_bfp_comp.py](../puxch/tests/test_puxch_bfp_comp.py) |
| [puxch_buffer](../puxch/rtl/puxch_buffer.sv) | Direct | [test_puxch_buffer.py](../puxch/tests/test_puxch_buffer.py) |
| [puxch_channel](../puxch/rtl/puxch_channel.sv) | Direct | [test_puxch_channel.py](../puxch/tests/test_puxch_channel.py) |
| [puxch_conv](../puxch/rtl/puxch_conv.sv) | Direct | [test_puxch_conv.py](../puxch/tests/test_puxch_conv.py) |
| [puxch_iq_ram](../puxch/rtl/puxch_iq_ram.sv) | Direct | [test_puxch_iq_ram.py](../puxch/tests/test_puxch_iq_ram.py) |
| [puxch_regs](../puxch/rtl/puxch_regs.v) | Direct | [test_puxch_regs.py](../puxch/tests/test_puxch_regs.py) |
| [puxch_resync](../puxch/rtl/puxch_resync.sv) | Direct | [test_puxch_resync.py](../puxch/tests/test_puxch_resync.py) |
| [puxch_top](../puxch/rtl/puxch_top.sv) | Direct | [test_puxch_top.py](../puxch/tests/test_puxch_top.py) |
| [ram_sdp](../ram/rtl/ram_sdp.sv) | Direct | [test_ram_sdp.py](../ram/tests/test_ram_sdp.py) |
| [ram_sdp_asym](../ram/rtl/ram_sdp_asym.sv) | Direct | [test_ram_sdp_asym.py](../ram/tests/test_ram_sdp_asym.py) |
| [ram_sdp_pipe](../ram/rtl/ram_sdp_pipe.sv) | Direct | [test_ram_sdp_pipe.py](../ram/tests/test_ram_sdp_pipe.py) |
| [ram_sp](../ram/rtl/ram_sp.sv) | Direct | [test_ram_sp.py](../ram/tests/test_ram_sp.py) |
| [ram_sp_pipe](../ram/rtl/ram_sp_pipe.sv) | Direct | [test_ram_sp_pipe.py](../ram/tests/test_ram_sp_pipe.py) |
| [ram_sp_uram_8k36](../ram/rtl/ram_sp_uram_8k36.sv) | Direct | [test_ram_sp_uram_8k36.py](../ram/tests/test_ram_sp_uram_8k36.py) |
| [ram_tdp](../ram/rtl/ram_tdp.sv) | Direct | [test_ram_tdp.py](../ram/tests/test_ram_tdp.py) |
| [ram_tdp_asym](../ram/rtl/ram_tdp_asym.sv) | Direct | [test_ram_tdp_asym.py](../ram/tests/test_ram_tdp_asym.py) |
| [ram_tdp_pipe](../ram/rtl/ram_tdp_pipe.sv) | Direct | [test_ram_tdp_pipe.py](../ram/tests/test_ram_tdp_pipe.py) |
| [shift_ram](../shift_ram/rtl/shift_ram.sv) | Direct | [test_shift_ram.py](../shift_ram/tests/test_shift_ram.py), [test_shift_ram_packed_uram.py](../shift_ram/tests/test_shift_ram_packed_uram.py) |
| [skid_buffer](../skid_buffer/rtl/skid_buffer.sv) | Direct | [test_skid_buffer.py](../skid_buffer/tests/test_skid_buffer.py) |
| [symbol_timer](../symbol_timer/rtl/symbol_timer.sv) | Direct | [test_symbol_timer.py](../symbol_timer/tests/test_symbol_timer.py) |
| [timer](../timer/rtl/timer.sv) | Direct | [test_timer.py](../timer/tests/test_timer.py) |
| [timer_core_400](../timer/rtl/timer_core_400.sv) | Indirect | Candidate parent: `timer`. |
| [timer_core_491p52](../timer/rtl/timer_core_491p52.sv) | Indirect | Candidate parent: `timer`. **Not enabled by existing test:** `FREQ_MODE` remains 0. |
| [timer_pps](../timer/rtl/timer_pps.sv) | Indirect | Candidate parent: `timer`. |
| [timer_regs](../timer/rtl/timer_regs.v) | Indirect | Candidate parent: `timer`. |
| [timer_rfs](../timer/rtl/timer_rfs.sv) | Indirect | Candidate parent: `timer`. |
| [timer_wrapper](../timer/rtl/timer_wrapper.v) | None found | Add a test/checked parent path, or document a support waiver. |
| [timer_syncer](../timer_syncer/rtl/timer_syncer.sv) | Direct | [test_timer_syncer.py](../timer_syncer/tests/test_timer_syncer.py) |
| [timer_syncer_156p25](../timer_syncer/rtl/timer_syncer_156p25.sv) | Indirect | Candidate parent: `timer_syncer`, `coe`, `ecpri`. |
| [timer_syncer_312p5](../timer_syncer/rtl/timer_syncer_312p5.sv) | Indirect | Candidate parent: `timer_syncer`, `coe`, `ecpri`. |
| [timer_syncer_390p625](../timer_syncer/rtl/timer_syncer_390p625.sv) | Indirect | Candidate parent: `timer_syncer`, `coe`, `ecpri`. |
| [timer_syncer_ch](../timer_syncer/rtl/timer_syncer_ch.sv) | Indirect | Candidate parent: `timer_syncer`, `coe`, `ecpri`. |

## Test files using banned scheduler triggers

These files contain actual calls to the prohibited triggers, not just comments or imports:

- [axi4l_bram/tests/test_axi4l_bram.py](../axi4l_bram/tests/test_axi4l_bram.py): `ReadWrite`.
- [ecpri/tests/test_ecpri_framer_trans.py](../ecpri/tests/test_ecpri_framer_trans.py): `FallingEdge`.
- [eth_pkt_fifo/tests/test_eth_pkt_fifo.py](../eth_pkt_fifo/tests/test_eth_pkt_fifo.py): `FallingEdge`.
- [fft/tests/test_fft_model.py](../fft/tests/test_fft_model.py): `ReadOnly`, `ReadWrite`.
- [fft/tests/test_fft_primitives.py](../fft/tests/test_fft_primitives.py): `ReadOnly`, `ReadWrite`.
- [pps_top/tests/test_pps_delay.py](../pps_top/tests/test_pps_delay.py): `FallingEdge`.
- [pps_top/tests/test_pps_expand.py](../pps_top/tests/test_pps_expand.py): `FallingEdge`.
- [pulse_delay/tests/test_pulse_delay.py](../pulse_delay/tests/test_pulse_delay.py): `ReadOnly`.
- [ram/tests/test_ram_sdp.py](../ram/tests/test_ram_sdp.py): `FallingEdge`, `ReadOnly`.
- [ram/tests/test_ram_sdp_asym.py](../ram/tests/test_ram_sdp_asym.py): `FallingEdge`, `ReadOnly`.
- [ram/tests/test_ram_sdp_pipe.py](../ram/tests/test_ram_sdp_pipe.py): `FallingEdge`, `ReadOnly`.
- [ram/tests/test_ram_sp.py](../ram/tests/test_ram_sp.py): `FallingEdge`, `ReadOnly`.
- [ram/tests/test_ram_sp_pipe.py](../ram/tests/test_ram_sp_pipe.py): `FallingEdge`, `ReadOnly`.
- [ram/tests/test_ram_tdp.py](../ram/tests/test_ram_tdp.py): `FallingEdge`, `ReadOnly`.
- [ram/tests/test_ram_tdp_asym.py](../ram/tests/test_ram_tdp_asym.py): `FallingEdge`, `ReadOnly`.
- [ram/tests/test_ram_tdp_pipe.py](../ram/tests/test_ram_tdp_pipe.py): `FallingEdge`, `ReadOnly`.
- [skid_buffer/tests/test_skid_buffer.py](../skid_buffer/tests/test_skid_buffer.py): `ReadWrite`.
- [timer_syncer/tests/test_timer_syncer.py](../timer_syncer/tests/test_timer_syncer.py): `ReadOnly`.
