import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge

prj_path = Path(__file__).resolve().parent.parent


ASYNC = int(os.environ.get("ASYNC", 0))
MODE = int(os.environ.get("MODE", 1))
FREQ = int(os.environ.get("FREQ", 1))

GUI = os.environ.get("GUI", "false").lower() == "true"


async def reset(dut):
    # Reset the DUT
    dut.rst.value = 1
    dut.sync.value = 0
    dut.sync_frame.value = 0

    dut.ctrl_delay.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    await ClockCycles(dut.clk, 100)
    dut.sync.value = 1
    await RisingEdge(dut.clk)
    dut.sync.value = 0
    await ClockCycles(dut.clk, 38400 + 1)
    assert dut.start_of_symbol.value == 3


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
    sim = "questa"

    hdl_toplevel = "symbol_timer"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "rtl/symbol_timer.v",
    ]

    test_args = [
        f"-gASYNC={ASYNC}",
        f"-gMODE={MODE}",
        f"-gFREQ={FREQ}",
    ]

    runner = get_runner(sim)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_args=test_args,
        test_module="test_symbol_timer",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    test_symbol_timer_runner()
