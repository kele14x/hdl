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
DEPTH = 8
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


async def reset(dut):
    dut.rst.value = 1
    dut.cen.value = 0
    dut.din.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_shift_ram_delay_and_clock_enable_hold(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)
    assert int(dut.dout.value) == 0

    # The RAM read pipeline and output register maintain the configured delay
    # in enabled transfer clocks.
    expected = deque([0] * DEPTH)
    dut.cen.value = 1
    for data in range(1, 20):
        dut.din.value = data
        await RisingEdge(dut.clk)
        await ReadWrite()
        assert int(dut.dout.value) == expected.popleft()
        expected.append(data)

    await FallingEdge(dut.clk)
    held = int(dut.dout.value)
    dut.cen.value = 0
    for data in (0xAA, 0x55, 0xCC):
        dut.din.value = data
        await RisingEdge(dut.clk)
        await ReadWrite()
        assert int(dut.dout.value) == held

    # Resume with the last enabled input. Disabled cycles must not advance
    # either address or the output pipeline.
    await FallingEdge(dut.clk)
    dut.cen.value = 1
    dut.din.value = 20
    await RisingEdge(dut.clk)
    await ReadWrite()
    assert int(dut.dout.value) == expected.popleft()


def test_shift_ram_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="shift_ram",
        verilog_sources=resolve_flt(prj_path / "shift_ram.flt"),
        parameters={"WIDTH": WIDTH, "DEPTH": DEPTH, "INPUT_REG": 0},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="shift_ram",
        hdl_toplevel_lang="verilog",
        test_module="test_shift_ram",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
