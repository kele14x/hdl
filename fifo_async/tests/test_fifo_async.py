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
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
SIM = SIM.lower()


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

    write_sequence, read_sequence = random_sequences(
        tb.data_width, RANDOM_TRANSFER_COUNT
    )
    await tb.run(write_sequence, read_sequence, timeout_ns=200_000)

    assert tb.write_agent.aborted_cycles > 0
    assert tb.read_agent.aborted_cycles > 0


CASES = [
    {"FIFO_DEPTH": 16, "FIFO_LATENCY": 1, "DATA_WIDTH": 8},
    {"FIFO_DEPTH": 16, "FIFO_LATENCY": 2, "DATA_WIDTH": 8},
    {"FIFO_DEPTH": 16, "FIFO_LATENCY": 3, "DATA_WIDTH": 8},
]


@pytest.mark.parametrize("params", CASES)
def test_fifo_async_runner(params):
    hdl_toplevel = "fifo_async"

    sources = resolve_flt(prj_path / "fifo_async.flt")

    build_args = []
    if SIM == "verilator":
        build_args = []

    case_name = "_".join(f"{key}{value}" for key, value in sorted(params.items()))
    runner = get_runner(SIM)
    run_dir = prj_path / "sim_build" / case_name
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
