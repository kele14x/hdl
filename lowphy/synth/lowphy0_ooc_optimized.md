# lowphy0 Vivado OOC resource result after PDXCH FDV optimization

- Date: 2026-08-06
- Tool: Vivado 2026.1, build 6511674
- Top: `lowphy0_wrapper`
- Device: `xcku5p-ffvb676-2-i`
- RAM implementation: `RAM_USE_XPM`
- Flow: `synth_design -mode out_of_context -flatten_hierarchy rebuilt`
- Design state: Synthesized; 0 errors

## lowphy0_wrapper total

| Resource | Used | Available | Utilization |
| --- | ---: | ---: | ---: |
| CLB LUTs | 55,944 | 216,960 | 25.79% |
| CLB registers / FFs | 56,737 | 433,920 | 13.08% |
| Block RAM Tile | 373.5 | 480 | 77.81% |
| UltraRAM | 0 | 64 | 0.00% |
| DSP blocks | 369 | 1,824 | 20.23% |

Primitive detail: 331 `RAMB36E2` and 85 `RAMB18E2`, equivalent to
`331 + 85/2 = 373.5` Block RAM Tiles.

## `pdxch_top` hierarchy

| Resource | Used |
| --- | ---: |
| CLB LUTs | 16,594 |
| CLB registers / FFs | 14,989 |
| RAMB36 | 96 |
| RAMB18 | 39 |
| Block RAM Tile equivalent | 115.5 |
| UltraRAM | 0 |
| DSP blocks | 93 |

## Reduction versus the original lowphy0 OOC baseline

| Resource | Baseline | Final | Reduction |
| --- | ---: | ---: | ---: |
| LUT | 61,577 | 55,944 | 9.15% |
| FF | 60,016 | 56,737 | 5.46% |
| BRAM Tile | 409.5 | 373.5 | 8.79% |
| URAM | 0 | 0 | N/A |
| DSP | 369 | 369 | 0.00% |

Each full-block `fdv_buffer` instance uses 16 `RAMB36` and 4 `RAMB18`
primitives for the four antenna memories. The readout keeps the existing
FFT bit-reverse and logical-RE mapping, then applies:

```text
IQ address  = bank * IQ_BANK_DEPTH  + logical_re / 2
EXP address = bank * EXP_BANK_DEPTH + logical_re / 4
```

where `IQ_BANK_DEPTH/EXP_BANK_DEPTH` are `(1792, 825)` for full block and
`(1024, 480)` for half block. Exponents are therefore replicated three times
per PRB, with one exponent shared by four REs.

Reports and checkpoint are under
`sim_build/vivado_ooc_lowphy0_20260805/`.
