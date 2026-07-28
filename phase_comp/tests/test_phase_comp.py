import os
from pathlib import Path

import pytest
import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, RisingEdge

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(12345)

HAS_CDC = int(os.environ.get("HAS_CDC", 0))
NUM_ANT = int(os.environ.get("NUM_ANT", 4))

LATENCY = 10

GUI = os.environ.get("GUI", "False").lower() == "true"

SIM = os.environ.get("SIM", "verilator")

CTRL_PHASE_COMP = rng.integers(0, 2**31, size=16)

input_queue = Queue()
output_queue = Queue()


async def reset(dut):
    """Reset the DUT."""
    dut.rst.value = 1
    dut.ctrl_rst.value = 1

    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_sf.value = 0
    dut.din_sl.value = 0
    dut.din_sy.value = 0
    dut.din_chn.value = 0
    dut.din_dv.value = 0

    dut.ctrl_rat.value = 0

    dut.ctrl_phase_comp_addr.value = 0
    dut.ctrl_phase_comp_we.value = 0
    dut.ctrl_phase_comp_din.value = 0

    await ClockCycles(dut.clk, 100)
    dut.rst.value = 0

    await ClockCycles(dut.ctrl_clk, 100)
    dut.ctrl_rst.value = 0


async def write_coef(dut):
    """Write coefficients to the phase compensation register."""
    for i in range(16):
        await RisingEdge(dut.ctrl_clk)
        dut.ctrl_phase_comp_addr.value = i
        dut.ctrl_phase_comp_we.value = 1
        dut.ctrl_phase_comp_din.value = int(CTRL_PHASE_COMP[i])
    await RisingEdge(dut.ctrl_clk)
    dut.ctrl_phase_comp_we.value = 0


@cocotb.test()
async def test_phase_comp_single_channel(dut):
    """Test phase compensation with single channel."""
    cocotb.log.info("Simulation started")
    # Generate clocks
    cocotb.start_soon(Clock(dut.clk, 10).start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 14).start())

    # Reset DUT
    await reset(dut)
    await write_coef(dut)

    # Start drivers
    for i in range(16):
        await RisingEdge(dut.clk)
        dut.din_dr.value = int(rng.integers(0, 2**16))
        dut.din_di.value = int(rng.integers(0, 2**16))
        dut.din_sf.value = 1 if i % 8 == 0 else 0
        dut.din_sl.value = 1 if i % 4 == 0 else 0
        dut.din_sy.value = 1 if i % 2 == 0 else 0
        dut.din_chn.value = 0
        dut.din_dv.value = 1
    await RisingEdge(dut.clk)
    dut.din_dv.value = 0

    # finish
    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


@cocotb.test()
async def test_phase_comp_multi_channel(dut):
    """Test phase compensation with multi channel."""
    cocotb.log.info("Simulation started")
    # Generate clocks
    cocotb.start_soon(Clock(dut.clk, 10).start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 14).start())

    # Reset DUT
    await reset(dut)
    await write_coef(dut)

    # Start drivers
    for i in range(16):
        for chn in range(NUM_ANT):
            await RisingEdge(dut.clk)
            dut.din_dr.value = int(rng.integers(0, 2**16))
            dut.din_di.value = int(rng.integers(0, 2**16))
            dut.din_sf.value = 1 if i % 8 == 0 else 0
            dut.din_sl.value = 1 if i % 4 == 0 else 0
            dut.din_sy.value = 1 if i % 2 == 0 else 0
            dut.din_chn.value = chn
            dut.din_dv.value = 1
    await RisingEdge(dut.clk)
    dut.din_dv.value = 0

    # finish
    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


@cocotb.test()
async def test_phase_comp_full_channel(dut):
    """Test phase compensation with full channel."""
    cocotb.log.info("Simulation started")
    # Generate clocks
    cocotb.start_soon(Clock(dut.clk, 10).start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 14).start())

    # Reset DUT
    await reset(dut)
    await write_coef(dut)

    # Start drivers
    for i in range(16):
        for chn in range(16):
            await RisingEdge(dut.clk)
            dut.din_dr.value = int(rng.integers(0, 2**16))
            dut.din_di.value = int(rng.integers(0, 2**16))
            dut.din_sf.value = 1 if i % 8 == 0 else 0
            dut.din_sl.value = 1 if i % 4 == 0 else 0
            dut.din_sy.value = 1 if i % 2 == 0 else 0
            dut.din_chn.value = chn
            dut.din_dv.value = 1 if chn < NUM_ANT else 0
    await RisingEdge(dut.clk)
    dut.din_dv.value = 0

    # finish
    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


def test_phase_comp_runner():
    """Run the test."""
    hdl_toplevel = "phase_comp"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "phase_comp.flt")

    parameters = {
        "HAS_CDC": HAS_CDC,
        "NUM_ANT": NUM_ANT,
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
        test_module="test_phase_comp",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
