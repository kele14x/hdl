# Low-PHY cocotb framework

The tests are split by verification cost so a failure points to a small area
of the design:

1. `test_lowphy_regs.py` compiles only `lowphy_regs.v`. It checks AXI-Lite
   protocol behavior, reset values, writable field masks, control outputs, and
   hardware status inputs. This is the default fast regression layer.
2. `test_lowphy_smoke.py` compiles `lowphy.flt` and checks the control path
   through a complete `lowphy0` or `lowphy1` top. It starts the 100 MHz AXI,
   400 MHz internal-bus, and approximately 491.52 MHz radio clocks, sequences every reset,
   initializes all inputs, and leaves output streams ready.
3. Future datapath scenarios should use the same `LowphyTB` environment and
   the shared UVM-style agents in `common/tb`. Keep numerical models outside
   the driver, and compare monitor transactions in a scoreboard rather than
   cycle by cycle; the integrated datapath contains buffering and clock
   crossings.

## Running

From the repository root:

```sh
uv run python -m pytest lowphy/tests/test_lowphy_regs.py -q
uv run python -m pytest lowphy/tests/test_lowphy_smoke.py -q
LOWPHY_TOP=lowphy1 uv run python -m pytest lowphy/tests/test_lowphy_smoke.py -q
SIM=questa uv run python -m pytest lowphy/tests/test_lowphy_regs.py -q
```

`GUI=true` opens the selected simulator GUI. Use `WAVES=true` to enable wave
capture and `REBUILD=true` to force recompilation. Build products are kept
under `lowphy/sim_build/<simulator>/<top>`.

## Adding datapath coverage

Build each scenario from four independent pieces:

- a source driver for one logical interface (UL AXI-Stream, deframer data,
  beam ID, timing, or PRACH control);
- a sink monitor that records only accepted transfers (`valid && ready`);
- a pure Python reference model that does not access DUT signals;
- a scoreboard with explicit tolerance for fixed-point DSP comparisons and a
  bounded timeout for missing output.

Start with one carrier and one antenna, then add multi-carrier routing,
backpressure, reset during traffic, and randomized gaps. Use a fixed random
seed in CI and print it on failure so every randomized failure is reproducible.
