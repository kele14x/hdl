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


def pol2cart_model(radius, theta):
    width = DATA_WIDTH + 3
    x = radius
    y = 0
    for index in range(ITERATIONS):
        direction = (theta >> (ITERATIONS - index - 1)) & 1
        if direction:
            x, y = x - (y >> index), y + (x >> index)
        else:
            x, y = x + (y >> index), y - (x >> index)
        x = signed(x, width)
        y = signed(y, width)
    if (theta >> ITERATIONS) & 1:
        x, y = -x, -y
    x = signed((x >> 1) + (x >> 3), width)
    y = signed((y >> 1) + (y >> 3), width)
    x = signed(x - (x >> 5), width)
    y = signed(y - (y >> 5), width)
    return x, y


async def send_and_check(dut, radius, theta):
    expected = pol2cart_model(radius, theta)
    dut.r.value = radius
    dut.theta.value = theta
    dut.ctrl_in.value = 1
    await RisingEdge(dut.clk)
    dut.ctrl_in.value = 0

    for _ in range(20):
        await RisingEdge(dut.clk)
        await ReadWrite()
        if int(dut.ctrl_out.value):
            actual = (dut.xout.value.to_signed(), dut.yout.value.to_signed())
            assert actual == expected
            return
    raise AssertionError("CORDIC output control did not arrive")


@cocotb.test()
async def test_cordic_pol2cart_matches_fixed_point_reference(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.r.value = 0
    dut.theta.value = 0
    dut.ctrl_in.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    for vector in ((40, 0b000000), (31, 0b00101), (29, 0b11010)):
        await send_and_check(dut, *vector)


def test_cordic_pol2cart_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cordic_pol2cart",
        verilog_sources=resolve_flt(prj_path / "cordic_pol2cart.flt"),
        parameters={"DATA_WIDTH": DATA_WIDTH, "CTRL_WIDTH": 1, "ITERATIONS": ITERATIONS},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="cordic_pol2cart",
        hdl_toplevel_lang="verilog",
        test_module="test_cordic_pol2cart",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
