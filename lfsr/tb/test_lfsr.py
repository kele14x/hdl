import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge

prj_path = Path(__file__).resolve().parent.parent


BIT_WIDTH = int(os.environ.get("BIT_WIDTH", 8))
INITIAL = int(os.environ.get("INITIAL", 2**BIT_WIDTH - 1))
POLYNOMIAL = int(os.environ.get("POLYNOMIAL", 259))
STRUCTURE = os.environ.get("STRUCTURE", "FIBONACCI")
GATE_TYPE = os.environ.get("GATE_TYPE", "XOR")
PARALLEL_OUTPUT = int(os.environ.get("PARALLEL_OUTPUT", 1))

GUI = os.environ.get("GUI", "False") == "True"


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
    sim = "questa"

    hdl_toplevel = "lfsr"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "rtl/lfsr.v",
    ]

    test_args = [
        f"-gBIT_WIDTH={BIT_WIDTH}",
        f"-gINITIAL={INITIAL}",
        f"-gPOLYNOMIAL={POLYNOMIAL}",
        f"-gSTRUCTURE={STRUCTURE}",
        f"-gGATE_TYPE={GATE_TYPE}",
        f"-gPARALLEL_OUTPUT={PARALLEL_OUTPUT}",
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
        test_module="test_lfsr",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    test_lfsr_runner()
