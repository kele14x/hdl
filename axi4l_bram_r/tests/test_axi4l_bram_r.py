#!/usr/bin/env python3
"""Reusable cocotb verification environment for ``axi4l_bram_r``.

The tests at the end of this file are intentionally only vector construction.
Add a new scenario by creating an :class:`ARSequence` and an :class:`RSequence`
and passing them to :meth:`ReadTestbench.run`.
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

DATA_XOR = 0xDEADBEEF


def bram_latency_from_env(default: int) -> int:
    """Return the optional fixed BRAM latency selected for a command-line run."""

    value = int(os.environ.get("BRAM_LATENCY", str(default)), 0)
    if value < 0:
        raise ValueError("BRAM_LATENCY must be non-negative")
    return value


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


async def _edge(dut) -> None:
    """Wait for a rising edge.

    Monitors sample the values that were stable before this edge; drivers then
    update outputs in the following delta cycle for the next clock edge.
    """

    await RisingEdge(dut.aclk)


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
                gap = 0 if last_handshake_cycle is None else cycle - last_handshake_cycle - 1
                self.observed.append(
                    ARTransaction(address=int(self.dut.araddr.value), pre_packet_gap=gap)
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
    ):
        self.dut = dut
        self.latency = latency
        self.data_fn = data_fn or (lambda address: address ^ DATA_XOR)
        self.requests: list[int] = []

    def expected_data(self, address: int) -> int:
        return self.data_fn(address)

    def _latency_for(self, address: int) -> int:
        value = self.latency(address, len(self.requests)) if callable(self.latency) else self.latency
        if value < 0:
            raise ValueError("BRAM latency must be non-negative")
        return value

    async def _run_clocked_latency(self) -> None:
        # Entries are [ack-drive-cycle, address].  Each request gets its own
        # target cycle; the FIFO below arbitrates collisions in request order.
        pending: deque[list[int]] = deque()
        cycle = 0
        self.dut.bram_ack.value = 0
        while True:
            await RisingEdge(self.dut.aclk)
            # bram_en is assigned by a nonblocking assignment in the DUT.
            # ReadWrite sees its new value in this same timestep, allowing a
            # latency-zero request to drive ACK and data without a clock delay.
            await ReadWrite()
            cycle += 1
            self.dut.bram_ack.value = 0

            if int(self.dut.bram_en.value):
                address = int(self.dut.bram_addr.value)
                latency = self._latency_for(address)
                pending.append([cycle + latency, address])
                self.requests.append(address)

            # Only the oldest due request may respond.  This preserves BRAM
            # ordering and turns a same-cycle collision into a one-cycle delay
            # for the later response.
            if pending and pending[0][0] <= cycle:
                _, address = pending.popleft()
                self.dut.bram_rdata.value = self.expected_data(address)
                self.dut.bram_ack.value = 1

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
        raise TimeoutError(f"Timed out waiting for {count} R transfers; got {len(self.r_agent.observed)}")

    def check(self, ar_vector: ARSequence, r_vector: RSequence) -> None:
        expected_addresses = [transaction.address for transaction in ar_vector]
        observed_addresses = [transaction.address for transaction in self.ar_agent.observed]
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

        for index, (address, response) in enumerate(zip(expected_addresses, self.r_agent.observed)):
            expected_data = self.ram.expected_data(address)
            if response.resp != 0:
                raise AssertionError(f"R[{index}] has RRESP={response.resp}, expected OKAY")
            if response.data != expected_data:
                raise AssertionError(
                    f"R[{index}] data mismatch for address 0x{address:08X}: "
                    f"got 0x{response.data:08X}, expected 0x{expected_data:08X}"
                )


async def check_no_ack_when_full(dut) -> None:
    """Protocol guard: the DUT must not accept BRAM data with a full R FIFO."""

    while True:
        await _edge(dut)
        if int(dut.r_state.value) == 0b11 and int(dut.bram_ack.value):
            raise AssertionError("bram_ack asserted while both R slots are occupied")


class ReadTestbench:
    """Owns agents, reference model, reset, and scenario execution."""

    def __init__(self, dut, bram_latency: int | Callable[[int, int], int] = 1):
        self.dut = dut
        self.ar = ARAgent(dut)
        self.r = RAgent(dut)
        self.ram = BramReadModel(dut, latency=bram_latency)
        self.scoreboard = ReadScoreboard(self.ar, self.r, self.ram)

    async def reset(self) -> None:
        self.dut.aresetn.value = 0
        self.dut.arvalid.value = 0
        self.dut.araddr.value = 0
        self.dut.rready.value = 0
        self.dut.bram_rdata.value = 0
        self.dut.bram_ack.value = 0
        await ClockCycles(self.dut.aclk, 5)
        self.dut.aresetn.value = 1
        await ClockCycles(self.dut.aclk, 2)

    async def start(self) -> None:
        await self.reset()
        cocotb.start_soon(self.ar.monitor())
        cocotb.start_soon(self.r.monitor())
        cocotb.start_soon(self.ram.run())
        cocotb.start_soon(check_no_ack_when_full(self.dut))

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
            raise ValueError("AR and R vectors must contain the same number of transactions")
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


async def make_testbench(dut, latency: int | Callable[[int, int], int] = 1) -> ReadTestbench:
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    tb = ReadTestbench(dut, bram_latency=latency)
    await tb.start()
    return tb


@cocotb.test()
async def test_single_read(dut):
    """Simple one-read scenario."""
    tb = await make_testbench(dut, latency=bram_latency_from_env(1))
    await tb.run(ARSequence([ARTransaction(0x1000)]), RSequence([RTransaction(0)]))


@cocotb.test()
async def test_back_to_back_reads(dut):
    """Back-to-back AR requests and proactive R acceptance."""
    tb = await make_testbench(dut, latency=1)
    addresses = [0x100, 0x200, 0x300, 0x400, 0x500]
    await tb.run(
        ARSequence([ARTransaction(address, pre_packet_gap=0) for address in addresses]),
        RSequence([RTransaction(-1) for _ in addresses]),
    )


@cocotb.test()
async def test_ordered_variable_bram_latency(dut):
    """Colliding response cycles must remain ordered and use one ACK per clock."""
    latencies = [3, 2, 0, 1, 0]
    tb = await make_testbench(dut, latency=lambda _address, index: latencies[index])
    addresses = [0x800 + 4 * index for index in range(len(latencies))]
    await tb.run(
        ARSequence([ARTransaction(address) for address in addresses]),
        RSequence([RTransaction(-1) for _ in addresses]),
    )


@cocotb.test()
async def test_ar_stress_then_flush_r(dut):
    """Fill the DUT under R backpressure, then flush all responses."""
    tb = await make_testbench(dut, latency=3)
    addresses = [0x1000 + 4 * index for index in range(12)]
    await tb.run(
        ARSequence([ARTransaction(address) for address in addresses]),
        RSequence([RTransaction(-1) for _ in addresses]),
        r_start_delay=12,
        timeout_cycles=1_000,
    )


@cocotb.test()
async def test_random_reads(dut):
    """Random AR gaps, random R acceptance delays, and variable BRAM latency."""
    rng = random.Random(42)
    tb = await make_testbench(dut, latency=lambda _address, index: index % 4)
    num_reads = random_read_count_from_env(250)
    addresses = [rng.randrange(0, 0x1_0000) * 4 for _ in range(num_reads)]
    ar_vector = ARSequence([ARTransaction(address, rng.randrange(0, 4)) for address in addresses])
    r_vector = RSequence([RTransaction(rng.choice([-1, 0, 1, 2])) for _ in addresses])
    await tb.run(ar_vector, r_vector, timeout_cycles=20_000)


def test_axi4l_bram_r_runner():
    """Run the test for AXI4-Lite BRAM read adapter"""
    hdl_toplevel = "axi4l_bram_r"

    verilog_sources = resolve_flt(prj_path / "axi4l_bram_r.flt")

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
        test_module="test_axi4l_bram_r",
        waves=True,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
