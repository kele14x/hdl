import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb_tools.runner import get_runner
from cocotb.utils import get_sim_time
from tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge

prj_path = Path(__file__).resolve().parent.parent


ASYNC = int(os.environ.get("ASYNC", 0))
MODE = int(os.environ.get("MODE", 1))
FREQ = int(os.environ.get("FREQ", 1))

GUI = os.environ.get("GUI", "false").lower() == "true"

SIM = os.environ.get("SIM", "verilator")


async def reset(dut):
    # Reset the DUT
    dut.rst.value = 1
    dut.sync.value = 0

    dut.ctrl_delay.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    frame_ticks = 38400 * FREQ

    async def wait_for_frame_start(limit):
        for ticks in range(1, limit + 1):
            await RisingEdge(dut.clk)
            await ReadOnly()
            if int(dut.start_of_frame.value):
                return get_sim_time(unit="ns")
        raise AssertionError(f"no start_of_frame pulse within {limit} clock cycles")

    await ClockCycles(dut.clk, 100)
    dut.sync.value = 1
    first_frame_time = await wait_for_frame_start(1000)
    await RisingEdge(dut.clk)
    dut.sync.value = 0

    # The external sync starts a frame; with AUTO enabled, the next one is
    # generated precisely one frame later. This ports the legacy SV bench's
    # only functional assertion while using the accelerated FREQ=1 default.
    next_frame_time = await wait_for_frame_start(frame_ticks + 10)
    assert next_frame_time - first_frame_time == frame_ticks * 10, (
        f"frame period {next_frame_time - first_frame_time} ns, "
        f"expected {frame_ticks * 10} ns"
    )


@cocotb.test()
async def test_symbol_timer(dut):
    dut._log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # Reset the DUT
    await reset(dut)

    # Test the DUT
    await drive(dut)

    await ClockCycles(dut.clk, 100)
    dut._log.info("Simulation finished")


def test_symbol_timer_runner():
    hdl_toplevel = "symbol_timer"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "symbol_timer.flt")

    parameters = {
        "ASYNC": ASYNC,
        "MODE": MODE,
        "FREQ": FREQ,
        "AUTO": 1,
    }

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        build_args=[],
        waves=True,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_symbol_timer",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
