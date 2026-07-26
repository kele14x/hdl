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
COMPLEX = int(os.environ.get("COMPLEX", 1))
GAIN_WIDTH = int(os.environ.get("GAIN_WIDTH", 16))

LATENCY = 8 if COMPLEX else 5

GUI = os.environ.get("GUI", "False").lower() == "true"

SIM = os.environ.get("SIM", "verilator")

CTRL_GAIN_DR = rng.integers(-(2 ** (GAIN_WIDTH - 1)), 2 ** (GAIN_WIDTH - 1), size=NUM_ANT)
CTRL_GAIN_DI = rng.integers(-(2 ** (GAIN_WIDTH - 1)), 2 ** (GAIN_WIDTH - 1), size=NUM_ANT)

input_queue = Queue()
output_queue = Queue()


def truncate(x, w):
    """Truncate the input to the specified width."""
    x = x % 2**w
    x = x - 2**w if x > 2 ** (w - 1) - 1 else x
    return x


def saturation(x, w):
    """Saturate the input to the specified width."""
    if x > 2 ** (w - 1) - 1:
        return 2 ** (w - 1) - 1
    elif x < -(2 ** (w - 1)):
        return -(2 ** (w - 1))
    else:
        return x


def model(dr, di, gr, gi):
    """Model the adder."""
    dout_dr = dr * gr - di * gi
    dout_di = dr * gi + di * gr
    dout_dr = (dout_dr + 2**13) / 2**14
    dout_di = (dout_di + 2**13) / 2**14
    dout_dr = int(np.floor(dout_dr))
    dout_di = int(np.floor(dout_di))
    dout_dr = saturation(dout_dr, GAIN_WIDTH)
    dout_di = saturation(dout_di, GAIN_WIDTH)
    return (dout_dr, dout_di)


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
        dut.ctrl_gain_dr[i].value = int(CTRL_GAIN_DR[i])
        dut.ctrl_gain_di[i].value = int(CTRL_GAIN_DI[i])

    await ClockCycles(dut.clk, 10)
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
                dut.din_dr.value,
                dut.din_di.value,
                dut.din_sf.value.integer,
                dut.din_sl.value.integer,
                dut.din_sy.value.integer,
                dut.din_chn.value.integer,
                dut.din_dv.value.integer,
            )
        )


async def output_monitor(dut):
    """Monitor the output."""
    await ClockCycles(dut.clk, LATENCY)
    while True:
        await RisingEdge(dut.clk)
        output_queue.put_nowait(
            (
                dut.dout_dr.value,
                dut.dout_di.value,
                dut.dout_sf.value.integer,
                dut.dout_sl.value.integer,
                dut.dout_sy.value.integer,
                dut.dout_chn.value.integer,
                dut.dout_dv.value.integer,
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

        assert (dout_sf, dout_sl, dout_sy, dout_chn, dout_dv) == (din_sf, din_sl, din_sy, din_chn, din_dv)

        if din_dv and din_chn < NUM_ANT:
            din_dr = din_dr.signed_integer
            din_di = din_di.signed_integer
            dout_dr = dout_dr.signed_integer
            dout_di = dout_di.signed_integer
            gr = int(CTRL_GAIN_DR[din_chn])
            gi = int(CTRL_GAIN_DI[din_chn]) if COMPLEX else 0

            (dout_dr_ref, dout_di_ref) = model(din_dr, din_di, gr, gi)

            assert (dout_dr, dout_di) == (dout_dr_ref, dout_di_ref), (
                f"Result mismatch! "
                f"Input: din_dr = {din_dr}, din_di = {din_di}; "
                f"Output: dout_dr = {dout_dr}, dout_di = {dout_di}; "
                f"Reference: dout_dr_ref = {dout_dr_ref}, dout_di_ref = {dout_di_ref}"
            )


@cocotb.test()
async def test_adder(dut):
    """Test the adder."""
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


def test_gain_runner():
    """Run the test."""
    hdl_toplevel = "gain"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "gain.flt")

    parameters = {
        "NUM_ANT": NUM_ANT,
        "COMPLEX": COMPLEX,
        "GAIN_WIDTH": GAIN_WIDTH,
    }

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_gain",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
