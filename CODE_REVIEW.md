# Code Review Notes

Review of the full `hdl` monorepo (40 IP modules, 221 RTL files, 92 test files).
Date: 2026-08-21.

## Overall

Strong health. Git tree clean, no committed junk, no CRLF, `ruff format` clean,
Verilator lint clean on `cdc`, `mixer`, `axis_reg`. AGENTS.md conventions are
followed near-universally (`timescale` + `default_nettype` wrapping, ANSI ports,
`parameter int`/`localparam int`, 41 `drc_check` blocks, module-scope concurrent
assertions). No X-assignments, latches, or combinational loops found.

## High priority

1. `fft/rtl/fft.sv:108-110` — latent saturation bug. `saturate()` hardcodes
   `16'h8000` / `16'h7FFF` regardless of `DATA_WIDTH`, yet the DRC (line 68)
   allows 8-32 bits. For `DATA_WIDTH=8` the truncated values become `8'h00` /
   `8'hFF` (0 and -1) instead of -128 / +127. Correct only at the default 16.
   Should be width-parameterized, e.g. `{1'b1, {(DATA_WIDTH-1){1'b0}}}` /
   `{{(DATA_WIDTH-1){1'b1}}, 1'b0}`. Related: `fft.sv:211-227` hardcode
   1k/2k/4k latency constants.

2. `oran_slave/` and `ptp/` have no tests at all despite having a Makefile and
   `.flt` filelist. Largest coverage gap (oran_slave is 36 RTL files).

3. `make lint` fails on `fft/` — 2x `UNUSEDSIGNAL` in the shared
   `ram/rtl/ram_sdp_uram_8k36.sv:25-26` (`physical_dina` / `physical_wea` only
   used under `RAM_USE_XPM`). Pre-documented in `KNOWN_ISSUES.md` section 1.

4. `KNOWN_ISSUES.md` section 4 is stale — it lists 17 files for deprecated
   `verilog_sources=`, but 4 (`cdc/tests/test_cdc.py`,
   `cdc/tests/test_cdc_handshake_corner.py`,
   `cdc/tests/test_cdc_pulse_reset_corner.py`) no longer exist. Current count
   is 13.

## Medium

5. `uv run ruff check .` fails with 88 errors across 29 test files — mostly
   auto-fixable: `I001` x20 (import sort), `PLR2044` x21 (empty comments),
   `PLW1508` x17 (`os.environ.get` int default), `EXE001` x8 (shebang not
   executable), `PIE808` x6, `F401` x5 (unused imports), `RUF059` x4.
   `hdl_tools/` and root `tests/` are clean; only shared-code finding is
   `common/tests/libbfp.py` (4).

6. Deprecated/banned cocotb API beyond the documented `verilog_sources=`:
   - 6 files use `units=` instead of `unit=` (coe, power_meter, bfp_comp,
     pdxch_fdv_buffer_write, ecpri x2).
   - 20 files use `FallingEdge` / `ReadOnly` / `ReadWrite` (banned) — ram x8,
     axi4l_bram, ecpri_framer_trans, eth_pkt_fifo, fft x2, pps_top x2,
     prach_stream2block, pulse_delay, shift_ram diag, skid_buffer,
     timer_syncer.
   - 10 files create `Clock` without `unit=` (mult, fh framer_padding, mixer,
     cmult, adder, nco, phase_comp, dds_lut, ecpri framer_padding, common).
   - `common/tb/*.py` uses `.kill()` instead of `.cancel()` (memory.py:180,
     timing.py:130,221, fifo.py:227, dsp.py:188,261).
   - 3 files use unseeded RNG (`coe`, `ecpri/test_ecpri.py`,
     `ecpri/test_ecpri_framer.py`) — violates the reproducible-seed rule.

7. Agent duplication:
   - `common/tb/base.py` is a byte-for-byte copy of `hdl_tools/tb_base.py`
     (parallel `AgentMode` / `AnalysisPort` definitions).
   - `skid_buffer/tests/test_skid_buffer.py` hand-rolls `SAgent` / `MAgent`
     instead of using `hdl_tools.axis` (as `axis_reg` does).

## Low / hygiene

8. `common/` has tests but no Makefile, so root `make test` skips it.

9. Build-dir conventions:
   - `puxch` / `lowphy` build into `sim_build/<SIM>/<...>` vs the
     `sim_build/<case>/` convention.
   - Several runners (mixer, ecpri, timer, nco, bfp_comp, power_meter,
     pulse_delay, phase_comp, coe, fh) omit `build_dir` / `test_dir` entirely.

10. `fh/fh.flt` references `../ecpri/rtl/ecpri_pkg.sv` directly instead of the
    recursive `.flt` convention used everywhere else. `nco/nco.flt` lists its
    own source before its `.flt` refs (opposite ordering).

11. 8 test files have a shebang but missing executable bit (EXE001):
    lowphy/test_lowphy_smoke, pdxch x6 (axis_array, config_matrix, fdv_top_lane,
    lte, phase_comp_alignment, reference), skid_buffer.

12. `.ruff_cache/` missing from root `.gitignore` (only self-ignored via its
    internal `.gitignore`).

13. ~34 TODOs / 2 FIXMEs in RTL comments, concentrated in `oran_slave/rtl/`
    (16) and `ecpri/rtl/` (6). `ecpri/rtl/ecpri_statistics.sv:238,243` are
    `FIXME: not implemented`. Notable: `prach/rtl/prach_hb2.sv:140` and
    `prach_hb4.sv:316` ("saturate"), `nco/rtl/nco.sv:35` (bare `TODO:`).

## Minor style deviations

- `nco/rtl/nco.sv:44-46` — untyped parameters (`NUM_PARALLEL`,
  `PHASE_INTEGER_WIDTH`, `PHASE_FRACTION_WIDTH`).
- Missing `drc_check` block in `mixer/rtl/mixer.sv`, `axis_reg.sv`,
  `skid_buffer.sv` (small modules; inconsistent with the rest).
- `oran_slave/rtl/oran_pkg.sv` — package without `default_nettype` (acceptable
  for a package).
- Widespread plain `always @(posedge)` instead of `always_ff` in legacy
  Cisco-style blocks (cdc, oran_statistics, ecpri, coe, ram, common).