# PRACH top OOC resource and timing result

This document records the latest resource and timing result of the full
`prach` wrapper from out-of-context synthesis and implementation, together with
the per-instance breakdown, so that later area analysis does not have to re-run
synthesis first.

## Configuration

- Date: 2026-09-13
- Source: the C1 `prach_stream2block` bank merge plus the `prach_reshape` delay
  depth policy (see History); the baseline they were measured against was `41fdd7a`
- Tool: Vivado v2024.2 (Build 5239630)
- Device: `xcku5p-ffvb676-2-i` — **stand-in part**
- Top: `prach`
- Parameter: `ANT_ID=0`
- Synthesis mode: out of context
- Hierarchy: none (`-flatten_hierarchy none`)
- Define: `RAM_USE_XPM`

Script:

```text
prach/synth/prach_ooc.tcl
```

The stand-in part is not the product target: production builds target a ZU19EG,
and the project instantiates one `lowphy0` plus one `lowphy1`, each containing
several PRACH instances. Utilisation percentages below are therefore *per PRACH
block on the stand-in part*, not project-level figures. See `prach/README.md`
("Resource and integration context") before drawing area conclusions.

## Resource result

| Resource        | Synth | Impl  |
|-----------------|------:|------:|
| CLB LUTs        | 18907 | 16983 |
| — LUT as Logic  |   n/a | 12798 |
| — LUT as Memory |   n/a |  4185 |
| CLB Registers   | 27756 | 26912 |
| Block RAM tiles |    63 |    63 |
| UltraRAM        |     0 |     0 |
| DSP Blocks      |   183 |   183 |

The synthesis report gives only the `CLB LUTs*` estimate, with no logic/memory
split. **25 % of the implemented LUT budget is LUT-based storage** (SRL +
distributed RAM), which matters when weighing "move it to FFs" against "move it
to BRAM": an SRL holds 32 bits per LUT, a flip-flop holds 1 bit, and a BRAM tile
holds 36 Kb.

## Per-instance breakdown (implementation)

Reading notes:

- `report_utilization -hierarchical` repeats a block's totals at every level of
  the tree, so only one level may be summed. The tables below use the direct
  children of each block.
- `NUM_CC = 3`, so `prach_channel` and everything inside it exist three times.
  The copies are near-identical; individual LUT counts differ by 1–2 between them
  and between runs (place/opt nondeterminism), so the tables list one copy and
  totals are x3.
- `u_framer` contains `u_buffer`, which contains `u_compress`, `u_gearbox` and
  `u_fifo`; those rows are indented and must not be added to their parents.

### Top level and per-CC blocks

| Instance | Module | LUT | Logic | LUTRAM | SRL | FF |
|---|---|---:|---:|---:|---:|---:|
| `prach` | (top) | 16983 | 12798 | 1674 | 2511 | 26912 |
| `g_cc[n].u_channel` (x3) | `prach_channel` | 5468 | 4073 | 558 | 837 | 8675 |
| `u_fft` | `prach_fft` | 2425 | 1965 | 252 | 208 | 3447 |
| `u_ddc` | `prach_ddc` | 1308 | 480 | 242 | 586 | 2501 |
| `u_framer` | `prach_framer` | 1030 | 966 | 64 | 0 | 1571 |
| &nbsp;&nbsp;`u_buffer` | `prach_framer_buffer` | 936 | 872 | 64 | 0 | 1280 |
| &nbsp;&nbsp;&nbsp;&nbsp;`u_compress` | `prach_bfp_compress` | 536 | 536 | 0 | 0 | 936 |
| &nbsp;&nbsp;&nbsp;&nbsp;`u_gearbox` | `prach_bfp_gearbox` | 268 | 268 | 0 | 0 | 278 |
| &nbsp;&nbsp;&nbsp;&nbsp;`u_fifo` | `axis_fifo_alt` | 93 | 93 | 0 | 0 | 293 |
| `u_ctrl` | `prach_ctrl` | 348 | 348 | 0 | 0 | 722 |
| `u_stream2block` | `prach_stream2block` | 197 | 169 | 0 | 28 | 199 |
| `u_resync` | `prach_resync` | 91 | 91 | 0 | 0 | 127 |
| `u_pulse_delay_in` | `pulse_delay` | 71 | 56 | 0 | 15 | 53 |
| `u_symbol_timer` | `symbol_timer` | 40 | 40 | 0 | 0 | 54 |

So per CC: FFT 44 %, DDC 24 %, framer (incl. buffer/compress/gearbox/fifo) 19 %,
control 7 %, stream2block 4 %.

### DDC stages (one `u_ddc`; DDC total 1308 LUT / 242 LUTRAM / 586 SRL / 2501 FF)

