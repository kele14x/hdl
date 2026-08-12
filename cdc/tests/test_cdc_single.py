#!/usr/bin/env python3
import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb_tools.runner import get_runner
from libcdc import wait_for_value

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"


@cocotb.test()
async def test_cdc_single_synchronizes_both_levels(dut):
    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 10, unit="ns").start())
    dut.src_in.value = 0
    await ClockCycles(dut.dest_clk, 4)

    dut.src_in.value = 1
    await wait_for_value(dut.dest_out, dut.dest_clk, 1)
    dut.src_in.value = 0
    await wait_for_value(dut.dest_out, dut.dest_clk, 0)


CASES = [
    {
        "name": "init1_inreg1",
        "params": {"DEST_SYNC_FF": 2, "INIT_SYNC_FF": 1, "SRC_INPUT_REG": 1},
    },
    {
        "name": "init0_inreg1",
        "params": {"DEST_SYNC_FF": 2, "INIT_SYNC_FF": 0, "SRC_INPUT_REG": 1},
    },
]


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_cdc_single_runner(case):
    parameters = case["params"]
    run_dir = prj_path / "sim_build" / case["name"]
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cdc_single",
        sources=resolve_flt(prj_path / "cdc.flt"),
        parameters=parameters,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="cdc_single",
        hdl_toplevel_lang="verilog",
        test_module="test_cdc_single",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
        extra_env={key: str(value) for key, value in parameters.items()},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
