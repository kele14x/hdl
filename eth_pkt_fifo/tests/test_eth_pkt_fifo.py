import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


def output_word(dut):
    return (
        int(dut.m_axis_tdata.value),
        int(dut.m_axis_tkeep.value),
        int(dut.m_axis_tlast.value),
        int(dut.m_axis_tstamp_out.value),
        int(dut.m_axis_tstamp_valid.value),
    )


async def send_packet(dut, words, bad_last=False):
    for index, (data, keep, stamp, stamp_valid) in enumerate(words):
        await FallingEdge(dut.aclk)
        dut.s_axis_tdata.value = data
        dut.s_axis_tkeep.value = keep
        dut.s_axis_tlast.value = index == len(words) - 1
        dut.s_axis_tuser.value = bad_last and index == len(words) - 1
        dut.s_axis_tstamp_out.value = stamp
        dut.s_axis_tstamp_valid.value = stamp_valid
        dut.s_axis_tvalid.value = 1
        while True:
            await RisingEdge(dut.aclk)
            if int(dut.s_axis_tready.value):
                break

    await FallingEdge(dut.aclk)
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tuser.value = 0


async def monitor_output(dut, received):
    while True:
        await RisingEdge(dut.aclk)
        if int(dut.m_axis_tvalid.value) and int(dut.m_axis_tready.value):
            received.put_nowait(output_word(dut))


async def expect_packet(received, words):
    for index, (data, keep, stamp, stamp_valid) in enumerate(words):
        got = await with_timeout(received.get(), 1, "us")
        assert got == (data, keep, int(index == len(words) - 1), stamp, stamp_valid)


@cocotb.test()
async def test_eth_pkt_fifo_store_forward_drop_and_backpressure(dut):
    cocotb.start_soon(Clock(dut.aclk, 8, unit="ns").start())
    dut.aresetn.value = 0
    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tuser.value = 0
    dut.s_axis_tstamp_out.value = 0
    dut.s_axis_tstamp_valid.value = 0
    dut.m_axis_tready.value = 0
    await ClockCycles(dut.aclk, 4)
    assert int(dut.s_axis_tready.value) == 0
    assert int(dut.m_axis_tvalid.value) == 0

    dut.aresetn.value = 1
    await ClockCycles(dut.aclk, 3)
    assert int(dut.s_axis_tready.value) == 1

    received = Queue()
    cocotb.start_soon(monitor_output(dut, received))

    first_packet = [
        (0x0706050403020100, 0xFF, 0x00112233445566778899, 1),
        (0x0000000000000908, 0x03, 0x00112233445566778899, 1),
    ]
    await send_packet(dut, first_packet)
    await ClockCycles(dut.aclk, 5)
    assert int(dut.m_axis_tvalid.value) == 1

    held = output_word(dut)
    await ClockCycles(dut.aclk, 3)
    assert output_word(dut) == held

    dut.m_axis_tready.value = 1
    await expect_packet(received, first_packet)
    await ClockCycles(dut.aclk, 3)
    assert int(dut.m_axis_tvalid.value) == 0

    # A packet with tuser on its final beat is rolled back and must not become
    # visible, even though its earlier beat was written speculatively.
    dut.m_axis_tready.value = 0
    bad_packet = [
        (0x1716151413121110, 0xFF, 0x00000000000000000055, 1),
        (0x0000000000001918, 0x03, 0x00000000000000000055, 1),
    ]
    await send_packet(dut, bad_packet, bad_last=True)
    await ClockCycles(dut.aclk, 5)
    assert int(dut.m_axis_tvalid.value) == 0

    second_packet = [(0x2726252423222120, 0xFF, 0x0, 0)]
    await send_packet(dut, second_packet)
    await ClockCycles(dut.aclk, 5)
    assert int(dut.m_axis_tvalid.value) == 1
    assert output_word(dut) == (
        second_packet[0][0],
        second_packet[0][1],
        1,
        second_packet[0][2],
        second_packet[0][3],
    )

    dut.m_axis_tready.value = 1
    await expect_packet(received, second_packet)


def test_eth_pkt_fifo_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="eth_pkt_fifo",
        sources=resolve_flt(prj_path / "eth_pkt_fifo.flt"),
        parameters={"ADDR_WIDTH": 4},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="eth_pkt_fifo",
        hdl_toplevel_lang="verilog",
        test_module="test_eth_pkt_fifo",
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
