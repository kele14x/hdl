#!/usr/bin/env python3
import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM")
GUI = os.environ.get("GUI", "false").lower() == "true"


async def drive(dut):
    # Wait reset done
    for it in range(1, 30):
        dut.cen.value = 1
        dut.din.value = it
        await RisingEdge(dut.clk)


async def monitor(dut):
    it = 0
    while 1:
        din = int(dut.din.value)
        cen = int(dut.cen.value)
        dout = int(dut.dout.value)
        print(f"it={it} din={din} cen={cen} dout={dout}")
        it += 1
        await RisingEdge(dut.clk)


@cocotb.test()
async def diag(dut):
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # Reset DUT
    dut.rst.value = 1
    dut.cen.value = 0
    dut.din.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    # Sync to rising edge then start driver and monitor
    await RisingEdge(dut.clk)
    cocotb.start_soon(monitor(dut))
    await drive(dut)

    await ClockCycles(dut.clk, 10)
    print("Done")


def test_diag_runner():
    runner = get_runner(SIM)
    run_dir = prj_path / "sim_build" / "diag"
    runner.build(
        hdl_toplevel="shift_ram",
        sources=resolve_flt(prj_path / "shift_ram.flt"),
        parameters={"WIDTH": 8, "DEPTH": 8, "INPUT_REG": 0},
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="shift_ram",
        hdl_toplevel_lang="verilog",
        test_module="test_diag_latency",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-s"]))
