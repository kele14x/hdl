#! /usr/bin/env python3
import math
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

GUI = os.environ.get("GUI", "False").lower() == "true"
SIM = os.environ.get("SIM", "verilator")


def get_latency(dut):
    return 7 if int(dut.USE_3_MULT.value) else 5


def truncate(x, w):
    x = x % 2**w
    return x - 2**w if x > 2 ** (w - 1) - 1 else x


def saturation(x, w):
    if x > 2 ** (w - 1) - 1:
        return 2 ** (w - 1) - 1
    if x < -(2 ** (w - 1)):
        return -(2 ** (w - 1))
    return x


def model(ar, ai, br, bi, cfg):
    shift = cfg["SHIFT"]
    p_width = cfg["P_WIDTH"]
    rnd = cfg["ROUND"]
    saturate_en = cfg["SATURATE"]

    pr = ar * br - ai * bi
    pi = ar * bi + ai * br

    if rnd and shift > 0:
        pr = (pr + 2 ** (shift - 1)) / 2**shift
        pi = (pi + 2 ** (shift - 1)) / 2**shift
    else:
        pr = pr / 2**shift if shift > 0 else pr
        pi = pi / 2**shift if shift > 0 else pi

    pr = math.floor(pr)
    pi = math.floor(pi)

    ovf = (
        pr > 2 ** (p_width - 1) - 1
        or pr < -(2 ** (p_width - 1))
        or pi > 2 ** (p_width - 1) - 1
        or pi < -(2 ** (p_width - 1))
    )

    if saturate_en:
        pr = saturation(pr, p_width)
        pi = saturation(pi, p_width)
    else:
        pr = truncate(pr, p_width)
        pi = truncate(pi, p_width)

    return (pr, pi, int(ovf))


async def reset(dut):
    dut.rst.value = 1
    dut.ar.value = 0
    dut.ai.value = 0
    dut.br.value = 0
    dut.bi.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive_random(dut, cfg, n=1000):
    a_width = cfg["A_WIDTH"]
    b_width = cfg["B_WIDTH"]
    for _ in range(n):
        await RisingEdge(dut.clk)
        dut.ar.value = int(rng.integers(-(2 ** (a_width - 1)), 2 ** (a_width - 1)))
        dut.ai.value = int(rng.integers(-(2 ** (a_width - 1)), 2 ** (a_width - 1)))
        dut.br.value = int(rng.integers(-(2 ** (b_width - 1)), 2 ** (b_width - 1)))
        dut.bi.value = int(rng.integers(-(2 ** (b_width - 1)), 2 ** (b_width - 1)))


async def input_monitor(dut, input_queue):
    while True:
        await RisingEdge(dut.clk)
        input_queue.put_nowait(
            (
                dut.ar.value.to_signed(),
                dut.ai.value.to_signed(),
                dut.br.value.to_signed(),
                dut.bi.value.to_signed(),
            )
        )


async def output_monitor(dut, output_queue):
    await ClockCycles(dut.clk, get_latency(dut))
    while True:
        await RisingEdge(dut.clk)
        output_queue.put_nowait(
            (dut.pr.value.to_signed(), dut.pi.value.to_signed(), int(dut.ovf.value))
        )


async def checker(input_queue, output_queue, cfg, n=1000):
    for i in range(n):
        (ar, ai, br, bi) = await input_queue.get()
        (pr, pi, ovf) = await output_queue.get()
        (pr_ref, pi_ref, ovf_ref) = model(ar, ai, br, bi, cfg)
        assert (pr_ref, pi_ref, ovf_ref) == (pr, pi, ovf), (
            f"Mismatch #{i + 1}: "
            f"in(ar={ar}, ai={ai}, br={br}, bi={bi}), "
            f"got(pr={pr}, pi={pi}, ovf={ovf}), "
            f"ref(pr={pr_ref}, pi={pi_ref}, ovf={ovf_ref})"
        )


