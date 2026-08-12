#!/usr/bin/env python3
import os
import random
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

NUM_SRC = 2
NUM_DEST = 2
DATA_WIDTH = 8
USER_WIDTH = 2
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"

TIMEOUT_NS = 20_000


async def reset(dut):
    dut.rst.value = 1
    for source in range(NUM_SRC):
        dut.s_axis_tdata[source].value = 0
        dut.s_axis_tkeep[source].value = 0
        dut.s_axis_tlast[source].value = 0
        dut.s_axis_tdest[source].value = 0
        dut.s_axis_tuser[source].value = 0
        dut.s_axis_tvalid[source].value = 0
    for destination in range(NUM_DEST):
        dut.m_axis_tready[destination].value = 0
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 2)


def expected_beats(packets):
    """Flatten (dest, [(data, user), ...]) packets into scoreboard words."""
    beats = []
    for _, words in packets:
        for index, (data, user) in enumerate(words):
            beats.append((data, 1, int(index == len(words) - 1), user))
    return beats


async def drive_source(dut, source, packets):
    """Drive packets as (dest bitmask, [(data, user), ...]) on one source."""
    for dest, words in packets:
        for index, (data, user) in enumerate(words):
            dut.s_axis_tdata[source].value = data
            dut.s_axis_tkeep[source].value = 1
            dut.s_axis_tlast[source].value = int(index == len(words) - 1)
            dut.s_axis_tdest[source].value = dest
            dut.s_axis_tuser[source].value = user
            dut.s_axis_tvalid[source].value = 1
            await RisingEdge(dut.clk)
            while not int(dut.s_axis_tready[source].value):
                await RisingEdge(dut.clk)
    dut.s_axis_tvalid[source].value = 0


async def drive_ready(dut, policy):
    """Drive m_axis_tready from policy(cycle, destination) -> bool."""
    cycle = 0
    while True:
        for destination in range(NUM_DEST):
            dut.m_axis_tready[destination].value = int(policy(cycle, destination))
        await RisingEdge(dut.clk)
        cycle += 1


async def monitor_dest(dut, destination, received):
    while True:
        await RisingEdge(dut.clk)
        if int(dut.m_axis_tvalid[destination].value) and int(
            dut.m_axis_tready[destination].value
        ):
            received.append(
                (
                    int(dut.m_axis_tdata[destination].value),
                    int(dut.m_axis_tkeep[destination].value),
                    int(dut.m_axis_tlast[destination].value),
                    int(dut.m_axis_tuser[destination].value),
                )
            )


async def check_payload_stable(dut, destination):
    """AXI-Stream: payload must hold while TVALID is high and TREADY low."""
    pending = None
    while True:
        await RisingEdge(dut.clk)
        valid = int(dut.m_axis_tvalid[destination].value)
        ready = int(dut.m_axis_tready[destination].value)
        payload = (
            int(dut.m_axis_tdata[destination].value),
            int(dut.m_axis_tkeep[destination].value),
            int(dut.m_axis_tlast[destination].value),
            int(dut.m_axis_tuser[destination].value),
        )
        if valid and not ready:
            assert pending is None or payload == pending, (
                f"dest{destination} payload changed while stalled: "
                f"{pending} -> {payload}"
            )
            pending = payload
        else:
            pending = None


async def run_and_collect(dut, sources, received, expected, ready_task=None):
    """Join the source drivers, then wait until every beat is observed."""
    for task in sources:
        await with_timeout(task, TIMEOUT_NS, "ns")
    total = sum(len(beats) for beats in expected)
    for _ in range(1000):
        if sum(len(words) for words in received) >= total:
            break
        await RisingEdge(dut.clk)
    else:
        raise AssertionError(f"expected {total} beats, observed {received}")
    if ready_task is not None:
        ready_task.cancel()


