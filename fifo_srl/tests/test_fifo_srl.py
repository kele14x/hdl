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

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
SIM = SIM.lower()
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


CASES = [
    {"FIFO_DEPTH": 16, "DATA_WIDTH": 16},
    {"FIFO_DEPTH": 32, "DATA_WIDTH": 12},
]


@pytest.mark.parametrize("params", CASES)
def test_fifo_srl_runner(params):
    runner = get_runner(SIM)
    hdl_toplevel = "fifo_srl"

    case_name = "_".join(f"{key}{value}" for key, value in sorted(params.items()))
    run_dir = prj_path / "sim_build" / case_name
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
