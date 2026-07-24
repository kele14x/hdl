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

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(12345)

PARAM_SETS_FILE = Path(__file__).resolve().parent / "param_sets.json"

SIM = os.environ.get("SIM", "verilator").lower()
GUI = os.environ.get("GUI", "False").lower() == "true"

input_queue = Queue()
output_queue = Queue()


async def reset(dut):
    dut.rst.value = 1
    dut.wren.value = 0
    dut.din.value = 0
    dut.rden.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut, cfg):
    data_width = cfg["DATA_WIDTH"]
    for _ in range(10000):
        await RisingEdge(dut.clk)
        dut.wren.value = int(rng.integers(0, 2))
        dut.din.value = int(rng.integers(0, 2**data_width))
        dut.rden.value = int(rng.integers(0, 2))


async def input_monitor(dut):
    while True:
        await RisingEdge(dut.clk)
        if int(dut.wren.value) and not int(dut.full.value):
            input_queue.put_nowait(int(dut.din.value))


async def output_monitor(dut):
    while True:
        await RisingEdge(dut.clk)
        if int(dut.rden.value) and not int(dut.empty.value):
            output_queue.put_nowait(int(dut.dout.value))


async def checker():
    while True:
        input_value = await input_queue.get()
        output_value = await output_queue.get()
        assert input_value == output_value, (
            f"Result mismatch! input = {input_value}, output = {output_value}"
        )


@cocotb.test()
async def test_fifo_srl(dut):
    cfg = {
        "FIFO_DEPTH": int(dut.FIFO_DEPTH.value),
        "DATA_WIDTH": int(dut.DATA_WIDTH.value),
    }

    cocotb.log.info("Simulation started")
    cocotb.start_soon(Clock(dut.clk, 10).start())

    await reset(dut)

    cocotb.start_soon(input_monitor(dut))
    cocotb.start_soon(output_monitor(dut))
    cocotb.start_soon(checker())

    await drive(dut, cfg)

    await ClockCycles(dut.clk, 10)
    cocotb.log.info("Simulation finished")


def _normalize_param_sets(data):
    if not isinstance(data, list) or len(data) == 0:
        raise ValueError("param_sets.json must be a non-empty JSON list")
    required = {"FIFO_DEPTH", "DATA_WIDTH"}
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
            "FIFO_DEPTH": int(item["FIFO_DEPTH"]),
            "DATA_WIDTH": int(item["DATA_WIDTH"]),
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
def test_fifo_srl_runner(params):
    runner = get_runner(SIM)
    hdl_toplevel = "fifo_srl"

    with tempfile.TemporaryDirectory(prefix="fifo_srl_param_") as run_dir:
        runner.build(
            hdl_toplevel=hdl_toplevel,
            sources=[
                prj_path / "../util/rtl/srl.sv",
                prj_path / "rtl/fifo_srl.sv",
            ],
            parameters=params,
            waves=True,
            always=True,
            build_dir=run_dir,
        )

        runner.test(
            hdl_toplevel=hdl_toplevel,
            hdl_toplevel_lang="verilog",
            test_module="test_fifo_srl",
            gui=GUI,
            test_dir=run_dir,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
