import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt
from hdl_tools.timing import RadioTimingAgent, RadioTimingAgentConfig

prj_path = Path(__file__).resolve().parent.parent


ASYNC = int(os.environ.get("ASYNC", "0"))
MODE = int(os.environ.get("MODE", "1"))
FREQ = int(os.environ.get("FREQ", "1"))

GUI = os.environ.get("GUI", "false").lower() == "true"

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")


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

    timing = RadioTimingAgent(
        dut,
        RadioTimingAgentConfig(
            numerology=1,
            slots_per_frame=20,
            timeout_cycles=frame_ticks + 10,
        ),
    )
    await timing.start()

    await ClockCycles(dut.clk, 100)
    await timing.pulse_sync()
    first_frame = await timing.wait_frame(1000)

    # The external sync starts a frame; with AUTO enabled, the next one is
    # generated precisely one frame later. This ports the legacy SV bench's
    # only functional assertion while using the accelerated FREQ=1 default.
    next_frame = await timing.wait_frame()
    assert next_frame.cycle - first_frame.cycle == frame_ticks, (
        f"frame period {next_frame.cycle - first_frame.cycle} cycles, "
        f"expected {frame_ticks} cycles"
    )
    assert (first_frame.slot, first_frame.symbol) == (0, 0)
    assert first_frame.start_slot and first_frame.start_symbol


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

    parameters = {
        "ASYNC": ASYNC,
        "MODE": MODE,
        "FREQ": FREQ,
        "AUTO": 1,
    }

    runner = get_runner(SIM)
    run_dir = prj_path / "sim_build" / "symbol_timer"
    runner.build(
        hdl_toplevel=hdl_toplevel,
        sources=resolve_flt(prj_path / "symbol_timer.flt"),
        parameters=parameters,
        build_args=[],
        waves=True,
        always=True,
        build_dir=run_dir,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_symbol_timer",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
