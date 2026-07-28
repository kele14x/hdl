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
async def test_ch_fir_basic(dut):
    """
    Perform some basic test of the ch_fir module.
    """
    NUM_STAGES = dut.NUM_STAGES.value

    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 2).start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 10).start())

    # Reset the DUT
    dut.rst.value = 1
    dut.ctrl_rst.value = 1
    dut.data_in.value = 0
    dut.ctrl_coe_en.value = 0
    dut.ctrl_coe_we.value = 0
    dut.ctrl_coe_addr.value = 0
    dut.ctrl_coe_din.value = 0
    await ClockCycles(dut.ctrl_clk, 100)
    dut.rst.value = 0
    dut.ctrl_rst.value = 0
    await ClockCycles(dut.ctrl_clk, 10)

    # Configure coefficients
    for i in range(NUM_STAGES):
        await RisingEdge(dut.ctrl_clk)
        dut.ctrl_coe_en.value = 1
        dut.ctrl_coe_we.value = 1
        dut.ctrl_coe_addr.value = i
        dut.ctrl_coe_din.value = 100+i*2

    await RisingEdge(dut.ctrl_clk)
    dut.ctrl_coe_en.value = 0
    dut.ctrl_coe_we.value = 0
    dut.ctrl_coe_addr.value = 0
    dut.ctrl_coe_din.value = 0

    # Test impulse response
    await RisingEdge(dut.clk)
    dut.data_in.value = 16384
    await RisingEdge(dut.clk)
    dut.data_in.value = 0

    # Wait for the simulation to finish
    await ClockCycles(dut.clk, 1000)
    dut._log.info("Simulation finished")


def test_ch_fir_runner():
    hdl_toplevel = "fir2"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "fir2.flt")

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        build_args=["--timing", "-Wno-WIDTHTRUNC", "-Wno-WIDTHEXPAND"],
        always=True,
        waves=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_ch_fir",
        waves=True,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
