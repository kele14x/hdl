# PDXCH mandatory-BFP Vivado OOC resource result

- Date: 2026-08-06
- Tool: Vivado 2026.1, build 6511674
- Top: `pdxch_top`
- Device: `xcku5p-ffvb676-2-i`
- Parameters: `NUM_CC=3`, `NUM_ANT=4`, `HALF_BLOCK=0`
- RAM implementation: `RAM_USE_XPM`
- Design state: Synthesized; 0 errors

## Standalone `pdxch_top`

| Resource | Used | Available | Utilization |
| --- | ---: | ---: | ---: |
| CLB LUTs | 16,835 | 216,960 | 7.76% |
| CLB registers / FFs | 14,643 | 433,920 | 3.37% |
| Block RAM Tile | 115.5 | 480 | 24.06% |
| UltraRAM | 0 | 64 | 0.00% |
| DSP blocks | 93 | 1,824 | 5.10% |

For an apples-to-apples comparison with the original lowphy0 OOC run, use
the `pdxch_top` hierarchy inside the lowphy reports: LUT 22,112 → 16,594,
FF 18,254 → 14,989, and BRAM 151.5 → 115.5 tiles.

| Resource | Baseline | Final | Reduction |
| --- | ---: | ---: | ---: |
| LUT | 22,112 | 16,594 | 24.95% |
| FF | 18,254 | 14,989 | 17.89% |
| BRAM Tile | 151.5 | 115.5 | 23.76% |
| URAM | 0 | 0 | N/A |
| DSP | 93 | 93 | 0.00% |

The PDXCH input path now always instantiates `bfp_gearbox`; `HAS_BFP` has
been removed from `pdxch` and `pdxch_top`. The shared `lowphy_band.HAS_BFP`
parameter remains for the independent PRACH/PUXCH blocks.

Reports and checkpoint are under
`sim_build/vivado_ooc_pdxch_top_20260806/`.