| Stage | Filter | LUT | Logic | LUTRAM | SRL | FF |
|---|---|---:|---:|---:|---:|---:|
| `g_stage[0].g_hb0` | `prach_hb2` (`DELAY_BASE` 8) | 68 | 25 | 0 | 43 | 115 |
| `g_stage[0].u_reshape` | `prach_reshape` (SIZE 8) | 16 | 16 | 0 | 0 | 215 |
| `g_stage[1].g_hb1` | `prach_hb2` (16) | 76 | 25 | 0 | 51 | 125 |
| `g_stage[1].u_reshape` | `prach_reshape` (16) | 17 | 16 | 0 | 1 | 171 |
| `g_stage[2].g_hb2` | `prach_hb2` (32) | 127 | 25 | 0 | 102 | 125 |
| `g_stage[2].u_reshape` | `prach_reshape` (32) | 33 | 16 | 0 | 17 | 59 |
| `g_stage[3].g_hb3` | `prach_hb2` (64) | 202 | 25 | 0 | 177 | 125 |
| `g_stage[3].u_reshape` | `prach_reshape` (64) | 43 | 16 | 0 | 27 | 59 |
| `g_stage[4].g_hb4` | `prach_hb4` (128) | 168 | 46 | 97 | 25 | 344 |
| `g_stage[4].u_reshape` | `prach_reshape` (128) | 59 | 21 | 16 | 22 | 68 |
| `g_stage[5].g_hb5` | `prach_hb4` (256) | 168 | 44 | 97 | 27 | 335 |
| `g_stage[5].u_reshape` | `prach_reshape` (256) | 100 | 24 | 32 | 44 | 69 |
| `u_mixer` | `mixer` | 147 | 124 | 0 | 23 | 372 |
| `u_conv` | `prach_conv` | 55 | 37 | 0 | 18 | 159 |

The reshape delays pick their implementation by depth, the way the FFT butterfly
does (`prach_fft_ditfft2_bf.sv`): flip-flops for the two 16-bit data delays up to
depth 8, SRLs to depth 32, single-port LUTRAM beyond that. The 13-bit sideband
delay is control information, so it only chooses between flip-flops (depth <= 8)
and SRLs and never uses LUTRAM or block RAM. There is no block-RAM branch at all:
the widest delay here is 16 x 129 bits. The hb4/hb5 `lane_history` arrays are the
97-LUTRAM rows — a 199-bit x 8-deep word costs 97 LUTs, i.e. Vivado packs 2 bits
per LUT at this depth.

### FFT stages (one `u_fft`; FFT total 2425 LUT / 252 LUTRAM / 208 SRL / 3447 FF)

| Stage | `FFT_SIZE` | LUT | Logic | LUTRAM | SRL | FF |
|---|---:|---:|---:|---:|---:|---:|
| `g_left_dit2[0].g_first.u_ditfft3` | radix-3 | 331 | 331 | 0 | 0 | 305 |
| `g_left_dit2[1].g_left.u_ditfft2` | 6 | 137 | 133 | 0 | 4 | 313 |
| `g_left_dit2[2].g_left.u_ditfft2` | 12 | 151 | 142 | 0 | 9 | 429 |
| `g_left_dit2[3].g_left.u_ditfft2` | 24 | 192 | 149 | 0 | 43 | 266 |
| `g_left_dit2[4].g_left.u_ditfft2` | 48 | 202 | 164 | 18 | 20 | 287 |
| `g_left_dit2[5].g_left.u_ditfft2` | 96 | 245 | 189 | 36 | 20 | 291 |
| `g_left_dit2[6].g_left.u_ditfft2` | 192 | 307 | 233 | 72 | 2 | 363 |
| `g_left_dit2[7].g_left.u_ditfft2` | 384 | 360 | 234 | 126 | 0 | 409 |
| `g_left_dit2[8].g_left.u_ditfft2` | 768 | 165 | 165 | 0 | 0 | 341 |
| `g_left_dit2[9].g_left.u_ditfft2` | 1536 | 174 | 174 | 0 | 0 | 345 |
| `u_delay_chn` | 2b x 1622 | 102 | 0 | 0 | 102 | 2 |
| `u_delay_sy` | `pulse_delay` | 43 | 35 | 0 | 8 | 29 |

Note the stage rows sum to the reported FFT total only if just `u_delay_sy` is
counted: the other three `pulse_delay` instances in `prach_fft.sv`
(`u_delay_sf`, `u_delay_sl`, `u_delay_last`) appear **zero** times in both the
synthesis and implementation reports, i.e. Vivado prunes them as unused. Their
44 LUTs each are therefore not recoverable by "optimising" them; do not budget a
saving for them.

