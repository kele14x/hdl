import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


async def tick(dut):
    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")


@cocotb.test()
async def test_pps_expand_reset_retrigger_and_wrap(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start(start_high=False))
    dut.rst.value = 1
    dut.pps_in.value = 0
    await tick(dut)
    assert int(dut.pps_out_pad.value) == 0

    dut.rst.value = 0
    await FallingEdge(dut.clk)
    dut.pps_in.value = 1
    await tick(dut)
    assert int(dut.pps_out_pad.value) == 0

    await FallingEdge(dut.clk)
    dut.pps_in.value = 0
    for _ in range(5):
        await tick(dut)
        assert int(dut.pps_out_pad.value) == 1

    # A retrigger restarts the extension counter without a low output gap.
    await FallingEdge(dut.clk)
    dut.pps_in.value = 1
    await tick(dut)
    assert int(dut.pps_out_pad.value) == 1
    await FallingEdge(dut.clk)
    dut.pps_in.value = 0

    # pps_ext counts from 1 through all 11-bit nonzero values; pps_reg adds
    # one output register of latency.
    for _ in range((1 << 11) - 1):
        await tick(dut)
        assert int(dut.pps_out_pad.value) == 1
    await tick(dut)
    assert int(dut.pps_out_pad.value) == 0


def test_pps_expand_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="pps_expand",
        sources=resolve_flt(prj_path / "pps_top.flt"),
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="pps_expand",
        hdl_toplevel_lang="verilog",
        test_module="test_pps_expand",
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
