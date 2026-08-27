"""Reusable agents for native synchronous and asynchronous FIFO interfaces."""

from __future__ import annotations

import random
from collections.abc import Iterator, Sequence
from dataclasses import dataclass, field
from typing import Any

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Lock, RisingEdge, with_timeout

from .tb_base import AgentMode, AnalysisPort

__all__ = [
    "FifoError",
    "FifoReadAgent",
    "FifoReadBus",
    "FifoReadDriver",
    "FifoReadMonitor",
    "FifoReadSequence",
    "FifoReadTransaction",
    "FifoScoreboard",
    "FifoTestbench",
    "FifoTransfer",
    "FifoWriteAgent",
    "FifoWriteBus",
    "FifoWriteDriver",
    "FifoWriteMonitor",
    "FifoWriteSequence",
    "FifoWriteTransaction",
    "directed_sequences",
    "random_sequences",
]


class FifoError(AssertionError):
    """Raised for an invalid FIFO operation or a transaction timeout."""


@dataclass(frozen=True)
class FifoWriteTransaction:
    """One write request, including optional source-side backpressure."""

    data: int
    wren_probability: float = 1.0
    pre_gap: int = 0
    max_cycles: int | None = None

    def __post_init__(self) -> None:
        if not 0.0 <= self.wren_probability <= 1.0:
            raise ValueError("wren_probability must be within [0.0, 1.0]")
        if self.pre_gap < 0:
            raise ValueError("pre_gap must be non-negative")
        if self.max_cycles is not None and self.max_cycles <= 0:
            raise ValueError("max_cycles must be positive")


