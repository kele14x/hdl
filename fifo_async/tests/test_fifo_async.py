#!/usr/bin/env python3
from __future__ import annotations

import json
import os
from pathlib import Path
import sys
import tempfile

import cocotb
import pytest
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
repo_path = prj_path.parent
sys.path.insert(0, str(repo_path / "common" / "tests"))

from libfifo import (  # noqa: E402
    FifoReadBus,
    FifoTestbench,
    FifoWriteBus,
    directed_sequences,
    random_sequences,
)


PARAM_SETS_FILE = Path(__file__).resolve().parent / "param_sets.json"
RANDOM_TRANSFER_COUNT = int(os.getenv("RANDOM_TRANSFER_COUNT", 256))

GUI = os.getenv("GUI", "False").lower() == "true"
SIM = os.environ.get("SIM", "verilator").lower()


@cocotb.test()
async def test_fifo_async(dut):
    tb = FifoTestbench(
        write_bus=FifoWriteBus(
            clk=dut.wr_clk,
            en=dut.wr_en,
            data=dut.wr_din,
            full=dut.wr_full,
        ),
        read_bus=FifoReadBus(
            clk=dut.rd_clk,
            en=dut.rd_en,
            data=dut.rd_dout,
            empty=dut.rd_empty,
        ),
        reset_signal=dut.rst,
        data_width=int(dut.DATA_WIDTH.value),
    )
    await tb.start(clocks=((dut.wr_clk, 10, "ns"), (dut.rd_clk, 13, "ns")))

    write_sequence, read_sequence = directed_sequences(tb.data_width)
    await tb.run(write_sequence, read_sequence, timeout_ns=200_000)

    write_sequence, read_sequence = random_sequences(tb.data_width, RANDOM_TRANSFER_COUNT)
    await tb.run(write_sequence, read_sequence, timeout_ns=200_000)

    assert tb.write_agent.aborted_cycles > 0
    assert tb.read_agent.aborted_cycles > 0


def _normalize_param_sets(data):
    if not isinstance(data, list) or len(data) == 0:
        raise ValueError("param_sets.json must be a non-empty JSON list")
    required = {"FIFO_DEPTH", "FIFO_LATENCY", "DATA_WIDTH"}
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
        sets.append({key: int(item[key]) for key in required})
    return sets


def _param_sets_for_pytest():
    if not PARAM_SETS_FILE.exists():
        raise FileNotFoundError(f"Parameter set file not found: {PARAM_SETS_FILE}")
    with PARAM_SETS_FILE.open("r", encoding="utf-8") as f:
        data = json.load(f)
    return _normalize_param_sets(data)


@pytest.mark.parametrize("params", _param_sets_for_pytest())
def test_fifo_async_runner(params):
    hdl_toplevel = "fifo_async"

    sources = resolve_flt(prj_path / "fifo_async.flt")

    build_args = []
    if SIM == "verilator":
        build_args = ["--timing", "-Wno-WIDTHTRUNC", "-Wno-MULTIDRIVEN"]

    runner = get_runner(SIM)
    with tempfile.TemporaryDirectory(prefix="fifo_async_param_") as run_dir:
        runner.build(
            hdl_toplevel=hdl_toplevel,
            sources=sources,
            parameters=params,
            build_args=build_args,
            waves=True,
            always=True,
            build_dir=run_dir,
        )

        runner.test(
            hdl_toplevel=hdl_toplevel,
            hdl_toplevel_lang="verilog",
            test_module="test_fifo_async",
            waves=True,
            gui=GUI,
            test_dir=run_dir,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
