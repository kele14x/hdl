# FFT delay-line LUT optimization plan

Work order for a machine with Vivado 2026.1 installed. The analysis behind it
was done by static RTL reading only — the authoring machine has no Vivado and
no surviving `sim_build/` reports — so **Phase 0 is a blocking measurement
step**. Do not skip it: two of the three findings below are unverified
inferences, and one of them may be worth 7x more than the other two combined.

Baseline revision: `d3f9f62` (`update lowphy1 ooc result`).

## Contents

1. Goal and scope
2. Prerequisites
3. Established facts and open questions
4. Phase 0 — measurement (blocking)
5. Decision gates
6. Phase 1 — `RAM_STYLE` case sensitivity (conditional)
7. Phase 2 — single-port LUTRAM delay line
8. Phase 3 — depth 256/512 (conditional)
9. Verification
10. Acceptance criteria
11. Risks and rollback
12. Report-back template

---

## 1. Goal and scope

LUT is the tightest of the four main resources:

| Design | LUT | FF | BRAM tile | URAM | DSP |
|---|---:|---:|---:|---:|---:|
| `lowphy1_wrapper` | 115,877 (53.41%) | 124,213 (28.63%) | 343.5 (71.56%) | 6 (9.38%) | 861 (47.20%) |
| `lowphy0_wrapper` | 51,988 (23.96%) | 59,178 (13.64%) | 295.5 (61.56%) | 6 | 369 |

Device `xcku5p-ffvb676-2-i`: 216,960 LUT, 433,920 FF, 480 BRAM tiles, 64 URAM,
1,824 DSP48E2.

Note that **BRAM (71.56%) is proportionally tighter than LUT (53.41%)** in
lowphy1. Any option that trades LUT for BRAM must be rejected; trading LUT for
FF is fine (FF has the largest headroom).

This plan targets the `fft_bf2` inter-stage delay lines. It does not touch the
butterfly arithmetic, twiddle ROMs, coefficient widths, rounding, or output
widths, and it does not change FFT latency.

### Out of scope but recorded for later

Separately identified LUT candidates, not part of this work order:
`shift_ram.sv:141` output mask (~2.4k), merging the four identical
`pulse_delay` instances in `fft.sv:271-309` (~2.5k), constant-propagating
`ctrl_bypass` for the 11 of 12 butterflies that can never bypass — currently
blocked by the four `keep_hierarchy="yes"` attributes in `fft_stage.sv`
(~4k), and converting `prach_hb2.sv:82-95` / `prach_reshape.sv` to the sparse
event-history scheme already proven in `prach_hb4` (~4-5k).

---

## 2. Prerequisites

- Vivado 2026.1, build 6511674 (match the existing reports for comparability).
- `uv sync` for the Python/cocotb environment.
- Verilator for `make lint`.
- A simulator for the regression. `SIM` must be set explicitly; there is no
  default. The recorded regressions in this repo used `SIM=questa`.

Existing OOC entry points:

```text
lowphy/synth/lowphy1_ooc.tcl   -> sim_build/vivado_ooc_lowphy1_20260806/
lowphy/synth/lowphy0_ooc.tcl   -> sim_build/vivado_ooc_lowphy0_.../
```

Both use `synth_design -mode out_of_context -flatten_hierarchy rebuilt
-verilog_define {RAM_USE_XPM}`. Keep every option identical across
before/after runs. `-flatten_hierarchy rebuilt` preserves hierarchy, so
per-instance queries work.

---

## 3. Established facts and open questions

### 3.1 The delay structure

`fft_bf2.sv:33-34`:

```systemverilog
localparam int DelayWidth = DATA_WIDTH * 2;                             // 36
localparam int DelayDepth = (1 << (LOG_FFT_SIZE + $clog2(NUM_ANT) - 1));
```

`DATA_WIDTH` reaching `fft_bf2` is `DataWidthInt = 16 + 2 = 18`, so
`DelayWidth = 36` everywhere.

`fft_bf2.sv:237-267` selects the implementation:

```systemverilog
if (DelayDepth <= 128) begin : g_srl        // common/rtl/delay.sv
end else begin : g_shift_ram                // shift_ram/rtl/shift_ram.sv
end
```

