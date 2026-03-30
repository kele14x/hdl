# Copilot Instructions for `hdl`

## Build, test, and lint commands

This repository has no single top-level build/test target; workflows are mostly module-local.

### Cocotb + Makefile.sim modules

Common pattern (examples: `adder/tests`, `mult/tests`, `nco/tests`, `lfsr/tests`, `fft_radix2/tests`, `cmult/tests`, `fir/tests`, `fir2/tests`, `dummy_source/tests`):

```bash
cd <module>/tests
make
```

Most of these default to `SIM=questa` and pass parameters through Make variables.

Useful variants:

```bash
cd adder/tests && make SIM=icarus A_WIDTH=8 B_WIDTH=8 P_WIDTH=9 SRA_BITS=0
cd nco/tests && make SIM=questa PHASE_FRACTION_WIDTH=20 PHASE_ENTRIES=3072 DATA_WIDTH=16
```

Single-test selection (when debugging a specific cocotb test in a module):

```bash
cd adder/tests && make TESTCASE=test_adder_basic
```

### Python cocotb runner style (`tb/test_*.py`)

Many modules keep tests in `tb/test_*.py` with a `test_*_runner()` entry point (for example `nco/tb/test_nco.py`, `ecpri/tb/test_ecpri.py`):

```bash
python nco/tb/test_nco.py
python ecpri/tb/test_ecpri.py
```

Single test function via pytest selection:

```bash
pytest nco/tb/test_nco.py -k test_nco
```

### Xilinx xsim flows

Examples:

```bash
make -C axi4l_ipif/tb all
make -C axi4l_ipif/tb wave
make -C fifo_srl sim
```

### Lint

No repository-wide lint command/config was found in the current tree.

## High-level architecture

This is a multi-IP HDL monorepo. Most leaf IPs are self-contained blocks with reusable interfaces (`rtl/` or `src/`), local testbenches (`tb/`), and often module-local cocotb Makefiles (`tests/`).

Big-picture composition is radio/transport oriented:

- Timing and synchronization come from `pps_top`/`timer`/`symbol_timer`.
- Packetization and transport are handled by `ecpri`, `coe`, `fh`, `ptp`, `eth_*`, and `oran_slave`.
- Baseband and DSP blocks include `fft*`, `cordic*`, `nco`, `fir*`, `gain`, `phase_comp`, `prach`, `pdxch`, `puxch`, `bfp_*`, and others.
- Utility primitives (`cdc`, `fifo_*`, `ram`, `srl`, `util`) are shared broadly across higher-level blocks.

System-level tops (for example `oran_slave/src/oran_top.sv`, `lowphy/src/lowphy_top.sv`, `pps_top/src/pps_top.sv`) connect AXI-Lite control with AXI-Stream and timer/data-plane paths, typically through generated-channel arrays and per-block control/status register modules.

## Key conventions in this codebase

- **Module layout is feature-local**: expect `<block>/{rtl|src}`, `<block>/tb`, and often `<block>/tests`.
- **Control plane convention**: AXI4-Lite register modules named `*_regs.v` are common and instantiated by top/wrapper modules (`*_top.sv`, `*_wrapper.v`).
- **Data plane convention**: AXI-Stream naming is consistent (`*_tdata`, `*_tkeep`, `*_tvalid`, `*_tlast`, `*_tready`) with explicit clock/reset domains (`clk/rst`, `eth_clk/eth_rst`, `s_axi_aclk/s_axi_aresetn`).
- **Verification is mixed-style**:
  - cocotb for many block-level tests (Makefile.sim and/or Python runner API),
  - UVM/SystemVerilog environments under `uvm/` and parts of `oran_slave/tb`.
- **Simulator defaults skew to Questa** in cocotb Makefiles/test runners; some flows explicitly target Xilinx `xsim`.
- **Cross-module dependencies are explicit in tests**: test source lists frequently include shared primitives from sibling directories instead of relying on a central project file.
- **Some cocotb tests depend on MATLAB Engine** (for golden models), e.g. in `adder/tests/test_adder.py` and `nco/tests/test_nco.py`.
