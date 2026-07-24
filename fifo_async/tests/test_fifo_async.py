#!/usr/bin/env python3
from __future__ import annotations

import os
from pathlib import Path
import sys

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


FIFO_DEPTH = int(os.getenv("FIFO_DEPTH", 16))
FIFO_LATENCY = int(os.getenv("FIFO_LATENCY", 3))
DATA_WIDTH = int(os.getenv("DATA_WIDTH", 8))
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


def test_fifo_async_runner():
    hdl_toplevel = "fifo_async"

    sources = [
        prj_path / "../cdc/rtl/cdc_async_rst.sv",
        prj_path / "../cdc/rtl/cdc_gray.sv",
        prj_path / "../ram/rtl/ram_sdp.sv",
        prj_path / "rtl/fifo_async.v",
    ]

    parameters = {
        "FIFO_DEPTH": FIFO_DEPTH,
        "FIFO_LATENCY": FIFO_LATENCY,
        "DATA_WIDTH": DATA_WIDTH,
    }

    build_args = []
    if SIM == "verilator":
        build_args = ["--timing", "-Wno-WIDTHTRUNC", "-Wno-MULTIDRIVEN"]

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        sources=sources,
        parameters=parameters,
        build_args=build_args,
        waves=True,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang="verilog",
        test_module="test_fifo_async",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
