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


A_WIDTH = int(os.environ.get("A_WIDTH", 16))
B_WIDTH = int(os.environ.get("B_WIDTH", 16))
C_WIDTH = int(os.environ.get("C_WIDTH", 16))
P_WIDTH = int(os.environ.get("P_WIDTH", 16))
SHIFT = int(os.environ.get("SHIFT", 15))
ROUND = int(os.environ.get("ROUND", 1))
SATURATE = int(os.environ.get("SATURATE", 1))

LATENCY = 4

GUI = os.environ.get("GUI", "False").lower() == "true"


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


def model(a, b, c):
    """Model for mult_add."""
    p = a * b + c

    if ROUND:
        p = (p + 2 ** (SHIFT - 1)) / 2**SHIFT
    else:
        p = p / 2**SHIFT
    p = math.floor(p)

    # Overflow detection
    ovf = p > 2 ** (P_WIDTH - 1) - 1 or p < -(2 ** (P_WIDTH - 1))

    if SATURATE:
        p = saturation(p, P_WIDTH)
    else:
        p = truncate(p, P_WIDTH)
    return (p, ovf)


async def reset(dut):
    """Reset the DUT."""
    dut.rst.value = 1

    dut.a.value = 0
    dut.b.value = 0
    dut.c.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    """Drive the DUT with random inputs."""
    for _ in range(1000):
        await RisingEdge(dut.clk)
        dut.a.value = random.randint(-(2 ** (A_WIDTH - 1)), 2 ** (A_WIDTH - 1) - 1)
        dut.b.value = random.randint(-(2 ** (B_WIDTH - 1)), 2 ** (B_WIDTH - 1) - 1)
        dut.c.value = random.randint(-(2 ** (C_WIDTH - 1)), 2 ** (C_WIDTH - 1) - 1)


async def input_monitor(dut):
    """Monitor the inputs."""
    while True:
        await RisingEdge(dut.clk)
        input_queue.put_nowait((dut.a.value.signed_integer, dut.b.value.signed_integer, dut.c.value.signed_integer))


async def output_monitor(dut):
    """Monitor the outputs."""
    await ClockCycles(dut.clk, LATENCY)
    while True:
        await RisingEdge(dut.clk)
        output_queue.put_nowait((dut.p.value.signed_integer, dut.ovf.value))


async def checker():
    """Checker for the DUT."""
    n = 0
    while True:
        dut_input = await input_queue.get()
        dut_output = await output_queue.get()
        n += 1
        if n % 100 == 0:
            cocotb.log.info("%d / 1000", n)
        (a, b, c) = dut_input
        (p, ovf) = dut_output

        (p_ref, ovf_ref) = model(a, b, c)
        assert p_ref == p and ovf == ovf_ref, (
            f"Result mismatch! "
            f"Input: a = {a}, b = {b}, c = {c}; "
            f"Output: p = {p}, ovf = {ovf}; "
            f" Reference: p_ref = {p_ref}, ovf_ref = {ovf_ref}"
        )


@cocotb.test
async def test_mult_add(dut):
    """Test for mult_add."""
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


def test_mult_add_runner():
    """Run the test for mult_add"""
    sim = "questa"

    hdl_toplevel = "mult_add"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "rtl/mult_add.v",
    ]

    test_args = [
        f"-gA_WIDTH={A_WIDTH}",
        f"-gB_WIDTH={B_WIDTH}",
        f"-gC_WIDTH={C_WIDTH}",
        f"-gP_WIDTH={P_WIDTH}",
        f"-gSHIFT={SHIFT}",
        f"-gROUND={ROUND}",
        f"-gSATURATE={SATURATE}",
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
        test_module="test_mult_add",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    test_mult_add_runner()
