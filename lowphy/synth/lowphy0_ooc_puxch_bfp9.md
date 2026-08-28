# lowphy0 Vivado OOC result after PUXCH BFP9 buffer optimization

- Date: 2026-08-27
- Repository HEAD: `78ea372` plus the uncommitted PUXCH buffer changes
- Tool: Vivado 2026.1, build 6511674
- Top: `lowphy0_wrapper`
- Configuration: `NUM_CC=3`, `NUM_ANT=4`, `HALF_BLOCK=0`
- Device: `xcku5p-ffvb676-2-i`
- RAM implementation: `RAM_USE_XPM`
- Flow: `synth_design -mode out_of_context -flatten_hierarchy rebuilt`
- RTL list: `lowphy/lowphy.flt` (96 unique RTL sources)
- Design state: synthesized; 0 errors and 0 critical warnings

## PUXCH buffer BRAM mapping

Vivado maps every antenna/carrier buffer to the intended exact-capacity
layout:

| Memory per antenna per CC | Logical organization | Primitive mapping |
| --- | --- | ---: |
| IQ full segments | 3 x (2048 x 18 write / 1024 x 36 read) | 3 `RAMB36E2` |
| IQ tail segment | 1024 x 18 write / 512 x 36 read | 1 `RAMB18E2` |
| Per-RE exponent | 7168 x 4 write / 3584 x 8 read | 1 `RAMB36E2` |
| **Total** | | **4 `RAMB36E2` + 1 `RAMB18E2` = 4.5 tiles** |

Across 3 CC x 4 antennas, the PUXCH buffers consume 48 `RAMB36E2` and
12 `RAMB18E2`, equivalent to 54 BRAM tiles. The primitive names in
`lowphy0_bram_primitives.txt` show all 36 full IQ segments, 12 IQ tails, and
12 exponent memories separately.

| PUXCH buffer storage | Previous raw-IQ design | BFP9 design | Reduction |
| --- | ---: | ---: | ---: |
| Per antenna per CC | 8 tiles | 4.5 tiles | 3.5 tiles (43.75%) |
| 3 CC x 4 antennas | 96 tiles | 54 tiles | 42 tiles (43.75%) |

The new buffer therefore uses 56.25% of the original BRAM storage.

## `puxch_top` hierarchy

This hierarchy includes the PUXCH channels/FFTs as well as the buffers.

| Resource | Used |
| --- | ---: |
| CLB LUTs | 18,681 |
| CLB registers / FFs | 18,092 |
| RAMB36 | 72 |
| RAMB18 | 27 |
| Block RAM Tile equivalent | 85.5 |
| UltraRAM | 3 |
| DSP blocks | 93 |

The four `puxch_buffer` antenna hierarchies each contain three CC memories and
use 12 `RAMB36E2` plus 3 `RAMB18E2`, or 13.5 BRAM tiles per antenna.

## `lowphy0_wrapper` total

| Resource | Used | Available | Utilization |
| --- | ---: | ---: | ---: |
| CLB LUTs | 54,460 | 216,960 | 25.10% |
| CLB registers / FFs | 58,816 | 433,920 | 13.55% |
| Block RAM Tile | 241.5 | 480 | 50.31% |
| UltraRAM | 6 | 64 | 9.38% |
| DSP blocks | 369 | 1,824 | 20.23% |

Primitive detail: 195 `RAMB36E2` and 93 `RAMB18E2`, equivalent to
`195 + 93/2 = 241.5` Block RAM Tiles.

## Comparison with the saved 2026-08-24 OOC result

The saved `lowphy0_ooc_optimized.md` result was produced at commit `a2ef997`.
The current run is at `78ea372` plus uncommitted changes, so this top-level
comparison includes other intervening RTL changes and is not an isolated
measurement of the PUXCH buffer optimization. The 42-tile buffer reduction
above is the direct primitive-level comparison for this change.

| Resource | 2026-08-24 | Current | Change |
| --- | ---: | ---: | ---: |
| CLB LUTs | 51,988 | 54,460 | +2,472 (+4.75%) |
| CLB registers / FFs | 59,178 | 58,816 | -362 (-0.61%) |
| Block RAM Tile | 295.5 | 241.5 | -54 (-18.27%) |
| UltraRAM | 6 | 6 | 0 |
| DSP blocks | 369 | 369 | 0 |

## Verification and artifacts

- Final OOC synthesis: passed with 0 errors and 0 critical warnings.
- Focused half-block compatibility regression after the final RTL cleanup:
  `1 passed` with Questa.
- Timing is not signoff timing. No user XDC timing constraints were supplied,
  and the OOC timing report identifies the design as unconstrained.
- Reproduction script: `lowphy/synth/lowphy0_puxch_bfp9_ooc.tcl`.
- Reports, primitive audit, and checkpoint:
  `sim_build/vivado_ooc_lowphy0_puxch_bfp9_20260827/`.