@cocotb.test()
async def test_cmult_basic(dut):
    cfg = {
        "A_WIDTH": int(dut.A_WIDTH.value),
        "B_WIDTH": int(dut.B_WIDTH.value),
        "P_WIDTH": int(dut.P_WIDTH.value),
        "SHIFT": int(dut.SHIFT.value),
        "ROUND": int(dut.ROUND.value),
        "SATURATE": int(dut.SATURATE.value),
    }

    cocotb.log.info("Basic simulation started")
    cocotb.start_soon(Clock(dut.clk, 10).start())

    dut.rst.value = 1
    dut.ar.value = 0
    dut.ai.value = 0
    dut.br.value = 0
    dut.bi.value = 0
    await ClockCycles(dut.clk, 11)
    assert int(dut.pr.value) == 0, "pr should reset to 0"
    assert int(dut.pi.value) == 0, "pi should reset to 0"
    assert int(dut.ovf.value) == 0, "ovf should reset to 0"
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    await RisingEdge(dut.clk)
    dut.ar.value = 16384
    dut.ai.value = 16384
    dut.br.value = 16384
    dut.bi.value = 16384

    await ClockCycles(dut.clk, get_latency(dut) + 2)
    (pr_ref, pi_ref, ovf_ref) = model(16384, 16384, 16384, 16384, cfg)
    assert dut.pr.value.to_signed() == pr_ref, f"pr should be {pr_ref}"
    assert dut.pi.value.to_signed() == pi_ref, f"pi should be {pi_ref}"
    assert int(dut.ovf.value) == ovf_ref, f"ovf should be {ovf_ref}"

    await ClockCycles(dut.clk, 10)
    cocotb.log.info("Basic simulation finished")


@cocotb.test()
async def test_cmult_random(dut):
    cfg = {
        "A_WIDTH": int(dut.A_WIDTH.value),
        "B_WIDTH": int(dut.B_WIDTH.value),
        "P_WIDTH": int(dut.P_WIDTH.value),
        "SHIFT": int(dut.SHIFT.value),
        "ROUND": int(dut.ROUND.value),
        "SATURATE": int(dut.SATURATE.value),
    }

    cocotb.log.info("Random simulation started")
    cocotb.start_soon(Clock(dut.clk, 10).start())

    await reset(dut)

    input_queue = Queue()
    output_queue = Queue()
    num_samples = 1000

    cocotb.start_soon(input_monitor(dut, input_queue))
    cocotb.start_soon(output_monitor(dut, output_queue))
    checker_task = cocotb.start_soon(
        checker(input_queue, output_queue, cfg, num_samples)
    )

    await drive_random(dut, cfg, num_samples)
    await checker_task

    await ClockCycles(dut.clk, 10)
    cocotb.log.info("Random simulation finished")


CASES = [
    {
        "A_WIDTH": 16,
        "B_WIDTH": 16,
        "P_WIDTH": 16,
        "SHIFT": 15,
        "ROUND": 1,
        "SATURATE": 1,
        "USE_3_MULT": 0,
    },
    {
        "A_WIDTH": 16,
        "B_WIDTH": 16,
        "P_WIDTH": 16,
        "SHIFT": 15,
        "ROUND": 0,
        "SATURATE": 0,
        "USE_3_MULT": 0,
    },
    {
        "A_WIDTH": 16,
        "B_WIDTH": 16,
        "P_WIDTH": 16,
        "SHIFT": 15,
        "ROUND": 1,
        "SATURATE": 1,
        "USE_3_MULT": 1,
    },
    {
        "A_WIDTH": 16,
        "B_WIDTH": 16,
        "P_WIDTH": 16,
        "SHIFT": 15,
        "ROUND": 0,
        "SATURATE": 0,
        "USE_3_MULT": 1,
    },
]


@pytest.mark.parametrize("params", CASES)
def test_cmult_runner(params):
    runner = get_runner(SIM)
    hdl_toplevel = "cmult"

    case_name = "_".join(f"{key}{value}" for key, value in sorted(params.items()))
    run_dir = prj_path / "sim_build" / case_name
    runner.build(
        hdl_toplevel=hdl_toplevel,
        sources=resolve_flt(prj_path / "cmult.flt"),
        parameters=params,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang="verilog",
        test_module="test_cmult",
        gui=GUI,
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
