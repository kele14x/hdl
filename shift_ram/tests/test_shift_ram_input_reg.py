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
OUTPUT_DELAY = DEPTH + 1
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"


@cocotb.test()
async def test_shift_ram_input_register_has_configured_enabled_cycle_delay(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    # Keep the pipeline enabled during reset with zero data so every stage
    # and the first memory location are deterministically initialized.
    dut.cen.value = 1
    dut.din.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    # With INPUT_REG enabled the input sample is registered before the write;
    # the adjusted circular read address keeps the DUT delay at DEPTH enabled
    # cycles. Inputs are driven right after the sampling edge, so the DUT
    # captures them on the following edge, and a read taken right after a
    # RisingEdge shows the previous edge's output, giving an observable delay
    # of DEPTH + 1 loop iterations.
    expected = deque([0] * OUTPUT_DELAY)
    for value in range(1, 13):
        await RisingEdge(dut.clk)
        dut.cen.value = 1
        dut.din.value = value
        assert int(dut.dout.value) == expected.popleft()
        expected.append(value)

    # One final enabled edge advances the pipeline once more; the read right
    # after that edge still shows the previous output.
    await RisingEdge(dut.clk)
    dut.cen.value = 0
    dut.din.value = 0xEE
    assert int(dut.dout.value) == expected.popleft()

    # The in-flight value from the last enabled edge becomes visible one edge
    # later, by which time cen=0 has frozen the output.
    await RisingEdge(dut.clk)
    held = int(dut.dout.value)
    assert held == expected.popleft()

    for _ in range(3):
        await RisingEdge(dut.clk)
        assert int(dut.dout.value) == held

    # Resuming continues exactly where the frozen pipeline left off. After
    # re-enabling, wait one edge for the pipeline to advance and one more for
    # the read to observe it (reads trail the edge by one cycle).
    await RisingEdge(dut.clk)
    dut.cen.value = 1
    dut.din.value = 13
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert int(dut.dout.value) == expected.popleft()


def test_shift_ram_input_reg_runner():
    runner = get_runner(SIM)
    run_dir = prj_path / "sim_build" / "shift_ram_input_reg"
    runner.build(
        hdl_toplevel="shift_ram",
        sources=resolve_flt(prj_path / "shift_ram.flt"),
        parameters={"WIDTH": WIDTH, "DEPTH": DEPTH, "INPUT_REG": 1},
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="shift_ram",
        hdl_toplevel_lang="verilog",
        test_module="test_shift_ram_input_reg",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
