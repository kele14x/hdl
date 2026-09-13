# PRACH

`prach` is the multi-antenna PRACH receive block: it resynchronises the radio
stream, decimates it in the DDC, runs the 1536-point FFT, and packs the result
for the U-plane.

Layout:

- `rtl/` — SystemVerilog sources (`prach.sv`, `prach_channel.sv`, `prach_ddc.sv`, ...)
- `tests/` — cocotb regression tests and cycle-accurate Python models
- `tb/` — traditional SystemVerilog testbench helpers
- `doc/` — design notes and OOC synthesis results
- `synth/` — Vivado OOC scripts (`prach_ooc.tcl` synthesis, `prach_impl.tcl` implementation)
- `prach.flt` — RTL filelist (no testbench files)

## Resource and integration context

Read any PRACH area number in context before drawing conclusions:

- The committed OOC flow (`synth/prach_ooc.tcl`, part `xcku5p-ffvb676-2-i`) uses a
  **stand-in part**. The production device is a **ZU19EG**.
- Production instantiates **one `lowphy0` and one `lowphy1`, each containing
  several PRACH instances**. A single-`prach` OOC run therefore says nothing about
  project-level utilisation: do not turn a prach percentage into a project
  percentage by dividing by the device, and do not assume the stand-in part's
  spare capacity is available to PRACH.
- What *does* transfer between the two views is the **per-instance delta** — e.g.
  "this edit saves N LUTs in `u_ddc`, x3 per prach, xK prach instances". Decide on
  post-implementation numbers from a labelled baseline-vs-variant OOC run, never
  on synthesis estimates.
- Latest single-`prach` OOC baseline (Vivado 2024.2, `ANT_ID=0`): 17,597 CLB LUTs
  = 13,163 logic + **4,434 LUT-as-memory**, 25,755 FF, 63/480 BRAM, 183 DSP,
  `clk` WNS +0.117 ns. A quarter of the LUT budget is LUT-based storage, so
  moving storage between LUT / FF / BRAM is a live lever — but weigh each option's
  real exchange rate (an SRL holds 32 bits per LUT, a flip-flop holds 1 bit, a
  BRAM tile holds 36 Kb) against the project's actual resource pressure rather
  than assuming any one resource is free. For reference, in the committed
  `lowphy/synth/lowphy0_ooc_puxch_bfp9.md` result on the same stand-in part, BRAM
  was the most-utilised resource (241/480 = 50 % vs 24 % LUT), so "just move it to
  BRAM" needs a project-level check.

### FFT channel-sharing headroom (known; deliberately not implemented)

The DDC decimates each channel to 1.92 Msps, the stream is compacted in a RAM
buffer, and the four antennas then take turns through the FFT — so the FFT
processes already-packed data.

At a 491.52 MHz clock and 1.92 Msps per channel, **one FFT could serve up to 256
channels** (491.52 / 1.92). The largest configuration is one PRACH with 3 CC x
4 antennas = **12 channels**, about 5 % of a single FFT's capacity, yet the design
instantiates one FFT per CC (three in total). Sharing one FFT across the CCs is
the largest LUT lever in the block by a wide margin, but it is an architectural
change — per-stream pipeline state, arbitration, latency re-derivation — that was
consciously skipped for design-complexity reasons. It is recorded here so it does
not have to be re-derived, not as a pending task.

Only the FFT and the stages after it have this headroom. In the 122.88 Msps mode
the resync/DDC input carries a valid complex word every clock, so those stages are
fully occupied and cannot be shared.

## DDC clock and input modes

**The DDC clock is 491.52 MHz. The input sample rate is one of 122.88 / 61.44 /
30.72 Msps, and 4 antenna lanes are interleaved onto the single datapath. The
number of valid lanes per chn cycle follows from that rate:**

| Input rate | Valid complex lanes per chn cycle | `chn_max` | `ctrl_bw` | HB stages bypassed | Decimation | DDC output |
|---|---|---|---|---|---|---|
| 122.88 Msps | 4 of 4 (fully valid) | 3 | `0xF` (default) | none | /64 | 1.92 Msps |
| 61.44 Msps | 4 of 8 (half valid) | 7 | `0x3` | stage 0 | /32 | 1.92 Msps |
| 30.72 Msps | 4 of 16 (quarter valid) | 15 | `0x0`–`0x2` | stages 0, 1 | /16 | 1.92 Msps |

The DDC output for these modes is 1.92 Msps (the PRACH counter rate). That is why
the bypass exists: a lower input rate has already skipped the decimation that the
first HB stage(s) would provide, so those stages are bypassed rather than made to
decimate twice (122.88/64 = 61.44/32 = 30.72/16 = 1.92).

