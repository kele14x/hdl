# Known issues

## Cocotb trigger and sampling conventions

- Audit and resolution date: 2026-09-22.
- Source baseline: `f897c85`; historical inventory line numbers refer to this revision.
- Status: TB-001, TB-002, TB-003, and the additional timed drivers corrected in the working tree; intentional exceptions retained.
- Scope: 110 per-IP Python files, 13 shared `hdl_tools` files, and five root Python test files.
- Inventory counts are static call sites, not runtime executions or failing test counts; categories can overlap within a test.

### Resolution and verification

The correction changes 43 test Python files across 12 IP modules, without RTL
or configuration changes. Synchronous drivers now provide inputs after a rising
clock edge for capture at the next edge. Checkers sample stable values at clock
edges, with explicit observation latency and pipeline draining. Ready/valid
accounting uses the transfer accepted at that edge. RAM models retain ordered
responses; zero configured latency means no extra wait after a clock-sampled
request, not a same-timestep combinational response.

The final static scan found no `FallingEdge`, `ReadOnly`, or `ReadWrite` calls.
All 359 active `RisingEdge` sites across 83 files resolve to clocks, including
configured clocks and helper parameters; all 312 `ClockCycles` calls use rising
clock edges. No hidden trigger aliases or other non-clock edge waits remain
outside the intentional asynchronous reset check.
The four retained `Timer` sites are combinational checks in
`common/tests/test_type_cast.py`, `pdxch/tests/test_pdxch_fdv_buffer_map.py`,
and `pdxch/tests/test_pdxch_conv.py`, plus initial setup in
`ram/tests/test_ram_sp_uram_8k36.py`. The asynchronous reset test retains
`ValueChange(dest_arst)` with the destination clock stopped.

Affected-module suites passed with both Verilator and Questa:

| Module | Verilator pytest cases | Questa pytest cases |
| --- | ---: | ---: |
| axi4l_bram | 8 | 8 |
| ecpri | 5 | 5 |
| eth_pkt_fifo | 1 | 1 |
| fft | 23 | 23 |
| pdxch | 29 | 29 |
| pps_top | 3 | 3 |
| prach | 16 | 16 |
| pulse_delay | 1 | 1 |
| puxch | 14 | 14 |
| ram | 23 | 23 |
| skid_buffer | 1 | 1 |
| timer_syncer | 3 | 3 |
| **Total per simulator invocation** | **127** | **127** |

These are pytest case counts, not individual cocotb test counts; FFT includes
Python model tests. All 14 shared Python tests also passed. Testing was limited
to the affected-module suites and shared Python tests. Final `ruff check` and
`ruff format --check` passed for all 43 modified Python files; `git diff --check`
also passed.
No repository-wide regression, RTL lint sweep, or synthesis sweep was rerun for
this test-only correction. Earlier interrupted regression results are not
reclassified as passing by these focused runs.

### Historical audit inventory (`f897c85`)

The findings, counts, and line numbers below describe the original audit, not
remaining violations in the corrected working tree. The initial audit was
read-only; corrections and simulation results are recorded above.

These findings expand the trigger-convention issue in the earlier
[cocotb testbench audit](cocotb_testbench_audit.md). Separate PDXCH RTL issues
remain in [pdxch_known_issues.md](../pdxch/doc/pdxch_known_issues.md).

The repository convention is to drive and sample synchronous interfaces on
`RisingEdge` of the relevant clock, checking valid/ready/data at that edge.
Inputs driven after an edge are intended for the next edge. `FallingEdge`,
`ReadOnly`, and `ReadWrite` are explicitly banned for driving or sampling in
[AGENTS.md](../AGENTS.md). Timed settling used instead of the prescribed
clock-edge sampling is tracked separately below.

### TB-001: Non-clock rising-edge waits

Three active call sites in two files wait on a valid signal rather than
polling it on the relevant clock. A valid transition is a real event, but
other signals updated at the same simulation timestamp may not yet have
settled when the waiter resumes. This caused the previously fixed CDC
handshake checker failure; it does not establish that the sites below fail.

