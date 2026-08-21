#! /usr/bin/env python3
import os
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(12345)

LATENCY = 4
GUI = os.environ.get("GUI", "False").lower() == "true"
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

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


def model(a, b, cfg):
    shift = cfg["SHIFT"]
    p_width = cfg["P_WIDTH"]
    rnd = cfg["ROUND"]
    saturate_en = cfg["SATURATE"]

    p = a * b
    if shift > 0:
        if rnd:
            p += 2 ** (shift - 1) - 1 + ((p >> shift) & 1)
        p >>= shift

    ovf = p > 2 ** (p_width - 1) - 1 or p < -(2 ** (p_width - 1))
    p = saturation(p, p_width) if saturate_en else truncate(p, p_width)
    return (p, int(ovf))


async def reset(dut):
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut, cfg):
    a_width = cfg["A_WIDTH"]
    b_width = cfg["B_WIDTH"]

    # Exercise both sides of zero and exact half-LSB ties before random data.
    directed = [(0, 0), (1, 1), (-1, 1), (1, -1), (-1, -1)]
    if a_width >= 2 and b_width >= 4:
        directed += [(1, 7), (-1, 7), (1, 8), (-1, 8)]
    for a, b in directed:
        await RisingEdge(dut.clk)
        dut.a.value = a
        dut.b.value = b

    for _ in range(1000):
        await RisingEdge(dut.clk)
        dut.a.value = int(rng.integers(-(2 ** (a_width - 1)), 2 ** (a_width - 1)))
        dut.b.value = int(rng.integers(-(2 ** (b_width - 1)), 2 ** (b_width - 1)))


async def input_monitor(dut):
    while True:
        await RisingEdge(dut.clk)
        input_queue.put_nowait((dut.a.value.to_signed(), dut.b.value.to_signed()))


async def output_monitor(dut):
    await ClockCycles(dut.clk, LATENCY)
    while True:
        await RisingEdge(dut.clk)
        output_queue.put_nowait((dut.p.value.to_signed(), int(dut.ovf.value)))


async def checker(cfg):
    while True:
        input_value = await input_queue.get()
        output_value = await output_queue.get()
        (a, b) = input_value
        (p, ovf) = output_value
        (p_ref, ovf_ref) = model(a, b, cfg)
        assert (p_ref, ovf_ref) == (p, ovf), (
            f"Mismatch: a={a}, b={b}, got(p={p},ovf={ovf}), "
            f"ref(p={p_ref},ovf={ovf_ref})"
        )


@cocotb.test()
async def test_mult(dut):
    cfg = {
        "A_WIDTH": int(dut.A_WIDTH.value),
        "B_WIDTH": int(dut.B_WIDTH.value),
        "P_WIDTH": int(dut.P_WIDTH.value),
        "SHIFT": int(dut.SHIFT.value),
        "ROUND": int(dut.ROUND.value),
        "SATURATE": int(dut.SATURATE.value),
    }

    cocotb.log.info("Simulation started")
    cocotb.start_soon(Clock(dut.clk, 10).start())

    await reset(dut)

    cocotb.start_soon(input_monitor(dut))
    cocotb.start_soon(output_monitor(dut))
    cocotb.start_soon(checker(cfg))

    await drive(dut, cfg)

    await ClockCycles(dut.clk, 10)
    cocotb.log.info("Simulation finished")


CASES = [
    {"A_WIDTH": 8, "B_WIDTH": 8, "P_WIDTH": 6, "SHIFT": 8, "ROUND": 1, "SATURATE": 1},
    {
        "A_WIDTH": 12,
        "B_WIDTH": 10,
        "P_WIDTH": 10,
        "SHIFT": 9,
        "ROUND": 0,
        "SATURATE": 0,
    },
    {"A_WIDTH": 8, "B_WIDTH": 8, "P_WIDTH": 8, "SHIFT": 4, "ROUND": 1, "SATURATE": 0},
]


@pytest.mark.parametrize("params", CASES)
def test_mult_runner(params):
    runner = get_runner(SIM)
    hdl_toplevel = "mult"

    case_name = "_".join(f"{key}{value}" for key, value in sorted(params.items()))
    run_dir = prj_path / "sim_build" / case_name
    runner.build(
        hdl_toplevel=hdl_toplevel,
        sources=resolve_flt(prj_path / "mult.flt"),
        parameters=params,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang="verilog",
        test_module="test_mult",
        gui=GUI,
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
