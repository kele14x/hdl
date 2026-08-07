import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb_tools.runner import get_runner

from common.tb.axis import (
    AxisAgent,
    AxisAgentConfig,
    AxisBeat,
    AxisFrame,
    AxisRole,
)
from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


async def reset(dut):
    dut.aresetn.value = 0
    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tuser.value = 0
    dut.s_axis_tvalid.value = 0
    dut.m_axis_tready.value = 0
    await ClockCycles(dut.aclk, 10)
    dut.aresetn.value = 1
    await ClockCycles(dut.aclk, 2)


@cocotb.test()
async def test_axis_reg_valid_ready_and_sideband(dut):
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    await reset(dut)

    ready_pattern = (0, 1, 0, 1, 1)
    source = AxisAgent(
        dut,
        AxisAgentConfig(
            prefix="s_axis",
            clock="aclk",
            reset="aresetn",
            role=AxisRole.SOURCE,
        ),
    )
    sink = AxisAgent(
        dut,
        AxisAgentConfig(
            prefix="m_axis",
            clock="aclk",
            reset="aresetn",
            role=AxisRole.SINK,
        ),
        ready_policy=lambda cycle: ready_pattern[cycle % len(ready_pattern)],
    )
    await source.start()
    await sink.start()

    expected = AxisFrame(
        [
            AxisBeat(
                data=index,
                keep=1,
                last=index == 31,
                user=index & 1,
            )
            for index in range(32)
        ]
    )
    await source.send(expected)

    source_observed = await source.monitor.frames.get()
    sink_observed = await sink.receive()
    assert source_observed == expected
    assert sink_observed == expected


def test_axis_reg_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="axis_reg",
        sources=resolve_flt(prj_path / "axis_reg.flt"),
        waves=True,
        always=True,
    )
    runner.test(
        hdl_toplevel="axis_reg",
        hdl_toplevel_lang="verilog",
        test_module="test_axis_reg",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