@cocotb.test()
async def test_broadcast_under_backpressure(dut):
    """Two broadcast packets serialize and reach every destination intact."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)

    packets = [
        [(0b11, [(0x11, 0), (0x12, 1)])],
        [(0b11, [(0x21, 2), (0x22, 3), (0x23, 0)])],
    ]
    # Fixed-priority arbitration lets source 0 finish before source 1 starts.
    expected = [expected_beats(packets[0]) + expected_beats(packets[1])] * NUM_DEST

    rng = random.Random(1234)
    received = [[] for _ in range(NUM_DEST)]
    monitors = [
        cocotb.start_soon(monitor_dest(dut, destination, received[destination]))
        for destination in range(NUM_DEST)
    ]
    checks = [
        cocotb.start_soon(check_payload_stable(dut, destination))
        for destination in range(NUM_DEST)
    ]
    ready_task = cocotb.start_soon(
        drive_ready(dut, lambda cycle, destination: rng.random() < 0.7)
    )

    sources = [
        cocotb.start_soon(drive_source(dut, source, packets[source]))
        for source in range(NUM_SRC)
    ]
    await run_and_collect(dut, sources, received, expected, ready_task)
    for task in monitors + checks:
        task.cancel()

    assert received == expected


@cocotb.test()
async def test_disjoint_unicast_routes_independently(dut):
    """Each destination only sees the source that targeted it."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)

    packets = [
        [(0b01, [(0xB1, 0), (0xB2, 1)]), (0b01, [(0xB3, 2), (0xB4, 3)])],
        [(0b10, [(0xC1, 0), (0xC2, 1)])],
    ]
    expected = [expected_beats(packets[source]) for source in range(NUM_SRC)]

    received = [[] for _ in range(NUM_DEST)]
    monitors = [
        cocotb.start_soon(monitor_dest(dut, destination, received[destination]))
        for destination in range(NUM_DEST)
    ]
    for destination in range(NUM_DEST):
        dut.m_axis_tready[destination].value = 1

    sources = [
        cocotb.start_soon(drive_source(dut, source, packets[source]))
        for source in range(NUM_SRC)
    ]
    await run_and_collect(dut, sources, received, expected)
    for task in monitors:
        task.cancel()

    assert received == expected


@cocotb.test()
async def test_tdest_zero_discards_packet(dut):
    """A TDEST == 0 packet is absorbed silently; later packets still route."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)

    packets = [
        [(0b00, [(0xD1, 0), (0xD2, 0)]), (0b01, [(0xA1, 1), (0xA2, 2)])],
        [(0b10, [(0xE1, 3), (0xE2, 0)])],
    ]
    # The discarded packet of source 0 must not appear anywhere.
    expected = [
        expected_beats(packets[0][1:]),
        expected_beats(packets[1]),
    ]

    received = [[] for _ in range(NUM_DEST)]
    monitors = [
        cocotb.start_soon(monitor_dest(dut, destination, received[destination]))
        for destination in range(NUM_DEST)
    ]
    for destination in range(NUM_DEST):
        dut.m_axis_tready[destination].value = 1

    sources = [
        cocotb.start_soon(drive_source(dut, source, packets[source]))
        for source in range(NUM_SRC)
    ]
    await run_and_collect(dut, sources, received, expected)
    for task in monitors:
        task.cancel()

    assert received == expected


@cocotb.test()
async def test_contending_broadcasts_serialize(dut):
    """A packet owns all its destinations until its TLAST transfer."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)

    packets = [
        [(0b11, [(0x10, 1), (0x11, 2)])],
        [(0b11, [(0x20, 3), (0x21, 0)])],
    ]
    expected = [expected_beats(packets[0]) + expected_beats(packets[1])] * NUM_DEST

    received = [[] for _ in range(NUM_DEST)]
    monitors = [
        cocotb.start_soon(monitor_dest(dut, destination, received[destination]))
        for destination in range(NUM_DEST)
    ]
    checks = [
        cocotb.start_soon(check_payload_stable(dut, destination))
        for destination in range(NUM_DEST)
    ]
    # Destination 1 stalls while words are pending; the stalled payload must
    # be retained and source 0 must not advance past it.
    ready_task = cocotb.start_soon(
        drive_ready(
            dut, lambda cycle, destination: destination == 0 or cycle not in (4, 5, 10)
        )
    )

    first_ready = [None] * NUM_SRC

    async def track_first_ready(source):
        cycle = 0
        while True:
            await RisingEdge(dut.clk)
            if int(dut.s_axis_tready[source].value) and first_ready[source] is None:
                first_ready[source] = cycle
            cycle += 1

    trackers = [
        cocotb.start_soon(track_first_ready(source)) for source in range(NUM_SRC)
    ]
    sources = [
        cocotb.start_soon(drive_source(dut, source, packets[source]))
        for source in range(NUM_SRC)
    ]
    await run_and_collect(dut, sources, received, expected, ready_task)
    for task in monitors + checks + trackers:
        task.cancel()

    assert received == expected
    assert first_ready[0] is not None
    assert first_ready[1] is not None
    assert first_ready[0] < first_ready[1]


def test_axis_switch_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="axis_switch",
        sources=resolve_flt(prj_path / "axis_switch.flt"),
        parameters={
            "NUM_SRC": NUM_SRC,
            "NUM_DEST": NUM_DEST,
            "DATA_WIDTH": DATA_WIDTH,
            "USER_WIDTH": USER_WIDTH,
        },
        build_dir=str(prj_path / "sim_build"),
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="axis_switch",
        hdl_toplevel_lang="verilog",
        test_module="test_axis_switch",
        build_dir=str(prj_path / "sim_build"),
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
