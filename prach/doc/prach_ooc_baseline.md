# PRACH top OOC resource baseline (post-timing-fix)

This document records the resource baseline of the full `prach` wrapper from
out-of-context synthesis and implementation, after the `u_compress` write-path
pipeline fix closed the timing violations in the `clk` (491.52 MHz) domain.
The pre-fix baseline (LUT 18,505 / FF 22,448, WNS -0.357 ns) was superseded
by this run. Use the same OOC script and synthesis options for all before/after
comparisons.

## Configuration

- Date: 2026-09-04
- Tool: Vivado v2026.1
- Device: `xcku5p-ffvb676-2-i`
- Top: `prach`
- Parameter: `ANT_ID=0`
- Synthesis mode: out of context
- Hierarchy: none (`-flatten_hierarchy none`)
- Define: `RAM_USE_XPM`

Script:

```text
prach/synth/prach_ooc.tcl
```

The script runs synthesis through implementation (`opt_design`, `place_design`,
`phys_opt_design`, `route_design`) and emits both pre- and post-impl reports.

## Resource baseline

| Resource | After synth | After impl |
|---|---:|---:|
| Total LUTs | 20752 | 18395 |
|   Logic LUTs | 13351 | 13001 |
|   LUTRAMs | 1660 | 1098 |
|   SRLs | 5741 | 4296 |
| Flip-flops | 23643 | 22704 |
| CARRY8 | 855 | 855 |
| Block RAM tiles | 63 | 63 |
|   RAMB36E2 | 51 | 51 |
|   RAMB18E2 | 24 | 24 |
| URAM | 0 | 0 |
| DSP48E2 | 183 | 183 |

Utilization on device: LUTs 8.48%, flip-flops 5.23%, BRAM 13.13%, DSP 10.03%
(after implementation).

## Timing fix

`prach_bfp_compress` pipelines the BFP write datapath: the barrel shift and the
process-control snapshot are registered in lockstep, the rounding and word
assembly feed a second register, and the write interface (we/addr/exp/
section_done) registers one cycle later from the same delayed snapshot. All
outputs shift uniformly by one cycle, so RAM contents and downstream behavior
are unchanged (verified by the compress and framer-buffer regressions).

## Generated reports

```text
prach/vivado_ooc/prach_20260901_ant0/
  prach_utilization.rpt
  prach_utilization_hierarchical.rpt
  prach_timing_summary.rpt
  prach_ooc.dcp
  prach_impl_utilization.rpt
  prach_impl_utilization_hierarchical.rpt
  prach_impl_timing_summary.rpt
  prach_impl.dcp
```

## Timing status

Implementation timing is met: 0 failing endpoints, WNS +0.116 ns in the `clk`
(491.52 MHz) domain, clk_eth_xran +0.218 ns, s_axi_aclk +6.898 ns. Hold
WHS +0.023 ns, pulse width clean. The worst remaining slack is the `clk`
domain at +0.116 ns, so the planned LUT-optimization work should re-check
timing after landing.