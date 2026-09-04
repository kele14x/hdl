import os
from collections import deque
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

WIDTH = 8
DEPTH = 8
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"


@cocotb.test()
async def test_shift_ram_delay_and_clock_enable_hold(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    # Keep the pipeline enabled during reset with zero data so every stage
    # captures a defined value.
    dut.cen.value = 1
    dut.din.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    # Flush the read pipeline with zeros so four-state simulators start from
    # defined values instead of X.
    for _ in range(DEPTH):
        await RisingEdge(dut.clk)
        dut.cen.value = 1
        dut.din.value = 0
    assert int(dut.dout.value) == 0

    # Inputs are driven right after the sampling edge, so the DUT captures
    # them on the following edge, and a read taken right after a RisingEdge
    # shows the output from the previous edge. Together that makes the
    # observable delay DEPTH + 1 loop iterations.
    expected = deque([0] * (DEPTH + 1))
    for data in range(1, 20):
        await RisingEdge(dut.clk)
        dut.cen.value = 1
        dut.din.value = data
        assert int(dut.dout.value) == expected.popleft()
        expected.append(data)

    # One final enabled edge advances the pipeline once more; the read right
    # after that edge still shows the previous output.
    await RisingEdge(dut.clk)
    dut.cen.value = 0
    dut.din.value = 0xAA
    assert int(dut.dout.value) == expected.popleft()

    # The in-flight value from the last enabled edge becomes visible one edge
    # later, by which time cen=0 has frozen both the addresses and the output.
    await RisingEdge(dut.clk)
    held = int(dut.dout.value)
    assert held == expected.popleft()

    for data in (0x55, 0xCC, 0x33):
        await RisingEdge(dut.clk)
        dut.din.value = data
        assert int(dut.dout.value) == held

    # Resuming continues exactly where the frozen pipeline left off. After
    # re-enabling, wait one edge for the pipeline to advance and one more for
    # the read to observe it (reads trail the edge by one cycle).
    await RisingEdge(dut.clk)
    dut.cen.value = 1
    dut.din.value = 20
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert int(dut.dout.value) == expected.popleft()


def test_shift_ram_runner():
    runner = get_runner(SIM)
    run_dir = prj_path / "sim_build" / "shift_ram"
    runner.build(
        hdl_toplevel="shift_ram",
        sources=resolve_flt(prj_path / "shift_ram.flt"),
        parameters={"WIDTH": WIDTH, "DEPTH": DEPTH},
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="shift_ram",
        hdl_toplevel_lang="verilog",
        test_module="test_shift_ram",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
