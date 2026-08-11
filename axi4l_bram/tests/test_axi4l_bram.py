#!/usr/bin/env python3
"""Cocotb regression for the merged AXI4-Lite BRAM adapter top.

Every scenario drives the ``axi4l_bram`` top through its split read/write
BRAM ports.  One parametrized runner iterates the configuration matrix —
``USE_DUAL_PORT`` 0/1, ``ADDR_WIDTH`` 32/12 and ``DATA_WIDTH`` 32/16 — and
each build runs the whole scenario set:

- ``test_top_*``: directed mixed-traffic scenarios
- ``test_r_*``:   read agent environment (AR/R vectors, reference model)
- ``test_w_*``:   write agent environment (AW/W/B vectors, reference model)

The agent scenarios are intentionally only vector construction: add a new one
by building the matching sequences and calling the testbench ``run`` method.
"""

from __future__ import annotations

import os
import random
from collections import deque
from collections.abc import Callable, Iterator, Sequence
from dataclasses import dataclass, field
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadWrite, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

PRJ_PATH = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=verilator")
ADDR_WIDTH = int(os.environ.get("ADDR_WIDTH", "32"))
DATA_WIDTH = int(os.environ.get("DATA_WIDTH", "32"))

DATA_MASK = (1 << DATA_WIDTH) - 1
DATA_XOR = 0xDEAD_BEEF & DATA_MASK
STRB_ALL = (1 << (DATA_WIDTH // 8)) - 1
READ_ERROR_ADDR = 0x104
WRITE_ERROR_ADDR = 0x204

USE_DUAL_PORT = int(os.environ.get("USE_DUAL_PORT", "0"))


def expected_read_data(address: int) -> int:
    return (address ^ DATA_XOR) & DATA_MASK


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------


async def _edge(dut) -> None:
    """Wait for a rising edge.

    Monitors sample the values that were stable before this edge; drivers then
    update outputs in the following delta cycle for the next clock edge.
    """

    await RisingEdge(dut.aclk)


async def reset(dut) -> None:
    dut.aresetn.value = 0
    dut.awvalid.value = 0
    dut.wvalid.value = 0
    dut.arvalid.value = 0
    dut.bready.value = 0
    dut.rready.value = 0
    dut.bram_wr_ack.value = 0
    dut.bram_wr_err.value = 0
    dut.bram_rd_ack.value = 0
    dut.bram_rd_err.value = 0
    dut.bram_rd_data.value = 0
    await ClockCycles(dut.aclk, 4)
    dut.aresetn.value = 1
    await ClockCycles(dut.aclk, 2)


async def send(dut, prefix: str, value: int) -> None:
    getattr(dut, f"{prefix}valid").value = 1
    if prefix in {"aw", "ar"}:
        getattr(dut, f"{prefix}addr").value = value
    else:
        dut.wdata.value = value
        dut.wstrb.value = STRB_ALL
    while True:
        await RisingEdge(dut.aclk)
        if int(getattr(dut, f"{prefix}ready").value):
            break
    getattr(dut, f"{prefix}valid").value = 0


def bram_latency_from_env(default: int) -> int:
    """Return the optional fixed BRAM latency selected for a command-line run."""

    value = int(os.environ.get("BRAM_LATENCY", str(default)), 0)
    if value < 0:
        raise ValueError("BRAM_LATENCY must be non-negative")
    return value


# ---------------------------------------------------------------------------
# Directed mixed-traffic scenarios
# ---------------------------------------------------------------------------


async def bram_model_split(
    dut,
    issued: list[tuple[bool, int, int]],
) -> None:
    """Pipelined BRAM model watching the split read/write port enables.

    Writes acknowledge after 8 idle clocks and reads after 1, so both
    response paths stay occupied while traffic is in flight.
    """
    pending_writes: deque[int] = deque()
    pending_reads: deque[int] = deque()
    write_delay = 0
    read_delay = 0
    while True:
        await RisingEdge(dut.aclk)
        dut.bram_wr_ack.value = 0
        dut.bram_wr_err.value = 0
        dut.bram_rd_ack.value = 0
        dut.bram_rd_err.value = 0

        if int(dut.bram_wr_en.value):
            address = int(dut.bram_wr_addr.value)
            data = int(dut.bram_wr_data.value)
            issued.append((True, address, data))
            pending_writes.append(address)
        if int(dut.bram_rd_en.value):
            address = int(dut.bram_rd_addr.value)
            issued.append((False, address, 0))
            pending_reads.append(address)

        if pending_writes:
            if write_delay == 0:
                address = pending_writes.popleft()
                dut.bram_wr_ack.value = 1
                dut.bram_wr_err.value = address == WRITE_ERROR_ADDR
                write_delay = 8
            else:
                write_delay -= 1
        if pending_reads:
            if read_delay == 0:
                address = pending_reads.popleft()
                dut.bram_rd_ack.value = 1
                dut.bram_rd_err.value = address == READ_ERROR_ADDR
                dut.bram_rd_data.value = expected_read_data(address)
                read_delay = 1
            else:
                read_delay -= 1


async def collect_responses(dut, num_writes: int, num_reads: int, timeout_cycles: int):
    """Sample B and R handshakes until the expected counts are reached."""
    got_b: list[int] = []
    got_r: list[tuple[int, int]] = []
    for _ in range(timeout_cycles):
        await RisingEdge(dut.aclk)
        if int(dut.bvalid.value) and int(dut.bready.value):
            got_b.append(int(dut.bresp.value))
        if int(dut.rvalid.value) and int(dut.rready.value):
            got_r.append((int(dut.rdata.value), int(dut.rresp.value)))
        if len(got_b) == num_writes and len(got_r) == num_reads:
            break
    return got_b, got_r


def split_issued(issued: list[tuple[bool, int, int]]):
    write_addrs = [addr for is_write, addr, _ in issued if is_write]
    read_addrs = [addr for is_write, addr, _ in issued if not is_write]
    return write_addrs, read_addrs


@cocotb.test()
async def test_top_mixed_read_write_traffic(dut) -> None:
    """Interleaved reads and writes with one error on each channel."""
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    await reset(dut)
    issued: list[tuple[bool, int, int]] = []
    cocotb.start_soon(bram_model_split(dut, issued))

    dut.bready.value = 1
    dut.rready.value = 1
    writes = [
        (0x200, 0x1234_5678 & DATA_MASK),
        (WRITE_ERROR_ADDR, 0xCAFE_BABE & DATA_MASK),
    ]
    reads = [0x100, READ_ERROR_ADDR]
    collector = cocotb.start_soon(collect_responses(dut, len(writes), len(reads), 200))
    await with_timeout(cocotb.start_soon(send(dut, "aw", writes[0][0])), 2, "us")
    await with_timeout(cocotb.start_soon(send(dut, "w", writes[0][1])), 2, "us")
    await with_timeout(cocotb.start_soon(send(dut, "ar", reads[0])), 2, "us")
    await with_timeout(cocotb.start_soon(send(dut, "aw", writes[1][0])), 2, "us")
    await with_timeout(cocotb.start_soon(send(dut, "w", writes[1][1])), 2, "us")
    await with_timeout(cocotb.start_soon(send(dut, "ar", reads[1])), 2, "us")

    got_b, got_r = await with_timeout(collector, 4, "us")
    assert got_b == [0, 2]
    assert got_r == [
        (expected_read_data(reads[0]), 0),
        (expected_read_data(reads[1]), 2),
    ]

    write_addrs, read_addrs = split_issued(issued)
    assert write_addrs == [writes[0][0], writes[1][0]]
    assert read_addrs == reads
    if not USE_DUAL_PORT:
        # The shared arbiter flips preference after every allocation, so the
        # buffered traffic is interleaved while both sides are available.
        assert issued == [
            (False, reads[0], 0),
            (True, writes[0][0], writes[0][1]),
            (False, reads[1], 0),
            (True, writes[1][0], writes[1][1]),
        ]


@cocotb.test()
async def test_top_concurrent_read_write(dut) -> None:
    """Sustained reads and writes in flight at the same time."""
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    await reset(dut)
    issued: list[tuple[bool, int, int]] = []
    cocotb.start_soon(bram_model_split(dut, issued))

    dut.bready.value = 1
    dut.rready.value = 1
    count = 6
    writes = [(0x400 + 4 * i, (0xA5A5_0000 + i) & DATA_MASK) for i in range(count)]
    reads = [0x300 + 4 * i for i in range(count)]
    collector = cocotb.start_soon(collect_responses(dut, count, count, 500))
    for i in range(count):
        await with_timeout(cocotb.start_soon(send(dut, "aw", writes[i][0])), 4, "us")
        await with_timeout(cocotb.start_soon(send(dut, "w", writes[i][1])), 4, "us")
        await with_timeout(cocotb.start_soon(send(dut, "ar", reads[i])), 4, "us")

    got_b, got_r = await with_timeout(collector, 8, "us")
    assert got_b == [0] * count
    assert got_r == [(expected_read_data(addr), 0) for addr in reads]
    write_addrs, read_addrs = split_issued(issued)
    assert write_addrs == [addr for addr, _ in writes]
    assert read_addrs == reads
    write_data = [data for is_write, _, data in issued if is_write]
    assert write_data == [data for _, data in writes]


@cocotb.test()
async def test_top_response_backpressure(dut) -> None:
    """Responses stall with BREADY/RREADY low and drain once released."""
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    await reset(dut)
    issued: list[tuple[bool, int, int]] = []
    cocotb.start_soon(bram_model_split(dut, issued))

    dut.bready.value = 0
    dut.rready.value = 0
    writes = [
        (0x400, 0x1111_2222 & DATA_MASK),
        (0x404, 0x3333_4444 & DATA_MASK),
    ]
    reads = [0x300, 0x304]
    collector = cocotb.start_soon(collect_responses(dut, len(writes), len(reads), 200))
    await with_timeout(cocotb.start_soon(send(dut, "aw", writes[0][0])), 2, "us")
    await with_timeout(cocotb.start_soon(send(dut, "w", writes[0][1])), 2, "us")
    await with_timeout(cocotb.start_soon(send(dut, "ar", reads[0])), 2, "us")
    await with_timeout(cocotb.start_soon(send(dut, "aw", writes[1][0])), 2, "us")
    await with_timeout(cocotb.start_soon(send(dut, "w", writes[1][1])), 2, "us")
    await with_timeout(cocotb.start_soon(send(dut, "ar", reads[1])), 2, "us")

    # Two response credits per channel: everything issues, nothing drains.
    await ClockCycles(dut.aclk, 30)
    assert len(issued) == len(writes) + len(reads)
    assert int(dut.bvalid.value) == 1
    assert int(dut.rvalid.value) == 1

    dut.bready.value = 1
    dut.rready.value = 1
    got_b, got_r = await with_timeout(collector, 4, "us")
    assert got_b == [0, 0]
    assert got_r == [(expected_read_data(addr), 0) for addr in reads]


# ---------------------------------------------------------------------------
# Read agent environment
# ---------------------------------------------------------------------------


def random_read_count_from_env(default: int) -> int:
    """Return the randomized-vector length selected for a command-line run."""

    value = int(os.environ.get("RANDOM_READ_COUNT", str(default)), 0)
    if value <= 0:
        raise ValueError("RANDOM_READ_COUNT must be positive")
    return value


@dataclass(frozen=True)
class ARTransaction:
    """An AXI read-address request.

    ``pre_packet_gap`` is the minimum number of idle clocks between this
    request and the preceding request.  A value of zero permits back-to-back
    AR handshakes.  The actual observed gap can be larger when ARREADY applies
    backpressure.
    """

    address: int
    pre_packet_gap: int = 0

    def __post_init__(self) -> None:
        if self.pre_packet_gap < 0:
            raise ValueError("pre_packet_gap must be non-negative")


@dataclass(frozen=True)
class ARSequence:
    """The AR-channel test vector."""

    transactions: Sequence[ARTransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[ARTransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


@dataclass(frozen=True)
class RTransaction:
    """An R-channel acceptance policy, or a monitored R transfer.

    For a vector, only ``idle_cycles`` is supplied.  A positive value keeps
    RREADY low for that many clocks after RVALID is seen; zero asserts RREADY
    in the same cycle RVALID is observed; a negative value asserts RREADY
    proactively, before waiting for RVALID.  Monitors additionally fill in
    ``data`` and ``resp`` for completed transfers.
    """

    idle_cycles: int = 0
    data: int | None = None
    resp: int | None = None


@dataclass(frozen=True)
class RSequence:
    """The R-channel test vector."""

    transactions: Sequence[RTransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[RTransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


class ARAgent:
    """AR driver and monitor."""

    def __init__(self, dut):
        self.dut = dut
        self.observed: list[ARTransaction] = []

    async def drive(self, sequence: ARSequence) -> None:
        self.dut.arvalid.value = 0
        for transaction in sequence:
            # An idle gap is measured from the handshake edge of the previous
            # request.  Hold ARVALID low for exactly the requested clocks.
            self.dut.arvalid.value = 0
            if transaction.pre_packet_gap:
                await ClockCycles(self.dut.aclk, transaction.pre_packet_gap)
            self.dut.araddr.value = transaction.address
            self.dut.arvalid.value = 1
            while True:
                await _edge(self.dut)
                if int(self.dut.arready.value):
                    break

        self.dut.arvalid.value = 0

    async def monitor(self) -> None:
        last_handshake_cycle: int | None = None
        cycle = 0
        while True:
            await _edge(self.dut)
            cycle += 1
            if int(self.dut.arvalid.value) and int(self.dut.arready.value):
                gap = (
                    0
                    if last_handshake_cycle is None
                    else cycle - last_handshake_cycle - 1
                )
                self.observed.append(
                    ARTransaction(
                        address=int(self.dut.araddr.value), pre_packet_gap=gap
                    )
                )
                last_handshake_cycle = cycle


class RAgent:
    """R driver and monitor."""

    def __init__(self, dut):
        self.dut = dut
        self.observed: list[RTransaction] = []

    async def _wait_for_rvalid(self) -> None:
        """Wait for RVALID, including the delta cycle in which it asserts."""

        if not int(self.dut.rvalid.value):
            await RisingEdge(self.dut.rvalid)
            await ReadWrite()

    async def _wait_for_handshake(self) -> None:
        """Wait for a sampled RVALID/RREADY handshake and settle the DUT."""

        while True:
            await RisingEdge(self.dut.aclk)
            if int(self.dut.rvalid.value) and int(self.dut.rready.value):
                await ReadWrite()
                return

    async def drive(self, sequence: RSequence) -> None:
        self.dut.rready.value = 0
        for transaction in sequence:
            if transaction.idle_cycles < 0:
                # Negative idle requests proactive ready.  Its magnitude is
                # deliberately not a delay: it is a policy, not a timeout.
                self.dut.rready.value = 1
            else:
                await self._wait_for_rvalid()
                if transaction.idle_cycles:
                    await ClockCycles(self.dut.aclk, transaction.idle_cycles)
                self.dut.rready.value = 1

            # For idle_cycles == 0, RREADY was driven in the same delta cycle
            # as RVALID's transition, so the following clock is the handshake.
            await self._wait_for_handshake()
            self.dut.rready.value = 0

    async def monitor(self) -> None:
        valid_since: int | None = None
        cycle = 0
        while True:
            await _edge(self.dut)
            cycle += 1
            if int(self.dut.rvalid.value) and valid_since is None:
                valid_since = cycle
            if int(self.dut.rvalid.value) and int(self.dut.rready.value):
                idle = 0 if valid_since is None else cycle - valid_since
                self.observed.append(
                    RTransaction(
                        idle_cycles=idle,
                        data=int(self.dut.rdata.value),
                        resp=int(self.dut.rresp.value),
                    )
                )
                valid_since = None


class BramReadModel:
    """Pipelined BRAM read model with a configurable read latency.

    A fixed latency of zero models a combinational BRAM response.  A callback
    ``(address, request_index) -> latency`` may return zero or a positive
    value to stress the interface with variable timing.  Responses preserve
    request order and the model emits at most one acknowledgement per clock.
    """

    def __init__(
        self,
        dut,
        latency: int | Callable[[int, int], int] = 1,
        data_fn: Callable[[int], int] | None = None,
        error_fn: Callable[[int], bool] | None = None,
    ):
        self.dut = dut
        self.latency = latency
        self.data_fn = data_fn or expected_read_data
        self.error_fn = error_fn or (lambda _address: False)
        self.requests: list[int] = []

    def expected_data(self, address: int) -> int:
        return self.data_fn(address)

    def expected_resp(self, address: int) -> int:
        return 2 if self.error_fn(address) else 0

    def _latency_for(self, address: int) -> int:
        value = (
            self.latency(address, len(self.requests))
            if callable(self.latency)
            else self.latency
        )
        if value < 0:
            raise ValueError("BRAM latency must be non-negative")
        return value

    async def _run_clocked_latency(self) -> None:
        # Entries are [ack-drive-cycle, address].  Each request gets its own
        # target cycle; the FIFO below arbitrates collisions in request order.
        pending: deque[list[int]] = deque()
        cycle = 0
        self.dut.bram_rd_ack.value = 0
        self.dut.bram_rd_err.value = 0
        while True:
            await RisingEdge(self.dut.aclk)
            # bram_rd_en is assigned by a nonblocking assignment in the DUT.
            # ReadWrite sees its new value in this same timestep, allowing a
            # latency-zero request to drive ACK and data without a clock delay.
            await ReadWrite()
            cycle += 1
            self.dut.bram_rd_ack.value = 0
            self.dut.bram_rd_err.value = 0

            if int(self.dut.bram_rd_en.value):
                address = int(self.dut.bram_rd_addr.value)
                latency = self._latency_for(address)
                pending.append([cycle + latency, address])
                self.requests.append(address)

            # Only the oldest due request may respond.  This preserves BRAM
            # ordering and turns a same-cycle collision into a one-cycle delay
            # for the later response.
            if pending and pending[0][0] <= cycle:
                _, address = pending.popleft()
                self.dut.bram_rd_data.value = self.expected_data(address)
                self.dut.bram_rd_ack.value = 1
                self.dut.bram_rd_err.value = self.error_fn(address)

    async def run(self) -> None:
        await self._run_clocked_latency()


class ReadScoreboard:
    """Checks monitor output against the AR vector and BRAM reference model."""

    def __init__(self, ar_agent: ARAgent, r_agent: RAgent, ram: BramReadModel):
        self.ar_agent = ar_agent
        self.r_agent = r_agent
        self.ram = ram

    async def wait_for_responses(self, count: int, timeout_cycles: int) -> None:
        for _ in range(timeout_cycles):
            if len(self.r_agent.observed) >= count:
                return
            await _edge(self.ar_agent.dut)
        raise TimeoutError(
            f"Timed out waiting for {count} R transfers; got {len(self.r_agent.observed)}"
        )

    def check(self, ar_vector: ARSequence, r_vector: RSequence) -> None:
        expected_addresses = [transaction.address for transaction in ar_vector]
        observed_addresses = [
            transaction.address for transaction in self.ar_agent.observed
        ]
        if observed_addresses != expected_addresses:
            raise AssertionError(
                f"AR monitor mismatch: observed={observed_addresses!r}, expected={expected_addresses!r}"
            )
        if len(self.r_agent.observed) != len(r_vector):
            raise AssertionError(
                f"R monitor count mismatch: observed={len(self.r_agent.observed)}, expected={len(r_vector)}"
            )
        if len(self.r_agent.observed) != len(expected_addresses):
            raise AssertionError(
                f"Read count mismatch: AR={len(expected_addresses)}, R={len(self.r_agent.observed)}"
            )

        for index, (address, response) in enumerate(
            zip(expected_addresses, self.r_agent.observed)
        ):
            expected_data = self.ram.expected_data(address)
            expected_resp = self.ram.expected_resp(address)
            if response.resp != expected_resp:
                raise AssertionError(
                    f"R[{index}] has RRESP={response.resp}, expected {expected_resp}"
                )
            if response.data != expected_data:
                raise AssertionError(
                    f"R[{index}] data mismatch for address 0x{address:08X}: "
                    f"got 0x{response.data:08X}, expected 0x{expected_data:08X}"
                )


class ReadTestbench:
    """Owns agents, reference model, reset, and scenario execution."""

    def __init__(
        self,
        dut,
        bram_latency: int | Callable[[int, int], int] = 1,
        bram_error: Callable[[int], bool] | None = None,
    ):
        self.dut = dut
        self.ar = ARAgent(dut)
        self.r = RAgent(dut)
        self.ram = BramReadModel(dut, latency=bram_latency, error_fn=bram_error)
        self.scoreboard = ReadScoreboard(self.ar, self.r, self.ram)

    async def start(self) -> None:
        await reset(self.dut)
        cocotb.start_soon(self.ar.monitor())
        cocotb.start_soon(self.r.monitor())
        cocotb.start_soon(self.ram.run())

    async def run(
        self,
        ar_vector: ARSequence,
        r_vector: RSequence,
        *,
        r_start_delay: int = 0,
        timeout_cycles: int = 500,
        post_idle_cycles: int = 10,
    ) -> None:
        if len(ar_vector) != len(r_vector):
            raise ValueError(
                "AR and R vectors must contain the same number of transactions"
            )
        if post_idle_cycles < 0:
            raise ValueError("post_idle_cycles must be non-negative")

        async def drive_r() -> None:
            await ClockCycles(self.dut.aclk, r_start_delay)
            await self.r.drive(r_vector)

        ar_driver = cocotb.start_soon(self.ar.drive(ar_vector))
        r_driver = cocotb.start_soon(drive_r())
        await with_timeout(ar_driver, timeout_cycles * 10, "ns")
        await with_timeout(r_driver, timeout_cycles * 10, "ns")
        await self.scoreboard.wait_for_responses(len(ar_vector), timeout_cycles)
        self.scoreboard.check(ar_vector, r_vector)

        # Keep the idle bus visible after the final observed transfer so a
        # waveform viewer has useful context after the scenario completes.
        self.dut.arvalid.value = 0
        self.dut.rready.value = 0
        await ClockCycles(self.dut.aclk, post_idle_cycles)


async def make_read_testbench(
    dut,
    latency: int | Callable[[int, int], int] = 1,
    bram_error: Callable[[int], bool] | None = None,
) -> ReadTestbench:
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    tb = ReadTestbench(dut, bram_latency=latency, bram_error=bram_error)
    await tb.start()
    return tb


@cocotb.test()
async def test_r_single_read(dut):
    """Simple one-read scenario."""
    tb = await make_read_testbench(dut, latency=bram_latency_from_env(1))
    await tb.run(ARSequence([ARTransaction(0x100)]), RSequence([RTransaction(0)]))


@cocotb.test()
async def test_r_bram_errors(dut):
    """BRAM read errors must become AXI SLVERR responses."""
    tb = await make_read_testbench(
        dut, latency=1, bram_error=lambda address: address == READ_ERROR_ADDR
    )
    addresses = [0x100, READ_ERROR_ADDR, 0x108]
    await tb.run(
        ARSequence([ARTransaction(address) for address in addresses]),
        RSequence([RTransaction(-1) for _ in addresses]),
    )


@cocotb.test()
async def test_r_back_to_back_reads(dut):
    """Back-to-back AR requests and proactive R acceptance."""
    tb = await make_read_testbench(dut, latency=1)
    addresses = [0x100, 0x200, 0x300, 0x400, 0x500]
    await tb.run(
        ARSequence([ARTransaction(address, pre_packet_gap=0) for address in addresses]),
        RSequence([RTransaction(-1) for _ in addresses]),
    )


@cocotb.test()
async def test_r_ordered_variable_latency(dut):
    """Colliding response cycles must remain ordered and use one ACK per clock."""
    latencies = [3, 2, 0, 1, 0]
    tb = await make_read_testbench(
        dut, latency=lambda _address, index: latencies[index]
    )
    addresses = [0x600 + 4 * index for index in range(len(latencies))]
    await tb.run(
        ARSequence([ARTransaction(address) for address in addresses]),
        RSequence([RTransaction(-1) for _ in addresses]),
    )


@cocotb.test()
async def test_r_stress_then_flush(dut):
    """Fill the DUT under R backpressure, then flush all responses."""
    tb = await make_read_testbench(dut, latency=3)
    addresses = [0x300 + 4 * index for index in range(12)]
    await tb.run(
        ARSequence([ARTransaction(address) for address in addresses]),
        RSequence([RTransaction(-1) for _ in addresses]),
        r_start_delay=12,
        timeout_cycles=1_000,
    )


@cocotb.test()
async def test_r_random_reads(dut):
    """Random AR gaps, random R acceptance delays, and variable BRAM latency."""
    rng = random.Random(42)
    tb = await make_read_testbench(dut, latency=lambda _address, index: index % 4)
    num_reads = random_read_count_from_env(250)
    address_count = 1 << max(ADDR_WIDTH - 2, 1)
    addresses = [rng.randrange(0, address_count) * 4 for _ in range(num_reads)]
    ar_vector = ARSequence(
        [ARTransaction(address, rng.randrange(0, 4)) for address in addresses]
    )
    r_vector = RSequence([RTransaction(rng.choice([-1, 0, 1, 2])) for _ in addresses])
    await tb.run(ar_vector, r_vector, timeout_cycles=20_000)


# ---------------------------------------------------------------------------
# Write agent environment
# ---------------------------------------------------------------------------


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
                gap = (
                    0
                    if last_handshake_cycle is None
                    else cycle - last_handshake_cycle - 1
                )
                self.observed.append(
                    AWTransaction(
                        address=int(self.dut.awaddr.value), pre_packet_gap=gap
                    )
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
                gap = (
                    0
                    if last_handshake_cycle is None
                    else cycle - last_handshake_cycle - 1
                )
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
        value = (
            self.latency(address, len(self.writes))
            if callable(self.latency)
            else self.latency
        )
        if value < 0:
            raise ValueError("BRAM latency must be non-negative")
        return value

    async def _run_clocked_latency(self) -> None:
        # Entries are [ack-drive-cycle, address].  Each request gets its own
        # target cycle; the FIFO below arbitrates collisions in request order.
        pending: deque[list[int]] = deque()
        cycle = 0
        self.dut.bram_wr_ack.value = 0
        self.dut.bram_wr_err.value = 0
        while True:
            await RisingEdge(self.dut.aclk)
            # bram_wr_en is assigned by a nonblocking assignment in the DUT.
            # ReadWrite sees its new value in this same timestep, allowing a
            # latency-zero request to drive ACK without a clock delay.
            await ReadWrite()
            cycle += 1
            self.dut.bram_wr_ack.value = 0
            self.dut.bram_wr_err.value = 0

            if int(self.dut.bram_wr_en.value):
                address = int(self.dut.bram_wr_addr.value)
                data = int(self.dut.bram_wr_data.value)
                strb = int(self.dut.bram_wr_strb.value)
                latency = self._latency_for(address)
                pending.append([cycle + latency, address])
                self.writes.append((address, data, strb))

            # Only the oldest due request may respond.  This preserves BRAM
            # ordering and turns a same-cycle collision into a one-cycle delay
            # for the later response.
            if pending and pending[0][0] <= cycle:
                _, address = pending.popleft()
                self.dut.bram_wr_ack.value = 1
                self.dut.bram_wr_err.value = self.error_fn(address)

    async def run(self) -> None:
        await self._run_clocked_latency()


class WriteScoreboard:
    """Checks monitor output against the vectors and the BRAM reference model."""

    def __init__(
        self, aw_agent: AWAgent, w_agent: WAgent, b_agent: BAgent, ram: BramWriteModel
    ):
        self.aw_agent = aw_agent
        self.w_agent = w_agent
        self.b_agent = b_agent
        self.ram = ram

    async def wait_for_responses(self, count: int, timeout_cycles: int) -> None:
        for _ in range(timeout_cycles):
            if len(self.b_agent.observed) >= count:
                return
            await _edge(self.b_agent.dut)
        raise TimeoutError(
            f"Timed out waiting for {count} B transfers; got {len(self.b_agent.observed)}"
        )

    def check(
        self, aw_vector: AWSequence, w_vector: WSequence, b_vector: BSequence
    ) -> None:
        expected_addresses = [transaction.address for transaction in aw_vector]
        observed_addresses = [
            transaction.address for transaction in self.aw_agent.observed
        ]
        if observed_addresses != expected_addresses:
            raise AssertionError(
                f"AW monitor mismatch: observed={observed_addresses!r}, expected={expected_addresses!r}"
            )
        expected_payloads = [
            (transaction.data, transaction.strb) for transaction in w_vector
        ]
        observed_payloads = [
            (transaction.data, transaction.strb)
            for transaction in self.w_agent.observed
        ]
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

        for index, (address, response) in enumerate(
            zip(expected_addresses, self.b_agent.observed)
        ):
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

    async def start(self) -> None:
        await reset(self.dut)
        cocotb.start_soon(self.aw.monitor())
        cocotb.start_soon(self.w.monitor())
        cocotb.start_soon(self.b.monitor())
        cocotb.start_soon(self.ram.run())

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
            raise ValueError(
                "AW, W and B vectors must contain the same number of transactions"
            )
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


async def make_write_testbench(
    dut,
    latency: int | Callable[[int, int], int] = 1,
    bram_error: Callable[[int], bool] | None = None,
) -> WriteTestbench:
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    tb = WriteTestbench(dut, bram_latency=latency, bram_error=bram_error)
    await tb.start()
    return tb


@cocotb.test()
async def test_w_single_write(dut):
    """Simple one-write scenario."""
    tb = await make_write_testbench(dut, latency=bram_latency_from_env(1))
    await tb.run(
        AWSequence([AWTransaction(0x100)]),
        WSequence([WTransaction(0xDEAD_BEEF & DATA_MASK)]),
        BSequence([BTransaction(0)]),
    )


@cocotb.test()
async def test_w_bram_errors(dut):
    """BRAM write errors must become AXI SLVERR responses."""
    tb = await make_write_testbench(
        dut, latency=1, bram_error=lambda address: address == WRITE_ERROR_ADDR
    )
    addresses = [0x200, WRITE_ERROR_ADDR, 0x208]
    await tb.run(
        AWSequence([AWTransaction(address) for address in addresses]),
        WSequence(
            [
                WTransaction((0xABCD_0000 + index) & DATA_MASK)
                for index in range(len(addresses))
            ]
        ),
        BSequence([BTransaction(-1) for _ in addresses]),
    )


@cocotb.test()
async def test_w_back_to_back_writes(dut):
    """Back-to-back AW/W requests with partial strobes and proactive B."""
    tb = await make_write_testbench(dut, latency=1)
    count = 5
    strbs = [max(1, s & STRB_ALL) for s in (0xF, 0x1, 0x3, 0xC, 0x5)]
    await tb.run(
        AWSequence([AWTransaction(0x100 + 4 * index) for index in range(count)]),
        WSequence(
            [
                WTransaction((0xA5A5_0000 + index) & DATA_MASK, strbs[index])
                for index in range(count)
            ]
        ),
        BSequence([BTransaction(-1) for _ in range(count)]),
    )


@cocotb.test()
async def test_w_ordered_variable_latency(dut):
    """Colliding ack cycles must remain ordered and use one ACK per clock."""
    latencies = [3, 2, 0, 1, 0]
    tb = await make_write_testbench(
        dut, latency=lambda _address, index: latencies[index]
    )
    count = len(latencies)
    await tb.run(
        AWSequence([AWTransaction(0x600 + 4 * index) for index in range(count)]),
        WSequence(
            [WTransaction((0x5A5A_0000 + index) & DATA_MASK) for index in range(count)]
        ),
        BSequence([BTransaction(-1) for _ in range(count)]),
    )


@cocotb.test()
async def test_w_stress_then_flush(dut):
    """Fill the DUT under B backpressure, then flush all responses."""
    tb = await make_write_testbench(dut, latency=3)
    count = 12
    await tb.run(
        AWSequence([AWTransaction(0x300 + 4 * index) for index in range(count)]),
        WSequence(
            [WTransaction((0xC3C3_0000 + index) & DATA_MASK) for index in range(count)]
        ),
        BSequence([BTransaction(-1) for _ in range(count)]),
        b_start_delay=12,
        timeout_cycles=1_000,
    )


@cocotb.test()
async def test_w_channel_skew(dut):
    """AW may run ahead of W; writes issue only once both are buffered."""
    tb = await make_write_testbench(dut, latency=1)
    count = 8
    await tb.run(
        AWSequence([AWTransaction(0x200 + 4 * index) for index in range(count)]),
        WSequence(
            [WTransaction((0x3C3C_0000 + index) & DATA_MASK) for index in range(count)]
        ),
        BSequence([BTransaction(-1) for _ in range(count)]),
        w_start_delay=6,
    )


@cocotb.test()
async def test_w_random_writes(dut):
    """Random AW/W gaps, random B acceptance delays, and variable BRAM latency."""
    rng = random.Random(42)
    tb = await make_write_testbench(dut, latency=lambda _address, index: index % 4)
    num_writes = random_write_count_from_env(250)
    address_count = 1 << max(ADDR_WIDTH - 2, 1)
    aw_vector = AWSequence(
        [
            AWTransaction(rng.randrange(0, address_count) * 4, rng.randrange(0, 4))
            for _ in range(num_writes)
        ]
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
    b_vector = BSequence(
        [BTransaction(rng.choice([-1, 0, 1, 2])) for _ in range(num_writes)]
    )
    await tb.run(aw_vector, w_vector, b_vector, timeout_cycles=20_000)


# ---------------------------------------------------------------------------
# Parametrized runner over the configuration matrix
# ---------------------------------------------------------------------------

CASES = [
    {
        "name": f"dual{dual}_addr{addr_width}_data{data_width}",
        "params": {
            "USE_DUAL_PORT": dual,
            "ADDR_WIDTH": addr_width,
            "DATA_WIDTH": data_width,
        },
    }
    for dual in (0, 1)
    for addr_width in (32, 12)
    for data_width in (32, 16)
]


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_axi4l_bram_runner(case) -> None:
    """Build one configuration of the top and run the whole scenario set."""
    parameters = case["params"]
    extra_env = {key: str(value) for key, value in parameters.items()}
    run_dir = PRJ_PATH / "sim_build" / case["name"]

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="axi4l_bram",
        sources=resolve_flt(PRJ_PATH / "axi4l_bram.flt"),
        parameters=parameters,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="axi4l_bram",
        test_module="test_axi4l_bram",
        waves=True,
        test_dir=run_dir,
        extra_env=extra_env,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