Per-butterfly depths, band 0 (`LOG_FFT_SIZE=12`, `NUM_ANT=4`,
`BIT_REVERSED_INPUT` either way, 6 stages x 2 butterflies):

| Stage | `i_bf2i` depth | `i_bf2ii` depth |
|---:|---:|---:|
| 0 | 4 | 8 |
| 1 | 16 | 32 |
| 2 | 64 | 128 |
| 3 | 256 | 512 |
| 4 | 1024 | 2048 |
| 5 | 4096 | 8192 |

Bands 1 and 2 (`LOG_FFT_SIZE=11`, `NUM_ANT=2`) give 2, 4, 8, 16, 32, 64, 128,
256, 512, 1024, 2048 — the last stage has `LOG_FFT_SIZE` odd so `HasBf2ii=0`
and there is no second butterfly.

Both configurations put exactly three butterflies at depth 32, 64 and 128,
which is what Phase 2 targets.

### 3.2 Instance count

`fft` is instantiated at exactly two sites: `pdxch_channel.sv:265` and
`puxch_channel.sv:319`. Each sits inside a per-CC generate loop
(`pdxch_top.sv:162`, `puxch_top.sv:88`). lowphy1 has 7 CC total (band 0: 3,
bands 1 and 2: 2 each), so **14 `fft` instances**; lowphy0 has 3 CC, so 6.
`prach_fft` is a separate implementation and is not counted here.

### 3.3 Proof that the `g_srl` delays are not flip-flops

Per FFT the `g_srl` branch holds:

- band 0: 4+8+16+32+64+128 = 252 words x 36 bit = 9,072 bit
- bands 1/2: 2+4+8+16+32+64+128 = 254 words x 36 bit = 9,144 bit

lowphy1 total: `6 x 9,072 + 8 x 9,144 = 127,584 bit`. If these were registers
they would need 127,584 flip-flops, but the whole design reports **124,213**.
So they are not flip-flops. They are LUT-based storage — almost certainly SRL.

### 3.4 Open question A: how does `delay.sv` become an SRL at all?

`common/rtl/delay.sv:49-61` clears **every** stage on reset:

```systemverilog
always @(posedge clk) begin : p_shift
  if (rst) begin
    for (i = 0; i < DEPTH; i = i + 1) dregs[i] <= 'b0;
  end else if (cen) begin
    dregs[0] <= din;
    for (i = 1; i < DEPTH; i = i + 1) dregs[i] <= dregs[i-1];
  end
end
```

`SRLC32E`/`SRL16E` have no reset port, so a literal implementation of this
cannot be an SRL. Yet 3.3 proves it is not registers either. Note that the
same repo contains `common/rtl/srl.sv`, which deliberately puts **no** reset on
the shift chain (only on the output register) — the author clearly knew the
distinction.

Two possibilities, both worth knowing:

- Vivado maps the chain to SRL and silently drops the reset. That is an
  **RTL-simulation vs hardware mismatch**: after a mid-stream reset the RTL
  model outputs zeros and the hardware outputs stale samples. This is a latent
  bug independent of this optimization and should be reported.
- The mapping is something else entirely (e.g. LUTRAM), which would change the
  Phase 2 arithmetic.

Phase 0 step 3 resolves this with one query. **Do not implement Phase 2 before
resolving it** — if the delays are not actually 306 LUT/FFT of SRL today, the
predicted saving is wrong.

### 3.5 Open question B: `RAM_STYLE` case sensitivity — the big one

`ram/rtl/ram_sdp.sv:103` forwards `RAM_STYLE` straight to XPM:

```systemverilog
.MEMORY_PRIMITIVE (RAM_STYLE),
```

and `fft_bf2.sv:258` passes **uppercase**:

```systemverilog
.RAM_STYLE (DelayDepth >= 8192 ? "ULTRA" : (DelayDepth >= 1024 ? "BLOCK" : "AUTO"))
```

