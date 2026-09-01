# lowphy0 Vivado OOC resource result after PDXCH FDV optimization

- Date: 2026-08-24 (re-verified at `a2ef997` baseline, OOC 20260824)
- Tool: Vivado (single consistent release for this comparison)
- Top: `lowphy0_wrapper`
- Device: `xcku5p-ffvb676-2-i`
- RAM implementation: `RAM_USE_XPM`
- Flow: `synth_design -mode out_of_context -flatten_hierarchy rebuilt`
- Design state: Synthesized; 0 errors

## lowphy0_wrapper total

| Resource | Used | Available | Utilization |
| --- | ---: | ---: | ---: |
| CLB LUTs | 51,988 | 216,960 | 23.96% |
| CLB registers / FFs | 59,178 | 433,920 | 13.64% |
| Block RAM Tile | 295.5 | 480 | 61.56% |
| UltraRAM | 6 | 64 | 9.38% |
| DSP blocks | 369 | 1,824 | 20.23% |

Primitive detail: 247 `RAMB36E2` and 97 `RAMB18E2`, equivalent to
`247 + 97/2 = 295.5` Block RAM Tiles.

> Supersedes the 2026-08-06 numbers (55,944 LUT / 373.5 BRAM); later
> mult/fft/ram tuning cut another ~4k LUT and ~78 BRAM tiles.

## `pdxch_top` hierarchy

| Resource | Used |
| --- | ---: |
| CLB LUTs | 16,196 |
| CLB registers / FFs | 15,884 |
| RAMB36 | 72 |
| RAMB18 | 39 |
| Block RAM Tile equivalent | 91.5 |
| UltraRAM | 3 |
| DSP blocks | 93 |

## Reduction versus the original lowphy0 OOC baseline

Baseline is the 2026-08-05 pre-PDXCH-FDV-optimization run; the original
August-06 "optimized" numbers are superseded by this run.

| Resource | Baseline | Final | Reduction |
| --- | ---: | ---: | ---: |
| LUT | 61,577 | 51,988 | 15.57% |
| FF | 60,016 | 59,178 | 1.40% |
| BRAM Tile | 409.5 | 295.5 | 27.84% |
| URAM | 0 | 6 | N/A (0 → 6) |
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
`sim_build/vivado_ooc_lowphy0_20260824/`.
