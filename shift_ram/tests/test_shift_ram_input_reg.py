import os
from collections import deque
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

WIDTH = 8
DEPTH = 8
OUTPUT_DELAY = DEPTH - 1
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"


@cocotb.test()
async def test_shift_ram_input_register_has_configured_enabled_cycle_delay(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.cen.value = 1
    dut.din.value = 0
    # Keep the memory write port enabled during reset so the first location is
    # deterministically initialized before the registered input stream begins.
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    # With INPUT_REG enabled, the input sample is written one clock later and
    # the adjusted circular read address produces an observable DEPTH-1 delay.
    expected = deque([0] * OUTPUT_DELAY)
    for value in range(1, 13):
        await FallingEdge(dut.clk)
        dut.cen.value = 1
        dut.din.value = value
        await RisingEdge(dut.clk)
        await ReadOnly()
        assert int(dut.dout.value) == expected.popleft()
        expected.append(value)

    await FallingEdge(dut.clk)
    dut.cen.value = 0
    dut.din.value = 0xEE
    held = int(dut.dout.value)
    await ClockCycles(dut.clk, 3)
    assert int(dut.dout.value) == held

    await FallingEdge(dut.clk)
    dut.cen.value = 1
    dut.din.value = 13
    await RisingEdge(dut.clk)
    await ReadOnly()
    assert int(dut.dout.value) == expected.popleft()


def test_shift_ram_input_reg_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="shift_ram",
        verilog_sources=resolve_flt(prj_path / "shift_ram.flt"),
        parameters={"WIDTH": WIDTH, "DEPTH": DEPTH, "INPUT_REG": 1},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="shift_ram",
        hdl_toplevel_lang="verilog",
        test_module="test_shift_ram_input_reg",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
