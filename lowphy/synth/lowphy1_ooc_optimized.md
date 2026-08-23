# lowphy1 Vivado OOC resource result (final configuration)

- Date: 2026-08-23
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
| CLB LUTs | 115,851 | 216,960 | 53.40% |
| CLB registers / FFs | 131,217 | 433,920 | 30.24% |
| Block RAM Tile | 409.5 | 480 | 85.31% |
| UltraRAM | 6 | 64 | 9.38% |
| DSP blocks | 861 | 1,824 | 47.20% |

Primitive detail: 319 `RAMB36E2` and 181 `RAMB18E2`, equivalent to
`319 + 181/2 = 409.5` Block RAM Tiles. The 6 UltraRAMs come from the
full-FFT band 0.

## Per-band hierarchy

| Instance | LUT | FF | RAMB36 | RAMB18 | URAM | DSP |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `u_b0` (3 CC / 4 ant, full FFT) | 51,752 | 59,144 | 187 | 85 | 6 | 369 |
| `u_b1` (2 CC / 2 ant, half FFT) | 31,990 | 35,980 | 66 | 48 | 0 | 246 |
| `u_b2` (2 CC / 2 ant, half FFT) | 31,992 | 35,983 | 66 | 48 | 0 | 246 |

## Delta vs. the earlier 2-CC run (band 0 half FFT)

| Resource | 2-CC, band0 half FFT | Final (band0 full FFT) | Δ |
| --- | ---: | ---: | ---: |
| LUT | 114,361 | 115,851 | +1.30% |
| FF | 129,027 | 131,217 | +1.70% |
| BRAM Tile | 406.5 | 409.5 | +0.74% |
| URAM | 0 | 6 | +6 |
| DSP | 861 | 861 | 0.00% |

Reports and checkpoint are under
`sim_build/vivado_ooc_lowphy1_20260806/` (the previous 3-CC run is preserved as
`lowphy1_utilization_old3cc.rpt`).