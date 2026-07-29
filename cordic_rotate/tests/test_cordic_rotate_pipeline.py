import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

DATA_WIDTH = 8
CTRL_WIDTH = 3
ITERATIONS = 5
COMPENSATION_SCALING = 1
LATENCY = ITERATIONS + 2 * COMPENSATION_SCALING + 1
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


def signed(value, width):
    value &= (1 << width) - 1
    return value - (1 << width) if value & (1 << (width - 1)) else value


def rotate_model(xin, yin, theta):
    width = DATA_WIDTH + 2
    x = signed(xin, DATA_WIDTH)
    y = signed(yin, DATA_WIDTH)
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


@cocotb.test()
async def test_cordic_rotate_keeps_data_aligned_with_back_to_back_controls(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.xin.value = 0
    dut.yin.value = 0
    dut.theta.value = 0
    dut.ctrl_in.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    vectors = [
        (40, 0, 0b000000),
        (32, -11, 0b00101),
        (-20, 17, 0b11010),
        (-128, 31, 0b11111),
        (7, -127, 0b10001),
    ]
    expected = {marker: rotate_model(*vector) for marker, vector in enumerate(vectors, 1)}
    sent_cycle = {}
    observed = {}

    for cycle in range(LATENCY + len(vectors) + 3):
        await FallingEdge(dut.clk)
        if cycle < len(vectors):
            xin, yin, theta = vectors[cycle]
            dut.xin.value = xin
            dut.yin.value = yin
            dut.theta.value = theta
            dut.ctrl_in.value = cycle + 1
        else:
            dut.ctrl_in.value = 0

        await RisingEdge(dut.clk)
        await ReadOnly()
        if cycle < len(vectors):
            sent_cycle[cycle + 1] = cycle
        marker = int(dut.ctrl_out.value)
        if marker:
            assert marker in expected
            assert marker not in observed
            observed[marker] = (dut.xout.value.to_signed(), dut.yout.value.to_signed())
            assert cycle == sent_cycle[marker] + LATENCY - 1

    assert observed == expected


def test_cordic_rotate_pipeline_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cordic_rotate",
        verilog_sources=resolve_flt(prj_path / "cordic_rotate.flt"),
        parameters={
            "DATA_WIDTH": DATA_WIDTH,
            "CTRL_WIDTH": CTRL_WIDTH,
            "ITERATIONS": ITERATIONS,
            "COMPENSATION_SCALING": COMPENSATION_SCALING,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="cordic_rotate",
        hdl_toplevel_lang="verilog",
        test_module="test_cordic_rotate_pipeline",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
