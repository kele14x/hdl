import os
from pathlib import Path

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(12345)

A_WIDTH = int(os.environ.get("A_WIDTH", 8))
B_WIDTH = int(os.environ.get("B_WIDTH", 8))
P_WIDTH = int(os.environ.get("P_WIDTH", 6))
SHIFT = int(os.environ.get("SHIFT", 2))
ROUND = int(os.environ.get("ROUND", 1))
SATURATE = int(os.environ.get("SATURATE", 1))

LATENCY = 1
GUI = os.environ.get("GUI", "False").lower() == "true"

input_queue = Queue()
output_queue = Queue()


def truncate(x, w):
    x = x % 2**w
    x = x - 2**w if x > 2 ** (w - 1) - 1 else x
    return x


def saturation(x, w):
    if x > 2 ** (w - 1) - 1:
        return 2 ** (w - 1) - 1
    if x < -(2 ** (w - 1)):
        return -(2 ** (w - 1))
    return x


def model(a, b, sub):
    p = a - b if sub else a + b
    if ROUND and SHIFT > 0:
        p = (p + 2 ** (SHIFT - 1)) / 2**SHIFT
    else:
        p = p / 2**SHIFT if SHIFT > 0 else p
    p = int(np.floor(p))

    ovf = p > 2 ** (P_WIDTH - 1) - 1 or p < -(2 ** (P_WIDTH - 1))
    p = saturation(p, P_WIDTH) if SATURATE else truncate(p, P_WIDTH)
    return (p, int(ovf))


async def reset(dut):
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    dut.sub.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    for _ in range(10000):
        await RisingEdge(dut.clk)
        dut.a.value = int(rng.integers(-(2 ** (A_WIDTH - 1)), 2 ** (A_WIDTH - 1)))
        dut.b.value = int(rng.integers(-(2 ** (B_WIDTH - 1)), 2 ** (B_WIDTH - 1)))
        dut.sub.value = int(rng.integers(0, 2))


async def input_monitor(dut):
    while True:
        await RisingEdge(dut.clk)
        input_queue.put_nowait(
            (dut.a.value.to_signed(), dut.b.value.to_signed(), int(dut.sub.value))
        )


async def output_monitor(dut):
    await ClockCycles(dut.clk, LATENCY)
    while True:
        await RisingEdge(dut.clk)
        output_queue.put_nowait((dut.p.value.to_signed(), int(dut.ovf.value)))


async def checker():
    while True:
        input_value = await input_queue.get()
        output_value = await output_queue.get()
        (a, b, sub) = input_value
        (p, ovf) = output_value
        (p_ref, ovf_ref) = model(a, b, sub)
        assert (p_ref, ovf_ref) == (p, ovf), (
            f"Mismatch: a={a}, b={b}, sub={sub}, got(p={p},ovf={ovf}), "
            f"ref(p={p_ref},ovf={ovf_ref})"
        )


@cocotb.test()
async def test_adder(dut):
    cocotb.log.info("Simulation started")
    cocotb.start_soon(Clock(dut.clk, 10).start())

    await reset(dut)

    cocotb.start_soon(input_monitor(dut))
    cocotb.start_soon(output_monitor(dut))
    cocotb.start_soon(checker())

    await drive(dut)

    await ClockCycles(dut.clk, 10)
    cocotb.log.info("Simulation finished")


def test_adder_runner():
    sim = os.environ.get("SIM", "questa")
    hdl_toplevel = "adder"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "rtl/adder.sv",
    ]

    parameters = {
        "A_WIDTH": A_WIDTH,
        "B_WIDTH": B_WIDTH,
        "P_WIDTH": P_WIDTH,
        "SHIFT": SHIFT,
        "ROUND": ROUND,
        "SATURATE": SATURATE,
    }

    runner = get_runner(sim)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_adder",
        gui=GUI,
    )


if __name__ == "__main__":
    test_adder_runner()
