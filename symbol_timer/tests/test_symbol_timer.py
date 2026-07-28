import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, RisingEdge

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
    await ClockCycles(dut.clk, 100)
    dut.sync.value = 1
    await RisingEdge(dut.clk)
    dut.sync.value = 0
    pulses = []
    for i in range(38400 + 10):
        await RisingEdge(dut.clk)
        if int(dut.start_of_symbol.value) == 3:
            pulses.append(i + 1)
    # First frame-start pulse, then one full frame (38400 ticks) later the
    # timer must roll over and pulse again
    assert pulses, "no start_of_symbol pulse observed"
    assert pulses[0] + 38400 in pulses, f"no frame roll-over pulse: {pulses[:3]}... last={pulses[-3:]}"


@cocotb.test()
async def test_symbol_timer(dut):
    dut._log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

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
        build_args=["--timing", "-Wno-WIDTHTRUNC", "-Wno-WIDTHEXPAND", "-Wno-REALCVT"],
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
