#!/usr/bin/env python3
import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ValueChange
from cocotb_tools.runner import get_runner
from libcdc import wait_for_value

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"

# Build parameters arrive via extra_env because the runner and the simulator
# are separate Python processes.
RST_ACTIVE_HIGH = int(os.environ.get("RST_ACTIVE_HIGH", "0"))
ASSERT_LEVEL = 1 if RST_ACTIVE_HIGH != 0 else 0
RELEASE_LEVEL = 1 - ASSERT_LEVEL


@cocotb.test()
async def test_cdc_async_rst_release_is_synchronized(dut):
    cocotb.start_soon(Clock(dut.dest_clk, 10, unit="ns").start())
    dut.src_arst.value = ASSERT_LEVEL
    await ClockCycles(dut.dest_clk, 3)
    assert int(dut.dest_arst.value) == ASSERT_LEVEL
    dut.src_arst.value = RELEASE_LEVEL
    await wait_for_value(dut.dest_arst, dut.dest_clk, RELEASE_LEVEL)


@cocotb.test()
async def test_cdc_async_rst_asserts_without_dest_clk(dut):
    clock_task = cocotb.start_soon(Clock(dut.dest_clk, 10, unit="ns").start())
    dut.src_arst.value = RELEASE_LEVEL
    await ClockCycles(dut.dest_clk, 4)
    assert int(dut.dest_arst.value) == RELEASE_LEVEL

    # Assertion must not need any dest_clk edges: stop the clock first.
    clock_task.cancel()
    dut.src_arst.value = ASSERT_LEVEL
    await ValueChange(dut.dest_arst)
    assert int(dut.dest_arst.value) == ASSERT_LEVEL


# INIT_SYNC_FF exists only for compatibility with AMD XPM_CDC and has no
# effect here, so one case per polarity covers the module.
CASES = [
    {
        "name": "active_high1",
        "params": {"DEST_SYNC_FF": 2, "INIT_SYNC_FF": 1, "RST_ACTIVE_HIGH": 1},
    },
    {
        "name": "active_low0",
        "params": {"DEST_SYNC_FF": 2, "INIT_SYNC_FF": 1, "RST_ACTIVE_HIGH": 0},
    },
]


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_cdc_async_rst_runner(case):
    parameters = case["params"]
    run_dir = prj_path / "sim_build" / case["name"]
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cdc_async_rst",
        sources=resolve_flt(prj_path / "cdc.flt"),
        parameters=parameters,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="cdc_async_rst",
        hdl_toplevel_lang="verilog",
        test_module="test_cdc_async_rst",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
        extra_env={key: str(value) for key, value in parameters.items()},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