| Baseline location | Trigger and following behavior | Assessment |
| --- | --- | --- |
| [prach/tests/test_prach.py:266](../prach/tests/test_prach.py) | `_monitor_fft` waits on `RisingEdge(fft.dout_dv)`, then 1 ps before reading channel and I/Q data. | Non-clock capture startup with timed settling; not an unguarded immediate payload read. |
| [prach/tests/test_prach.py:286](../prach/tests/test_prach.py) | `_monitor_valid_samples` waits on `RisingEdge(stream.dout_dv)`, then 1 ps before reading channel and I/Q data; used for DDC and stream2block. | Same pattern at each valid burst. |
| [skid_buffer/tests/test_skid_buffer.py:165](../skid_buffer/tests/test_skid_buffer.py) | `_wait_for_m_vld` waits on `RisingEdge(m_vld_o)`, then `ReadWrite()` before the caller drives ready. | Event-triggered ready response; payload monitoring itself uses clock edges. |

Follow-up: use clock-edge valid polling while preserving intended transfer
counts, backpressure, and latency checks; validate on Verilator and Questa.
No additional non-clock `RisingEdge` targets were found among 293 active
`RisingEdge` call sites across 76 per-IP files, including wrapper review.

### TB-002: Explicitly prohibited falling-edge and phase waits

There are **134 call sites across 18 files**: 74 `FallingEdge`, 50 `ReadOnly`,
and 10 `ReadWrite`. These are convention violations, not evidence that all
of the affected tests currently fail.

| File | `FallingEdge` lines | `ReadOnly` lines | `ReadWrite` lines |
| --- | --- | --- | --- |
| [ram/tests/test_ram_sp.py](../ram/tests/test_ram_sp.py) | 113 | 120, 144 | — |
| [ram/tests/test_ram_sdp.py](../ram/tests/test_ram_sdp.py) | 67, 79, 85, 93, 102, 109, 115, 122 | 89, 113, 118, 126 | — |
| [ram/tests/test_ram_tdp.py](../ram/tests/test_ram_tdp.py) | 54, 65, 118, 125 | 60, 71, 123, 129 | — |
| [ram/tests/test_ram_sp_pipe.py](../ram/tests/test_ram_sp_pipe.py) | 71, 78, 88, 97, 109, 112, 122, 134, 139, 144, 148 | 92, 100, 104, 115, 126, 137, 141, 151 | — |
| [ram/tests/test_ram_sdp_pipe.py](../ram/tests/test_ram_sdp_pipe.py) | 67, 78, 87, 99, 102, 112, 124, 129, 134, 138 | 82, 90, 94, 105, 116, 127, 131, 141 | — |
| [ram/tests/test_ram_tdp_pipe.py](../ram/tests/test_ram_tdp_pipe.py) | 75, 82, 89, 96, 102, 111, 122, 128, 135, 144, 149, 152, 158, 161, 169, 175, 180, 184 | 93, 106, 114, 118, 139, 155, 164, 173, 177, 187 | — |
| [ram/tests/test_ram_sdp_asym.py](../ram/tests/test_ram_sdp_asym.py) | 68, 85, 93, 101, 106, 112 | 89, 105, 109, 116 | — |
| [ram/tests/test_ram_tdp_asym.py](../ram/tests/test_ram_tdp_asym.py) | 73, 91, 99, 106, 112, 117 | 95, 111, 115, 121 | — |
| [pps_top/tests/test_pps_delay.py](../pps_top/tests/test_pps_delay.py) | 35, 40, 48 | — | — |
| [pps_top/tests/test_pps_expand.py](../pps_top/tests/test_pps_expand.py) | 34, 39, 46, 50 | — | — |
| [ecpri/tests/test_ecpri_framer_trans.py](../ecpri/tests/test_ecpri_framer_trans.py) | 92 | — | — |
| [eth_pkt_fifo/tests/test_eth_pkt_fifo.py](../eth_pkt_fifo/tests/test_eth_pkt_fifo.py) | 33, 46 | — | — |
| [pulse_delay/tests/test_pulse_delay.py](../pulse_delay/tests/test_pulse_delay.py) | — | 39 | — |
| [timer_syncer/tests/test_timer_syncer.py](../timer_syncer/tests/test_timer_syncer.py) | — | 23, 59, 70 | — |
| [fft/tests/test_fft_primitives.py](../fft/tests/test_fft_primitives.py) | — | 24 | 29, 37, 57 |
| [fft/tests/test_fft_model.py](../fft/tests/test_fft_model.py) | — | 69 | 90, 98, 165 |
| [axi4l_bram/tests/test_axi4l_bram.py](../axi4l_bram/tests/test_axi4l_bram.py) | — | — | 389, 663 |
| [skid_buffer/tests/test_skid_buffer.py](../skid_buffer/tests/test_skid_buffer.py) | — | — | 166, 174 |

