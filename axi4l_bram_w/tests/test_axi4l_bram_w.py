#!/usr/bin/env python3
"""Reusable cocotb verification environment for ``axi4l_bram_w``.

The tests at the end of this file are intentionally only vector construction.
Add a new scenario by creating an :class:`AWSequence`, a :class:`WSequence`
and a :class:`BSequence` and passing them to :meth:`WriteTestbench.run`.
"""

from __future__ import annotations

from collections import deque
from collections.abc import Callable, Iterator, Sequence
from dataclasses import dataclass, field
from pathlib import Path
import os
import random

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadWrite, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

ADDR_WIDTH = int(os.environ.get("ADDR_WIDTH", 32))
DATA_WIDTH = int(os.environ.get("DATA_WIDTH", 32))

SIM = os.environ.get("SIM", "verilator")

STRB_ALL = (1 << (DATA_WIDTH // 8)) - 1


def bram_latency_from_env(default: int) -> int:
    """Return the optional fixed BRAM latency selected for a command-line run."""

    value = int(os.environ.get("BRAM_LATENCY", str(default)), 0)
    if value < 0:
        raise ValueError("BRAM_LATENCY must be non-negative")
    return value


def random_write_count_from_env(default: int) -> int:
    """Return the randomized-vector length selected for a command-line run."""

    value = int(os.environ.get("RANDOM_WRITE_COUNT", str(default)), 0)
    if value <= 0:
        raise ValueError("RANDOM_WRITE_COUNT must be positive")
    return value


@dataclass(frozen=True)
class AWTransaction:
    """An AXI write-address request.

    ``pre_packet_gap`` is the minimum number of idle clocks between this
    request and the preceding request.  A value of zero permits back-to-back
    AW handshakes.  The actual observed gap can be larger when AWREADY applies
    backpressure.
    """

    address: int
    pre_packet_gap: int = 0

    def __post_init__(self) -> None:
        if self.pre_packet_gap < 0:
            raise ValueError("pre_packet_gap must be non-negative")


@dataclass(frozen=True)
class AWSequence:
    """The AW-channel test vector."""

    transactions: Sequence[AWTransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[AWTransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


@dataclass(frozen=True)
class WTransaction:
    """An AXI write-data request.

    ``pre_packet_gap`` has the same meaning as in :class:`AWTransaction`,
    measured on the W channel.
    """

    data: int
    strb: int = STRB_ALL
    pre_packet_gap: int = 0

    def __post_init__(self) -> None:
        if self.pre_packet_gap < 0:
            raise ValueError("pre_packet_gap must be non-negative")


@dataclass(frozen=True)
class WSequence:
    """The W-channel test vector."""

    transactions: Sequence[WTransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[WTransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


@dataclass(frozen=True)
class BTransaction:
    """A B-channel acceptance policy, or a monitored B transfer.

    For a vector, only ``idle_cycles`` is supplied.  A positive value keeps
    BREADY low for that many clocks after BVALID is seen; zero asserts BREADY
    in the same cycle BVALID is observed; a negative value asserts BREADY
    proactively, before waiting for BVALID.  Monitors additionally fill in
    ``resp`` for completed transfers.
    """

    idle_cycles: int = 0
    resp: int | None = None


@dataclass(frozen=True)
class BSequence:
    """The B-channel test vector."""

    transactions: Sequence[BTransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[BTransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


async def _edge(dut) -> None:
    """Wait for a rising edge.

    Monitors sample the values that were stable before this edge; drivers then
    update outputs in the following delta cycle for the next clock edge.
    """

    await RisingEdge(dut.aclk)


class AWAgent:
    """AW driver and monitor."""

    def __init__(self, dut):
        self.dut = dut
        self.observed: list[AWTransaction] = []

    async def drive(self, sequence: AWSequence) -> None:
        self.dut.awvalid.value = 0
        for transaction in sequence:
            # An idle gap is measured from the handshake edge of the previous
            # request.  Hold AWVALID low for exactly the requested clocks.
            self.dut.awvalid.value = 0
            if transaction.pre_packet_gap:
                await ClockCycles(self.dut.aclk, transaction.pre_packet_gap)
            self.dut.awaddr.value = transaction.address
            self.dut.awvalid.value = 1
            while True:
                await _edge(self.dut)
                if int(self.dut.awready.value):
                    break

        self.dut.awvalid.value = 0

    async def monitor(self) -> None:
        last_handshake_cycle: int | None = None
        cycle = 0
        while True:
            await _edge(self.dut)
            cycle += 1
            if int(self.dut.awvalid.value) and int(self.dut.awready.value):
                gap = 0 if last_handshake_cycle is None else cycle - last_handshake_cycle - 1
                self.observed.append(
                    AWTransaction(address=int(self.dut.awaddr.value), pre_packet_gap=gap)
                )
                last_handshake_cycle = cycle


class WAgent:
    """W driver and monitor."""

    def __init__(self, dut):
        self.dut = dut
        self.observed: list[WTransaction] = []

    async def drive(self, sequence: WSequence) -> None:
        self.dut.wvalid.value = 0
        for transaction in sequence:
            self.dut.wvalid.value = 0
            if transaction.pre_packet_gap:
                await ClockCycles(self.dut.aclk, transaction.pre_packet_gap)
            self.dut.wdata.value = transaction.data
            self.dut.wstrb.value = transaction.strb
            self.dut.wvalid.value = 1
            while True:
                await _edge(self.dut)
                if int(self.dut.wready.value):
                    break

        self.dut.wvalid.value = 0

    async def monitor(self) -> None:
        last_handshake_cycle: int | None = None
        cycle = 0
        while True:
            await _edge(self.dut)
            cycle += 1
            if int(self.dut.wvalid.value) and int(self.dut.wready.value):
                gap = 0 if last_handshake_cycle is None else cycle - last_handshake_cycle - 1
                self.observed.append(
                    WTransaction(
                        data=int(self.dut.wdata.value),
                        strb=int(self.dut.wstrb.value),
                        pre_packet_gap=gap,
                    )
                )
                last_handshake_cycle = cycle


class BAgent:
    """B driver and monitor."""

    def __init__(self, dut):
        self.dut = dut
        self.observed: list[BTransaction] = []

    async def _wait_for_bvalid(self) -> None:
        """Wait for BVALID, including the delta cycle in which it asserts."""

        if not int(self.dut.bvalid.value):
            await RisingEdge(self.dut.bvalid)
            await ReadWrite()

    async def _wait_for_handshake(self) -> None:
        """Wait for a sampled BVALID/BREADY handshake and settle the DUT."""

        while True:
            await RisingEdge(self.dut.aclk)
            if int(self.dut.bvalid.value) and int(self.dut.bready.value):
                await ReadWrite()
                return

    async def drive(self, sequence: BSequence) -> None:
        self.dut.bready.value = 0
        for transaction in sequence:
            if transaction.idle_cycles < 0:
                # Negative idle requests proactive ready.  Its magnitude is
                # deliberately not a delay: it is a policy, not a timeout.
                self.dut.bready.value = 1
            else:
                await self._wait_for_bvalid()
                if transaction.idle_cycles:
                    await ClockCycles(self.dut.aclk, transaction.idle_cycles)
                self.dut.bready.value = 1

            # For idle_cycles == 0, BREADY was driven in the same delta cycle
            # as BVALID's transition, so the following clock is the handshake.
            await self._wait_for_handshake()
            self.dut.bready.value = 0

    async def monitor(self) -> None:
        valid_since: int | None = None
        cycle = 0
        while True:
            await _edge(self.dut)
            cycle += 1
            if int(self.dut.bvalid.value) and valid_since is None:
                valid_since = cycle
            if int(self.dut.bvalid.value) and int(self.dut.bready.value):
                idle = 0 if valid_since is None else cycle - valid_since
                self.observed.append(
                    BTransaction(
                        idle_cycles=idle,
                        resp=int(self.dut.bresp.value),
                    )
                )
                valid_since = None


class BramWriteModel:
    """Pipelined BRAM write model with a configurable write latency.

    A fixed latency of zero models a combinational BRAM response.  A callback
    ``(address, request_index) -> latency`` may return zero or a positive
    value to stress the interface with variable timing.  Every accepted write
    is recorded in ``writes`` as ``(address, data, strb)``; acknowledgements
    preserve request order and the model emits at most one per clock.
    """

    def __init__(
        self,
        dut,
        latency: int | Callable[[int, int], int] = 1,
        error_fn: Callable[[int], bool] | None = None,
    ):
        self.dut = dut
        self.latency = latency
        self.error_fn = error_fn or (lambda _address: False)
        self.writes: list[tuple[int, int, int]] = []

    def expected_resp(self, address: int) -> int:
        return 2 if self.error_fn(address) else 0

    def _latency_for(self, address: int) -> int:
        value = self.latency(address, len(self.writes)) if callable(self.latency) else self.latency
        if value < 0:
            raise ValueError("BRAM latency must be non-negative")
        return value

    async def _run_clocked_latency(self) -> None:
        # Entries are [ack-drive-cycle, address].  Each request gets its own
        # target cycle; the FIFO below arbitrates collisions in request order.
        pending: deque[list[int]] = deque()
        cycle = 0
        self.dut.bram_ack.value = 0
        self.dut.bram_err.value = 0
        while True:
            await RisingEdge(self.dut.aclk)
            # bram_en is assigned by a nonblocking assignment in the DUT.
            # ReadWrite sees its new value in this same timestep, allowing a
            # latency-zero request to drive ACK without a clock delay.
            await ReadWrite()
            cycle += 1
            self.dut.bram_ack.value = 0
            self.dut.bram_err.value = 0

            if int(self.dut.bram_en.value):
                address = int(self.dut.bram_addr.value)
                data = int(self.dut.bram_wdata.value)
                strb = int(self.dut.bram_wstrb.value)
                latency = self._latency_for(address)
                pending.append([cycle + latency, address])
                self.writes.append((address, data, strb))

            # Only the oldest due request may respond.  This preserves BRAM
            # ordering and turns a same-cycle collision into a one-cycle delay
            # for the later response.
            if pending and pending[0][0] <= cycle:
                _, address = pending.popleft()
                self.dut.bram_ack.value = 1
                self.dut.bram_err.value = self.error_fn(address)

    async def run(self) -> None:
        await self._run_clocked_latency()


class WriteScoreboard:
    """Checks monitor output against the vectors and the BRAM reference model."""

    def __init__(self, aw_agent: AWAgent, w_agent: WAgent, b_agent: BAgent, ram: BramWriteModel):
        self.aw_agent = aw_agent
        self.w_agent = w_agent
        self.b_agent = b_agent
        self.ram = ram

    async def wait_for_responses(self, count: int, timeout_cycles: int) -> None:
        for _ in range(timeout_cycles):
            if len(self.b_agent.observed) >= count:
                return
            await _edge(self.b_agent.dut)
        raise TimeoutError(f"Timed out waiting for {count} B transfers; got {len(self.b_agent.observed)}")

    def check(self, aw_vector: AWSequence, w_vector: WSequence, b_vector: BSequence) -> None:
        expected_addresses = [transaction.address for transaction in aw_vector]
        observed_addresses = [transaction.address for transaction in self.aw_agent.observed]
        if observed_addresses != expected_addresses:
            raise AssertionError(
                f"AW monitor mismatch: observed={observed_addresses!r}, expected={expected_addresses!r}"
            )
        expected_payloads = [(transaction.data, transaction.strb) for transaction in w_vector]
        observed_payloads = [(transaction.data, transaction.strb) for transaction in self.w_agent.observed]
        if observed_payloads != expected_payloads:
            raise AssertionError(
                f"W monitor mismatch: observed={observed_payloads!r}, expected={expected_payloads!r}"
            )
        if len(self.b_agent.observed) != len(b_vector):
            raise AssertionError(
                f"B monitor count mismatch: observed={len(self.b_agent.observed)}, expected={len(b_vector)}"
            )
        if len(self.b_agent.observed) != len(expected_addresses):
            raise AssertionError(
                f"Write count mismatch: AW={len(expected_addresses)}, B={len(self.b_agent.observed)}"
            )

        for index, (address, response) in enumerate(zip(expected_addresses, self.b_agent.observed)):
            expected_resp = self.ram.expected_resp(address)
            if response.resp != expected_resp:
                raise AssertionError(
                    f"B[{index}] has BRESP={response.resp}, expected {expected_resp}"
                )

        expected_writes = [
            (aw.address, w.data, w.strb) for aw, w in zip(aw_vector, w_vector)
        ]
        if self.ram.writes != expected_writes:
            raise AssertionError(
                f"BRAM write mismatch: observed={self.ram.writes!r}, expected={expected_writes!r}"
            )


async def check_no_ack_when_full(dut) -> None:
    """Protocol guard: the DUT must not accept a BRAM ack with a full B FIFO."""

    while True:
        await _edge(dut)
        if int(dut.b_pend.value) == 0b10 and int(dut.bram_ack.value):
            raise AssertionError("bram_ack asserted while both B slots are occupied")


async def check_no_stray_ack(dut) -> None:
    """Protocol guard: every BRAM ack must match an outstanding write.

    ``b_count_next`` is sampled so a latency-zero ack arriving in the same
    cycle as its write's issue is not mistaken for a stray ack.
    """

    while True:
        await _edge(dut)
        if int(dut.b_count_next.value) == 0 and int(dut.bram_ack.value):
            raise AssertionError("bram_ack asserted with no write outstanding")


class WriteTestbench:
    """Owns agents, reference model, reset, and scenario execution."""

    def __init__(
        self,
        dut,
        bram_latency: int | Callable[[int, int], int] = 1,
        bram_error: Callable[[int], bool] | None = None,
    ):
        self.dut = dut
        self.aw = AWAgent(dut)
        self.w = WAgent(dut)
        self.b = BAgent(dut)
        self.ram = BramWriteModel(dut, latency=bram_latency, error_fn=bram_error)
        self.scoreboard = WriteScoreboard(self.aw, self.w, self.b, self.ram)

    async def reset(self) -> None:
        self.dut.aresetn.value = 0
        self.dut.awvalid.value = 0
        self.dut.awaddr.value = 0
        self.dut.wvalid.value = 0
        self.dut.wdata.value = 0
        self.dut.wstrb.value = 0
        self.dut.bready.value = 0
        self.dut.bram_ack.value = 0
        self.dut.bram_err.value = 0
        await ClockCycles(self.dut.aclk, 5)
        self.dut.aresetn.value = 1
        await ClockCycles(self.dut.aclk, 2)

    async def start(self) -> None:
        await self.reset()
        cocotb.start_soon(self.aw.monitor())
        cocotb.start_soon(self.w.monitor())
        cocotb.start_soon(self.b.monitor())
        cocotb.start_soon(self.ram.run())
        cocotb.start_soon(check_no_ack_when_full(self.dut))
        cocotb.start_soon(check_no_stray_ack(self.dut))

    async def run(
        self,
        aw_vector: AWSequence,
        w_vector: WSequence,
        b_vector: BSequence,
        *,
        aw_start_delay: int = 0,
        w_start_delay: int = 0,
        b_start_delay: int = 0,
        timeout_cycles: int = 500,
        post_idle_cycles: int = 10,
    ) -> None:
        if not (len(aw_vector) == len(w_vector) == len(b_vector)):
            raise ValueError("AW, W and B vectors must contain the same number of transactions")
        if post_idle_cycles < 0:
            raise ValueError("post_idle_cycles must be non-negative")

        async def drive_aw() -> None:
            await ClockCycles(self.dut.aclk, aw_start_delay)
            await self.aw.drive(aw_vector)

        async def drive_w() -> None:
            await ClockCycles(self.dut.aclk, w_start_delay)
            await self.w.drive(w_vector)

        async def drive_b() -> None:
            await ClockCycles(self.dut.aclk, b_start_delay)
            await self.b.drive(b_vector)

        aw_driver = cocotb.start_soon(drive_aw())
        w_driver = cocotb.start_soon(drive_w())
        b_driver = cocotb.start_soon(drive_b())
        await with_timeout(aw_driver, timeout_cycles * 10, "ns")
        await with_timeout(w_driver, timeout_cycles * 10, "ns")
        await with_timeout(b_driver, timeout_cycles * 10, "ns")
        await self.scoreboard.wait_for_responses(len(aw_vector), timeout_cycles)
        self.scoreboard.check(aw_vector, w_vector, b_vector)

        # Keep the idle bus visible after the final observed transfer so a
        # waveform viewer has useful context after the scenario completes.
        self.dut.awvalid.value = 0
        self.dut.wvalid.value = 0
        self.dut.bready.value = 0
        await ClockCycles(self.dut.aclk, post_idle_cycles)


async def make_testbench(
    dut,
    latency: int | Callable[[int, int], int] = 1,
    bram_error: Callable[[int], bool] | None = None,
) -> WriteTestbench:
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    tb = WriteTestbench(dut, bram_latency=latency, bram_error=bram_error)
    await tb.start()
    return tb


@cocotb.test()
async def test_single_write(dut):
    """Simple one-write scenario."""
    tb = await make_testbench(dut, latency=bram_latency_from_env(1))
    await tb.run(
        AWSequence([AWTransaction(0x1000)]),
        WSequence([WTransaction(0xDEADBEEF)]),
        BSequence([BTransaction(0)]),
    )


@cocotb.test()
async def test_bram_errors(dut):
    """BRAM write errors must become AXI SLVERR responses."""
    tb = await make_testbench(dut, latency=1, bram_error=lambda address: address == 0x104)
    addresses = [0x100, 0x104, 0x108]
    await tb.run(
        AWSequence([AWTransaction(address) for address in addresses]),
        WSequence([WTransaction(0xABCD_0000 + index) for index in range(len(addresses))]),
        BSequence([BTransaction(-1) for _ in addresses]),
    )


@cocotb.test()
async def test_back_to_back_writes(dut):
    """Back-to-back AW/W requests with partial strobes and proactive B."""
    tb = await make_testbench(dut, latency=1)
    count = 5
    strbs = [0xF, 0x1, 0x3, 0xC, 0x5]
    await tb.run(
        AWSequence([AWTransaction(0x100 + 4 * index) for index in range(count)]),
        WSequence([WTransaction(0xA5A5_0000 + index, strbs[index]) for index in range(count)]),
        BSequence([BTransaction(-1) for _ in range(count)]),
    )


@cocotb.test()
async def test_ordered_variable_bram_latency(dut):
    """Colliding ack cycles must remain ordered and use one ACK per clock."""
    latencies = [3, 2, 0, 1, 0]
    tb = await make_testbench(dut, latency=lambda _address, index: latencies[index])
    count = len(latencies)
    await tb.run(
        AWSequence([AWTransaction(0x800 + 4 * index) for index in range(count)]),
        WSequence([WTransaction(0x5A5A_0000 + index) for index in range(count)]),
        BSequence([BTransaction(-1) for _ in range(count)]),
    )


@cocotb.test()
async def test_aw_w_stress_then_flush_b(dut):
    """Fill the DUT under B backpressure, then flush all responses."""
    tb = await make_testbench(dut, latency=3)
    count = 12
    await tb.run(
        AWSequence([AWTransaction(0x1000 + 4 * index) for index in range(count)]),
        WSequence([WTransaction(0xC3C3_0000 + index) for index in range(count)]),
        BSequence([BTransaction(-1) for _ in range(count)]),
        b_start_delay=12,
        timeout_cycles=1_000,
    )


@cocotb.test()
async def test_w_channel_skew(dut):
    """AW may run ahead of W; writes issue only once both are buffered."""
    tb = await make_testbench(dut, latency=1)
    count = 8
    await tb.run(
        AWSequence([AWTransaction(0x2000 + 4 * index) for index in range(count)]),
        WSequence([WTransaction(0x3C3C_0000 + index) for index in range(count)]),
        BSequence([BTransaction(-1) for _ in range(count)]),
        w_start_delay=6,
    )


@cocotb.test()
async def test_random_writes(dut):
    """Random AW/W gaps, random B acceptance delays, and variable BRAM latency."""
    rng = random.Random(42)
    tb = await make_testbench(dut, latency=lambda _address, index: index % 4)
    num_writes = random_write_count_from_env(250)
    aw_vector = AWSequence(
        [AWTransaction(rng.randrange(0, 0x1_0000) * 4, rng.randrange(0, 4)) for _ in range(num_writes)]
    )
    w_vector = WSequence(
        [
            WTransaction(
                rng.randrange(0, 1 << DATA_WIDTH),
                rng.randrange(1, STRB_ALL + 1),
                rng.randrange(0, 4),
            )
            for _ in range(num_writes)
        ]
    )
    b_vector = BSequence([BTransaction(rng.choice([-1, 0, 1, 2])) for _ in range(num_writes)])
    await tb.run(aw_vector, w_vector, b_vector, timeout_cycles=20_000)


def test_axi4l_bram_w_runner():
    """Run the test for AXI4-Lite BRAM write adapter"""
    hdl_toplevel = "axi4l_bram_w"

    verilog_sources = resolve_flt(prj_path / "axi4l_bram_w.flt")

    parameters = {
        "ADDR_WIDTH": ADDR_WIDTH,
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
        test_module="test_axi4l_bram_w",
        waves=True,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
