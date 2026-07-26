import math
import os
import random
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, RisingEdge

prj_path = Path(__file__).resolve().parent.parent


NUM_PARALLEL = int(os.environ.get("NUM_PARALLEL", 1))
PHASE_INTEGER_WIDTH = int(os.environ.get("PHASE_INTEGER_WIDTH", 12))
PHASE_FRACTION_WIDTH = int(os.environ.get("PHASE_FRACTION_WIDTH", 20))

GUI = os.environ.get("GUI", "FALSE") == "TRUE"

SIM = os.environ.get("SIM", "verilator")

LATENCY = 6

AMPLITUDE = 2 ** 15 - 2
PHASE_ENTRIES = (3 << (PHASE_FRACTION_WIDTH + PHASE_INTEGER_WIDTH - 2)) * NUM_PARALLEL
TOLERANCE = math.ceil(AMPLITUDE * math.sin(2 * math.pi * 1 / 2 ** PHASE_INTEGER_WIDTH))

input_queue = Queue()
output_queue = Queue()


def model(state, sync, pinc, poff):
    state = poff if sync else state + pinc
    ret = (state,)
    for i in range(NUM_PARALLEL):
        cos = round(AMPLITUDE * math.cos(2 * math.pi * (state + pinc * i / NUM_PARALLEL) / PHASE_ENTRIES))
        sin = round(AMPLITUDE * math.sin(2 * math.pi * (state + pinc * i / NUM_PARALLEL) / PHASE_ENTRIES))
        ret += (cos, sin)
    return ret


async def reset(dut):
    F0 = -10e6
    Fs = 491.52e6

    # Reset the DUT
    dut.rst.value = 1

    dut.sync.value = 0
    if F0 >= 0:
        dut.ctrl_pinc.value = int(F0 / Fs * PHASE_ENTRIES)
    else:
        dut.ctrl_pinc.value = PHASE_ENTRIES + int(F0 / Fs * PHASE_ENTRIES)
    dut.ctrl_poff.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    for i in range(10000):
        dut.sync.value = 1 if i == 0 else 0
        await RisingEdge(dut.clk)


async def input_monitor(dut):
    while True:
        await RisingEdge(dut.clk)
        input_queue.put_nowait(
            (
                dut.sync.value.integer,
                dut.ctrl_pinc.value.integer,
                dut.ctrl_poff.value.integer,
            )
        )


async def output_monitor(dut):
    await ClockCycles(dut.clk, LATENCY)
    while True:
        await RisingEdge(dut.clk)
        output = ()
        for i in range(NUM_PARALLEL):
            cos = (dut.cos.value.integer >> (i * 16)) & 0xFFFF
            sin = (dut.sin.value.integer >> (i * 16)) & 0xFFFF
            cos = cos - 2 ** 16 if cos >= 2 ** 15 else cos
            sin = sin - 2 ** 16 if sin >= 2 ** 15 else sin
            output += (cos, sin)
        output_queue.put_nowait(output)


async def checker():
    n = 0
    state = 0
    with open("nco_output.txt", "w") as f:
        while True:
            input = await input_queue.get()
            output = await output_queue.get()
            for i in range(int(len(output) / 2)):
                f.write(f"{output[i*2]}, {output[i*2+1]}\n")
            n += 1

            (state, *ref) = model(state, input[0], input[1], input[2])
            for i in range(len(output)):
                assert (
                    abs(ref[i] - output[i]) < TOLERANCE
                ), f"ref = {ref}, output = {output}"


@cocotb.test()
async def test_nco(dut):
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


def test_nco_runner():
    hdl_toplevel = "nco"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "nco.flt")

    parameters = {
        "NUM_PARALLEL": NUM_PARALLEL,
        "PHASE_INTEGER_WIDTH": PHASE_INTEGER_WIDTH,
        "PHASE_FRACTION_WIDTH": PHASE_FRACTION_WIDTH,
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
        test_module="test_nco",
        waves=True,
        gui=False,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