Stage 7 (`FFT_SIZE` 384) is the outlier: its 192-deep butterfly delay lands in
distributed RAM (126 LUTRAM) because `shift_ram` defaults to `RAM_STYLE = "AUTO"`.
Stages 8–9, whose delays are deeper, already map to block RAM. `fft/rtl/fft_bf2.sv`
carries an explicit `RAM_STYLE` ramp for this (BLOCK at depth >= 1024, ULTRA at
>= 8192), but the PRACH butterfly does not, and a 1536-point FFT never reaches
1024 anyway — so stage 7 behaves the same in both.

### LUT-based storage, by owner

| Owner | LUTRAM | SRL | Total | Note |
|---|---:|---:|---:|---|
| `prach` (all) | 1674 | 2511 | **4185** | 25 % of the 16983 LUTs |
| `g_cc[n].u_channel` (x3) | 558 | 837 | 1395 | per CC |
| `u_ddc` (x3) | 242 | 586 | 828 | largest single owner |
| `u_fft` (x3) | 252 | 208 | 460 | butterfly delays + `u_delay_chn` |
| `u_framer` / `u_buffer` (x3) | 64 | 0 | 64 | 4 x exponent RAM (128x4 distributed) |
| `u_stream2block` (x3) | 0 | 28 | 28 | two shallow delays |

Largest individual holders, per instance: `g_hb3` 177 SRL, `u_delay_chn` 102 SRL,
`g_hb2` 102 SRL, the FFT stage-7 butterfly delay 126 LUTRAM, the FFT stage-6
butterfly delay 72 LUTRAM, and the hb4/hb5 `lane_history` 97 LUTRAM each. The
reshape delays have dropped out of this list — they are now flip-flops or
LUTRAM sized to their depth.

## Timing result

Implementation:

| Clock          | Period    | Frequency | Setup WNS | Hold WHS  |
|----------------|----------:|----------:|----------:|----------:|
| `clk`          |  2.035 ns | 491.4 MHz | +0.137 ns | +0.012 ns |
| `clk_eth_xran` |  2.500 ns | 400.0 MHz | +0.320 ns | +0.042 ns |
| `s_axi_aclk`   | 10.000 ns | 100.0 MHz | +6.391 ns | +0.042 ns |

Synthesis, for comparison: `clk` WNS −0.070 ns. Timing only closes after
implementation, and `clk` closes by well under 0.2 ns, so any datapath change
must re-run implementation.

## Reproducing

```bash
# From the repository root:
make ooc OOC_MODULES=prach       # synthesis only -> prach/synth/prach_ooc.tcl
make ooc-impl OOC_MODULES=prach  # opt/place/route -> prach/synth/prach_impl.tcl

# Or directly (run the impl script after the synthesis script):
vivado -mode batch -source prach/synth/prach_ooc.tcl          # defaults to ANT_ID=0
vivado -mode batch -source prach/synth/prach_impl.tcl         # defaults to ANT_ID=0
# or: -tclargs 1
```

Reports land in `prach/vivado_ooc/prach_20260901_ant<ID>/` (git-ignored):

- `prach_utilization.rpt`, `prach_utilization_hierarchical.rpt` (post-synthesis)
- `prach_impl_utilization.rpt`, `prach_impl_utilization_hierarchical.rpt` (post-implementation)
- `prach_timing_summary.rpt`, `prach_impl_timing_summary.rpt`

Use `*_impl_utilization_hierarchical.rpt` for area analysis: its `Total LUTs`
column is `Logic LUTs + LUTRAMs + SRLs`, so it shows directly where the LUT budget
goes.

## History

- 2026-09-13, `prach_reshape` delay depth policy: the two 16-bit data delays now
  select flip-flops (depth <= 8), SRLs (<= 32) or single-port LUTRAM instead of
  always using SRLs; the 13-bit sideband delay chooses flip-flops (depth <= 8) or
  SRLs only. Measured post-implementation: **−214 CLB LUTs** (17197 → 16983;
  LUT-as-memory −249, logic +35 from the LUTRAM pointer logic), 0 BRAM/DSP,
  **+1090 FF** (25822 → 26912), and `clk` WNS improved 0.077 → 0.137 ns. Per
  channel the six `u_reshape` instances went 338 → 268 LUTs (−70, x3 ≈ the
  measured global −214).
- 2026-09-13, C1 `prach_stream2block` bank merge: **−400 CLB LUTs**
  (17597 → 17197), LUTRAM/SRL/BRAM/DSP unchanged, +67 FF, `clk` WNS
  0.117 → 0.077 ns.
- 2026-09-13, baseline at `41fdd7a`: 19594 synth / 17597 impl CLB LUTs, 26691 /
  25755 FF, 63 BRAM, 183 DSP, `clk` WNS +0.117 ns.
- 2026-09-10, commit `639ab21`: 19600 synth / 17607 impl CLB LUTs, 26691 / 25791
  FF. Within tool-run variation of the entry above.