Xilinx documents `MEMORY_PRIMITIVE` with **lowercase** values (`auto`,
`distributed`, `block`, `ultra`). If XPM compares the string exactly, every
uppercase value falls back to `auto`, and all the deliberate `RAM_STYLE`
steering in the repo is inert — including `fft_bf2.sv:258`,
`puxch_iq_ram.sv:97/165/197`, `puxch_buffer.sv:335`,
`pdxch_fdv_buffer.sv:190/210`, `prach_stream2block.sv:413`,
`prach_framer_buffer.sv:136/154` and `oran_framer_ul_ss_adaptor.sv:426`.

Circumstantial support: the only module in the design that produces UltraRAM
is `ram/rtl/ram_sdp_uram_8k36.sv:64`, which **hardcodes lowercase `"ultra"`**
and bypasses the `ram_sdp` wrapper entirely. Several `oran_slave` modules also
instantiate XPM directly with lowercase. lowphy1's URAM count of 6 matches
exactly the six band-0 FFTs' 8192-deep `PACKED_URAM` instances, which route
through that lowercase module.

Why this matters more than Phase 2: depths **256 and 512** fall in the
`"AUTO"` branch. If they land in distributed RAM, then because `ram_sdp` is
*simple dual-port* (separate `addra`/`addrb`, so distributed mapping
duplicates storage at 32 bit/LUT) they cost
`(256 + 512) x 36 / 32 = 864 LUT per FFT`, i.e. **~12k LUT across 14
instances**. That dwarfs Phase 2's 1.7k.

### 3.6 Density reference

A SLICEM LUT6 in memory mode has 64 storage cells. What you get depends on
whether a duplicate copy is needed, **not** on depth:

| Configuration | Duplicate? | Density |
|---|---|---:|
| `SRL16E` (2 per LUT6) / `SRLC32E` | half the cells unreachable via the shift cascade | 32 bit/LUT |
| `RAM32X1S`, `RAM64X1S`, `RAM128X1S`, `RAM32M` (shared write address) | no | **64 bit/LUT** |
| `RAM32X1D`, `RAM64X1D`, distributed simple-dual-port | one copy per read port | 32 bit/LUT |

The SRL 32 bit/LUT cap is a hard property of the primitive and **cannot** be
recovered by implementation-phase packing. This is different from LUTRAM: a
`prach_hb4` experiment on this repo showed 199 synthesis-stage LUTRAMs for an
8 x 199-bit array collapsing to ~100 LUTs during implementation, because two
1-bit shallow RAMs legally share one LUT6. That auto-packing is why Phase 2
below does not need manual `RAM32M` instantiation — but it is also why the
`prach_hb4` array needs no further work.

---

## 4. Phase 0 — measurement (blocking)

### Step 1 — reproduce the baseline

```bash
cd <repo_root>
vivado -mode batch -source lowphy/synth/lowphy1_ooc.tcl
vivado -mode batch -source lowphy/synth/lowphy0_ooc.tcl
```

Confirm 0 errors and that `lowphy1_utilization.rpt` still reports 115,877 LUT /
124,213 FF / 343.5 BRAM tile / 6 URAM / 861 DSP. If it does not, stop and
reconcile before going further — the rest of this plan is calibrated to those
numbers.

### Step 2 — record the LUT-as-memory split

From `lowphy1_utilization.rpt`, the `CLB Logic` table, capture:

```text
CLB LUTs
  LUT as Logic
  LUT as Memory
    LUT as Distributed RAM
    LUT as Shift Register
```

SRL and LUTRAM draw from the same SLICEM pool, so this split tells you how
much of the LUT pressure is storage rather than logic.

From `lowphy1_utilization_hierarchical.rpt`, capture the `Total LUTs / Logic
LUTs / LUTRAMs / SRLs / FFs / RAMB36 / RAMB18 / URAM / DSP` row for one
representative `fft` instance in each of band 0 and band 1.

### Step 3 — resolve open question A: what are the `g_srl` delays?

Run against the checkpoint:

