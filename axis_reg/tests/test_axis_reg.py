import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb_tools.runner import get_runner
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge
from tools.flt_tool import resolve_flt

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


async def drive_ready(dut):
    pattern = (0, 1, 0, 1, 1)
    index = 0
    while True:
        await FallingEdge(dut.aclk)
        dut.m_axis_tready.value = pattern[index % len(pattern)]
        index += 1


async def drive_source(dut, words):
    for data, keep, last, user in words:
        await FallingEdge(dut.aclk)
        dut.s_axis_tdata.value = data
        dut.s_axis_tkeep.value = keep
        dut.s_axis_tlast.value = last
        dut.s_axis_tuser.value = user
        dut.s_axis_tvalid.value = 1

        while True:
            await RisingEdge(dut.aclk)
            if dut.s_axis_tready.value:
                break

    await FallingEdge(dut.aclk)
    dut.s_axis_tvalid.value = 0


async def monitor_output(dut, received, expected_count):
    while len(received) < expected_count:
        # Sample the stable signal values that will handshake at the next
        # rising edge; post-edge sampling can miss a final valid deassertion.
        await FallingEdge(dut.aclk)
        await ReadOnly()
        if dut.m_axis_tvalid.value and dut.m_axis_tready.value:
            received.append(
                (
                    int(dut.m_axis_tdata.value),
                    int(dut.m_axis_tkeep.value),
                    int(dut.m_axis_tlast.value),
                    int(dut.m_axis_tuser.value),
                )
            )


@cocotb.test()
async def test_axis_reg_valid_ready_and_sideband(dut):
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    await reset(dut)

    words = [(index, 1, int(index == 31), index & 1) for index in range(32)]
    received = []
    cocotb.start_soon(drive_ready(dut))
    monitor = cocotb.start_soon(monitor_output(dut, received, len(words)))

    await drive_source(dut, words)
    for _ in range(100):
        if len(received) == len(words):
            break
        await RisingEdge(dut.aclk)
    else:
        raise AssertionError(f"only received {len(received)} of {len(words)} words")

    await monitor
    assert received == words


def test_axis_reg_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="axis_reg",
        verilog_sources=resolve_flt(prj_path / "axis_reg.flt"),
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
