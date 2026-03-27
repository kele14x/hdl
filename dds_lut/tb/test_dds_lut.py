import math
import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge

prj_path = Path(__file__).resolve().parent.parent


STRUCTURE = os.environ.get("STRUCTURE", "AUTO")
RASTERIZED = int(os.environ.get("RASTERIZED", 0))
DATA_WIDTH = int(os.environ.get("DATA_WIDTH", 16))
PHASE_WIDTH = int(os.environ.get("PHASE_WIDTH", 12))
NEGATIVE_COS = int(os.environ.get("NEGATIVE_COS", 0))
NEGATIVE_SIN = int(os.environ.get("NEGATIVE_SIN", 0))

LATENCY = 4

GUI = os.environ.get("GUI", "False").lower() == "true"

input_queue = Queue()
output_queue = Queue()


def model(phase):
    a = 2 ** (DATA_WIDTH - 1) - 2
    if RASTERIZED:
        k = int(2**PHASE_WIDTH * 3 / 4)
    else:
        k = 2**PHASE_WIDTH
    cos = round(a * math.cos(2 * math.pi * phase / k))
    sin = round(a * math.sin(2 * math.pi * phase / k))
    return (cos, sin)


async def reset(dut):
    # Reset the DUT
    dut.rst.value = 1

    dut.phase.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    if RASTERIZED:
        K = int(2**PHASE_WIDTH * 3 / 4)
    else:
        K = 2**PHASE_WIDTH
    for i in range(K):
        dut.phase.value = i
        await RisingEdge(dut.clk)


async def input_monitor(dut):
    while True:
        await RisingEdge(dut.clk)
        input_queue.put_nowait((dut.phase.value.integer,))


async def output_monitor(dut):
    await ClockCycles(dut.clk, LATENCY)
    while True:
        await RisingEdge(dut.clk)
        output_queue.put_nowait(
            (dut.cos_out.value.signed_integer, dut.sin_out.value.signed_integer)
        )


async def checker():
    n = 0
    while True:
        input = await input_queue.get()
        output = await output_queue.get()
        n += 1
        phase = input[0]
        cos = output[0]
        sin = output[1]

        (cos_ref, sin_ref) = model(phase)
        assert cos_ref == cos and sin_ref == sin, (
            f"Result mismatch! phase = {phase}, cos = {cos}, sin = {sin}, "
            f"cos_ref = {cos_ref}, sin_ref = {sin_ref}"
        )


@cocotb.test()
async def test_dds_lut(dut):
    dut._log.info("Simulation started")
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
    dut._log.info("Simulation finished")


def test_dds_lut_runner():
    sim = "questa"

    hdl_toplevel = "dds_lut"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "rtl/dds_lut.v",
        prj_path / "rtl/dds_lut_rom.v",
    ]

    test_args = [
        f'-gSTRUCTURE="{STRUCTURE}"',
        f"-gPHASE_WIDTH={PHASE_WIDTH}",
        f"-gRASTERIZED={RASTERIZED}",
        f"-gNEGATIVE_COS={NEGATIVE_COS}",
        f"-gNEGATIVE_SIN={NEGATIVE_SIN}",
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
        test_module="test_dds_lut",
        waves=True,
        gui=False,
    )


if __name__ == "__main__":
    test_dds_lut_runner()
