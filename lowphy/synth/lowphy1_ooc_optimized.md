# lowphy1 Vivado OOC resource result after PDXCH FDV optimization

- Date: 2026-08-06
- Tool: Vivado 2026.1, build 6511674
- Top: `lowphy1_wrapper`
- Device: `xcku5p-ffvb676-2-i`
- Parameters: RTL `HALF_BLOCK=1`
- RAM implementation: `RAM_USE_XPM`
- Design state: Synthesized

| Resource | Used | Available | Utilization |
| --- | ---: | ---: | ---: |
| CLB LUTs | 260,425 | 216,960 | 120.03% |
| CLB registers / FFs | 172,126 | 433,920 | 39.67% |
| Block RAM Tile | 528 | 480 | 110.00% |
| UltraRAM | 0 | 64 | 0.00% |
| DSP blocks | 1,107 | 1,824 | 60.69% |

The half-block FDV instance uses 8 `RAMB36E2` and 4 `RAMB18E2` primitives
for its four antennas. The overall lowphy1 wrapper exceeds KU5P capacity in
LUT and BRAM; this run is a parameter/elaboration check, not a fit result.

Reports and checkpoint are under
`sim_build/vivado_ooc_lowphy1_20260806/`.