```tcl
open_checkpoint sim_build/vivado_ooc_lowphy1_20260806/lowphy1_ooc.dcp

set fh [open fft_delay_census.txt w]

# Global primitive census, for context.
foreach ref {FDRE SRL16E SRLC32E RAM32X1S RAM64X1S RAM128X1S RAM256X1S \
             RAM32M RAM32M16 RAM64M RAM64M8 RAM32X1D RAM64X1D \
             RAMB18E2 RAMB36E2 URAM288} {
  set n [llength [get_cells -hier -quiet -filter "REF_NAME == $ref"]]
  puts $fh [format "global %-12s %d" $ref $n]
}

# Everything living under an i_delay instance, grouped by primitive type.
array unset cnt
foreach c [get_cells -hier -quiet -filter {IS_PRIMITIVE && NAME =~ "*i_delay*"}] {
  incr cnt([get_property REF_NAME $c])
}
foreach k [lsort [array names cnt]] {
  puts $fh [format "i_delay %-12s %d" $k $cnt($k)]
}

close $fh
```

Interpretation:

- `SRL16E`/`SRLC32E` dominate under `i_delay` -> section 3.3 holds, the
  reset is being dropped, Phase 2 applies as written, **and open question A is
  a real sim/hardware mismatch to report separately**.
- `FDRE` dominates -> section 3.3 is somehow wrong; recheck the FFT instance
  count and re-derive before touching anything.
- `RAM*` dominates -> the delays are already LUTRAM; recompute the Phase 2
  saving from the actual primitive mix, which will be much smaller.

### Step 4 — resolve open question B: does `RAM_STYLE` reach XPM?

Two independent checks.

**4a. Grep the synthesis log** for XPM parameter complaints:

```bash
grep -inE "MEMORY_PRIMITIVE|xpm_memory|invalid.*primitive" \
    sim_build/vivado_ooc_lowphy1_20260806/*.log \
    vivado.log 2>/dev/null
```

**4b. Decisive A/B experiment.** Synthesize `shift_ram` OOC at a size where
`auto` and `block` disagree with `distributed`, once with each spelling:

```tcl
# scratch script, run twice with STYLE = "BLOCK" then "block"
set STYLE "BLOCK"
read_verilog -sv { ... shift_ram.flt sources ... }
synth_design -top shift_ram -part xcku5p-ffvb676-2-i -mode out_of_context \
  -flatten_hierarchy none -verilog_define {RAM_USE_XPM} \
  -generic [list WIDTH=36 DEPTH=1024 INPUT_REG=1 RAM_STYLE=$STYLE]
report_utilization -file shift_ram_${STYLE}_util.rpt
```

Then repeat with `DEPTH=256` and `STYLE` in `{AUTO, auto, DISTRIBUTED,
distributed}`.

- If uppercase and lowercase give **the same** primitive mix, the wrapper is
  fine; skip Phase 1.
- If uppercase `BLOCK` yields BRAM but lowercase `block` also yields BRAM
  while uppercase `DISTRIBUTED` yields BRAM and lowercase `distributed`
  yields LUTRAM, then uppercase is being ignored -> Phase 1 applies.

Record what `DEPTH=256, WIDTH=36` and `DEPTH=512, WIDTH=36` actually map to
under the spelling the FFT uses today. That single data point decides whether
Phase 3 is worth ~6k LUT or nothing.

---

## 5. Decision gates

| Gate | Question | If yes | If no |
|---|---|---|---|
| A | Are `g_srl` delays SRL, ~306 LUT per FFT? | Phase 2 proceeds | recompute or drop Phase 2 |
| B | Is uppercase `RAM_STYLE` ignored by XPM? | Phase 1 first | skip Phase 1 |
| C | Do depth 256/512 map to distributed SDP RAM? | Phase 3 is worth ~6k LUT | skip Phase 3 |

Phase 2 does not depend on Phase 1 or Phase 3. If Phase 0 runs short on time,
Phase 2 alone is a safe, self-contained change.

---

## 6. Phase 1 — `RAM_STYLE` case sensitivity (conditional on gate B)

Normalize inside the wrapper rather than editing ~15 call sites, so both
spellings keep working:

In `ram/rtl/ram_sdp.sv` (and the same pattern in `ram_sp.sv`,
`ram_tdp.sv`, `ram_tdp_asym.sv`, `ram_sdp_asym.sv` — all forward `RAM_STYLE`
to `MEMORY_PRIMITIVE` the same way), derive a lowercase local parameter and
pass that to XPM:

