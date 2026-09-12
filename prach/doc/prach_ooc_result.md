# PRACH top OOC resource and timing result

This document records the latest resource and timing result of the full
`prach` wrapper from out-of-context synthesis and implementation.

## Configuration

- Date: 2026-09-10
- Source commit: `639ab21`
- Tool: Vivado v2024.2 (Build 5239630)
- Device: `xcku5p-ffvb676-2-i`
- Top: `prach`
- Parameter: `ANT_ID=0`
- Synthesis mode: out of context
- Hierarchy: none (`-flatten_hierarchy none`)
- Define: `RAM_USE_XPM`

Script:

```text
prach/synth/prach_ooc.tcl
```

## Resource result

| Resource        | Synth | Impl  |
|-----------------|------:|------:|
| CLB LUTs        | 19600 | 17607 |
| CLB Registers   | 26691 | 25791 |
| Block RAM tiles |    63 |    63 |
| UltraRAM        |     0 |     0 |
| DSP Blocks      |   183 |   183 |

## Timing result

| Clock          | Period    | Frequency | Setup WNS | Hold WHS  |
|----------------|----------:|----------:|----------:|----------:|
| `clk`          |  2.035 ns | 491.4 MHz | +0.179 ns | +0.005 ns |
| `clk_eth_xran` |  2.500 ns | 400.0 MHz | +0.096 ns | +0.046 ns |
| `s_axi_aclk`   | 10.000 ns | 100.0 MHz | +6.917 ns | +0.046 ns |

Design-wide summary: WNS +0.096 ns, TNS 0.000 ns, WHS +0.005 ns, THS
0.000 ns, and worst pulse-width slack +0.466 ns. The 491.52 MHz clock
constraint is rounded by Vivado to 2.035 ns (491.4 MHz).
