#!/usr/bin/env python3
import math
import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

STRUCTURE = os.environ.get("STRUCTURE", "AUTO")
RASTERIZED = int(os.environ.get("RASTERIZED", "0"))
DATA_WIDTH = int(os.environ.get("DATA_WIDTH", "16"))
PHASE_WIDTH = int(os.environ.get("PHASE_WIDTH", "12"))
NEGATIVE_COS = int(os.environ.get("NEGATIVE_COS", "0"))
NEGATIVE_SIN = int(os.environ.get("NEGATIVE_SIN", "0"))

LATENCY = 4
TOLERANCE = 0.5

GUI = os.environ.get("GUI", "False").lower() == "true"

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

input_queue = Queue()
output_queue = Queue()


def num_phases():
    return int(2**PHASE_WIDTH * 3 / 4) if RASTERIZED else 2**PHASE_WIDTH


def model(phase):
    amplitude = 2 ** (DATA_WIDTH - 1) - 2
    k = num_phases()

    cos = amplitude * math.cos(2 * math.pi * phase / k)
    sin = amplitude * math.sin(2 * math.pi * phase / k)

    if NEGATIVE_COS:
        cos = -cos
    if NEGATIVE_SIN:
        sin = -sin

    return (cos, sin)


async def reset(dut):
    dut.rst.value = 1
    dut.phase.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    for i in range(num_phases()):
        dut.phase.value = i
        await RisingEdge(dut.clk)


async def input_monitor(dut):
    while True:
        await RisingEdge(dut.clk)
        input_queue.put_nowait((dut.phase.value.to_unsigned(),))


async def output_monitor(dut):
    await ClockCycles(dut.clk, LATENCY)
    while True:
        await RisingEdge(dut.clk)
        output_queue.put_nowait(
            (dut.cos_out.value.to_signed(), dut.sin_out.value.to_signed())
        )


async def checker(n):
    for i in range(n):
        (phase,) = await input_queue.get()
        (cos, sin) = await output_queue.get()
        (cos_ref, sin_ref) = model(phase)
        assert abs(cos_ref - cos) <= TOLERANCE and abs(sin_ref - sin) <= TOLERANCE, (
            f"Result mismatch at sample {i}! phase = {phase}, cos = {cos}, sin = {sin}, "
            f"cos_ref = {cos_ref}, sin_ref = {sin_ref}, tolerance = {TOLERANCE}"
        )


@cocotb.test()
async def test_dds_lut(dut):
    dut._log.info("Simulation started")
    cocotb.start_soon(Clock(dut.clk, 10).start())

    await reset(dut)

    cocotb.start_soon(input_monitor(dut))
    cocotb.start_soon(output_monitor(dut))
    num_samples = num_phases()
    checker_task = cocotb.start_soon(checker(num_samples))

    await drive(dut)
    await checker_task

    await ClockCycles(dut.clk, 10)
    dut._log.info("Simulation finished")


CASES = [
    {
        "name": "auto_norm_pw12",
        "params": {
            "STRUCTURE": "AUTO",
            "RASTERIZED": 0,
            "DATA_WIDTH": 16,
            "PHASE_WIDTH": 12,
            "NEGATIVE_COS": 0,
            "NEGATIVE_SIN": 0,
        },
    },
    {
        "name": "full_norm_pw10",
        "params": {
            "STRUCTURE": "FULL",
            "RASTERIZED": 0,
            "DATA_WIDTH": 16,
            "PHASE_WIDTH": 10,
            "NEGATIVE_COS": 0,
            "NEGATIVE_SIN": 0,
        },
    },
    {
        "name": "half_norm_pw11",
        "params": {
            "STRUCTURE": "HALF",
            "RASTERIZED": 0,
            "DATA_WIDTH": 16,
            "PHASE_WIDTH": 11,
            "NEGATIVE_COS": 0,
            "NEGATIVE_SIN": 0,
        },
    },
    {
        "name": "quarter_norm_pw12",
        "params": {
            "STRUCTURE": "QUARTER",
            "RASTERIZED": 0,
            "DATA_WIDTH": 16,
            "PHASE_WIDTH": 12,
            "NEGATIVE_COS": 0,
            "NEGATIVE_SIN": 0,
        },
    },
    {
        "name": "quarter_rast_pw12",
        "params": {
            "STRUCTURE": "QUARTER",
            "RASTERIZED": 1,
            "DATA_WIDTH": 16,
            "PHASE_WIDTH": 12,
            "NEGATIVE_COS": 0,
            "NEGATIVE_SIN": 0,
        },
    },
    {
        "name": "half_rast_pw10",
        "params": {
            "STRUCTURE": "HALF",
            "RASTERIZED": 1,
            "DATA_WIDTH": 16,
            "PHASE_WIDTH": 10,
            "NEGATIVE_COS": 0,
            "NEGATIVE_SIN": 0,
        },
    },
    {
        "name": "full_rast_pw8",
        "params": {
            "STRUCTURE": "FULL",
            "RASTERIZED": 1,
            "DATA_WIDTH": 16,
            "PHASE_WIDTH": 8,
            "NEGATIVE_COS": 0,
            "NEGATIVE_SIN": 0,
        },
    },
    {
        "name": "quarter_norm_pw13_dw12_neg",
        "params": {
            "STRUCTURE": "QUARTER",
            "RASTERIZED": 0,
            "DATA_WIDTH": 12,
            "PHASE_WIDTH": 13,
            "NEGATIVE_COS": 1,
            "NEGATIVE_SIN": 1,
        },
    },
]


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_dds_lut_runner(case):
    params = case["params"]
    parameters = {**params, "STRUCTURE": f'"{params["STRUCTURE"]}"'}
    run_dir = prj_path / "sim_build" / case["name"]

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="dds_lut",
        sources=resolve_flt(prj_path / "dds_lut.flt"),
        parameters=parameters,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="dds_lut",
        hdl_toplevel_lang="verilog",
        test_module="test_dds_lut",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
        extra_env={key: str(value) for key, value in params.items()},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