Where this lives:

- `rtl/prach_resync.sv:105-113` — `chn_max` per `ctrl_bw` (15 / 7 / 3).
- `rtl/prach_resync.sv:188-195` — `dout_dv` is high while `chn < NUM_ANT`, i.e.
  4 valid complex lanes per `chn_max+1` clock cycle.
- `rtl/prach_ddc.sv:112-120` — `ctrl_bypass` per `ctrl_bw`
  (`6'b000011` / `6'b000001` / `6'b000000`).
- `rtl/prach_ddc.sv:186-460` — the six `prach_reshape` + HB stages; stage `i`
  gets `ctrl_bypass[i]`, and `DELAY_BASE = 8 << i`.

`ctrl_bw` 0, 1 and 2 all select the same 30.72 Msps input configuration (same
`chn_max` and bypass); the RTL comments annotate them 7.68 / 15.36 / 30.72, which
are channel-bandwidth settings rather than the input sample rate.

Note that bypass is a functional bypass (an output mux), not a clock gate: a
bypassed stage still shifts its delay line. `DELAY_BASE` for stage `i` is
`8 << i` regardless of mode.

## Writing tests against the DDC

**A test that drives the DDC must use one of the three occupancy patterns above
and set the matching bypass. Any other cadence is not a supported operating mode
— if a test does not do this, the test is wrong.**

Conformance of the existing tests:

- `tests/test_prach.py` (end-to-end) — **conformant.** It writes
  `BW_30MHZ_ALL_CC = 0x222` so `ctrl_bw = 2` (30.72 Msps input, stages 0–1
  bypassed) and drives one complex word per antenna every
  `RADIO_SAMPLES_PER_CLK = 16` clocks, i.e. 4 valid complex lanes per 16 clocks.
- `tests/test_prach_ddc.py` — **conformant**, and parametrized over all three
  modes: `ctrl_bw` 0x2/0x3/0xF with 4 valid lanes per 16/8/4 clocks. Each mode
  asserts the mixer occupancy it implies and matches the chain against
  `model_decimation_chain` with the matching bypass.
- `tests/test_prach_hb4.py` — unit test for `prach_hb4` alone. Its 8-lane bursts
  repeating every `DELAY_BASE` (128 / 256) **are** the real interface: measured at
  the hb4/hb5 inputs in all three modes, `lane_valid` (`chn[6:3] == 0`, plus
  `chn[7] == 0` for D256) fires in bursts of 8 with a period of exactly
  `DELAY_BASE`.