```systemverilog
localparam XpmMemoryPrimitive =
    (RAM_STYLE == "BLOCK")       ? "block" :
    (RAM_STYLE == "DISTRIBUTED") ? "distributed" :
    (RAM_STYLE == "ULTRA")       ? "ultra" : "auto";
```

Keep the existing `drc_check` assertion on the uppercase input so illegal
values are still caught.

**Warning:** if the steering was previously inert, fixing it will *move*
memories. Re-run both OOC builds and compare BRAM/URAM/LUT together. Because
BRAM is at 71.56%, a fix that suddenly honours every `"BLOCK"` request could
overflow BRAM. Treat this as a measurement change, not automatically an
improvement, and re-tune the individual `RAM_STYLE` choices afterwards.

---

## 7. Phase 2 — single-port LUTRAM delay line

### 7.1 Why `shift_ram` cannot be reused

`shift_ram` wraps `ram_sdp` = `xpm_memory_sdpram`, which has separate write
(`addra`) and read (`addrb`) addresses. A distributed mapping of a simple
dual-port memory duplicates storage per read port: 32 bit/LUT, the same as the
SRL it would replace. No gain. Reaching 64 bit/LUT requires read and write to
share **one** address.

### 7.2 New module

Create `common/rtl/delay_lutram.sv`. Do **not** modify `common/rtl/delay.sv` —
it has 56 instantiations across 29 files and its clear-on-reset semantics are
relied upon elsewhere.

```systemverilog
`timescale 1 ns / 1 ps
//
`default_nettype none

// Event-advanced delay line built from single-port distributed RAM. Read and
// write share one address, so a SLICEM LUT6 holds two bits of storage instead
// of the 32 bits an SRL cascade can reach.
//
// Unlike `delay`, the memory is not cleared by `rst`: only the address
// counter and the output register are. This matches the existing `shift_ram`
// behaviour, which also leaves its RAM contents intact across a reset.
module delay_lutram #(
    parameter int WIDTH = 36,
    parameter int DEPTH = 32
) (
    input var              clk,
    input var              rst,
    input var              cen,
    //
    input var  [WIDTH-1:0] din,
    output var [WIDTH-1:0] dout
);

  // The output register supplies one event of delay, so the memory holds
  // DEPTH-1 entries.
  localparam int MemDepth = DEPTH - 1;
  localparam int AddrWidth = $clog2(MemDepth);

  initial begin : drc_check
    assert (DEPTH >= 3 && DEPTH <= 256)
    else $error("[%m]: DEPTH (%0d) must be within the range 3 to 256.", DEPTH);

    assert (WIDTH >= 1 && WIDTH <= 1024)
    else $error("[%m]: WIDTH (%0d) must be within the range 1 to 1024.", WIDTH);
  end

  (* ram_style = "distributed" *)
  logic [    WIDTH-1:0] mem [MemDepth];

  logic [AddrWidth-1:0] addr;
  logic [    WIDTH-1:0] dout_r;

  initial begin : p_init
    for (int i = 0; i < MemDepth; i++) begin
      mem[i] = {WIDTH{1'b0}};
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      addr <= {AddrWidth{1'b0}};
    end else if (cen) begin
      addr <= (addr == AddrWidth'(MemDepth - 1)) ? {AddrWidth{1'b0}} : (addr + 1'b1);
    end
  end

  // One address drives both the synchronous write and the asynchronous read.
  // The read therefore returns the value written MemDepth events earlier,
  // before this cycle's write lands.
  always_ff @(posedge clk) begin
    if (cen) begin
      mem[addr] <= din;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_r <= {WIDTH{1'b0}};
    end else if (cen) begin
      dout_r <= mem[addr];
    end
  end

  assign dout = dout_r;

endmodule

`default_nettype wire
```

Add `rtl/delay_lutram.sv` to `common/common.flt`. `fft.flt` already pulls in
`../common/common.flt`, so no change is needed there.

### 7.3 Latency equivalence

This is the part to get right; everything else is mechanical.

`delay` with `DEPTH = D`: let event `k` be the `k`-th cycle with `cen` high.
`dregs[0] <= din` on every event, so after event `k` the output
`dout = dregs[D-1]` equals `din` from event `k - D + 1`.

`delay_lutram` with `MemDepth = M`: address `addr_k = (k-1) mod M`. At event
`k` the pre-write content of `mem[addr_k]` is `din` from event `k - M`, and
that value is captured into `dout_r`. So after event `k`,
`dout = din` from event `k - M`.

Setting `M = D - 1` makes the two identical. That is why the memory is
`DEPTH-1` deep, and why **FFT latency does not change**. The nine-way latency
constant mux in `fft.sv:239-259` and the `DelayDepth` compensation both stay
as they are.

Side benefit: for `D` a power of two, `M = D-1` fits exactly in
`AddrWidth = log2(D)` bits with one address unused, so `RAM32X1S`/`RAM64X1S`/
`RAM128X1S` are used at full depth and the wrap comparator is ~1 LUT.

### 7.4 Wiring it in

`fft_bf2.sv:237` — split the existing two-way choice into three. Convert only
depths 17..128; depths <= 16 gain nothing (see 7.5) and should stay on SRL.

```systemverilog
  generate
    if (DelayDepth <= 16) begin : g_srl

      delay #(
          .WIDTH(DelayWidth),
          .DEPTH(DelayDepth),
          .INIT (0)
      ) i_delay (
          .clk (clk),
          .rst (rst),
          .cen (shift),
          .din (delay_in),
          .dout(delay_out)
      );

    end else if (DelayDepth <= 128) begin : g_lutram

      delay_lutram #(
          .WIDTH(DelayWidth),
          .DEPTH(DelayDepth)
      ) i_delay (
          .clk (clk),
          .rst (rst),
          .cen (shift),
          .din (delay_in),
          .dout(delay_out)
      );

    end else begin : g_shift_ram

      // unchanged
      shift_ram #(
          .WIDTH      (DelayWidth),
          .DEPTH      (DelayDepth),
          .INPUT_REG  (1),
          .PACKED_URAM((DelayDepth == 8192 && DelayWidth == 36) ? 1 : 0),
          .RAM_STYLE  (DelayDepth >= 8192 ? "ULTRA" : (DelayDepth >= 1024 ? "BLOCK" : "AUTO"))
      ) i_delay (
          .clk (clk),
          .rst (rst),
          .cen (shift),
          .din (delay_in),
          .dout(delay_out)
      );

    end
  endgenerate
