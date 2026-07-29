import os
from collections import deque
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadWrite, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"

DATA_WIDTH = 8
DATA_PATH_LATENCY = 23


async def tick(dut):
    await RisingEdge(dut.clk)
    await ReadWrite()


async def drive_sample(dut, i_value, q_value):
    await FallingEdge(dut.clk)
    dut.data_i_in.value = i_value
    dut.data_q_in.value = q_value


@cocotb.test()
async def test_cfr_hardclipping_bypass_and_enabled_limit(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.ctrl_enable.value = 0
    dut.ctrl_threshold.value = 40
    dut.data_i_in.value = 0
    dut.data_q_in.value = 0
    for _ in range(6):
        await tick(dut)
    dut.rst.value = 0

    # Let the reset/control synchronizers and both CORDIC pipelines settle.
    for _ in range(40):
        await tick(dut)

    expected = deque([(0, 0)] * DATA_PATH_LATENCY)
    bypass_values = [(0, 0), (127, -128), (-97, 63), (18, -14), (-1, 1)]
    for i_value, q_value in bypass_values + [(0, 0)] * (DATA_PATH_LATENCY + 2):
        await drive_sample(dut, i_value, q_value)
        await tick(dut)
        expected_i, expected_q = expected.popleft()
        assert dut.data_i_out.value.to_signed() == expected_i
        assert dut.data_q_out.value.to_signed() == expected_q
        expected.append((i_value, q_value))

    dut.ctrl_enable.value = 1
    for _ in range(40):
        await drive_sample(dut, 0, 0)
        await tick(dut)

    # A sub-threshold sample is unchanged, while a horizontal high-amplitude
    # sample is constrained near the programmed magnitude.
    enabled_values = [(18, -14), (100, 0)]
    observed = []
    for i_value, q_value in enabled_values + [(0, 0)] * (DATA_PATH_LATENCY + 2):
        await drive_sample(dut, i_value, q_value)
        await tick(dut)
        observed.append(
            (dut.data_i_out.value.to_signed(), dut.data_q_out.value.to_signed())
        )

    below_threshold = observed[DATA_PATH_LATENCY]
    clipped = observed[DATA_PATH_LATENCY + 1]
    assert below_threshold == (18, -14)
    assert 32 <= clipped[0] <= 48
    assert abs(clipped[1]) <= 3


def test_cfr_hardclipping_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cfr_hardclipping",
        sources=resolve_flt(prj_path / "cfr_hardclipping.flt"),
        parameters={"DATA_WIDTH": DATA_WIDTH},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="cfr_hardclipping",
        hdl_toplevel_lang="verilog",
        test_module="test_cfr_hardclipping",
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
