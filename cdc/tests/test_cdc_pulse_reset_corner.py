import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"


async def emit_source_pulse(dut):
    await FallingEdge(dut.src_clk)
    dut.src_pulse.value = 1
    await RisingEdge(dut.src_clk)
    dut.src_pulse.value = 0
    await ClockCycles(dut.src_clk, 4)


@cocotb.test()
async def test_cdc_pulse_preserves_separated_edges_and_suppresses_reset_history(dut):
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
        await ReadOnly()
        pulse_count += int(dut.dest_pulse.value)
        if sender.done() and pulse_count == 2:
            break

    assert pulse_count == 2


def test_cdc_pulse_reset_corner_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cdc_pulse",
        verilog_sources=resolve_flt(prj_path / "cdc.flt"),
        parameters={
            "DEST_SYNC_FF": 2,
            "INIT_SYNC_FF": 1,
            "REG_OUTPUT": 1,
            "RST_USED": 1,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="cdc_pulse",
        hdl_toplevel_lang="verilog",
        test_module="test_cdc_pulse_reset_corner",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
