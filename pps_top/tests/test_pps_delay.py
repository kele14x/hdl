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
async def test_pps_delay_offset_is_measured_from_sync(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start(start_high=False))
    dut.rst.value = 1
    dut.sync_in.value = 0
    dut.ctrl_offset.value = 3
    await tick(dut)
    assert int(dut.strobe_10ms.value) == 0

    dut.rst.value = 0
    await FallingEdge(dut.clk)
    dut.sync_in.value = 1
    await tick(dut)
    assert int(dut.strobe_10ms.value) == 0

    await FallingEdge(dut.clk)
    dut.sync_in.value = 0
    for count in range(1, 7):
        await tick(dut)
        assert int(dut.strobe_10ms.value) == int(count == 4)

    # A fresh sync restarts the offset measurement rather than producing an
    # extra strobe from the prior count.
    await FallingEdge(dut.clk)
    dut.sync_in.value = 1
    await tick(dut)
    assert int(dut.strobe_10ms.value) == 0


def test_pps_delay_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="pps_delay",
        sources=resolve_flt(prj_path / "pps_top.flt"),
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="pps_delay",
        hdl_toplevel_lang="verilog",
        test_module="test_pps_delay",
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
