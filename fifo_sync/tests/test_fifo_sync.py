#!/usr/bin/env python3
from __future__ import annotations

from collections.abc import Iterator, Sequence
from dataclasses import dataclass, field
import os
from pathlib import Path
import random
import tempfile

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner


prj_path = Path(__file__).resolve().parent.parent

FIFO_DEPTH = int(os.getenv("FIFO_DEPTH", 16))
FIFO_LATENCY = int(os.getenv("FIFO_LATENCY", 3))
DATA_WIDTH = int(os.getenv("DATA_WIDTH", 16))
RANDOM_TRANSFER_COUNT = int(os.getenv("RANDOM_TRANSFER_COUNT", 256))

GUI = os.getenv("GUI", "False").lower() == "true"
SIM = os.environ.get("SIM", "verilator").lower()


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


async def reset(dut) -> None:
    dut.rst.value = 1
    dut.wren.value = 0
    dut.din.value = 0
    dut.rden.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


class FifoWriteAgent:
    def __init__(self, dut, rng: random.Random, data_width: int):
        self.dut = dut
        self.rng = rng
        self.data_width = data_width
        self.observed: list[FifoTransfer] = []
        self.aborted_cycles = 0

    def _noise(self) -> int:
        return self.rng.randrange(2**self.data_width)

    async def drive(self, sequence: FifoWriteSequence) -> None:
        self.dut.wren.value = 0
        self.dut.din.value = self._noise()

        for transaction in sequence:
            if transaction.pre_gap:
                self.dut.wren.value = 0
                for _ in range(transaction.pre_gap):
                    self.dut.din.value = self._noise()
                    await RisingEdge(self.dut.clk)

            cycles = 0
            while True:
                assert transaction.max_cycles is None or cycles < transaction.max_cycles, (
                    "write transaction timed out before acceptance"
                )

                wren = self.rng.random() < transaction.wren_probability
                self.dut.wren.value = int(wren)
                self.dut.din.value = transaction.data if wren else self._noise()
                await RisingEdge(self.dut.clk)
                cycles += 1

                if wren and not int(self.dut.full.value):
                    break
                if not wren:
                    self.aborted_cycles += 1

        self.dut.wren.value = 0
        self.dut.din.value = self._noise()

    async def monitor(self) -> None:
        cycle = 0
        while True:
            await RisingEdge(self.dut.clk)
            cycle += 1
            if int(self.dut.wren.value) and not int(self.dut.full.value):
                self.observed.append(FifoTransfer(data=int(self.dut.din.value), cycle=cycle))


class FifoReadAgent:
    def __init__(self, dut, rng: random.Random):
        self.dut = dut
        self.rng = rng
        self.observed: list[FifoTransfer] = []
        self.aborted_cycles = 0

    async def drive(self, sequence: FifoReadSequence) -> None:
        self.dut.rden.value = 0

        for transaction in sequence:
            if transaction.pre_gap:
                self.dut.rden.value = 0
                await ClockCycles(self.dut.clk, transaction.pre_gap)

            cycles = 0
            while True:
                assert transaction.max_cycles is None or cycles < transaction.max_cycles, (
                    "read transaction timed out before acceptance"
                )

                rden = self.rng.random() < transaction.rden_probability
                self.dut.rden.value = int(rden)
                await RisingEdge(self.dut.clk)
                cycles += 1

                if rden and not int(self.dut.empty.value):
                    break
                if not rden:
                    self.aborted_cycles += 1

        self.dut.rden.value = 0

    async def monitor(self) -> None:
        cycle = 0
        while True:
            await RisingEdge(self.dut.clk)
            cycle += 1
            if int(self.dut.rden.value) and not int(self.dut.empty.value):
                self.observed.append(FifoTransfer(data=int(self.dut.dout.value), cycle=cycle))


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
    def __init__(self, dut):
        self.dut = dut
        self.data_width = int(dut.DATA_WIDTH.value)
        self.write_agent = FifoWriteAgent(dut, random.Random(0x1234), self.data_width)
        self.read_agent = FifoReadAgent(dut, random.Random(0x5678))
        self.scoreboard = FifoScoreboard(self.write_agent, self.read_agent)

    async def start(self) -> None:
        cocotb.start_soon(Clock(self.dut.clk, 10).start())
        await reset(self.dut)
        cocotb.start_soon(self.write_agent.monitor())
        cocotb.start_soon(self.read_agent.monitor())

    async def run(self, write_sequence: FifoWriteSequence, read_sequence: FifoReadSequence) -> None:
        assert len(write_sequence) == len(read_sequence)
        write_task = cocotb.start_soon(self.write_agent.drive(write_sequence))
        read_task = cocotb.start_soon(self.read_agent.drive(read_sequence))
        await with_timeout(write_task, 100_000, "ns")
        await with_timeout(read_task, 100_000, "ns")
        await ClockCycles(self.dut.clk, 2)
        self.scoreboard.check()


