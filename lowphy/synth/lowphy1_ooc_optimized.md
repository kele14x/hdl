# lowphy1 Vivado OOC result after mandatory PUXCH BFP9 optimization

- Date: 2026-08-28
- Repository HEAD: `d975c3b` plus the uncommitted half-block/direct-merger changes
- Comparison baseline: `master` HEAD `78ea372` and its saved 2026-08-24 OOC report
- Tool: Vivado 2026.1, build 6511674
- Top: `lowphy1_wrapper`
- Device: `xcku5p-ffvb676-2-i`
- RAM implementation: `RAM_USE_XPM`
- Flow: `synth_design -mode out_of_context -flatten_hierarchy rebuilt`
- Design state: Synthesized; 0 errors

## Configuration (`lowphy1.sv`) — final

| Band | Instance | NUM_CC | NUM_ANT | HALF_BLOCK | HALF_FFT | FFT |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Band 0 (s0) | `u_b0` | 3 | 4 | 1 | **0** | full (4096-pt) |
| Band 1 (s1) | `u_b1` | 2 | 2 | 1 | 1 | half (2048-pt) |
| Band 2 (s2) | `u_b2` | 2 | 2 | 1 | 1 | half (2048-pt) |

`localparam NumCcBand12 = 2` drives the band-1/2 `NUM_CC`,
`m1/s1/m2/s2_axis_*` array widths, and the top-level generate guards.

## lowphy1_wrapper total

| Resource | Used | Available | Utilization |
| --- | ---: | ---: | ---: |
| CLB LUTs | 115,877 | 216,960 | 53.41% |
| CLB registers / FFs | 124,213 | 433,920 | 28.63% |
| Block RAM Tile | 343.5 | 480 | 71.56% |
| UltraRAM | 6 | 64 | 9.38% |
| DSP blocks | 861 | 1,824 | 47.20% |

Primitive detail: 247 `RAMB36E2` and 193 `RAMB18E2`, equivalent to
`247 + 193/2 = 343.5` Block RAM Tiles. The 6 UltraRAMs come from the
full-FFT band 0.

## Half-block PUXCH buffer mapping

All three bands compile PUXCH with `HALF_BLOCK=1`. Each antenna/CC buffer
supports 160 PRBs (1920 REs) in each ping/pong bank and maps as follows:

| Memory per antenna per CC | Logical organization | Primitive mapping |
| --- | --- | ---: |
| IQ bank 0 | 1920 x 18 write / 960 x 36 read | 1 `RAMB36E2` |
| IQ bank 1 | 1920 x 18 write / 960 x 36 read | 1 `RAMB36E2` |
| Per-RE exponent | 3840 x 4 write / 1920 x 8 read | 1 `RAMB18E2` |
| **Total** | | **2 `RAMB36E2` + 1 `RAMB18E2` = 2.5 tiles** |

Lowphy1 contains 20 antenna/CC buffers: 12 in band 0 and four each in bands
1 and 2. They therefore consume 40 `RAMB36E2` plus 20 `RAMB18E2`, or 50
tiles. Although the raw 32-bit buffer's theoretical target was four tiles per
antenna/CC, the `master` OOC hierarchy actually mapped the eight per-antenna
`u_buffer` instances to 116 tiles. The new implementation therefore saves 66
tiles (56.9%) against the measured `master` result.

## Per-band hierarchy

| Instance | LUT | FF | RAMB36 | RAMB18 | URAM | DSP |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `u_b0` (3 CC / 4 ant, full FFT) | 51,810 | 55,650 | 147 | 93 | 6 | 369 |
| `u_b1` (2 CC / 2 ant, half FFT) | 31,974 | 34,225 | 50 | 50 | 0 | 246 |
| `u_b2` (2 CC / 2 ant, half FFT) | 31,976 | 34,228 | 50 | 50 | 0 | 246 |

## Delta vs. the saved 2026-08-24 result

The whole-design delta is exactly equal to the sum of the three `u_puxch`
hierarchies, so the resource change is localized to PUXCH.

| Resource | 2026-08-24 | Current | Change |
| --- | ---: | ---: | ---: |
| LUT | 115,859 | 115,877 | +18 |
| FF | 131,217 | 124,213 | -7,004 |
| BRAM Tile | 409.5 | 343.5 | -66.0 |
| URAM | 6 | 6 | 0 |
| DSP | 861 | 861 | 0 |

## PUXCH hierarchy delta vs. `master` HEAD

| Hierarchy | Master BRAM | Current BRAM | BRAM change | LUT change | FF change |
| --- | ---: | ---: | ---: | ---: | ---: |
| `u_b0/u_puxch` | 97.5 | 61.5 | -36.0 | +50 | -3,494 |
| `u_b1/u_puxch` | 37.0 | 22.0 | -15.0 | -16 | -1,755 |
| `u_b2/u_puxch` | 37.0 | 22.0 | -15.0 | -16 | -1,755 |
| **Total** | **171.5** | **105.5** | **-66.0** | **+18** | **-7,004** |

Reports and checkpoint are under
`sim_build/vivado_ooc_lowphy1_20260806/`. Vivado completed with 0 errors and
0 critical warnings; the OOC timing report remains unconstrained and is not
a signoff timing result.
