#!/usr/bin/env python3
"""Cocotb regression for the alternate AXI-Stream packet FIFO."""

from __future__ import annotations

import os
import random
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner

from hdl_tools.axis import AxisAgent, AxisBeat, AxisFrame, AxisRole
from hdl_tools.flt_tool import resolve_flt

PRJ_PATH = Path(__file__).resolve().parent.parent
RNG = np.random.default_rng(1234567890)

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=verilator")

ASYNC_MODE = int(os.environ.get("ASYNC_MODE", "1"))
FIFO_DEPTH = int(os.environ.get("FIFO_DEPTH", "32"))
FIFO_LATENCY = int(os.environ.get("FIFO_LATENCY", "3"))
DATA_WIDTH = int(os.environ.get("DATA_WIDTH", "32"))
USER_WIDTH = int(os.environ.get("USER_WIDTH", "1"))

BYTES_PER_WORD = DATA_WIDTH // 8

NUM_PACKETS = 100
PACKET_SIZE_MIN = 1
PACKET_SIZE_MAX = 30
# Reader-starvation window: fixed-size packets that must overflow the FIFO.
STARVE_PACKETS = 8
STARVE_BEATS = 8
DRAIN_TIMEOUT_CYCLES = 20_000


def packet_from_bytes(data: bytes) -> AxisFrame:
    """Pack payload bytes into AXI-Stream beats with keep and last."""
    size = len(data)
    beats = []
    for index in range((size + BYTES_PER_WORD - 1) // BYTES_PER_WORD):
        word = 0
        keep = 0
        for lane in range(BYTES_PER_WORD):
            if index * BYTES_PER_WORD + lane < size:
                word |= int(data[index * BYTES_PER_WORD + lane]) << (8 * lane)
                keep |= 1 << lane
        last = index == (size + BYTES_PER_WORD - 1) // BYTES_PER_WORD - 1
        user = int(RNG.integers(0, 2**USER_WIDTH)) if USER_WIDTH else None
        beats.append(AxisBeat(data=word, keep=keep, user=user, last=last))
    return AxisFrame(beats)


def random_packet() -> AxisFrame:
    """Build one random packet as a frame of AXI-Stream beats."""
    size = int(RNG.integers(PACKET_SIZE_MIN, PACKET_SIZE_MAX + 1))
    return packet_from_bytes(RNG.bytes(size))


def starve_packet() -> AxisFrame:
    """Build a fixed-size packet of STARVE_BEATS full words."""
    return packet_from_bytes(RNG.bytes(STARVE_BEATS * BYTES_PER_WORD))


def beat_bytes(beat: AxisBeat) -> bytes:
    """Extract the kept payload bytes from one beat."""
    count = beat.keep.bit_count()
    return beat.data.to_bytes(BYTES_PER_WORD, "little")[:count]


def frame_bytes(frame: AxisFrame) -> bytes:
    return b"".join(beat_bytes(beat) for beat in frame)


async def reset(dut) -> None:
    dut.s_axis_aresetn.value = 0
    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tuser.value = 0
    dut.s_axis_tvalid.value = 0
    dut.m_axis_tready.value = 0
    await ClockCycles(dut.s_axis_aclk, 10)
    dut.s_axis_aresetn.value = 1
    await ClockCycles(dut.s_axis_aclk, 10)


async def packet_mode_checker(dut) -> None:
    """Check that m_axis_tvalid stays asserted within a packet."""
    in_packet = False
    while True:
        await RisingEdge(dut.m_axis_aclk)
        if in_packet:
            assert int(dut.m_axis_tvalid.value), "tvalid dropped inside a packet"
        if int(dut.m_axis_tvalid.value):
            in_packet = not int(dut.m_axis_tlast.value)


async def discard_tracker(dut, dropped: list) -> None:
    """Record one flag per input packet: set when err_discard pulses in it."""
    in_packet = False
    is_dropped = False
    while True:
        await RisingEdge(dut.s_axis_aclk)
        if not int(dut.s_axis_tvalid.value):
            continue
        if not in_packet:
            in_packet = True
            is_dropped = False
        if int(dut.err_discard.value):
            is_dropped = True
        if int(dut.s_axis_tlast.value):
            in_packet = False
            dropped.append(is_dropped)


@cocotb.test()
async def test_axis_fifo_alt(dut) -> None:
    """Random packets with a reader-starvation window forcing discards."""
    cocotb.log.info("Simulation started")
    cocotb.start_soon(Clock(dut.s_axis_aclk, 8, unit="ns").start(start_high=False))
    m_period = 10 if ASYNC_MODE else 8
    cocotb.start_soon(
        Clock(dut.m_axis_aclk, m_period, unit="ns").start(start_high=False)
    )

    rng = random.Random(42)
    source = AxisAgent(
        dut,
        prefix="s_axis",
        clock="s_axis_aclk",
        reset="s_axis_aresetn",
        timeout_cycles=5_000,
    )
    sink = AxisAgent(
        dut,
        prefix="m_axis",
        clock="m_axis_aclk",
        reset="s_axis_aresetn",
        role=AxisRole.SINK,
        ready_policy=lambda _cycle: rng.random() < 0.8,
        timeout_cycles=5_000,
    )
    dropped: list[bool] = []
    cocotb.start_soon(packet_mode_checker(dut))
    cocotb.start_soon(discard_tracker(dut, dropped))

    await reset(dut)
    await source.start()
    await sink.start()

    async def send_frame(frame) -> None:
        await with_timeout(
            source.send(
                frame, gap=lambda _index: int(RNG.choice([0, 1, 2], p=[0.8, 0.1, 0.1]))
            ),
            100,
            "us",
        )
        await ClockCycles(
            dut.s_axis_aclk, int(RNG.choice([0, 1, 2, 3], p=[0.7, 0.1, 0.1, 0.1]))
        )

    # Phase 1: normal traffic with an active reader.
    for _ in range(NUM_PACKETS // 2):
        await send_frame(random_packet())

    # Phase 2: starve the reader; the FIFO fills and packets must be dropped.
    sink.driver.ready_policy = lambda _cycle: False
    for _ in range(STARVE_PACKETS):
        await send_frame(starve_packet())

    # Phase 3: resume the reader and finish with normal traffic.
    sink.driver.ready_policy = lambda _cycle: rng.random() < 0.8
    for _ in range(NUM_PACKETS // 2):
        await send_frame(random_packet())

    total_sent = NUM_PACKETS + STARVE_PACKETS
    for _ in range(DRAIN_TIMEOUT_CYCLES // 10):
        if len(dropped) == total_sent and (
            sink.monitor.frames.qsize() >= total_sent - sum(dropped)
        ):
            break
        await ClockCycles(dut.m_axis_aclk, 10)

    def drain(port) -> list:
        frames = []
        while not port.empty():
            frames.append(port.get_nowait())
        return frames

    sent = drain(source.monitor.frames)
    received = drain(sink.monitor.frames)
    assert len(sent) == total_sent, f"source monitor saw {len(sent)} packets"
    assert len(dropped) == total_sent, f"discard tracker saw {len(dropped)} packets"
    expected = [frame for frame, is_dropped in zip(sent, dropped) if not is_dropped]
    assert len(received) == len(expected), (
        f"sink monitor saw {len(received)} packets, expected {len(expected)}"
    )
    for index, (tx, rx) in enumerate(zip(expected, received)):
        assert len(tx) == len(rx), f"packet {index}: beat count mismatch"
        for beat_index, (tx_beat, rx_beat) in enumerate(zip(tx, rx)):
            assert rx_beat.data == tx_beat.data, (
                f"packet {index} beat {beat_index}: data mismatch"
            )
            assert rx_beat.keep == tx_beat.keep, (
                f"packet {index} beat {beat_index}: keep mismatch"
            )
            assert rx_beat.last == tx_beat.last, (
                f"packet {index} beat {beat_index}: last mismatch"
            )
            if USER_WIDTH:
                assert rx_beat.user == tx_beat.user, (
                    f"packet {index} beat {beat_index}: user mismatch"
                )
        assert frame_bytes(rx) == frame_bytes(tx), f"packet {index}: payload mismatch"

    # The starvation window must have produced at least one discard.
    window = dropped[NUM_PACKETS // 2 : NUM_PACKETS // 2 + STARVE_PACKETS]
    assert any(window), "no packet was discarded during reader starvation"
    cocotb.log.info("Discarded %d / %d packets", sum(dropped), total_sent)

    source.stop()
    sink.stop()
    cocotb.log.info("Simulation finished")


# ---------------------------------------------------------------------------
# Parametrized runner over the configuration matrix
# ---------------------------------------------------------------------------

CASES = [
    {
        "name": f"async{async_mode}_d{depth}_l{latency}_w{data_width}",
        "params": {
            "ASYNC_MODE": async_mode,
            "FIFO_DEPTH": depth,
            "FIFO_LATENCY": latency,
            "DATA_WIDTH": data_width,
        },
    }
    for async_mode in (0, 1)
    for depth, latency, data_width in (
        (16, 1, 32),
        (16, 2, 64),
        (32, 2, 32),
        (32, 3, 64),
    )
]


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_axis_fifo_alt_runner(case) -> None:
    """Build one configuration of the FIFO and run the whole scenario set."""
    parameters = case["params"]
    extra_env = {key: str(value) for key, value in parameters.items()}
    run_dir = PRJ_PATH / "sim_build" / case["name"]

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="axis_fifo_alt",
        sources=resolve_flt(PRJ_PATH / "axis_fifo_alt.flt"),
        parameters=parameters,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="axis_fifo_alt",
        test_module="test_axis_fifo_alt",
        waves=True,
        test_dir=run_dir,
        extra_env=extra_env,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
