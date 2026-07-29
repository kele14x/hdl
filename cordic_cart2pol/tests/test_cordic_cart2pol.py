import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadWrite, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

DATA_WIDTH = 8
ITERATIONS = 5
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


def signed(value, width):
    value &= (1 << width) - 1
    return value - (1 << width) if value & (1 << (width - 1)) else value


def cart2pol_model(xin, yin):
    width = DATA_WIDTH + 3
    x = signed(xin, DATA_WIDTH)
    y = signed(yin, DATA_WIDTH)
    z = (xin >> (DATA_WIDTH - 1)) & 1
    for index in range(ITERATIONS):
        direction = ((y < 0) ^ (x < 0))
        if direction:
            x, y = x - (y >> index), y + (x >> index)
        else:
            x, y = x + (y >> index), y - (x >> index)
        x = signed(x, width)
        y = signed(y, width)
        z = ((z & ((1 << ITERATIONS) - 1)) << 1) | int(not direction)
    r = -x if (z >> ITERATIONS) & 1 else x
    r = signed((r >> 1) + (r >> 3), width)
    r = signed(r - (r >> 5), width)
    return z, r


async def send_and_check(dut, xin, yin):
    expected = cart2pol_model(xin, yin)
    dut.xin.value = xin
    dut.yin.value = yin
    dut.ctrl_in.value = 1
    await RisingEdge(dut.clk)
    dut.ctrl_in.value = 0

    for _ in range(20):
        await RisingEdge(dut.clk)
        await ReadWrite()
        if int(dut.ctrl_out.value):
            assert int(dut.theta.value) == expected[0]
            assert dut.r.value.to_signed() == expected[1]
            return
    raise AssertionError("CORDIC output control did not arrive")


@cocotb.test()
async def test_cordic_cart2pol_matches_fixed_point_reference(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.xin.value = 0
    dut.yin.value = 0
    dut.ctrl_in.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    for vector in ((40, 0), (17, -31), (-23, 19)):
        await send_and_check(dut, *vector)


def test_cordic_cart2pol_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cordic_cart2pol",
        verilog_sources=resolve_flt(prj_path / "cordic_cart2pol.flt"),
        parameters={"DATA_WIDTH": DATA_WIDTH, "CTRL_WIDTH": 1, "ITERATIONS": ITERATIONS},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="cordic_cart2pol",
        hdl_toplevel_lang="verilog",
        test_module="test_cordic_cart2pol",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