`tests/prach_ddc_model.py` is the cycle-accurate reference model for the chain
(`reshape`, `halfband2`, `halfband4`, `bypass_stage`, `model_decimation_chain`).
It is the authority for expected values. `model_decimation_chain` takes the
`ctrl_bypass` value via its `bypass` argument (`bypass_for_ctrl_bw` mirrors
`prach_ddc`'s decode); a bypassed stage is a pure delay of `DELAY_BASE + 8` for
both data and sideband, which is the same latency as the hb2 filter path — so the
chain latency is mode-independent. Bypass never reaches `prach_hb4` in any
supported mode, so only the hb2 form is modelled.

## `prach_stream2block` buffer organisation

The FFT input buffer is sized by the PRACH format that has to be supported, and
the non-obvious address mapping follows from that.

- An **F1** PRACH occasion carries **two consecutive 1536-sample symbols**
  (`rtl/prach_ctrl.sv:384`, "Number of symbol, F0 = 1, F1 = 2"), so the block
  buffers `2 x 1536 = 3072` words **per antenna**.
- A 32-bit simple-dual-port RAMB36 is at most **1024 deep**, so 3072 words are
  split into **3 banks of 1024** per antenna. With `NUM_ANT = 4` that is 12 RAMs,
  and one 1024x32 exactly fills one RAMB36 tile.
- Each symbol is cut into three 512-word chunks. The mapping from
  `{wr_bank, wr_cnt[10:9]}` to `{bank, addr[9]}` (the two `case` statements in
  `rtl/prach_stream2block.sv`) is deliberately **not linear**:

  | `wr_bank` (symbol) | chunk `wr_cnt[10:9]` | bank | `addr[9]` |
  |---:|---:|---:|---:|
  | 0 | 0 | 0 | 0 |
  | 0 | 1 | 0 | 1 |
  | 0 | 2 | 1 | 0 |
  | 1 | 0 | 1 | 1 |
  | 1 | 1 | 2 | 0 |
  | 1 | 2 | 2 | 1 |

  With it, the two symbols of the occasion share bank 1 only through different
  `addr[9]` halves, so the symbol that has finished can be read out while the
  other one is still being written — no two concurrent accesses hit the same
  bank half.

- The block does **not** ping-pong whole occasions. Processing is fast enough that
  an occasion is consumed before the next one needs the buffer, so only the two
  symbols of the current F1 occasion are held.
- The read side walks `rd_cnt` in bit-reversed order (`rd_cnt_rev`), which is the
  order the FFT consumes.

The C1 merge then folded the antenna into the address: one 4096x32 RAM per bank,
addressed by `{antenna, bank-relative address}`, so the read path selects 3 banks
instead of 12 antenna/bank combinations. The 4 antenna slots share each bank's
depth, so the RAM count, the depth and the tile count are unchanged; see
`doc/prach_ooc_result.md` for the measured effect.

## Lane cadence and the halfband delay lines

This matters for the delay-line microarchitecture, so it is recorded here.

`prach_hb4` stores one lane's sample history in a `ram_style = "distributed"`
word addressed by `din_chn[2:0]`, so a single read yields every tap
(`rtl/prach_hb4.sv:56-59`, `125-148`). That only works when the tap spacing is a
whole number of lane visits — i.e. `DELAY_BASE` is a multiple of the valid-sample
period at that stage.

In the supported modes this holds for every stage that actually filters, because
the bypassed stages are exactly the ones whose `DELAY_BASE` is too small:

| mode | valid period | stages that filter | `DELAY_BASE` values | multiple of period? |
|---|---|---|---|---|
| 122.88 | 4 | 0–5 | 8, 16, 32, 64, 128, 256 | yes |
| 61.44 | 8 | 1–5 | 16, 32, 64, 128, 256 | yes |
| 30.72 | 16 | 2–5 | 32, 64, 128, 256 | yes |

Measured against `prach_ddc_model` (tap-validity check per stage): in the
16-clock mode `B=32` is exactly tap-aligned (3968/3968 outputs) while `B=8` is
not (0/4064) — and `B=8` is bypassed in that mode, so it never filters.

For the hb4/hb5 stages the equivalent measurement is `lane_valid`
(`din_dv && chn[6:3] == 0`, plus `chn[7] == 0` for D256): at the hb4 input it
fires in bursts of 8 with a period of exactly `DELAY_BASE`, and at the hb5 input
likewise, in all three modes. That equality — visit period == `DELAY_BASE` — is
what lets one lane-addressed word hold every age that stage needs.

Consequence for `prach_hb2`: under the supported modes its taps are lane-aligned
wherever it filters, so the structure is *possible* there too — but it is **not
worth doing, and was evaluated and rejected**. The lane word only pays off when
the visit period `P` is large relative to the tap spacing, because every
intervening visit still has to be stored:

- hb4: `P = DELAY_BASE` (128/256 clocks), so the word needs only the 7+3+3 ages it
  actually uses (~199 bits) instead of ~900 stages of time-domain shift register,
  and it replaces eight replicated per-lane register banks (~360 LUTs).
- hb2: `P` is 4/8/16 clocks while `DELAY_BASE` is 8..64, so
  `Step = DELAY_BASE / P >= 2` and the word must carry `4 * Step` 16-bit entries
  per lane. A depth-8 LUTRAM costs 1 LUT/bit (two bit-planes cannot share a LUT6
  at that depth), giving `lane RAM / SRL ~ 32 / P`: about 2x worse at `P=16`, 4x
  at `P=8`, 8x at `P=4`. hb2 also has a single stream, so there are no replicated
  banks to collapse.

Rule of thumb: the lane-addressed word wins only when `P` exceeds roughly 43
clocks. hb4 (`P = 128/256`) does; hb2 (`P = 4/8/16`) does not.

If an area question like this comes up again, decide it on
**post-implementation** numbers rather than synthesis estimates (they differ by
~15% on this design): run a labelled baseline-vs-variant OOC pass through
`route_design` and diff the per-instance LUT / Logic LUT / LUTRAM / SRL columns
from `report_utilization -hierarchical`. `synth/prach_ooc.tcl` is the
full-wrapper flow to copy.

## References

- `rtl/prach_ddc.sv` — DDC datapath and `ctrl_bypass`.
- `rtl/prach_resync.sv` — `chn` counter, `chn_max`, `dout_dv`, antenna selection.
- `rtl/prach_hb2.sv`, `rtl/prach_hb4.sv` — the two halfband stages.
- `rtl/prach_reshape.sv` — lane/I-Q reshaping (`SIZE = 8 << i`).
- `tests/prach_ddc_model.py`, `tests/prach_waveform.py` — reference models.
- `synth/prach_ooc.tcl`, `doc/prach_ooc_result.md` — full-wrapper OOC flow/result.
