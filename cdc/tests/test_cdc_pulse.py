#!/usr/bin/env python3
import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"

# Build parameters arrive via extra_env because the runner and the simulator
# are separate Python processes.
RST_USED = int(os.environ.get("RST_USED", "1"))


async def emit_source_pulse(dut, gap_cycles=5):
    await RisingEdge(dut.src_clk)
    dut.src_pulse.value = 1
    await RisingEdge(dut.src_clk)
    dut.src_pulse.value = 0
    await ClockCycles(dut.src_clk, gap_cycles)


@cocotb.test()
async def test_cdc_pulse_emits_one_destination_pulse_per_source_event(dut):
    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 11, unit="ns").start())
    dut.src_rst.value = 1
    dut.dest_rst.value = 1
    dut.src_pulse.value = 0
    await ClockCycles(dut.src_clk, 3)
    dut.src_rst.value = 0
    dut.dest_rst.value = 0
    await ClockCycles(dut.dest_clk, 3)

    sender = cocotb.start_soon(emit_source_pulse(dut))
    pulses = 0
    for _ in range(30):
        await RisingEdge(dut.dest_clk)
        pulses += int(dut.dest_pulse.value)
        if sender.done() and pulses == 1:
            break

    assert pulses == 1


@cocotb.test()
async def test_cdc_pulse_ignores_resets_when_unused(dut):
    if RST_USED != 0:
        return

    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 11, unit="ns").start())
    # With RST_USED=0 the reset inputs must be dead: hold them asserted for
    # the whole test while pulses are sent.
    dut.src_rst.value = 1
    dut.dest_rst.value = 1
    dut.src_pulse.value = 0
    await ClockCycles(dut.src_clk, 3)

    async def send_two_pulses():
        await emit_source_pulse(dut, gap_cycles=8)
        await emit_source_pulse(dut, gap_cycles=8)

    sender = cocotb.start_soon(send_two_pulses())
    pulses = 0
    for _ in range(60):
        await RisingEdge(dut.dest_clk)
        pulses += int(dut.dest_pulse.value)
        if sender.done() and pulses == 2:
            break

    assert pulses == 2


@cocotb.test()
async def test_cdc_pulse_preserves_separated_edges_and_suppresses_reset_history(dut):
    if RST_USED != 1:
        return

    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 13, unit="ns").start())
    dut.src_rst.value = 1
    dut.dest_rst.value = 1
    dut.src_pulse.value = 0
    await ClockCycles(dut.src_clk, 3)
    dut.src_rst.value = 0
    dut.dest_rst.value = 0
    await ClockCycles(dut.dest_clk, 3)

    async def source_events():
        await emit_source_pulse(dut)
        await emit_source_pulse(dut)

    sender = cocotb.start_soon(source_events())
    pulse_count = 0
    for _ in range(60):
        await RisingEdge(dut.dest_clk)
        pulse_count += int(dut.dest_pulse.value)
        if sender.done() and pulse_count == 2:
            break

    assert pulse_count == 2


CASES = [
    {
        "name": "init1_reg1_rst1",
        "params": {
            "DEST_SYNC_FF": 2,
            "INIT_SYNC_FF": 1,
            "REG_OUTPUT": 1,
            "RST_USED": 1,
        },
    },
    {
        "name": "init1_reg0_rst0",
        "params": {
            "DEST_SYNC_FF": 2,
            "INIT_SYNC_FF": 1,
            "REG_OUTPUT": 0,
            "RST_USED": 0,
        },
    },
    {
        "name": "init0_reg1_rst1",
        "params": {
            "DEST_SYNC_FF": 2,
            "INIT_SYNC_FF": 0,
            "REG_OUTPUT": 1,
            "RST_USED": 1,
        },
    },
]


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_cdc_pulse_runner(case):
    parameters = case["params"]
    run_dir = prj_path / "sim_build" / case["name"]
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cdc_pulse",
        sources=resolve_flt(prj_path / "cdc.flt"),
        parameters=parameters,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="cdc_pulse",
        hdl_toplevel_lang="verilog",
        test_module="test_cdc_pulse",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
        extra_env={key: str(value) for key, value in parameters.items()},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
