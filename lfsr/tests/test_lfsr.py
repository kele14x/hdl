import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb_tools.runner import get_runner
from hdl_tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, RisingEdge

prj_path = Path(__file__).resolve().parent.parent


BIT_WIDTH = int(os.environ.get("BIT_WIDTH", 8))
INITIAL = int(os.environ.get("INITIAL", 2**BIT_WIDTH - 1))
POLYNOMIAL = int(os.environ.get("POLYNOMIAL", 259))
STRUCTURE = os.environ.get("STRUCTURE", "FIBONACCI")
GATE_TYPE = os.environ.get("GATE_TYPE", "XOR")
PARALLEL_OUTPUT = int(os.environ.get("PARALLEL_OUTPUT", 1))

GUI = os.environ.get("GUI", "False") == "True"

SIM = os.environ.get("SIM", "verilator")


async def reset(dut):
    # Reset DUT
    dut.rst.value = 1
    dut.en.value = 1
    dut.load.value = 0
    dut.din.value = 0

    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0


@cocotb.test()
async def test_lfsr(dut):
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    await reset(dut)

    # `dout` should be reset to initial value
    await RisingEdge(dut.clk)
    assert dut.dout.value == INITIAL

    await ClockCycles(dut.clk, 100)


def test_lfsr_runner():
    hdl_toplevel = "lfsr"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "lfsr.flt")

    parameters = {
        "BIT_WIDTH": BIT_WIDTH,
        "INITIAL": INITIAL,
        "POLYNOMIAL": POLYNOMIAL,
        "STRUCTURE": f'"{STRUCTURE}"',
        "GATE_TYPE": f'"{GATE_TYPE}"',
        "PARALLEL_OUTPUT": PARALLEL_OUTPUT,
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
        test_module="test_lfsr",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
