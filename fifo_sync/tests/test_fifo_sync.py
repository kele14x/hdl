#!/usr/bin/env python3
from __future__ import annotations

import os
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
RANDOM_TRANSFER_COUNT = int(os.getenv("RANDOM_TRANSFER_COUNT", "256"))

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

    write_sequence, read_sequence = random_sequences(
        tb.data_width, RANDOM_TRANSFER_COUNT
    )
    await tb.run(write_sequence, read_sequence)

    assert tb.write_agent.aborted_cycles > 0
    assert tb.read_agent.aborted_cycles > 0


CASES = [
    {"FIFO_DEPTH": 16, "FIFO_LATENCY": 3, "DATA_WIDTH": 16},
    {"FIFO_DEPTH": 16, "FIFO_LATENCY": 1, "DATA_WIDTH": 8},
    {"FIFO_DEPTH": 16, "FIFO_LATENCY": 2, "DATA_WIDTH": 8},
    {"FIFO_DEPTH": 16, "FIFO_LATENCY": 3, "DATA_WIDTH": 8},
]


@pytest.mark.parametrize("params", CASES)
def test_fifo_sync_runner(params):
    hdl_toplevel = "fifo_sync"
    case_name = "_".join(f"{key}{value}" for key, value in sorted(params.items()))
    coverage_dir = os.getenv("VERILATOR_COVERAGE_DIR")
    build_args = []
    test_args = []
    if SIM == "verilator" and coverage_dir:
        coverage_path = Path(coverage_dir)
        coverage_path.mkdir(parents=True, exist_ok=True)
        build_args.append("--coverage")
        test_args.append(
            f"+verilator+coverage+file+{coverage_path / f'{case_name}.dat'}"
        )

    runner = get_runner(SIM)
    run_dir = prj_path / "sim_build" / case_name
    runner.build(
        hdl_toplevel=hdl_toplevel,
        sources=resolve_flt(prj_path / "fifo_sync.flt"),
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
