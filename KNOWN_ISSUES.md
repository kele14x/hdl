# Known Issues

Pre-existing warnings and errors found while refactoring `axis_reg` to wrap
`skid_buffer` (2026-08-11). None of these are caused by that refactor: after
the change, `axis_reg` and `skid_buffer` both lint clean
(`verilator --lint-only -Wall`) and their tests pass. They are collected here
so they can be cleared later.

## 1. puxch — Verilator lint warnings (16, `UNUSEDSIGNAL`)

`make lint` in `puxch/` exits with `%Error: Exiting due to 16 warning(s)`.
All 16 are `UNUSEDSIGNAL`. Confirmed present before the refactor (verified by
re-linting with the change stashed).

| File | Line | Signal |
| ---- | ---- | ------ |
| puxch/rtl/puxch_top.sv | 74 | `dout_last` |
| puxch/rtl/puxch_top.sv | 83 | `bfp_m_axis_tuser` |
| puxch/rtl/puxch_buffer.sv | 11 | `rst` |
| puxch/rtl/puxch_buffer.sv | 16 | `din_sl` |
| puxch/rtl/puxch_buffer.sv | 32 | `m_fram_data_req` (unused bits `[32:25,6:4]`) |
| puxch/rtl/puxch_buffer.sv | 54 | `fifo_full` |
| puxch/rtl/puxch_buffer.sv | 55 | `fifo_err_discard` |
| puxch/rtl/puxch_buffer.sv | 94 | `fifo_m_axis_tuser` |
| puxch/rtl/puxch_buffer.sv | 95 | `reg_m_axis_tuser` |
| puxch/rtl/puxch_resync.sv | 14 | `s_axis_tuser` |
| puxch/rtl/puxch_resync.sv | 15 | `s_axis_tlast` |
| puxch/rtl/puxch_resync.sv | 16 | `s_axis_tvalid` |
| puxch/rtl/puxch_resync.sv | 42 | `ctrl_bist_s` |
| puxch/rtl/puxch_resync.sv | 45 | `stat_resync` |
| ram/rtl/ram_sdp_uram_8k36.sv | 25 | `physical_dina` |
| ram/rtl/ram_sdp_uram_8k36.sv | 26 | `physical_wea` |

Note: the last two are in the shared `ram` primitive, so they surface in any
module that instantiates `ram_sdp_uram_8k36`.

## 2. puxch — `test_puxch_buffer` build error (`WIDTHTRUNC`)

`SIM=verilator pytest puxch/tests/test_puxch_buffer.py` fails during Verilator
elaboration. Pre-existing: it reproduces on the pre-refactor tree.

- `puxch/rtl/puxch_buffer.sv:335` — `%Warning-WIDTHTRUNC: Bit extraction of
  array[1:0] requires 1 bit index, not 2 bits.`
  ```systemverilog
  rd_bank <= s_ul_sym_num[fifo_req_cc[1:0]][0];
  ```
  Suggested fix: index with a 1-bit slice (e.g. `s_ul_sym_num[fifo_req_cc[0]]`)
  or widen the indexed dimension, matching the intended bank select.

## 3. skid_buffer — ruff findings in `tests/test_skid_buffer.py` (3)

Pre-existing; `axis_reg/tests/test_axis_reg.py` is clean for comparison.

- Line 1 — `EXE001`: shebang present but file not executable. Per AGENTS.md,
  keep the shebang and set the executable bit (`chmod +x`).
- Line 9 — `I001`: import block unsorted (auto-fixable: `ruff check --fix`).
- Line 27 — `PLW1508`: `os.environ.get("DATA_WIDTH", 8)` default must be a
  string: `os.environ.get("DATA_WIDTH", "8")`.

## 4. Repo-wide — deprecated `verilog_sources=` in cocotb runners

AGENTS.md requires the language-agnostic `sources=` argument. `axis_reg` and
`skid_buffer` are clean; the following 17 test files still pass
`verilog_sources=` to `runner.build()` and each emits a `DeprecationWarning`:

- bfp_comp/tests/test_bfp_comp.py
- cdc/tests/test_cdc.py
- cdc/tests/test_cdc_handshake_corner.py
- cdc/tests/test_cdc_pulse_reset_corner.py
- coe/tests/test_coe.py
- ecpri/tests/test_ecpri.py
- ecpri/tests/test_ecpri_deframer.py
- ecpri/tests/test_ecpri_framer.py
- ecpri/tests/test_ecpri_framer_padding.py
- fh/tests/test_fh_framer_padding.py
- mixer/tests/test_mixer.py
- nco/tests/test_nco.py
- phase_comp/tests/test_phase_comp.py
- power_meter/tests/test_power_meter.py
- pulse_delay/tests/test_pulse_delay.py
- timer/tests/test_timer.py

## 5. puxch_buffer — stall-based readout vs. ping-pong bank overwrite (open)

Introduced by replacing the 2048-deep store-and-forward output FIFO with a
stall-based readout (branch `puxch-buffer-stall-readout`). The readout now
paces the BRAM reads with the downstream `tready`, so the read bank stays
occupied for the whole burst duration instead of being drained into the FIFO
within ~1650 cycles.

If downstream backpressure holds longer than ~2 symbol boundaries, the write
side (fixed rate, not backpressurable) toggles `wr_bank` back to the bank
still being read and overwrites it, so the buffer silently ships mixed
old/new data. Queued requests in the request FIFO go stale the same way.
Budget: worst-case burst 275 PRB x 6 = 1650 words (~5.4 us at ~307 MHz);
hazard opens at sustained `tready` duty below ~15% (30 kHz SCS, ~35.7 us
symbols) or ~8% (15 kHz SCS).

Candidate fix: watchdog using `s_ul_sym_num` (already in the `clk_eth_xran`
domain) — abort the burst if still `rd_busy` 2 symbol ticks after accept,
plus an error counter. Open question: abort semantics. The downstream
(AMD ORAN IF IP) requires an AXIS packet response for every uplink request
per its document, and it is unknown how it handles a truncated or dropped
response, so the abort behavior (forced `tlast` truncation vs. discard) is
deferred until that is clarified.