def directed_sequences(data_width: int) -> tuple[FifoWriteSequence, FifoReadSequence]:
    mask = 2**data_width - 1
    write_transactions = tuple(
        FifoWriteTransaction(data=(index * 17 + 3) & mask, wren_probability=1.0, max_cycles=64)
        for index in range(32)
    )
    read_transactions = tuple(
        FifoReadTransaction(rden_probability=1.0, pre_gap=8 if index == 0 else 0, max_cycles=128)
        for index in range(len(write_transactions))
    )
    return FifoWriteSequence(write_transactions), FifoReadSequence(read_transactions)


def random_sequences(
    data_width: int,
    transfer_count: int,
) -> tuple[FifoWriteSequence, FifoReadSequence]:
    rng = random.Random(0xC0C0_2026)
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


@cocotb.test()
async def test_fifo_sync(dut):
    tb = FifoTestbench(dut)
    await tb.start()

    write_sequence, read_sequence = directed_sequences(tb.data_width)
    await tb.run(write_sequence, read_sequence)

    write_sequence, read_sequence = random_sequences(tb.data_width, RANDOM_TRANSFER_COUNT)
    await tb.run(write_sequence, read_sequence)

    assert tb.write_agent.aborted_cycles > 0
    assert tb.read_agent.aborted_cycles > 0


@pytest.mark.parametrize(
    "params",
    [
        {"FIFO_DEPTH": FIFO_DEPTH, "FIFO_LATENCY": FIFO_LATENCY, "DATA_WIDTH": DATA_WIDTH},
        {"FIFO_DEPTH": 16, "FIFO_LATENCY": 1, "DATA_WIDTH": 8},
        {"FIFO_DEPTH": 16, "FIFO_LATENCY": 2, "DATA_WIDTH": 8},
        {"FIFO_DEPTH": 16, "FIFO_LATENCY": 3, "DATA_WIDTH": 8},
    ],
)
def test_fifo_sync_runner(params):
    hdl_toplevel = "fifo_sync"
    coverage_dir = os.getenv("VERILATOR_COVERAGE_DIR")
    build_args = ["--timing"]
    test_args = []
    if SIM == "verilator" and coverage_dir:
        coverage_path = Path(coverage_dir)
        coverage_path.mkdir(parents=True, exist_ok=True)
        label = "_".join(f"{key}{value}" for key, value in sorted(params.items()))
        build_args.append("--coverage")
        test_args.append(f"+verilator+coverage+file+{coverage_path / f'{label}.dat'}")

    runner = get_runner(SIM)
    with tempfile.TemporaryDirectory(prefix="fifo_sync_param_") as run_dir:
        runner.build(
            hdl_toplevel=hdl_toplevel,
            sources=[
                prj_path / "../ram/rtl/ram_sdp.sv",
                prj_path / "rtl/fifo_sync.sv",
            ],
            parameters=params,
            build_args=build_args,
            waves=True,
            always=True,
            build_dir=run_dir,
        )

        runner.test(
            hdl_toplevel=hdl_toplevel,
            hdl_toplevel_lang="verilog",
            test_module="test_fifo_sync",
            gui=GUI,
            test_args=test_args,
            test_dir=run_dir,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
