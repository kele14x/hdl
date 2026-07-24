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


prj_path = Path(__file__).resolve().parent.parent
repo_path = prj_path.parent
sys.path.insert(0, str(repo_path / "tests"))

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
async def test_fifo_sync(dut):
    tb = FifoTestbench(
        write_bus=FifoWriteBus(clk=dut.clk, en=dut.wren, data=dut.din, full=dut.full),
        read_bus=FifoReadBus(clk=dut.clk, en=dut.rden, data=dut.dout, empty=dut.empty),
        reset_signal=dut.rst,
        data_width=int(dut.DATA_WIDTH.value),
    )
    await tb.start(clocks=((dut.clk, 10, "ns"),))

    write_sequence, read_sequence = directed_sequences(tb.data_width)
    await tb.run(write_sequence, read_sequence)

    write_sequence, read_sequence = random_sequences(tb.data_width, RANDOM_TRANSFER_COUNT)
    await tb.run(write_sequence, read_sequence)

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
def test_fifo_sync_runner(params):
    hdl_toplevel = "fifo_sync"
    coverage_dir = os.getenv("VERILATOR_COVERAGE_DIR")
    build_args = ["--timing"]
    test_args = []
    if SIM == "verilator" and coverage_dir:
        coverage_path = Path(coverage_dir)
        coverage_path.mkdir(parents=True, exist_ok=True)
        label = "_".join(f"{key}{value}" for key, value in sorted(params.items()))
        build_args.append("--coverage")
        test_args.append(f"+verilator+coverage+file+{coverage_path / f'{label}.dat'}")

    runner = get_runner(SIM)
    with tempfile.TemporaryDirectory(prefix="fifo_sync_param_") as run_dir:
        runner.build(
            hdl_toplevel=hdl_toplevel,
            sources=[
                prj_path / "../ram/rtl/ram_sdp.sv",
                prj_path / "rtl/fifo_sync.sv",
            ],
            parameters=params,
            build_args=build_args,
            waves=True,
            always=True,
            build_dir=run_dir,
        )

        runner.test(
            hdl_toplevel=hdl_toplevel,
            hdl_toplevel_lang="verilog",
            test_module="test_fifo_sync",
            gui=GUI,
            test_args=test_args,
            test_dir=run_dir,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
