# PDXCH Vivado OOC synthesis and implementation result

- Date: 2026-09-08
- Source commit: `786f998`
- Tool: Vivado v2024.2
- Top: `pdxch` (instantiates `pdxch_top`)
- Device: `xcku5p-ffvb676-2-i`
- Parameters: `NUM_CC=3`, `NUM_ANT=4`, `HALF_BLOCK=0`, `HALF_FFT=0`
- Synthesis mode: out of context
- Hierarchy: none (`-flatten_hierarchy none`)
- Define: `RAM_USE_XPM`

The OOC flow is defined in `pdxch/synth/pdxch_top_ooc.tcl`.

## Resource result

| Resource       |   Synth |    Impl |
| -------------- | ------: | ------: |
| CLB LUTs       |  16,317 |  13,452 |
| CLB Registers  |  15,985 |  16,121 |
| Block RAM Tile |    91.5 |    91.5 |
| UltraRAM       |       3 |       3 |
| DSP blocks     |      99 |      99 |
