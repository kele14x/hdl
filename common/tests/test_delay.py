import os
from collections import deque
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadWrite, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

WIDTH = 8
DEPTH = 4
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


@cocotb.test()
async def test_delay_reset_data_delay_and_clock_enable(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.cen.value = 0
    dut.din.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    expected = deque([0] * DEPTH)
    dut.cen.value = 1
    for value in (3, 7, 11, 19, 23, 29):
        dut.din.value = value
        await RisingEdge(dut.clk)
        await ReadWrite()
        assert int(dut.dout.value) == expected.popleft()
        expected.append(value)

    await FallingEdge(dut.clk)
    held = int(dut.dout.value)
    dut.cen.value = 0
    dut.din.value = 0xFF
    await ClockCycles(dut.clk, 3)
    assert int(dut.dout.value) == held


def test_delay_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="delay",
        verilog_sources=resolve_flt(prj_path / "common.flt"),
        parameters={"WIDTH": WIDTH, "DEPTH": DEPTH, "INIT": 1},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="delay",
        hdl_toplevel_lang="verilog",
        test_module="test_delay",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
