#!/usr/bin/env python3
"""Reusable cocotb verification environment for ``skid_buffer``.

The tests at the end of this file are intentionally only vector construction.
Add a new scenario by creating an :class:`SSequence` and an :class:`MSequence`
and passing them to :meth:`TransferTestbench.run`.
"""

from __future__ import annotations

from collections.abc import Iterator, Sequence
from dataclasses import dataclass, field
from pathlib import Path
import os
import random

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadWrite, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner
from hdl_tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

DATA_WIDTH = int(os.environ.get("DATA_WIDTH", 8))

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")


def random_transfer_count_from_env(default: int) -> int:
    """Return the randomized-vector length selected for a command-line run."""

    value = int(os.environ.get("RANDOM_TRANSFER_COUNT", str(default)), 0)
    if value <= 0:
        raise ValueError("RANDOM_TRANSFER_COUNT must be positive")
    return value


@dataclass(frozen=True)
class STransaction:
    """A slave-side transfer request.

    ``pre_packet_gap`` is the minimum number of idle clocks between this
    request and the preceding request.  A value of zero permits back-to-back
    S handshakes.  The actual observed gap can be larger when S_RDY applies
    backpressure.
    """

    data: int
    pre_packet_gap: int = 0

    def __post_init__(self) -> None:
        if self.pre_packet_gap < 0:
            raise ValueError("pre_packet_gap must be non-negative")


