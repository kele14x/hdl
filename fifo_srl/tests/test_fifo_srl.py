#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path

import cocotb
import pytest
from cocotb_tools.runner import get_runner

from common.tb.fifo import (
    FifoReadBus,
    FifoTestbench,
    FifoWriteBus,
    directed_sequences,
    random_sequences,
)
from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent
PARAM_SETS_FILE = Path(__file__).resolve().parent / "param_sets.json"
RANDOM_TRANSFER_COUNT = int(os.getenv("RANDOM_TRANSFER_COUNT", "256"))

SIM = os.environ.get("SIM", "verilator").lower()
GUI = os.environ.get("GUI", "False").lower() == "true"


@cocotb.test()
async def test_fifo_srl(dut):
    tb = FifoTestbench(
        write_bus=FifoWriteBus(clk=dut.clk, en=dut.wren, data=dut.din, full=dut.full),
        read_bus=FifoReadBus(clk=dut.clk, en=dut.rden, data=dut.dout, empty=dut.empty),
        reset_signal=dut.rst,
        data_width=int(dut.DATA_WIDTH.value),
    )
    await tb.start(clocks=((dut.clk, 10, "ns"),))

    write_sequence, read_sequence = directed_sequences(tb.data_width)
    await tb.run(write_sequence, read_sequence)

    write_sequence, read_sequence = random_sequences(
        tb.data_width, RANDOM_TRANSFER_COUNT
    )
    await tb.run(write_sequence, read_sequence)

    assert tb.write_agent.aborted_cycles > 0
    assert tb.read_agent.aborted_cycles > 0


def _normalize_param_sets(data):
    if not isinstance(data, list) or len(data) == 0:
        raise ValueError("param_sets.json must be a non-empty JSON list")
    required = {"FIFO_DEPTH", "DATA_WIDTH"}
    sets = []
    for i, item in enumerate(data, start=1):
        if not isinstance(item, dict):
            raise TypeError(f"Parameter set #{i} must be a JSON object")
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
            sources=resolve_flt(prj_path / "fifo_srl.flt"),
            parameters=params,
            waves=True,
            always=True,
            build_dir=run_dir,
            build_args=[],
        )

        runner.test(
            hdl_toplevel=hdl_toplevel,
            hdl_toplevel_lang="verilog",
            test_module="test_fifo_srl",
            test_args=["-suppress", "7061"] if SIM == "questa" else [],
            gui=GUI,
            test_dir=run_dir,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
