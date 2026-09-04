# PRACH LUT optimization analysis baseline (pre-optimization)

This document records the LUT-usage analysis of the full `prach` wrapper
before any optimization work. It complements `prach/doc/prach_ooc_baseline.md`
(resource baseline) and should be updated with before/after numbers for each
optimization as it lands. The `u_compress` write-path pipeline (timing fix,
Sep 04) already landed and reduced the compress LUT count; the remaining
opportunities below are unchanged.

## Configuration

- Date: 2026-09-04
- Tool: Vivado v2026.1
- Device: `xcku5p-ffvb676-2-i`
- Top: `prach`, `ANT_ID=0`
- Synthesis mode: out of context, `-flatten_hierarchy none`
- Stage: post-implementation (routed)

## LUT budget

Total: 18,395 LUTs = 13,001 logic + 1,098 LUTRAM + 4,296 SRL (SRLs are 23% of
the total LUT count; they are already the minimal per-bit form and are only
addressable via algorithmic changes).

Per channel (3 antenna channels):

| Block | Logic | LUTRAM | SRL | Total | x3 |
|---|---:|---:|---:|---:|---:|
| u_fft | 1,913 | 108 | 674 | 2,695 | 8,085 |
| u_framer (u_compress 535 + u_gearbox 267 + rest) | 965 | 64 | 0 | 1,029 | 3,087 |
| u_ddc (HB2/HB4 + mixer + conv) | 463 | 194 | 715 | 1,372 | 4,116 |
| u_stream2block | 302 | 0 | 28 | 330 | 990 |
| u_ctrl | 342 | 0 | 0 | 347 | 1,041 |
| u_resync | 91 | 0 | 0 | 91 | 273 |

Source: `prach/vivado_ooc/prach_20260901_ant0/prach_impl_utilization_hierarchical.rpt`.

## Ranked optimization opportunities

### 1. FFT butterfly adders -> DSP48E2 (est -1200..-2000 LUTs)

Each `prach_fft_ditfft2_bf` (117-148 logic LUTs, x10 stages per channel)
implements 4 conditional 18-bit add/sub with sign-extension muxes
(`prach_fft_ditfft2_bf.sv` lines 110-132). The mux+adder structure maps
naturally onto the DSP48E2 pre-adder/ALU. DSP usage is only 183/1,824 (10%),
so 30 butterflies x 4 DSPs = +120 DSPs is free headroom. The `prach_fft_ditfft3_bf2`
(147 LUTs, already uses 2 DSP) is the same pattern.

### 2. u_compress shifter (535 LUT/ch -> 1,605 total, est -300..-500 remaining)

The 4 parallel 16-bit variable barrel shifters + round (+1/saturate) dominate
`prach_bfp_compress`. The write-path pipeline (barrel shift registered in
lockstep with the control snapshot, rounding and write interface in separate
stages) landed as the timing fix and reduced the block from 575 to 535 LUTs/ch.
The remaining opportunity is time-sharing the shifter: processing runs 6
cycles per PRB while capture takes 12, so the shifter is half-idle - a
2-deep time-shared pipeline would roughly halve it.

### 3. u_gearbox rotation register (267 LUT/ch -> 801 total, est -240..-360)

`t6_data` + `t6_data_f` are two 64-bit registers each fed by a 12-way slice
mux (~4 LUTs/bit). A single 68-bit rotating packing register with 4-bit
granularity shifts and RAM insert covers both roles with ~half the mux logic.

### 4. HB2/HB3 SRL delay lines -> sparse event history (est -300..-800)

HB4/HB5 already got this treatment (previous baseline: -1,347 LUTs on one
stage pair). The HB2 stages still use clock-based delay lines
(34/51/102/177 SRLs) - the same proven pattern applies.

### 5. u_ctrl dual datapath (342/ch, est -150..-250)

Static-C and C-Plane each compute full start-symbol/sample/FCW expressions,
then mux on `static_c_en` (`prach_ctrl.sv` lines 393-446). The F0/F1 and
15/30 kHz selection logic is duplicated - sharing the arithmetic saves the
redundant mux trees.

### 6. Minor items

- `prach_fft_ditfft2_bf.sv` lines 175-178: `ovf` terms duplicated (x2r_s and
  x2i_s each checked twice) - a 1-LUT bug, ~2 LUTs/stage.
- `prach_stream2block`: the 12:1 x 32-bit read-data mux could move the
  antenna select into the RAM enables (est -100..-180).

## Notes

- `-flatten_hierarchy none` blocks cross-module optimization by design; that
  is the tradeoff for hierarchy attribution.
- Re-run the OOC script (`prach/synth/prach_ooc.tcl`) and compare against
  `prach/doc/prach_ooc_baseline.md` after each optimization lands.