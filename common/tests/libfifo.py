#!/usr/bin/env python3
from __future__ import annotations

from collections.abc import Iterator, Sequence
from dataclasses import dataclass, field
import random
from typing import Any

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout


@dataclass(frozen=True)
class FifoWriteTransaction:
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


class FifoWriteAgent:
    def __init__(self, bus: FifoWriteBus, rng: random.Random, data_width: int):
        self.bus = bus
        self.rng = rng
        self.data_width = data_width
        self.observed: list[FifoTransfer] = []
        self.aborted_cycles = 0

    def _noise(self) -> int:
        return self.rng.randrange(2**self.data_width)

    async def drive(self, sequence: FifoWriteSequence) -> None:
        self.bus.en.value = 0
        self.bus.data.value = self._noise()

        for transaction in sequence:
            if transaction.pre_gap:
                self.bus.en.value = 0
                for _ in range(transaction.pre_gap):
                    self.bus.data.value = self._noise()
                    await RisingEdge(self.bus.clk)

            cycles = 0
            while True:
                assert transaction.max_cycles is None or cycles < transaction.max_cycles, (
                    "write transaction timed out before acceptance"
                )

                wren = self.rng.random() < transaction.wren_probability
                self.bus.en.value = int(wren)
                self.bus.data.value = transaction.data if wren else self._noise()
                await RisingEdge(self.bus.clk)
                cycles += 1

                if wren and not int(self.bus.full.value):
                    break
                if not wren:
                    self.aborted_cycles += 1

        self.bus.en.value = 0
        self.bus.data.value = self._noise()

    async def monitor(self) -> None:
        cycle = 0
        while True:
            await RisingEdge(self.bus.clk)
            cycle += 1
            if int(self.bus.en.value) and not int(self.bus.full.value):
                self.observed.append(FifoTransfer(data=int(self.bus.data.value), cycle=cycle))


class FifoReadAgent:
    def __init__(self, bus: FifoReadBus, rng: random.Random):
        self.bus = bus
        self.rng = rng
        self.observed: list[FifoTransfer] = []
        self.aborted_cycles = 0

    async def drive(self, sequence: FifoReadSequence) -> None:
        self.bus.en.value = 0

        for transaction in sequence:
            if transaction.pre_gap:
                self.bus.en.value = 0
                await ClockCycles(self.bus.clk, transaction.pre_gap)

            cycles = 0
            while True:
                assert transaction.max_cycles is None or cycles < transaction.max_cycles, (
                    "read transaction timed out before acceptance"
                )

                rden = self.rng.random() < transaction.rden_probability
                self.bus.en.value = int(rden)
                await RisingEdge(self.bus.clk)
                cycles += 1

                if rden and not int(self.bus.empty.value):
                    break
                if not rden:
                    self.aborted_cycles += 1

        self.bus.en.value = 0

    async def monitor(self) -> None:
        cycle = 0
        while True:
            await RisingEdge(self.bus.clk)
            cycle += 1
            if int(self.bus.en.value) and not int(self.bus.empty.value):
                self.observed.append(FifoTransfer(data=int(self.bus.data.value), cycle=cycle))


class FifoScoreboard:
    def __init__(self, write_agent: FifoWriteAgent, read_agent: FifoReadAgent):
        self.write_agent = write_agent
        self.read_agent = read_agent

    def check(self) -> None:
        written = [transfer.data for transfer in self.write_agent.observed]
        read = [transfer.data for transfer in self.read_agent.observed]
        assert len(written) == len(read), (
            f"transfer count mismatch: written={len(written)}, read={len(read)}"
        )
        for index, (expected, actual) in enumerate(zip(written, read, strict=True)):
            assert expected == actual, (
                f"transfer {index} mismatch: expected={expected:#x}, actual={actual:#x}"
            )


class FifoTestbench:
    def __init__(
        self,
        write_bus: FifoWriteBus,
        read_bus: FifoReadBus,
        reset_signal: Any,
        data_width: int,
    ):
        self.write_bus = write_bus
        self.read_bus = read_bus
        self.reset_signal = reset_signal
        self.data_width = data_width
        self.write_agent = FifoWriteAgent(write_bus, random.Random(0x1234), data_width)
        self.read_agent = FifoReadAgent(read_bus, random.Random(0x5678))
        self.scoreboard = FifoScoreboard(self.write_agent, self.read_agent)

    async def start(
        self,
        clocks: Sequence[tuple[Any, float, str]] = (),
        reset_cycles: int = 10,
        settle_cycles: int = 10,
    ) -> None:
        for signal, period, units in clocks:
            cocotb.start_soon(Clock(signal, period, units=units).start())

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

        cocotb.start_soon(self.write_agent.monitor())
        cocotb.start_soon(self.read_agent.monitor())

    async def run(
        self,
        write_sequence: FifoWriteSequence,
        read_sequence: FifoReadSequence,
        timeout_ns: int = 100_000,
    ) -> None:
        assert len(write_sequence) == len(read_sequence)
        write_task = cocotb.start_soon(self.write_agent.drive(write_sequence))
        read_task = cocotb.start_soon(self.read_agent.drive(read_sequence))
        await with_timeout(write_task, timeout_ns, "ns")
        await with_timeout(read_task, timeout_ns, "ns")
        await ClockCycles(self.write_bus.clk, 2)
        if self.read_bus.clk is not self.write_bus.clk:
            await ClockCycles(self.read_bus.clk, 2)
        self.scoreboard.check()


def directed_sequences(
    data_width: int,
    count: int = 32,
) -> tuple[FifoWriteSequence, FifoReadSequence]:
    mask = 2**data_width - 1
    write_transactions = tuple(
        FifoWriteTransaction(data=(index * 17 + 3) & mask, wren_probability=1.0, max_cycles=64)
        for index in range(count)
    )
    read_transactions = tuple(
        FifoReadTransaction(rden_probability=1.0, pre_gap=8 if index == 0 else 0, max_cycles=128)
        for index in range(count)
    )
    return FifoWriteSequence(write_transactions), FifoReadSequence(read_transactions)


def random_sequences(
    data_width: int,
    transfer_count: int,
    seed: int = 0xC0C0_2026,
) -> tuple[FifoWriteSequence, FifoReadSequence]:
    rng = random.Random(seed)
    mask = 2**data_width - 1
    write_probabilities = (0.15, 0.35, 0.5, 0.8, 1.0)
    read_probabilities = (0.1, 0.25, 0.5, 0.75, 1.0)

    write_transactions = tuple(
        FifoWriteTransaction(
            data=rng.randrange(mask + 1),
            wren_probability=rng.choice(write_probabilities),
            pre_gap=rng.randrange(4),
            max_cycles=512,
        )
        for _ in range(transfer_count)
    )
    read_transactions = tuple(
        FifoReadTransaction(
            rden_probability=rng.choice(read_probabilities),
            pre_gap=rng.randrange(3),
            max_cycles=1024,
        )
        for _ in range(transfer_count)
    )
    return FifoWriteSequence(write_transactions), FifoReadSequence(read_transactions)
