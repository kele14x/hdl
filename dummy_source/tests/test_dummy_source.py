import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM", "verilator")


@cocotb.test()
async def test_dummy_source_basic(dut):
    """
    Perform some basic test of the dummy_source module.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 2).start())

    # Reset the DUT
    dut.rst.value = 1
    dut.data_sync_in.value = 0
    dut.ctrl_numerology.value = 0
    dut.ctrl_iq_width.value = 0
    dut.ctrl_shift.value = 0
    dut.ctrl_scalar.value = 0
    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    dut.data_sync_in.value = 1 << 3
    await RisingEdge(dut.clk)
    dut.data_sync_in.value = 0

    # Wait for the simulation to finish
    await ClockCycles(dut.clk, 2**20)
    dut._log.info("Simulation finished")


def test_dummy_source_runner():
    hdl_toplevel = "dummy_source"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "dummy_source.flt")

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        build_args=[],
        always=True,
        waves=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_dummy_source",
        waves=True,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