@dataclass(frozen=True)
class SSequence:
    """The slave-side test vector."""

    transactions: Sequence[STransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[STransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


@dataclass(frozen=True)
class MTransaction:
    """A master-side acceptance policy, or a monitored M transfer.

    For a vector, only ``idle_cycles`` is supplied.  A positive value keeps
    M_RDY low for that many clocks after M_VLD is seen; zero asserts M_RDY in
    the same cycle M_VLD is observed; a negative value asserts M_RDY
    proactively, before waiting for M_VLD.  Monitors additionally fill in
    ``data`` for completed transfers.
    """

    idle_cycles: int = 0
    data: int | None = None


@dataclass(frozen=True)
class MSequence:
    """The master-side test vector."""

    transactions: Sequence[MTransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[MTransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


async def _edge(dut) -> None:
    """Wait for a rising edge.

    Monitors sample the values that were stable before this edge; drivers then
    update outputs in the following delta cycle for the next clock edge.
    """

    await RisingEdge(dut.clk)


class SAgent:
    """Slave-side driver and monitor."""

    def __init__(self, dut):
        self.dut = dut
        self.observed: list[STransaction] = []

    async def drive(self, sequence: SSequence) -> None:
        self.dut.s_vld_i.value = 0
        for transaction in sequence:
            # An idle gap is measured from the handshake edge of the previous
            # request.  Hold S_VLD low for exactly the requested clocks.
            self.dut.s_vld_i.value = 0
            if transaction.pre_packet_gap:
                await ClockCycles(self.dut.clk, transaction.pre_packet_gap)
            self.dut.s_data_i.value = transaction.data
            self.dut.s_vld_i.value = 1
            while True:
                await _edge(self.dut)
                if int(self.dut.s_rdy_o.value):
                    break

        self.dut.s_vld_i.value = 0

    async def monitor(self) -> None:
        last_handshake_cycle: int | None = None
        cycle = 0
        while True:
            await _edge(self.dut)
            cycle += 1
            if int(self.dut.s_vld_i.value) and int(self.dut.s_rdy_o.value):
                gap = (
                    0
                    if last_handshake_cycle is None
                    else cycle - last_handshake_cycle - 1
                )
                self.observed.append(
                    STransaction(data=int(self.dut.s_data_i.value), pre_packet_gap=gap)
                )
                last_handshake_cycle = cycle


class MAgent:
    """Master-side driver and monitor."""

    def __init__(self, dut):
        self.dut = dut
        self.observed: list[MTransaction] = []

    async def _wait_for_m_vld(self) -> None:
        """Wait for M_VLD, including the delta cycle in which it asserts."""

        if not int(self.dut.m_vld_o.value):
            await RisingEdge(self.dut.m_vld_o)
            await ReadWrite()

    async def _wait_for_handshake(self) -> None:
        """Wait for a sampled M_VLD/M_RDY handshake and settle the DUT."""

        while True:
            await RisingEdge(self.dut.clk)
            if int(self.dut.m_vld_o.value) and int(self.dut.m_rdy_i.value):
                await ReadWrite()
                return

    async def drive(self, sequence: MSequence) -> None:
        self.dut.m_rdy_i.value = 0
        for transaction in sequence:
            if transaction.idle_cycles < 0:
                # Negative idle requests proactive ready.  Its magnitude is
                # deliberately not a delay: it is a policy, not a timeout.
                self.dut.m_rdy_i.value = 1
            else:
                await self._wait_for_m_vld()
                if transaction.idle_cycles:
                    await ClockCycles(self.dut.clk, transaction.idle_cycles)
                self.dut.m_rdy_i.value = 1

            # For idle_cycles == 0, M_RDY was driven in the same delta cycle
            # as M_VLD's transition, so the following clock is the handshake.
            await self._wait_for_handshake()
            self.dut.m_rdy_i.value = 0

    async def monitor(self) -> None:
        valid_since: int | None = None
        cycle = 0
        while True:
            await _edge(self.dut)
            cycle += 1
            if int(self.dut.m_vld_o.value) and valid_since is None:
                valid_since = cycle
            if int(self.dut.m_vld_o.value) and int(self.dut.m_rdy_i.value):
                idle = 0 if valid_since is None else cycle - valid_since
                self.observed.append(
                    MTransaction(idle_cycles=idle, data=int(self.dut.m_data_o.value))
                )
                valid_since = None


class TransferScoreboard:
    """Checks monitor output against the S vector; data must pass in order."""

    def __init__(self, s_agent: SAgent, m_agent: MAgent):
        self.s_agent = s_agent
        self.m_agent = m_agent

    async def wait_for_transfers(self, count: int, timeout_cycles: int) -> None:
        for _ in range(timeout_cycles):
            if len(self.m_agent.observed) >= count:
                return
            await _edge(self.s_agent.dut)
        raise TimeoutError(
            f"Timed out waiting for {count} M transfers; got {len(self.m_agent.observed)}"
        )

    def check(self, s_vector: SSequence, m_vector: MSequence) -> None:
        expected_data = [transaction.data for transaction in s_vector]
        observed_s_data = [transaction.data for transaction in self.s_agent.observed]
        if observed_s_data != expected_data:
            raise AssertionError(
                f"S monitor mismatch: observed={observed_s_data!r}, expected={expected_data!r}"
            )
        if len(self.m_agent.observed) != len(m_vector):
            raise AssertionError(
                f"M monitor count mismatch: observed={len(self.m_agent.observed)}, expected={len(m_vector)}"
            )

        observed_m_data = [transaction.data for transaction in self.m_agent.observed]
        if observed_m_data != expected_data:
            raise AssertionError(
                f"M data mismatch: observed={observed_m_data!r}, expected={expected_data!r}"
            )


async def check_legal_state(dut) -> None:
    """Protocol guard: 2'b10 is an illegal state."""

    while True:
        await _edge(dut)
        if int(dut.state.value) == 0b10:
            raise AssertionError("skid buffer reached illegal state 2'b10")


async def check_output_stability(dut) -> None:
    """Protocol guard: M_VLD/M_DATA must hold while a transfer is stalled."""

    while True:
        await _edge(dut)
        if int(dut.m_vld_o.value) and not int(dut.m_rdy_i.value):
            data = int(dut.m_data_o.value)
            await _edge(dut)
            if not int(dut.m_vld_o.value):
                raise AssertionError("m_vld_o deasserted before the transfer completed")
            if int(dut.m_data_o.value) != data:
                raise AssertionError(
                    f"m_data_o changed while stalled: was 0x{data:02X}, got 0x{int(dut.m_data_o.value):02X}"
                )


class TransferTestbench:
    """Owns agents, scoreboard, reset, and scenario execution."""

    def __init__(self, dut):
        self.dut = dut
        self.s = SAgent(dut)
        self.m = MAgent(dut)
        self.scoreboard = TransferScoreboard(self.s, self.m)

    async def reset(self) -> None:
        self.dut.rst_n.value = 0
        self.dut.s_vld_i.value = 0
        self.dut.s_data_i.value = 0
        self.dut.m_rdy_i.value = 0
        await ClockCycles(self.dut.clk, 5)
        self.dut.rst_n.value = 1
        await ClockCycles(self.dut.clk, 2)

    async def start(self) -> None:
        await self.reset()
        cocotb.start_soon(self.s.monitor())
        cocotb.start_soon(self.m.monitor())
        cocotb.start_soon(check_legal_state(self.dut))
        cocotb.start_soon(check_output_stability(self.dut))

    async def run(
        self,
        s_vector: SSequence,
        m_vector: MSequence,
        *,
        m_start_delay: int = 0,
        timeout_cycles: int = 500,
        post_idle_cycles: int = 10,
    ) -> None:
        if len(s_vector) != len(m_vector):
            raise ValueError(
                "S and M vectors must contain the same number of transactions"
            )
        if post_idle_cycles < 0:
            raise ValueError("post_idle_cycles must be non-negative")

        async def drive_m() -> None:
            await ClockCycles(self.dut.clk, m_start_delay)
            await self.m.drive(m_vector)

        s_driver = cocotb.start_soon(self.s.drive(s_vector))
        m_driver = cocotb.start_soon(drive_m())
        await with_timeout(s_driver, timeout_cycles * 10, "ns")
        await with_timeout(m_driver, timeout_cycles * 10, "ns")
        await self.scoreboard.wait_for_transfers(len(s_vector), timeout_cycles)
        self.scoreboard.check(s_vector, m_vector)

        # Keep the idle bus visible after the final observed transfer so a
        # waveform viewer has useful context after the scenario completes.
        self.dut.s_vld_i.value = 0
        self.dut.m_rdy_i.value = 0
        await ClockCycles(self.dut.clk, post_idle_cycles)


async def make_testbench(dut) -> TransferTestbench:
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    tb = TransferTestbench(dut)
    await tb.start()
    return tb


@cocotb.test()
async def test_single_transfer(dut):
    """Simple one-transfer scenario."""
    tb = await make_testbench(dut)
    await tb.run(SSequence([STransaction(0xA5)]), MSequence([MTransaction(0)]))


@cocotb.test()
async def test_back_to_back_transfers(dut):
    """Back-to-back S requests and proactive M acceptance."""
    tb = await make_testbench(dut)
    data = [0x10, 0x20, 0x30, 0x40, 0x50]
    await tb.run(
        SSequence([STransaction(value, pre_packet_gap=0) for value in data]),
        MSequence([MTransaction(-1) for _ in data]),
    )


@cocotb.test()
async def test_fill_then_flush(dut):
    """Fill both slots under M backpressure, then flush all transfers."""
    tb = await make_testbench(dut)
    data = [0x80 + index for index in range(12)]
    await tb.run(
        SSequence([STransaction(value) for value in data]),
        MSequence([MTransaction(-1) for _ in data]),
        m_start_delay=12,
        timeout_cycles=1_000,
    )


@cocotb.test()
async def test_slow_drain(dut):
    """Every transfer stalled for several cycles on the M side."""
    tb = await make_testbench(dut)
    data = [index for index in range(16)]
    await tb.run(
        SSequence([STransaction(value) for value in data]),
        MSequence([MTransaction(3) for _ in data]),
    )


@cocotb.test()
async def test_random_transfers(dut):
    """Random S gaps and random M acceptance delays."""
    rng = random.Random(42)
    tb = await make_testbench(dut)
    count = random_transfer_count_from_env(250)
    data = [rng.randrange(0, 1 << DATA_WIDTH) for _ in range(count)]
    s_vector = SSequence([STransaction(value, rng.randrange(0, 4)) for value in data])
    m_vector = MSequence([MTransaction(rng.choice([-1, 0, 1, 2])) for _ in data])
    await tb.run(s_vector, m_vector, timeout_cycles=20_000)


def test_skid_buffer_runner():
    """Run the test for skid buffer"""
    hdl_toplevel = "skid_buffer"

    verilog_sources = resolve_flt(prj_path / "skid_buffer.flt")

    parameters = {
        "DATA_WIDTH": DATA_WIDTH,
    }

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        always=True,
        waves=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module="test_skid_buffer",
        waves=True,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