RAM tests use falling edges for stimulus/pipeline alignment and `ReadOnly`
for registered-output checks. PPS, eCPRI, and Ethernet FIFO falling edges
schedule stimulus. FFT helpers use phase waits for both driving and sampling;
pulse-delay and timer-syncer phase waits sample outputs. AXI-Lite BRAM models
use `ReadWrite` for intentional same-timestep request/response modeling, but
that primitive remains prohibited by the repository convention.

Follow-up: convert each driver/checker with explicit cycle accounting rather
than mechanically replacing trigger names, preserving RAM latency,
handshake acceptance, model response timing, and reset/hold coverage.

### TB-003: Timed settling used for synchronous sampling

There are **52 explicit `Timer` call sites across 23 files** used for live
synchronous sampling, usually clock edge followed by 1 ps before reading
registered outputs or checking a handshake. `Timer` is not explicitly banned
by name in AGENTS.md; these sites nevertheless depart from the intended
clock-edge-only sampling pattern. A picosecond delay advances simulation
time and is not itself a delta-cycle trigger.

| File | Sampling `Timer` lines |
| --- | --- |
| [pps_top/tests/test_pps_delay.py](../pps_top/tests/test_pps_delay.py) | 22 |
| [pps_top/tests/test_pps_expand.py](../pps_top/tests/test_pps_expand.py) | 22 |
| [ram/tests/test_ram_sp_uram_8k36.py](../ram/tests/test_ram_sp_uram_8k36.py) | 62 |
| [pdxch/tests/test_pdxch_conv.py](../pdxch/tests/test_pdxch_conv.py) | 94, 151, 191 |
| [pdxch/tests/test_pdxch_conv_nco.py](../pdxch/tests/test_pdxch_conv_nco.py) | 31 |
| [pdxch/tests/test_pdxch_regs.py](../pdxch/tests/test_pdxch_regs.py) | 45, 56, 72, 81 |
| [pdxch/tests/test_pdxch_fdv_buffer_write.py](../pdxch/tests/test_pdxch_fdv_buffer_write.py) | 51, 73 |
| [pdxch/tests/test_pdxch_fdv_buffer_readout.py](../pdxch/tests/test_pdxch_fdv_buffer_readout.py) | 72, 176, 214 |
| [pdxch/tests/test_pdxch_fdv_buffer.py](../pdxch/tests/test_pdxch_fdv_buffer.py) | 67, 79, 139, 184, 247 |
| [pdxch/tests/test_pdxch_bfp_gearbox.py](../pdxch/tests/test_pdxch_bfp_gearbox.py) | 88, 96, 130 |
| [pdxch/tests/test_pdxch_phase_comp_alignment.py](../pdxch/tests/test_pdxch_phase_comp_alignment.py) | 58 |
| [pdxch/tests/test_pdxch_channel.py](../pdxch/tests/test_pdxch_channel.py) | 56, 69, 116 |
| [pdxch/tests/test_pdxch_block2stream.py](../pdxch/tests/test_pdxch_block2stream.py) | 69 |
| [pdxch/tests/test_pdxch.py](../pdxch/tests/test_pdxch.py) | 219, 230, 261 |
| [pdxch/tests/test_pdxch_lte.py](../pdxch/tests/test_pdxch_lte.py) | 135, 161 |
| [pdxch/tests/test_pdxch_config_matrix.py](../pdxch/tests/test_pdxch_config_matrix.py) | 120, 139 |
| [pdxch/tests/test_pdxch_fdv_top_lane.py](../pdxch/tests/test_pdxch_fdv_top_lane.py) | 136, 151, 162, 197 |
| [prach/tests/test_prach_stream2block.py](../prach/tests/test_prach_stream2block.py) | 151, 194 |
| [prach/tests/test_prach_hb4.py](../prach/tests/test_prach_hb4.py) | 209 |
| [prach/tests/test_prach_ddc.py](../prach/tests/test_prach_ddc.py) | 185 |
| [prach/tests/test_prach.py](../prach/tests/test_prach.py) | 252, 267, 280, 287, 297, 382 |
| [puxch/tests/test_puxch.py](../puxch/tests/test_puxch.py) | 185 |
| [puxch/tests/puxch_test_utils.py](../puxch/tests/puxch_test_utils.py) | 22 |

