#!/usr/bin/env python3

import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"

CASES = [
    {"name": "depth32", "params": {"WIDTH": 8, "DEPTH": 32}},
    {"name": "depth64", "params": {"WIDTH": 8, "DEPTH": 64}},
    {"name": "depth128", "params": {"WIDTH": 8, "DEPTH": 128}},
]


@cocotb.test()
async def test_delay_lutram_data_delay_and_clock_enable(dut):
    depth = int(os.environ.get("DEPTH", "32"))
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.cen.value = 0
    dut.din.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    # The LUTRAM delay has the same event-based latency as delay: DEPTH
    # enabled edges separate an input sample from its output.
    dut.cen.value = 1
    values = list(range(1, 7))
    seen = []
    for value in values + [0] * depth:
        dut.din.value = value
        await RisingEdge(dut.clk)
        seen.append(int(dut.dout.value))
    assert seen == [0] * depth + values

    # Disabled events must not advance either the pointer or the output.
    dut.cen.value = 0
    dut.din.value = 0xAA
    await RisingEdge(dut.clk)
    held = int(dut.dout.value)
    await ClockCycles(dut.clk, 3)
    assert int(dut.dout.value) == held


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_delay_lutram_runner(case):
    parameters = case["params"]
    run_dir = prj_path / "sim_build" / "delay_lutram" / case["name"]
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="delay_lutram",
        sources=resolve_flt(prj_path / "common.flt"),
        parameters=parameters,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="delay_lutram",
        hdl_toplevel_lang="verilog",
        test_module="test_delay_lutram",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
        extra_env={key: str(value) for key, value in parameters.items()},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
