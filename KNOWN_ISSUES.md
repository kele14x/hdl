# Known Issues

Issues reproduced locally or reported from integration runs. Each entry
records the symptom, the evidence gathered so far, and the next step.

## PDXCH: end-to-end RTL-vs-float RMS tests fail (7 tests)

**Status:** investigation pending. Confirmed pre-existing on `HEAD`
(commit 3505059), unrelated to the readout decompressor rework
(commit 0c7f529).

### Symptom

With Questa Altera Starter FPGA Edition 2025.3 + cocotb 5.x
(`SIM=questa pytest pdxch/tests/` → 21 passed, 7 failed), these tests fail:

- `test_pdxch.test_nr100m_4channel_3cc_waveform_and_spectrum`
  ("RTL RMS error against the floating-point reference exceeds 5 LSBs",
  RMS ≈ 3650, max |I/Q error| ≈ 10 000 on every CC/ant/sym)
- `test_pdxch_config_matrix` ×4
  (`test_configured_chain_matches_reference`, same RMS class)
- `test_pdxch_fdv_top_lane`
  (`test_gearbox_fdv_ram_readout_keeps_antenna_identity`:
  `pre_conv channel N best matches antenna M at offset ±8, RMS 3616`)
- `test_pdxch_lte`
  (`test_lte20_full_block_full_fft_waveform_and_dc_null`)

### Evidence

- Failure is identical on `HEAD`: same RMS numbers (e.g. 3616.287),
  same alignment offset, nearly identical simulation timestamps.
- The errors are large (RMS ≈ 3650, ~5x the QPSK+1/-1 LSB scale), while
  best-match offsets wander within ±8 — the captured streams do not align
  with the float reference at all; this is not a 1-LSB rounding or delay
  class problem.
- Failures occur at the converter/FFT stage captures; the FDV RAM direct
  readout path and all unit-level tests (readout, conv, fft, block2stream,
  gearbox) pass.

### Hypotheses (in order of likelihood)

1. Questa FSE (Altera Starter Edition) simulates some construct
   differently than the commercial edition used in CI.
2. Pre-existing RTL-vs-reference mismatch in the integrated chain
   (e.g. frequency-converter/FFT gain or phase), independent of the
   readout rework.

### Next step

Confirm on the commercial Questa / CI environment. If it reproduces
there, bisect the integrated-FFT path against `pdxch_reference.py`.