The PUXCH `sample_after_rising` helper also affects callers in
`puxch/tests/test_puxch_iq_ram.py:70`, `test_puxch_conv.py:67`,
`test_puxch_resync.py:45`, `test_puxch_regs.py:15`,
`test_puxch_channel.py:59`, `test_puxch_top.py:78`, and
`test_puxch_buffer.py:123` under the same directory. Its call sites are not
additional explicit `Timer` sites.

Follow-up: check which cycle each expected result represents before changing
sampling; do not shift scoreboards by a cycle or confuse post-edge valid/ready
values with the handshake accepted at that edge.

### Other timed driving patterns to review

These are not included in the 52 synchronous-sampling sites:

- Delayed pulse/request/valid deassertion: `pdxch/tests/test_pdxch.py:213`,
  `pdxch/tests/test_pdxch_fdv_buffer.py:61`,
  `pdxch/tests/test_pdxch_fdv_buffer_readout.py:63`,
  `prach/tests/test_prach.py:219,227`, and
  `puxch/tests/test_puxch.py:214,223` (seven sites).
- Elapsed-time radio stimulus pacing: `prach/tests/test_prach.py:245`
  advances by a 16-clock-equivalent interval plus 1 ps between input updates.

These drive rather than sample the DUT, but should be considered when
converting the affected synchronous testbench to clock-based scheduling.

### Intentional exceptions and clean shared code

- [cdc/tests/test_cdc_async_rst.py:48](../cdc/tests/test_cdc_async_rst.py#L48)
  waits for `ValueChange(dest_arst)` after stopping the destination clock to
  prove reset assertion is asynchronous. Replacing this with a destination
  clock wait would defeat that test; it is not a synchronous sampling defect.
- Genuine combinational settling is used in `common/tests/test_type_cast.py:117`,
  `pdxch/tests/test_pdxch_fdv_buffer_map.py:28`, and
  `pdxch/tests/test_pdxch_conv.py:75` (FFT-size decode with CDC disabled).
  These are not included in the 52 synchronous-sampling sites.
- `ram/tests/test_ram_sp_uram_8k36.py:74` uses a setup delay before stimulus,
  not live synchronous sampling. Together with the other categories above,
  this accounts for all 64 explicit per-IP `Timer` sites.
- Software events, queues, task joins, and safety timeouts coordinate testbench
  work; they are not waits on changing DUT data and were not classified as
  sampling violations.
- Shared `hdl_tools` AXI, AXI-Lite, FIFO, DSP, handshake, and timing helpers use
  configured clock edges for DUT driving/sampling; no non-clock signal-edge
  or prohibited phase waits were found there. Root Python tests have no
  cocotb trigger waits.
