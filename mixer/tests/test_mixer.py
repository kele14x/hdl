import os
from pathlib import Path

import pytest
import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from hdl_tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, RisingEdge

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(12345)

HAS_CDC = int(os.environ.get("HAS_CDC", 0))
NUM_ANT = int(os.environ.get("NUM_ANT", 4))

LATENCY = 13

GUI = os.environ.get("GUI", "False").lower() == "true"

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

CTRL_PINC = np.zeros(NUM_ANT)
CTRL_PINC[0] = 1600
CTRL_POFF = np.zeros(NUM_ANT)
CTRL_POFF[0] = 98304

input_queue = Queue()
output_queue = Queue()


async def reset(dut):
    """Reset the DUT."""
    dut.rst.value = 1

    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_sf.value = 0
    dut.din_sl.value = 0
    dut.din_sy.value = 0
    dut.din_chn.value = 0
    dut.din_dv.value = 0

    for i in range(NUM_ANT):
        dut.ctrl_pinc[i].value = int(CTRL_PINC[i])
        dut.ctrl_poff[i].value = int(CTRL_POFF[i])

    await ClockCycles(dut.clk, LATENCY + 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    """Drive the DUT."""
    for _ in range(10000):
        await RisingEdge(dut.clk)
        dut.din_dr.value = int(rng.integers(-(2**15), 2**15))
        dut.din_di.value = int(rng.integers(-(2**15), 2**15))
        dut.din_sf.value = int(rng.choice([0, 1]))
        dut.din_sl.value = int(rng.choice([0, 1]))
        dut.din_sy.value = int(rng.choice([0, 1]))
        dut.din_chn.value = int(rng.integers(0, NUM_ANT))
        dut.din_dv.value = int(rng.choice([0, 1]))


async def input_monitor(dut):
    """Monitor the input."""
    while True:
        await RisingEdge(dut.clk)
        input_queue.put_nowait(
            (
                dut.din_dr.value.signed_integer,
                dut.din_di.value.signed_integer,
                int(dut.din_sf.value),
                int(dut.din_sl.value),
                int(dut.din_sy.value),
                int(dut.din_chn.value),
                int(dut.din_dv.value),
            )
        )


async def output_monitor(dut):
    """Monitor the output."""
    await ClockCycles(dut.clk, LATENCY)
    while True:
        await RisingEdge(dut.clk)
        output_queue.put_nowait(
            (
                dut.dout_dr.value.signed_integer,
                dut.dout_di.value.signed_integer,
                int(dut.dout_sf.value),
                int(dut.dout_sl.value),
                int(dut.dout_sy.value),
                int(dut.dout_chn.value),
                int(dut.dout_dv.value),
            )
        )


async def checker():
    """Checker."""
    n = 0
    while True:
        input = await input_queue.get()
        output = await output_queue.get()
        n += 1
        if n % 100 == 0:
            cocotb.log.info("%d / 10000", n)
        (din_dr, din_di, din_sf, din_sl, din_sy, din_chn, din_dv) = input
        (dout_dr, dout_di, dout_sf, dout_sl, dout_sy, dout_chn, dout_dv) = output

        assert (dout_sf, dout_sl, dout_sy, dout_chn, dout_dv) == (
            din_sf,
            din_sl,
            din_sy,
            din_chn,
            din_dv,
        )
        # assert (dout_dr, dout_di) == (dout_dr_ref, dout_di_ref), (
        #     f"Result mismatch! "
        #     f"Input: din_dr = {din_dr}, din_di = {din_di}; "
        #     f"Output: dout_dr = {dout_dr}, dout_di = {dout_di}; "
        #     f"Reference: dout_dr_ref = {dout_dr_ref}, dout_di_ref = {dout_di_ref}"
        # )


@cocotb.test()
async def test_mixer_single_channel(dut):
    """Test the mixer with a single channel."""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    await reset(dut)

    for i in range(4096):
        dut.din_dr.value = 32767
        dut.din_di.value = 0
        dut.din_sf.value = 1 if i == 0 else 0
        dut.din_sl.value = 0
        dut.din_sy.value = 0
        dut.din_chn.value = 0
        dut.din_dv.value = 1
        await RisingEdge(dut.clk)

    await ClockCycles(dut.clk, 10)
    cocotb.log.info("Simulation finished")


@cocotb.test()
async def test_mixer_full_channel(dut):
    """Test the mixer with full channel."""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    await reset(dut)

    for i in range(256):
        for ch in range(16):
            dut.din_dr.value = 32767
            dut.din_di.value = 0
            dut.din_sf.value = 1 if i == 0 else 0
            dut.din_sl.value = 0
            dut.din_sy.value = 0
            dut.din_chn.value = ch
            dut.din_dv.value = 1 if ch < NUM_ANT else 0
            await RisingEdge(dut.clk)

    await ClockCycles(dut.clk, 10)
    cocotb.log.info("Simulation finished")


@cocotb.test()
async def test_mixer(dut):
    """Test the mixer."""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    await reset(dut)

    # Start monitor and checker
    cocotb.start_soon(input_monitor(dut))
    cocotb.start_soon(output_monitor(dut))
    cocotb.start_soon(checker())

    # Run test multiple times
    await drive(dut)

    await ClockCycles(dut.clk, 10)
    cocotb.log.info("Simulation finished")


def test_mixer_runner():
    """Run the test."""
    hdl_toplevel = "mixer"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "mixer.flt")

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
        test_module="test_mixer",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
