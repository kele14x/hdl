# lowphy0 Vivado OOC resource baseline

- Date: 2026-08-05
- Tool: Vivado 2026.1, build 6511674
- Top: `lowphy0_wrapper`
- RTL list: `lowphy/lowphy.flt` (91 unique RTL sources)
- Parameters: `lowphy0` with `NUM_CC=3`, `NUM_ANT=4`, `HAS_BFP=1`, `HALF_BLOCK=0`
- RAM implementation: `RAM_USE_XPM` passed to `synth_design`
- Device: `xcku5p-ffvb676-2-i`
- Flow: `synth_design -mode out_of_context -flatten_hierarchy rebuilt`

The repository's generated IP metadata names `xczu19eg`, but Zynq UltraScale+
parts are not installed in this Vivado instance. This KU5P result is therefore
the working same-generation UltraScale+ comparison baseline, not a ZU19EG
capacity/utilization result.

## lowphy0_wrapper total

| Resource | Used | Available | Utilization |
| --- | ---: | ---: | ---: |
| CLB LUTs | 61,577 | 216,960 | 28.38% |
| CLB registers / FFs | 60,016 | 433,920 | 13.83% |
| Block RAM Tile | 409.5 | 480 | 85.31% |
| UltraRAM | 0 | 64 | 0.00% |
| DSP blocks | 369 | 1,824 | 20.23% |

BRAM primitive detail: 367 `RAMB36E2` and 85 `RAMB18E2`, equivalent to
`367 + 85/2 = 409.5` Block RAM Tiles.

## `pdxch_top` hierarchy

| Resource | Used |
| --- | ---: |
| CLB LUTs | 22,112 |
| CLB registers / FFs | 18,254 |
| RAMB36 | 132 |
| RAMB18 | 39 |
| Block RAM Tile equivalent | 151.5 |
| UltraRAM | 0 |
| DSP blocks | 93 |

Relative to the `lowphy0_wrapper` total, `pdxch_top` accounts for about 35.9%
of LUTs, 30.4% of FFs, 37.0% of BRAM Tiles, and 25.2% of DSPs.

## Notes

- A one-line Vivado-compatibility change was made in `prach/rtl/prach.sv`:
  the unused `ctrl_format` unpacked array is concatenated element-by-element.
  It does not affect datapath behavior, but is needed because Vivado rejects a
  direct concatenation of the unpacked array.
- OOC timing is not signoff timing: no user XDC clocks or I/O delays were
  supplied. The timing report contains unconstrained-clock warnings.
- Raw reports and checkpoint are under
  `sim_build/vivado_ooc_lowphy0_20260805/`.
