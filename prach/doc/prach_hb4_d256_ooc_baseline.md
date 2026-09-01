# PRACH HB4 `DELAY_BASE=256` OOC resource baseline

This document records the resource baseline for the last PRACH half-band stage
(HB5), which originally instantiated `prach_hb4` with `DELAY_BASE=256`, and the
subsequent sparse-history replacement of both HB4 and HB5. Use the same OOC
script and synthesis options for all before/after comparisons.

## Configuration

- Date: 2026-08-08
- Tool: Vivado (single consistent release for each comparison)
- Device: `xcku5p-ffva676-2-i`
- Top: `prach_hb4`
- Parameter: `DELAY_BASE=256`
- Synthesis mode: out of context
- Hierarchy: none

Equivalent synthesis command:

```tcl
synth_design \
  -top prach_hb4 \
  -part xcku5p-ffva676-2-i \
  -mode out_of_context \
  -flatten_hierarchy none \
  -generic {DELAY_BASE=256}
```

Reusable script:

```text
prach/sim_build/run_prach_hb4_d256_ooc.tcl
```

## Resource baseline

| Resource | Used |
|---|---:|
| Total LUTs | 1662 |
| Logic LUTs | 25 |
| LUTRAMs | 0 |
| SRLs | 1637 |
| Flip-flops | 220 |
| CARRY8 | 3 |
| DSP48E2 | 4 |
| BRAM/URAM | 0 |

SRLs account for 98.5% of the total LUT count.

## SRL breakdown

| Storage | Logical depth and width | SRLs |
|---|---:|---:|
| `xp1` data history | 777 x 16 bits | 416 |
| `xp2` data history | 1793 x 16 bits | 896 |
| Data history subtotal | 41,120 bits | 1312 |
| `u_delay` sideband history | 778 x 13 bits | 325 |
| Total | 51,234 bits | 1637 |

The hierarchy report gives the same split:

| Hierarchy | Total LUTs | Logic LUTs | SRLs | FFs | DSPs |
|---|---:|---:|---:|---:|---:|
| `prach_hb4` total | 1662 | 25 | 1637 | 220 | 4 |
| Datapath/self | 1337 | 25 | 1312 | 192 | 4 |
| `u_delay` | 325 | 0 | 325 | 26 | 0 |

The two remaining flip-flops belong to the bypass synchronizer.

## Simulation baseline

`prach/tests/test_prach_hb4.py` covers both `DELAY_BASE=128` and 256. For the
256 case, each valid burst consists of eight consecutive real lanes:

```text
din_chn: 0 1 2 3 4 5 6 7
din_dv : 1 1 1 1 1 1 1 1
```

Each clock carries the even-index sample in `din_dp1` and the odd-index sample
in `din_dp2`. Invalid clocks contain randomized data. All bursts that supply
the checked filter taps are marked valid.

Because the existing SRLs cannot be reset, the test sends
`7 * DELAY_BASE + 20 = 1812` zero clocks before checking the 256 configuration.
The pre-change result is:

```text
test_prach_hb4_runner[hb4-delay-128] PASSED
test_prach_hb4_runner[hb5-delay-256] PASSED
```

## Generated reports

```text
prach/sim_build/vivado_ooc_prach_hb4_d256_baseline/
  prach_hb4_d256_ooc.dcp
  prach_hb4_d256_utilization.rpt
  prach_hb4_d256_utilization_hierarchical.rpt
```

The isolated OOC result is the comparison baseline. Do not compare an updated
OOC result directly with a hierarchical row from the complete DDC/Lowphy0
synthesis, because surrounding context can change optimization and packing.

## Sparse event-history implementation

The sparse event-history implementation replaces the clock-based sample and
sideband delay lines with eight lane-local event histories. A lane history is
advanced only when that lane has a valid input. Each 199-bit lane word stores:

| History | Per-lane depth | Bits |
|---|---:|---:|
| Odd samples used by the four symmetric tap pairs | 7 x 16 | 112 |
| Even samples used by the center tap | 3 x 16 | 48 |
| Sideband associated with the center sample | 3 x 13 | 39 |
| Total per lane | | 199 |
| Total for eight lanes | | 1592 |

Vivado infers the eight 199-bit words as 199 distributed-RAM LUTs. The old
51,234-bit clock history is therefore no longer present. The four-DSP multiply
and accumulate cascade, coefficient widths, rounding, and output width are
unchanged.

The implementation computes the output centered on lane event N when event
N+3 arrives. This has the same timing as the original circuit for the
continuous eight-clock input bursts used by the DDC. A finite test vector
needs three future lane events to produce its last three centered outputs; a
continuous radio stream naturally supplies them.

For `DELAY_BASE=128`, the input alternates between the retained phase at
channels 0..7 and the adjacent phase at channels 128..135. Both phases advance
the same eight lane histories and participate in filtering, but only the
0..7 phase asserts output `dv` and continues to the `DELAY_BASE=256` stage.
For `DELAY_BASE=256`, only channels 0..7 are accepted.

On reset, the per-lane valid counts and short sideband pipeline are reset. The
distributed RAM itself does not need reset because old entries are masked
until enough new valid events have been written.

## OOC comparison after optimization

The optimized result uses the same Vivado release, part, OOC mode, and
`-flatten_hierarchy none` setting as the baseline.

| Resource | Original `prach_hb4` | Sparse event history | Change |
|---|---:|---:|---:|
| Total LUTs | 1662 | 315 | -1347 (-81.0%) |
| Logic LUTs | 25 | 71 | +46 |
| LUTRAMs | 0 | 199 | +199 |
| SRLs | 1637 | 45 | -1592 (-97.3%) |
| Flip-flops | 220 | 401 | +181 |
| CARRY8 | 3 | 3 | 0 |
| DSP48E2 | 4 | 4 | 0 |
| BRAM/URAM | 0 | 0 | 0 |