```

Note the existing code at `fft_bf2.sv:237` uses a bare `if`/`else` without the
`generate` keyword, which contradicts the repo style rule in `AGENTS.md`.
Wrapping it as shown fixes that at the same time.

### 7.5 Expected saving

Per FFT, `DelayWidth = 36`:

| Depth | SRL today | Single-port LUTRAM | Saving |
|---:|---:|---:|---:|
| 2 / 4 / 8 / 16 | 18 each (2x`SRL16E` per LUT6) | 18 (`RAM32X1S` depth floor) | 0 — keep SRL |
| 32 | 36 (`SRLC32E` x36) | **18** (`RAM32X1S`, 2 bit/LUT6) | 18 |
| 64 | 72 | **36** (`RAM64X1S`) | 36 |
| 128 | 144 | **72** (`RAM128X1S`) | 72 |
| **Converted subtotal** | **252** | **126** | **126** |

Added per converted instance: 36 FF output register, `AddrWidth` FF counter,
~1-2 LUT wrap comparator. Three instances per FFT: ~+126 FF, ~+5 LUT.

| Design | FFT instances | LUT delta | FF delta |
|---|---:|---:|---:|
| `lowphy1_wrapper` | 14 | **-1,764 + ~70 = ~-1,700** | ~+1,760 |
| `lowphy0_wrapper` | 6 | **~-730** | ~+760 |

About 1.5% of lowphy1's LUT. Modest, but low risk and independent of the two
open questions.

### 7.6 The one behavioural change

`delay` zeroes its contents on `rst`; `delay_lutram` does not. Justification
for accepting this:

- `shift_ram.sv:129-143` already behaves this way. Its `vld` shift register is
  only `RamReadLatency` (2 or 3) deep, so after a reset it masks the output for
  2-3 events and then passes whatever was already in the RAM. The six deepest
  butterflies in every FFT therefore **already** carry stale delay data across
  a reset. Phase 2 extends existing behaviour to three more butterflies rather
  than introducing new behaviour.
- Both simulation and hardware start from zeros: `delay_lutram` has an
  `initial` zero-fill (matching `ram_sdp.sv:185-193`), and Vivado initializes
  distributed RAM to zero. The divergence appears only on a **mid-stream**
  reset.

If the regression does show a dependency on clear-on-reset, the fallback is a
warm-up mask (`dout_r <= mem[addr] & {WIDTH{warm}}`), but note that this costs
36 LUTs per instance and would consume most of the 126-LUT saving. Prefer
investigating why the test needs the clear over paying for the mask.

---

## 8. Phase 3 — depth 256/512 (conditional on gate C)

Only if Phase 0 step 4 shows that `DEPTH=256` and `DEPTH=512` with
`WIDTH=36` currently map to **distributed** RAM through the simple-dual-port
`ram_sdp`.

In that case each FFT spends `(256 + 512) x 36 / 32 = 864 LUT` on those two
butterflies — about 12k LUT across 14 instances. Two options:

1. Raise `delay_lutram`'s `DEPTH` limit to 512 and extend the `g_lutram`
   branch to cover 17..512. Density goes 32 -> 64 bit/LUT: ~432 LUT per FFT,
   about **-6k LUT** design-wide, at the cost of ~+72 FF per FFT. Same
   single-address mechanism, so the same latency argument holds.
2. Push them to BRAM. **Reject** unless BRAM headroom has been re-measured:
   BRAM is at 71.56%, proportionally tighter than LUT.

Option 1 needs `delay_lutram`'s `DRC` upper bound and the `AddrWidth`
arithmetic re-checked at `MemDepth = 255` and `511` (both still one below a
power of two, so `RAM256X1S`/two-deep cascades stay efficient), plus a fresh
timing check — a 511-entry distributed RAM has a longer asynchronous read path
than a 127-entry one, and the read feeds the next stage's adder.

---

## 9. Verification

Run all of it, in this order. Per `AGENTS.md`, read the simulation logs for
cocotb/Verilator warnings — do not rely on the pytest summary alone.

### 9.1 Lint

```bash
make -C common lint
make -C fft    lint
make -C pdxch  lint
make -C puxch  lint
make -C prach  lint
make -C lowphy lint
```

Must be clean under `verilator --lint-only -Wall`.

### 9.2 Formatting

```bash
uv run ruff check
uv run ruff format
```

Only relevant if any Python changes; RTL formatting uses
`make -C common format` / `make -C fft format` (verible).

### 9.3 Regression

```bash
export SIM=questa      # or verilator; must be set explicitly
uv run python -m pytest -q fft/tests
uv run python -m pytest -q pdxch/tests
uv run python -m pytest -q puxch/tests
uv run python -m pytest -q lowphy/tests
uv run python -m pytest -q prach/tests    # shared common/ change
```

`fft/tests/test_fft_model.py` and `fft/tests/test_fft_primitives.py` are the
primary gate: they compare the RTL against the fixed-point model in
`fft/tests/fft_fixed_model.py`, so any latency or delay-depth error shows up
immediately as a sample-alignment mismatch.

Because `common/common.flt` changed, `prach` and every other module listed
above must be re-run even though `delay.sv` itself was not touched.

### 9.4 Re-synthesize and diff

```bash
vivado -mode batch -source lowphy/synth/lowphy1_ooc.tcl
vivado -mode batch -source lowphy/synth/lowphy0_ooc.tcl
```

Compare against the Phase 0 baseline, using both the flat and the hierarchical
report. Also re-run the Phase 0 step 3 census and confirm the SRL count under
`i_delay` dropped by the predicted amount and that `RAM32X1S`/`RAM64X1S`/
`RAM128X1S` appeared.

---

## 10. Acceptance criteria

Phase 2, `lowphy1_wrapper`:

| Resource | Baseline | Expected | Tolerance |
|---|---:|---:|---|
| CLB LUT | 115,877 | ~114,180 | -1,700 +/- 300 |
| CLB FF | 124,213 | ~125,970 | +1,760 +/- 300 |
| BRAM tile | 343.5 | 343.5 | must be unchanged |
| URAM | 6 | 6 | must be unchanged |
| DSP48E2 | 861 | 861 | must be unchanged |

Phase 2, `lowphy0_wrapper`: LUT 51,988 -> ~51,260; BRAM 295.5, URAM 6, DSP 369
unchanged.

Also required:

- `LUT as Shift Register` drops by ~1,764; `LUT as Distributed RAM` rises by
  ~882. Net `LUT as Memory` down ~882. If SRL drops but LUTRAM rises by the
  *same* amount, the single-port packing did not happen — check that the
  `ram_style` attribute survived and that Vivado did not infer a dual-port
  memory.
- Every regression above passes with no new warnings.
- FFT latency unchanged: the model-comparison tests pass without touching
  `fft.sv:239-259`.

Abort and report if any of BRAM/URAM/DSP moves, or if LUT moves by less than
1,000 — the latter means the density assumption in 3.6 does not hold for this
tool version and the whole approach needs re-derivation.

---

## 11. Risks and rollback

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Gate A fails: delays are not SRL today | medium | Phase 2 saving evaporates | Phase 0 step 3 is cheap; run it first |
| Vivado infers dual-port and keeps 32 bit/LUT | medium | no saving, no harm | verify via primitive census; force with `ram_style` / check that only one address net reaches the memory |
| Regression depends on clear-on-reset | low | needs warm-up mask, saving drops to ~20/FFT | see 7.6; `shift_ram` precedent suggests it will not |
| Asynchronous read path hurts timing | low at depth 128, real at 512 | timing closure | OOC timing here is unconstrained and not a signoff result; run a constrained implementation before trusting Phase 3 |
| Phase 1 relocates memories and overflows BRAM | medium if gate B is yes | build failure | treat Phase 1 as a measurement change; re-tune `RAM_STYLE` per site afterwards |

Rollback for each phase is a single-file revert:

- Phase 1: `ram/rtl/ram_sdp.sv` and siblings.
- Phase 2: revert `fft_bf2.sv:237-267` to the two-way `if`, drop
  `rtl/delay_lutram.sv` from `common/common.flt`.
- Phase 3: revert the `g_lutram` bound.

**Do not commit anything.** Per `AGENTS.md` this repo never auto-commits;
leave the working tree dirty and report back, or commit only on explicit
instruction.

---

## 12. Report-back template

```text
## Phase 0

