import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

WIDTH = 8
DEPTH = 4
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"

CASES = [
    {"name": "srl", "use_reg": 0},
    {"name": "register", "use_reg": 1},
]


@cocotb.test()
async def test_delay_reset_data_delay_and_clock_enable(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.cen.value = 0
    dut.din.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    # Enable the delay line and feed one value per clock. The taps are always
    # initialized to 0, providing the leading zeros for both implementations;
    # the SRL implementation intentionally does not use rst because SRLs have
    # no reset input.
    dut.cen.value = 1
    values = [3, 7, 11, 19, 23, 29]
    stream = values + [0] * DEPTH
    seen = []
    for value in stream:
        dut.din.value = value
        await RisingEdge(dut.clk)
        seen.append(int(dut.dout.value))
    assert seen == [0] * DEPTH + values

    # With cen deasserted the output must hold (din must not shift through).
    # Deassert cen, let it take effect, then sample the frozen output and
    # verify it stays constant.
    dut.cen.value = 0
    dut.din.value = 0xFF
    await RisingEdge(dut.clk)
    held = int(dut.dout.value)
    await ClockCycles(dut.clk, 3)
    assert int(dut.dout.value) == held


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_delay_runner(case):
    run_dir = prj_path / "sim_build" / "delay" / case["name"]
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="delay",
        sources=resolve_flt(prj_path / "common.flt"),
        parameters={
            "WIDTH": WIDTH,
            "DEPTH": DEPTH,
            "USE_REG": case["use_reg"],
        },
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="delay",
        hdl_toplevel_lang="verilog",
        test_module="test_delay",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
