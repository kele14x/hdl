#! /usr/bin/env python3
import json
import os
import tempfile
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

PARAM_SETS_FILE = Path(__file__).resolve().parent / "param_sets.json"

LATENCY = 1
SIM = os.environ.get("SIM", "verilator").lower()
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


def model(a, b, sub, cfg):
    shift = cfg["SHIFT"]
    p_width = cfg["P_WIDTH"]
    rnd = cfg["ROUND"]
    saturate_en = cfg["SATURATE"]

    p = a - b if sub else a + b
    if rnd and shift > 0:
        p = (p + 2 ** (shift - 1)) / 2**shift
    else:
        p = p / 2**shift if shift > 0 else p
    p = int(np.floor(p))

    ovf = p > 2 ** (p_width - 1) - 1 or p < -(2 ** (p_width - 1))
    p = saturation(p, p_width) if saturate_en else truncate(p, p_width)
    return (p, int(ovf))


async def reset(dut):
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    dut.sub.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut, cfg):
    a_width = cfg["A_WIDTH"]
    b_width = cfg["B_WIDTH"]
    for _ in range(10000):
        await RisingEdge(dut.clk)
        dut.a.value = int(rng.integers(-(2 ** (a_width - 1)), 2 ** (a_width - 1)))
        dut.b.value = int(rng.integers(-(2 ** (b_width - 1)), 2 ** (b_width - 1)))
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


async def checker(cfg):
    while True:
        input_value = await input_queue.get()
        output_value = await output_queue.get()
        (a, b, sub) = input_value
        (p, ovf) = output_value
        (p_ref, ovf_ref) = model(a, b, sub, cfg)
        assert (p_ref, ovf_ref) == (p, ovf), (
            f"Mismatch: a={a}, b={b}, sub={sub}, got(p={p},ovf={ovf}), "
            f"ref(p={p_ref},ovf={ovf_ref})"
        )


@cocotb.test()
async def test_adder(dut):
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


def _normalize_param_sets(data):
    if not isinstance(data, list) or len(data) == 0:
        raise ValueError("param_sets.json must be a non-empty JSON list")
    required = {"A_WIDTH", "B_WIDTH", "P_WIDTH", "SHIFT", "ROUND", "SATURATE"}
    sets = []
    for i, item in enumerate(data, start=1):
        if not isinstance(item, dict):
            raise ValueError(f"Parameter set #{i} must be a JSON object")
        unknown = set(item.keys()) - required
        if unknown:
            raise ValueError(f"Parameter set #{i} has unknown keys: {sorted(unknown)}")
        missing = required - set(item.keys())
        if missing:
            raise ValueError(f"Parameter set #{i} is missing keys: {sorted(missing)}")
        merged = {
            "A_WIDTH": int(item["A_WIDTH"]),
            "B_WIDTH": int(item["B_WIDTH"]),
            "P_WIDTH": int(item["P_WIDTH"]),
            "SHIFT": int(item["SHIFT"]),
            "ROUND": int(item["ROUND"]),
            "SATURATE": int(item["SATURATE"]),
        }
        sets.append(merged)
    return sets


def _param_sets_for_pytest():
    if not PARAM_SETS_FILE.exists():
        raise FileNotFoundError(f"Parameter set file not found: {PARAM_SETS_FILE}")
    with PARAM_SETS_FILE.open("r", encoding="utf-8") as f:
        data = json.load(f)
    return _normalize_param_sets(data)


@pytest.mark.parametrize("params", _param_sets_for_pytest())
def test_adder_runner(params):
    runner = get_runner(SIM)
    hdl_toplevel = "adder"

    with tempfile.TemporaryDirectory(prefix="adder_param_") as run_dir:
        runner.build(
            hdl_toplevel=hdl_toplevel,
            sources=resolve_flt(prj_path / "adder.flt"),
            parameters=params,
            always=True,
            waves=True,
            build_dir=run_dir,
        )
        runner.test(
            hdl_toplevel=hdl_toplevel,
            hdl_toplevel_lang="verilog",
            test_module="test_adder",
            gui=GUI,
            test_dir=run_dir,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