The remaining 45 SRLs are short fixed-depth tap/output alignment pipelines,
not `DELAY_BASE`-scaled input history.

Optimized reports:

```text
prach/sim_build/vivado_ooc_prach_hb4_sparse_d256/
  prach_hb4_sparse_d256_ooc.dcp
  prach_hb4_sparse_d256_utilization.rpt
  prach_hb4_sparse_d256_utilization_hierarchical.rpt
```

## `DELAY_BASE=128` validation

The same event-history implementation also supports the preceding HB4 stage
with `DELAY_BASE=128`. Its storage depends on valid events per lane rather than
the clock interval between those events. The isolated result below predates
the small output-valid phase gate described above; the final integrated
resource result is recorded in the next section.

The D128 comparison also uses the same Vivado release, the same part, OOC mode, and
`-flatten_hierarchy none`:

| Resource | Original D128 | Sparse D128 | Change |
|---|---:|---:|---:|
| Total LUTs | 850 | 315 | -535 (-62.9%) |
| Logic LUTs | 25 | 71 | +46 |
| LUTRAMs | 0 | 199 | +199 |
| SRLs | 825 | 45 | -780 (-94.5%) |
| Flip-flops | 220 | 401 | +181 |
| DSP48E2 | 4 | 4 | 0 |
| BRAM/URAM | 0 | 0 | 0 |

D128 reports:

```text
prach/sim_build/vivado_ooc_prach_hb4_d128_baseline/
  prach_hb4_d128_ooc.dcp
  prach_hb4_d128_utilization.rpt
  prach_hb4_d128_utilization_hierarchical.rpt

prach/sim_build/vivado_ooc_prach_hb4_sparse_d128/
  prach_hb4_sparse_d128_ooc.dcp
  prach_hb4_sparse_d128_utilization.rpt
  prach_hb4_sparse_d128_utilization_hierarchical.rpt
```

The validated prototype was initially named `prach_hb4_sparse`. Its
implementation has now replaced the body of `prach_hb4.sv`, and the temporary
module has been removed. Both the D128 HB4 instance and the D256 HB5 instance
in `prach_ddc` continue to instantiate the public `prach_hb4` module name.

## Complete `prach_channel` OOC comparison

The complete before/after synthesis uses the same Vivado release, device
`xcku5p-ffva676-2-i`, OOC mode, and `-flatten_hierarchy none`. The baseline
uses the original clock-delay implementation for both stages; the optimized
build uses the sparse event-history implementation for both stages. The
optimized report predates the final module rename, which does not change the
logic.

| Resource | Original channel | Sparse HB4 + HB5 | Change |
|---|---:|---:|---:|
| Total LUTs | 7966 | 6199 | -1767 (-22.2%) |
| Logic LUTs | 3854 | 3965 | +111 (+2.9%) |
| LUTRAMs | 0 | 386 | +386 |
| SRLs | 4112 | 1848 | -2264 (-55.1%) |
| Flip-flops | 7295 | 7711 | +416 (+5.7%) |
| Block RAM tiles | 27.5 | 27.5 | 0 |
| DSP48E2 | 61 | 61 | 0 |

The hierarchy report isolates the change inside `u_ddc`:

| Hierarchy | Total LUTs | Logic LUTs | LUTRAMs | SRLs | FFs | DSPs |
|---|---:|---:|---:|---:|---:|---:|
| `u_ddc`, original | 3609 | 407 | 0 | 3202 | 1891 | 23 |
| `u_ddc`, sparse | 1814 | 510 | 386 | 918 | 2303 | 23 |
| D128 HB4, original | 824 | 25 | 0 | 799 | 189 | 4 |
| D128 HB4, sparse | 319 | 83 | 193 | 43 | 395 | 4 |
| D256 HB5, original | 1596 | 25 | 0 | 1571 | 189 | 4 |
| D256 HB5, sparse | 306 | 70 | 193 | 43 | 395 | 4 |

Thus `u_ddc` saves 1795 LUTs (49.7%). The D128 stage saves 505 LUTs
(61.3%), and the D256 stage saves 1290 LUTs (80.8%). The extra logic LUTs and
flip-flops implement event qualification, history warm-up masking, and short
pipeline alignment; no DSP or block RAM was added.

Complete-channel reports:

```text
prach/sim_build/vivado_ooc_prach_channel_baseline/
  prach_channel_baseline_ooc.dcp
  prach_channel_baseline_utilization.rpt
  prach_channel_baseline_utilization_hierarchical.rpt

prach/sim_build/vivado_ooc_prach_channel_sparse/
  prach_channel_sparse_ooc.dcp
  prach_channel_sparse_utilization.rpt
  prach_channel_sparse_utilization_hierarchical.rpt
```

## Regression result

The following Questa regression was run while comparing the original and
sparse implementations before the final module rename:

```text
test_prach_hb4_runner[hb4-delay-128] PASSED
test_prach_hb4_runner[hb4-sparse-delay-128] PASSED
test_prach_hb4_runner[hb5-original-delay-256] PASSED
test_prach_hb4_runner[hb5-sparse-delay-256] PASSED
test_six_stage_chain_matches_cycle_accurate_model PASSED
5 passed in 69.84s
```

After the sparse implementation replaced `prach_hb4.sv` and the temporary
module was removed, the final public-module regression was rerun:

```text
test_prach_hb4_runner[hb4-delay-128] PASSED
test_prach_hb4_runner[hb5-delay-256] PASSED
test_six_stage_chain_matches_cycle_accurate_model PASSED
3 passed in 48.36s
```