Vivado version:
Baseline reproduced (Y/N), deltas if N:

lowphy1 CLB Logic:
  CLB LUTs               =
  LUT as Logic           =
  LUT as Memory          =
    LUT as Distributed RAM =
    LUT as Shift Register  =

fft instance hierarchy row (band 0):
  Total LUTs / Logic LUTs / LUTRAMs / SRLs / FFs / RAMB36 / RAMB18 / URAM / DSP
fft instance hierarchy row (band 1):

Gate A - primitive census under i_delay:
  SRL16E   =        SRLC32E  =
  FDRE     =        RAM*     =
  -> delays are: [SRL | FF | LUTRAM]
  -> open question A (sim/hw reset mismatch) confirmed? (Y/N)

Gate B - RAM_STYLE case:
  XPM warnings in log:
  shift_ram DEPTH=1024 WIDTH=36, "BLOCK" -> primitives:
  shift_ram DEPTH=1024 WIDTH=36, "block" -> primitives:
  shift_ram DEPTH=256  WIDTH=36, "AUTO"  -> primitives:
  shift_ram DEPTH=256  WIDTH=36, "auto"  -> primitives:
  -> uppercase ignored? (Y/N)

Gate C - what depth 256 / 512 map to today:
  -> Phase 3 worth pursuing? (Y/N)

## Phase 2

Files changed:
Lint clean (Y/N):
Regression: <pytest summaries + any new warnings>

lowphy1 after: LUT / FF / BRAM / URAM / DSP =
lowphy0 after: LUT / FF / BRAM / URAM / DSP =
LUT as Shift Register delta:
LUT as Distributed RAM delta:
Acceptance criteria met (Y/N), with explanation for any miss:

## Phase 1 / Phase 3

Attempted (Y/N), results:
```