@dataclass(frozen=True)
class FifoWriteSequence:
    transactions: Sequence[FifoWriteTransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[FifoWriteTransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


@dataclass(frozen=True)
class FifoReadTransaction:
    """One read request, including optional sink-side backpressure."""

    rden_probability: float = 1.0
    pre_gap: int = 0
    max_cycles: int | None = None

    def __post_init__(self) -> None:
        if not 0.0 <= self.rden_probability <= 1.0:
            raise ValueError("rden_probability must be within [0.0, 1.0]")
        if self.pre_gap < 0:
            raise ValueError("pre_gap must be non-negative")
        if self.max_cycles is not None and self.max_cycles <= 0:
            raise ValueError("max_cycles must be positive")


@dataclass(frozen=True)
class FifoReadSequence:
    transactions: Sequence[FifoReadTransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[FifoReadTransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


@dataclass(frozen=True)
class FifoTransfer:
    """One accepted FIFO transfer observed at an interface."""

    data: int
    cycle: int


@dataclass(frozen=True)
class FifoWriteBus:
    clk: Any
    en: Any
    data: Any
    full: Any


@dataclass(frozen=True)
class FifoReadBus:
    clk: Any
    en: Any
    data: Any
    empty: Any


class FifoWriteDriver:
    """Active driver for a FIFO write port."""

    def __init__(self, bus, rng, data_width):
        self.bus = bus
        self.rng = rng
        self.data_width = data_width
        self.aborted_cycles = 0
        self._transaction_lock = Lock()

    def _noise(self):
        return self.rng.randrange(2**self.data_width)

    def idle(self):
        self.bus.en.value = 0
        self.bus.data.value = self._noise()

    async def drive(self, sequence):
        async with self._transaction_lock:
            self.idle()
            for transaction in sequence:
                if transaction.pre_gap:
                    self.bus.en.value = 0
                    for _ in range(transaction.pre_gap):
                        self.bus.data.value = self._noise()
                        await RisingEdge(self.bus.clk)

                cycles = 0
                while True:
                    if (
                        transaction.max_cycles is not None
                        and cycles >= transaction.max_cycles
                    ):
                        self.idle()
                        raise FifoError("write transaction timed out before acceptance")

                    enabled = self.rng.random() < transaction.wren_probability
                    self.bus.en.value = int(enabled)
                    self.bus.data.value = transaction.data if enabled else self._noise()
                    await RisingEdge(self.bus.clk)
                    cycles += 1

                    if enabled and not int(self.bus.full.value):
                        break
                    if not enabled:
                        self.aborted_cycles += 1
            self.idle()


class FifoReadDriver:
    """Active driver for a FIFO read port."""

    def __init__(self, bus, rng):
        self.bus = bus
        self.rng = rng
        self.aborted_cycles = 0
        self._transaction_lock = Lock()

    def idle(self):
        self.bus.en.value = 0

    async def drive(self, sequence):
        async with self._transaction_lock:
            self.idle()
            for transaction in sequence:
                if transaction.pre_gap:
                    self.bus.en.value = 0
                    await ClockCycles(self.bus.clk, transaction.pre_gap)

                cycles = 0
                while True:
                    if (
                        transaction.max_cycles is not None
                        and cycles >= transaction.max_cycles
                    ):
                        self.idle()
                        raise FifoError("read transaction timed out before acceptance")

                    enabled = self.rng.random() < transaction.rden_probability
                    self.bus.en.value = int(enabled)
                    await RisingEdge(self.bus.clk)
                    cycles += 1

                    if enabled and not int(self.bus.empty.value):
                        break
                    if not enabled:
                        self.aborted_cycles += 1
            self.idle()


class _FifoMonitor:
    def __init__(self, bus):
        self.bus = bus
        self.transfers = AnalysisPort[FifoTransfer]()
        self.observed: list[FifoTransfer] = []
        self._task = None

    def start(self):
        if self._task is None:
            self._task = cocotb.start_soon(self.run())
        return self._task

    def stop(self):
        if self._task is not None:
            self._task.cancel()
            self._task = None

    def _publish(self, data, cycle):
        transfer = FifoTransfer(data=data, cycle=cycle)
        self.observed.append(transfer)
        self.transfers.write(transfer)


class FifoWriteMonitor(_FifoMonitor):
    """Passive monitor for accepted FIFO writes."""

    async def run(self):
        cycle = 0
        while True:
            await RisingEdge(self.bus.clk)
            cycle += 1
            if int(self.bus.en.value) and not int(self.bus.full.value):
                self._publish(int(self.bus.data.value), cycle)


class FifoReadMonitor(_FifoMonitor):
    """Passive monitor for accepted FIFO reads."""

    async def run(self):
        cycle = 0
        while True:
            await RisingEdge(self.bus.clk)
            cycle += 1
            if int(self.bus.en.value) and not int(self.bus.empty.value):
                self._publish(int(self.bus.data.value), cycle)


class FifoWriteAgent:
    """FIFO write agent containing a monitor and optional active driver."""

    def __init__(self, bus, rng=None, data_width=None, mode=AgentMode.ACTIVE):
        self.bus = bus
        self.monitor = FifoWriteMonitor(bus)
        if AgentMode(mode) is AgentMode.ACTIVE:
            if data_width is None:
                data_width = len(bus.data)
            self.driver = FifoWriteDriver(bus, rng or random.Random(), data_width)
        else:
            self.driver = None

    @property
    def observed(self):
        return self.monitor.observed

    @property
    def aborted_cycles(self):
        return 0 if self.driver is None else self.driver.aborted_cycles

    async def start(self):
        if self.driver is not None:
            self.driver.idle()
        self.monitor.start()

    def stop(self):
        self.monitor.stop()
        if self.driver is not None:
            self.driver.idle()

    async def drive(self, sequence):
        if self.driver is None:
            raise FifoError("passive FIFO write agent has no driver")
        await self.driver.drive(sequence)


class FifoReadAgent:
    """FIFO read agent containing a monitor and optional active driver."""

    def __init__(self, bus, rng=None, mode=AgentMode.ACTIVE):
        self.bus = bus
        self.monitor = FifoReadMonitor(bus)
        self.driver = (
            FifoReadDriver(bus, rng or random.Random())
            if AgentMode(mode) is AgentMode.ACTIVE
            else None
        )

    @property
    def observed(self):
        return self.monitor.observed

    @property
    def aborted_cycles(self):
        return 0 if self.driver is None else self.driver.aborted_cycles

    async def start(self):
        if self.driver is not None:
            self.driver.idle()
        self.monitor.start()

    def stop(self):
        self.monitor.stop()
        if self.driver is not None:
            self.driver.idle()

    async def drive(self, sequence):
        if self.driver is None:
            raise FifoError("passive FIFO read agent has no driver")
        await self.driver.drive(sequence)


class FifoScoreboard:
    def __init__(self, write_agent, read_agent):
        self.write_agent = write_agent
        self.read_agent = read_agent

    def check(self):
        written = [transfer.data for transfer in self.write_agent.observed]
        read = [transfer.data for transfer in self.read_agent.observed]
        if len(written) != len(read):
            raise FifoError(
                f"transfer count mismatch: written={len(written)}, read={len(read)}"
            )
        for index, (expected, actual) in enumerate(zip(written, read, strict=True)):
            if expected != actual:
                raise FifoError(
                    f"transfer {index} mismatch: expected={expected:#x}, "
                    f"actual={actual:#x}"
                )


class FifoTestbench:
    """Compatibility testbench facade composed from the reusable agents."""

    def __init__(self, write_bus, read_bus, reset_signal, data_width):
        self.write_bus = write_bus
        self.read_bus = read_bus
        self.reset_signal = reset_signal
        self.data_width = data_width
        self.write_agent = FifoWriteAgent(
            write_bus,
            random.Random(0x1234),
            data_width,
        )
        self.read_agent = FifoReadAgent(read_bus, random.Random(0x5678))
        self.scoreboard = FifoScoreboard(self.write_agent, self.read_agent)

    async def start(self, clocks=(), reset_cycles=10, settle_cycles=10):
        for signal, period, unit in clocks:
            cocotb.start_soon(Clock(signal, period, unit=unit).start())

        self.reset_signal.value = 1
        self.write_bus.en.value = 0
        self.write_bus.data.value = 0
        self.read_bus.en.value = 0

        await ClockCycles(self.write_bus.clk, reset_cycles)
        if self.read_bus.clk is not self.write_bus.clk:
            await ClockCycles(self.read_bus.clk, reset_cycles)
        self.reset_signal.value = 0
        await ClockCycles(self.write_bus.clk, settle_cycles)
        if self.read_bus.clk is not self.write_bus.clk:
            await ClockCycles(self.read_bus.clk, settle_cycles)

        await self.write_agent.start()
        await self.read_agent.start()

    async def run(self, write_sequence, read_sequence, timeout_ns=100_000):
        if len(write_sequence) != len(read_sequence):
            raise ValueError("write and read sequences must contain equal transactions")
        write_task = cocotb.start_soon(self.write_agent.drive(write_sequence))
        read_task = cocotb.start_soon(self.read_agent.drive(read_sequence))
        await with_timeout(write_task, timeout_ns, "ns")
        await with_timeout(read_task, timeout_ns, "ns")
        await ClockCycles(self.write_bus.clk, 2)
        if self.read_bus.clk is not self.write_bus.clk:
            await ClockCycles(self.read_bus.clk, 2)
        self.scoreboard.check()


def directed_sequences(data_width, count=32):
    mask = 2**data_width - 1
    writes = tuple(
        FifoWriteTransaction(
            data=(index * 17 + 3) & mask,
            wren_probability=1.0,
            max_cycles=64,
        )
        for index in range(count)
    )
    reads = tuple(
        FifoReadTransaction(
            rden_probability=1.0,
            pre_gap=8 if index == 0 else 0,
            max_cycles=128,
        )
        for index in range(count)
    )
    return FifoWriteSequence(writes), FifoReadSequence(reads)


def random_sequences(data_width, transfer_count, seed=0xC0C0_2026):
    rng = random.Random(seed)
    mask = 2**data_width - 1
    write_probabilities = (0.15, 0.35, 0.5, 0.8, 1.0)
    read_probabilities = (0.1, 0.25, 0.5, 0.75, 1.0)
    writes = tuple(
        FifoWriteTransaction(
            data=rng.randrange(mask + 1),
            wren_probability=rng.choice(write_probabilities),
            pre_gap=rng.randrange(4),
            max_cycles=512,
        )
        for _ in range(transfer_count)
    )
    reads = tuple(
        FifoReadTransaction(
            rden_probability=rng.choice(read_probabilities),
            pre_gap=rng.randrange(3),
            max_cycles=1024,
        )
        for _ in range(transfer_count)
    )
    return FifoWriteSequence(writes), FifoReadSequence(reads)
