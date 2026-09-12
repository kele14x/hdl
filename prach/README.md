# PRACH

`prach` is the multi-antenna PRACH receive block: it resynchronises the radio
stream, decimates it in the DDC, runs the 1536-point FFT, and packs the result
for the U-plane.

Layout:

- `rtl/` — SystemVerilog sources (`prach.sv`, `prach_channel.sv`, `prach_ddc.sv`, ...)
- `tests/` — cocotb regression tests and cycle-accurate Python models
- `tb/` — traditional SystemVerilog testbench helpers
- `doc/` — design notes and OOC synthesis results
- `synth/` — Vivado OOC scripts and utilization comparison tooling
- `prach.flt` — RTL filelist (no testbench files)

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
- `tests/test_prach_ddc.py` — **does not conform.** It sets `ctrl_bw = 0xF`
  (122.88 Msps, no bypass) but `_make_vector` marks only 4 valid complex lanes
  per **128** clocks. The 122.88 mode requires 4 of 4; 4 of 128 corresponds to no
  supported mode. Fix by driving 4-of-4 (`ctrl_bw = 0xF`), 4-of-8
  (`ctrl_bw = 0x3`) or 4-of-16 (`ctrl_bw = 0x0`–`0x2`) and keeping the bypass
  consistent with the chosen mode.
- `tests/test_prach_hb4.py` — unit test for `prach_hb4` alone. It drives 8-lane
  bursts repeating every `DELAY_BASE` (128 / 256). This is a synthetic pattern,
  not a full-DDC mode; do not use it to reason about the production lane cadence.

`tests/prach_ddc_model.py` is the cycle-accurate reference model for the chain
(`reshape`, `halfband2`, `halfband4`, `model_decimation_chain`). It is the
authority for expected values; its stage loop does not model bypass, so callers
driving a bypassed mode must account for that.

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
