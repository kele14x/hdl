#!/usr/bin/env python3
"""Cocotb regression for the AXI-Stream packet FIFO."""

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

ASYNC_MODE = int(os.environ.get("ASYNC_MODE", "0"))
PACKET_MODE = int(os.environ.get("PACKET_MODE", "0"))
FIFO_DEPTH = int(os.environ.get("FIFO_DEPTH", "32"))
FIFO_LATENCY = int(os.environ.get("FIFO_LATENCY", "3"))
USER_WIDTH = int(os.environ.get("USER_WIDTH", "1"))

DATA_WIDTH = 32
BYTES_PER_WORD = DATA_WIDTH // 8

NUM_PACKETS = 100
PACKET_SIZE_MIN = 1
PACKET_SIZE_MAX = 30
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


def oversize_packet(num_beats: int) -> AxisFrame:
    """Build a packet larger than the FIFO; packet mode must drop it."""
    return packet_from_bytes(RNG.bytes(num_beats * BYTES_PER_WORD))


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


@cocotb.test()
async def test_axis_fifo(dut) -> None:
    """Random packets through the FIFO with gaps and backpressure."""
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
    if PACKET_MODE:
        cocotb.start_soon(packet_mode_checker(dut))

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

    # Oversize packets injected in packet mode; the FIFO must drop them.
    # DEPTH+1 covers the case where the refused beat carries tlast.
    drop_sizes = {}
    if PACKET_MODE:
        drop_sizes = {
            NUM_PACKETS // 3: FIFO_DEPTH + 1,
            2 * NUM_PACKETS // 3: FIFO_DEPTH + 4,
        }

    for index in range(NUM_PACKETS):
        await send_frame(random_packet())
        if index in drop_sizes:
            await send_frame(oversize_packet(drop_sizes[index]))

    for _ in range(DRAIN_TIMEOUT_CYCLES // 10):
        if sink.monitor.frames.qsize() >= NUM_PACKETS:
            break
        await ClockCycles(dut.m_axis_aclk, 10)

    def drain(port) -> list:
        frames = []
        while not port.empty():
            frames.append(port.get_nowait())
        return frames

    sent = drain(source.monitor.frames)
    received = drain(sink.monitor.frames)
    expected = [frame for frame in sent if len(frame) <= FIFO_DEPTH]
    assert len(sent) == NUM_PACKETS + len(drop_sizes), (
        f"source monitor saw {len(sent)} packets"
    )
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

    source.stop()
    sink.stop()
    cocotb.log.info("Simulation finished")


# ---------------------------------------------------------------------------
# Parametrized runner over the configuration matrix
# ---------------------------------------------------------------------------

CASES = [
    {
        "name": f"async{async_mode}_pkt{packet_mode}_d{depth}_l{latency}",
        "params": {
            "ASYNC_MODE": async_mode,
            "PACKET_MODE": packet_mode,
            "FIFO_DEPTH": depth,
            "FIFO_LATENCY": latency,
        },
    }
    for async_mode, packet_mode in ((0, 0), (0, 1), (1, 0), (1, 1))
    for depth, latency in ((16, 1), (16, 2), (32, 2), (32, 3))
]


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_axis_fifo_runner(case) -> None:
    """Build one configuration of the FIFO and run the whole scenario set."""
    parameters = case["params"]
    extra_env = {key: str(value) for key, value in parameters.items()}
    run_dir = PRJ_PATH / "sim_build" / case["name"]

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="axis_fifo",
        sources=resolve_flt(PRJ_PATH / "axis_fifo.flt"),
        parameters=parameters,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="axis_fifo",
        test_module="test_axis_fifo",
        waves=True,
        test_dir=run_dir,
        extra_env=extra_env,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
