# PUXCH two-pass BFP9 buffer Vivado OOC resource result

- Date: 2026-08-24
- Tool: Vivado 2026.1, build 6511674
- Top: `puxch_top`
- Device: `xcku5p-ffvb676-2-i`
- Parameters: `NUM_CC=3`, `NUM_ANT=4`
- RAM implementation: `RAM_USE_XPM`
- Design state: Synthesized; 0 errors in all runs
- Baseline: `puxch/synth/puxch_top_ooc.tcl` with `-tclargs 0 0` / `1 1` on the
  pre-redesign checkout (git worktree of `a2ef997`, `HAS_BFP=1`)

## Full block (HALF_BLOCK=0, HALF_FFT=0)

| Resource | Baseline (a2ef997) | Final (HEAD) | Δ | Δ% |
| --- | ---: | ---: | ---: | ---: |
| CLB LUTs | 16,305 | 36,156 | +19,851 | +121.8% |
| CLB registers / FFs | 17,906 | 24,479 | +6,573 | +36.7% |
| Block RAM Tile | 139.5 | 97.5 | −42.0 | −30.1% |
| UltraRAM | 3 | 3 | 0 | 0.0% |
| DSP blocks | 93 | 93 | 0 | 0.0% |

## Half block (HALF_BLOCK=1, HALF_FFT=1; the lowphy1 production config)

| Resource | Baseline (a2ef997) | Final (HEAD) | Δ | Δ% |
| --- | ---: | ---: | ---: | ---: |
| CLB LUTs | 15,411 | 28,797 | +13,386 | +86.9% |
| CLB registers / FFs | 17,003 | 20,068 | +3,065 | +18.0% |
| Block RAM Tile | 96 | 72 | −24 | −25.0% |
| UltraRAM | 0 | 0 | 0 | 0.0% |
| DSP blocks | 93 | 93 | 0 | 0.0% |

## Verdict

BRAM savings are real (−24 to −42 tiles, 25–30%), but LUTs roughly doubled
(＋86–122%). The redesign moves compression to the write side, so it deletes
the separate `bfp_comp` datapath but adds a per-RE normalize/store/read-back
datapath; on top of that the metadata RAMs are the dominant new cost.

## Root cause per antenna (full block, `g_ant[*].u_bfp_buffer`)

| Block | LUT | FF | RAMB36 | RAMB18 |
| --- | ---: | ---: | ---: | ---: |
| Old `puxch_buffer` + `bfp_comp` (sum) | 951 | 1,363 | 25 | 4 |
| New `puxch_bfp_buffer` | 5,927 | 3,083 | 16 | 1 |
| of which 6× `u_meta_ram` (6×3584 LUTRAM) | 3,672 | 2,088 | 0 | 0 |

The six 6-bit×3584-deep metadata RAMs per antenna are implemented as
*distributed* (XPM LUTRAM, `RAM_STYLE("DISTRIBUTED")` in
`puxch_bfp_buffer.sv`), burning 448 LUTRAM + 348 FF each. Across 4 antennas
that is ~10,752 LUTRAM — essentially all of the LUT-as-memory increase
(92 → 10,844) and the LUT flip to ~2×.

The remaining ~9.1k logic LUT increase is the two-pass datapath itself
(write-side msb/shift per RE, read-side max-exponent compare + 24×
variable-shift round/saturate + pack/gearbox) versus the old streaming
`bfp_comp` (607 LUT/antenna).

## Suggested follow-up (not implemented)

- Switch `u_meta_ram` to `RAM_STYLE("BLOCK")` (or widen the IQ RAM word and
  fold the metadata into the same block RAM). Cost: ~6 RAMB per antenna for
  the metadata (24 tiles total, still well inside the 42-tile saving at full
  block), recovering ~10.7k LUTRAM and ~2k FF.
- If BRAM is scarcer than LUT in the final lowphy build, the distributed
  choice is defensible — but the ~2:1 LUT ratio makes BLOCK the better
  default on `xcku5p`.

Reports and checkpoints under
`sim_build/vivado_ooc_puxch_top_20260824/` (HEAD) and
`sim_build/puxch_ooc_old/sim_build/vivado_ooc_puxch_top_20260824/` (baseline).