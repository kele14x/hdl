# PDXCH Vivado OOC synthesis and implementation result

- Date: 2026-09-08
- Source commit: `786f998`
- Tool: Vivado v2024.2
- Top: `pdxch` (instantiates `pdxch_top`)
- Device: `xcku5p-ffvb676-2-i`
- Parameters: `NUM_CC=3`, `NUM_ANT=4`, `HALF_BLOCK=0`, `HALF_FFT=0`
- Synthesis mode: out of context
- Hierarchy: none (`-flatten_hierarchy none`)
- Define: `RAM_USE_XPM`

The OOC flow is defined in `pdxch/synth/pdxch_top_ooc.tcl`. It now runs from
RTL elaboration through synthesis and implementation (`opt_design`,
`place_design`, `phys_opt_design`, `route_design`), retaining both the
synthesis and post-route checkpoints and reports.

## Resource result

| Resource | After synth | After impl | Available | Impl utilization |
| --- | ---: | ---: | ---: | ---: |
| CLB LUTs | 16,317 | 13,452 | 216,960 | 6.20% |
| LUT as Logic | 14,008 | 11,848 | 216,960 | 5.46% |
| LUT as Memory | 2,309 | 1,604 | 99,840 | 1.61% |
| CLB registers / FFs | 15,985 | 16,121 | 433,920 | 3.72% |
| Block RAM Tile | 91.5 | 91.5 | 480 | 19.06% |
| UltraRAM | 3 | 3 | 64 | 4.69% |
| DSP blocks | 99 | 99 | 1,824 | 5.43% |

Implementation resource counts are from the post-route utilization report;
the LUT count is lower than synthesis after physical optimization and LUT
combining.

## Timing result

| Clock | Period | Synth WNS | Synth WHS | Impl WNS | Impl WHS |
| --- | ---: | ---: | ---: | ---: | ---: |
| `clk` | 2.035 ns / 491.4 MHz | -0.018 ns | 0.030 ns | 0.054 ns | 0.029 ns |
| `clk_eth_xran` | 2.500 ns / 400 MHz | 0.565 ns | 0.046 ns | 0.145 ns | 0.044 ns |
| `s_axi_aclk` | 10.000 ns / 100 MHz | 8.733 ns | 0.042 ns | 6.749 ns | 0.042 ns |

Post-route timing is met on all constrained clocks: 0 failing setup
endpoints, 0 failing hold endpoints, global WNS `+0.054 ns`, and global WHS
`+0.029 ns`. The route report contains 32,673 fully routed nets and 0 routing
errors.

The OOC run still reports the expected `HD.CLK_SRC` and `HD.PARTPIN_LOCS`
warnings because clock and top-level port locations are assigned by the
integrating design. This is an OOC implementation result, not full-chip
signoff timing.

## Generated reports and checkpoints

```text
pdxch/vivado_ooc/pdxch_20260908_hb0_hf0/
  pdxch_utilization.rpt
  pdxch_utilization_hierarchical.rpt
  pdxch_timing_summary.rpt
  pdxch_ooc.dcp
  pdxch_impl_utilization.rpt
  pdxch_impl_utilization_hierarchical.rpt
  pdxch_impl_timing_summary.rpt
  pdxch_impl_route_status.rpt
  pdxch_impl.dcp
```
