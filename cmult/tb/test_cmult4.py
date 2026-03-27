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


A_WIDTH = int(os.getenv("A_WIDTH", 16))
B_WIDTH = int(os.getenv("B_WIDTH", 16))
P_WIDTH = int(os.getenv("P_WIDTH", 16))
SHIFT = int(os.getenv("SHIFT", 14))
ROUND = int(os.environ.get("ROUND", 1))
SATURATE = int(os.environ.get("SATURATE", 1))

LATENCY = 5

GUI = os.getenv("GUI", "False").lower() == "true"


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


def model(ar, ai, br, bi):
    """Model the cmult."""
    pr = ar * br - ai * bi
    pi = ar * bi + ai * br

    if ROUND:
        pr = (pr + 2 ** (SHIFT - 1)) / 2**SHIFT
        pi = (pi + 2 ** (SHIFT - 1)) / 2**SHIFT
    else:
        pr = pr / 2**SHIFT
        pi = pi / 2**SHIFT
    pr = math.floor(pr)
    pi = math.floor(pi)

    ovf = (
        pr > 2 ** (P_WIDTH - 1) - 1
        or pr < -(2 ** (P_WIDTH - 1))
        or pi > 2 ** (P_WIDTH - 1) - 1
        or pi < -(2 ** (P_WIDTH - 1))
    )

    if SATURATE:
        pr = saturation(pr, P_WIDTH)
        pi = saturation(pi, P_WIDTH)
    else:
        pr = truncate(pr, P_WIDTH)
        pi = truncate(pi, P_WIDTH)
    return (pr, pi, ovf)


async def reset(dut):
    """Reset the DUT."""
    dut.rst.value = 1

    dut.ar.value = 0
    dut.ai.value = 0
    dut.br.value = 0
    dut.bi.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    """Drive the DUT."""
    for _ in range(1000):
        dut.ar.value = random.randint(-(2 ** (A_WIDTH - 1)), 2 ** (A_WIDTH - 1) - 1)
        dut.ai.value = random.randint(-(2 ** (A_WIDTH - 1)), 2 ** (A_WIDTH - 1) - 1)
        dut.br.value = random.randint(-(2 ** (B_WIDTH - 1)), 2 ** (B_WIDTH - 1) - 1)
        dut.bi.value = random.randint(-(2 ** (B_WIDTH - 1)), 2 ** (B_WIDTH - 1) - 1)
        await RisingEdge(dut.clk)


async def input_monitor(dut):
    """Monitor the input."""
    while True:
        await RisingEdge(dut.clk)
        input_queue.put_nowait(
            (
                dut.ar.value.signed_integer,
                dut.ai.value.signed_integer,
                dut.br.value.signed_integer,
                dut.bi.value.signed_integer,
            )
        )


async def output_monitor(dut):
    """Monitor the output."""
    await ClockCycles(dut.clk, LATENCY)
    while True:
        await RisingEdge(dut.clk)
        output_queue.put_nowait((dut.pr.value.signed_integer, dut.pi.value.signed_integer, dut.ovf.value))


async def checker():
    """Checker."""
    n = 0
    while True:
        input = await input_queue.get()
        output = await output_queue.get()
        n += 1
        if n % 100 == 0:
            cocotb.log.info("%d / 1000", n)
        (ar, ai, br, bi) = input
        (pr, pi, ovf) = output

        (pr_ref, pi_ref, ovf_ref) = model(ar, ai, br, bi)
        assert (
            pr_ref == pr and pi_ref == pi and ovf == ovf_ref
        ), (
            f"Result mismatch! "
            f"Input: ar = {ar}, ai = {ai}, br = {br}, bi = {bi}; "
            f"Output: pr = {pr}, pi = {pi}, ovf = {ovf}; "
            f"Reference: pr_ref = {pr_ref}, pi_ref = {pi_ref}, ovf_ref = {ovf_ref}"
        )


@cocotb.test()
async def test_cmult4(dut):
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


def test_cmult4_runner():
    sim = "questa"

    hdl_toplevel = "cmult4"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "rtl/cmult4.v",
    ]

    test_args = [
        f"-gA_WIDTH={A_WIDTH}",
        f"-gB_WIDTH={B_WIDTH}",
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
        test_module="test_cmult4",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    test_cmult4_runner()
