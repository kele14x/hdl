"""Agents for the repository's native single- and dual-port memories."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum

import cocotb
from cocotb.triggers import FallingEdge, Lock, ReadOnly, RisingEdge

from .base import AgentMode, AnalysisPort

__all__ = [
    "MemoryAgent",
    "MemoryAgentConfig",
    "MemoryDriver",
    "MemoryError",
    "MemoryMonitor",
    "MemoryOperation",
    "MemoryPortBus",
    "MemoryReadResponse",
    "MemoryTransaction",
]


class MemoryError(AssertionError):
    """Raised for invalid use of a native memory agent."""


class MemoryOperation(str, Enum):
    READ = "read"
    WRITE = "write"


@dataclass(frozen=True)
class MemoryTransaction:
    operation: MemoryOperation
    address: int
    data: int = 0
    cycle: int | None = field(default=None, compare=False)


@dataclass(frozen=True)
class MemoryReadResponse:
    request: MemoryTransaction
    data: int
    cycle: int | None = field(default=None, compare=False)


@dataclass(frozen=True)
class MemoryPortBus:
    """Signal handles for one native memory port.

    ``write_enable`` and ``write_data`` may be omitted for a read-only port;
    ``read_data`` may be omitted for a write-only port.
    """

    clock: object
    enable: object
    address: object
    write_enable: object | None = None
    write_data: object | None = None
    read_data: object | None = None


@dataclass(frozen=True)
class MemoryAgentConfig:
    read_latency: int = 1
    mode: AgentMode = AgentMode.ACTIVE

    def __post_init__(self):
        if self.read_latency < 1:
            raise ValueError("read_latency must be at least one cycle")


class MemoryDriver:
    """Active driver supporting isolated and pipelined native RAM accesses."""

    def __init__(self, bus, config):
        self.bus = bus
        self.config = config
        self._transaction_lock = Lock()

    @property
    def _all_pipeline_enables(self):
        return (1 << self.config.read_latency) - 1

    def idle(self):
        self.bus.enable.value = 0
        self.bus.address.value = 0
        if self.bus.write_enable is not None:
            self.bus.write_enable.value = 0
        if self.bus.write_data is not None:
            self.bus.write_data.value = 0

    def _require_write_port(self):
        if self.bus.write_enable is None or self.bus.write_data is None:
            raise MemoryError("memory port is read-only")

    def _require_read_port(self):
        if self.bus.read_data is None:
            raise MemoryError("memory port is write-only")

    async def write(self, address, data):
        await self.write_burst(((address, data),))

    async def write_burst(self, words):
        self._require_write_port()
        words = list(words)
        if not words:
            return
        async with self._transaction_lock:
            await FallingEdge(self.bus.clock)
            for index, (address, data) in enumerate(words):
                self.bus.enable.value = 1
                self.bus.write_enable.value = 1
                self.bus.address.value = address
                self.bus.write_data.value = data
                await RisingEdge(self.bus.clock)
                if index != len(words) - 1:
                    await FallingEdge(self.bus.clock)
            await FallingEdge(self.bus.clock)
            self.idle()

    async def read(self, address):
        values = await self.read_burst((address,))
        return values[0]

    async def read_burst(self, addresses):
        self._require_read_port()
        addresses = list(addresses)
        if not addresses:
            return []

        async with self._transaction_lock:
            values = []
            await FallingEdge(self.bus.clock)
            if self.bus.write_enable is not None:
                self.bus.write_enable.value = 0
            self.bus.enable.value = self._all_pipeline_enables

            for index, address in enumerate(addresses):
                self.bus.address.value = address
                await RisingEdge(self.bus.clock)
                await ReadOnly()
                if index >= self.config.read_latency - 1:
                    values.append(int(self.bus.read_data.value))
                await FallingEdge(self.bus.clock)

            self.bus.enable.value = self._all_pipeline_enables & ~1
            for _ in range(self.config.read_latency - 1):
                await RisingEdge(self.bus.clock)
                await ReadOnly()
                values.append(int(self.bus.read_data.value))
                await FallingEdge(self.bus.clock)
            self.idle()
            return values


class MemoryMonitor:
    """Passive command and response monitor for a native RAM port."""

    def __init__(self, bus, config):
        self.bus = bus
        self.config = config
        self.transactions = AnalysisPort[MemoryTransaction]()
        self.reads = AnalysisPort[MemoryReadResponse]()
        self.observed: list[MemoryTransaction] = []
        self.read_responses: list[MemoryReadResponse] = []
        self._pipeline = [None] * config.read_latency
        self._task = None

    def start(self):
        if self._task is None:
            self._task = cocotb.start_soon(self.run())
        return self._task

    def stop(self):
        if self._task is not None:
            self._task.kill()
            self._task = None

    async def run(self):
        cycle = 0
        while True:
            await RisingEdge(self.bus.clock)
            await ReadOnly()
            cycle += 1
            enables = int(self.bus.enable.value)
            old_pipeline = self._pipeline.copy()

            operation = None
            if enables & 1:
                is_write = self.bus.write_enable is not None and int(
                    self.bus.write_enable.value
                )
                operation = MemoryTransaction(
                    operation=(
                        MemoryOperation.WRITE if is_write else MemoryOperation.READ
                    ),
                    address=int(self.bus.address.value),
                    data=(
                        int(self.bus.write_data.value)
                        if is_write and self.bus.write_data is not None
                        else 0
                    ),
                    cycle=cycle,
                )
                self.observed.append(operation)
                self.transactions.write(operation)

            new_pipeline = old_pipeline.copy()
            new_pipeline[0] = operation if enables & 1 else old_pipeline[0]
            for stage in range(1, self.config.read_latency):
                if enables & (1 << stage):
                    new_pipeline[stage] = old_pipeline[stage - 1]
            self._pipeline = new_pipeline

            completed = new_pipeline[-1]
            final_enabled = enables & (1 << (self.config.read_latency - 1))
            if (
                final_enabled
                and completed is not None
                and completed.operation is MemoryOperation.READ
                and self.bus.read_data is not None
            ):
                response = MemoryReadResponse(
                    request=completed,
                    data=int(self.bus.read_data.value),
                    cycle=cycle,
                )
                self.read_responses.append(response)
                self.reads.write(response)


class MemoryAgent:
    """Native RAM agent containing a monitor and optional active driver."""

    def __init__(self, bus, config=None):
        self.bus = bus
        self.config = config or MemoryAgentConfig()
        self.monitor = MemoryMonitor(bus, self.config)
        self.driver = (
            MemoryDriver(bus, self.config)
            if AgentMode(self.config.mode) is AgentMode.ACTIVE
            else None
        )

    async def start(self):
        if self.driver is not None:
            self.driver.idle()
        self.monitor.start()

    def stop(self):
        self.monitor.stop()
        if self.driver is not None:
            self.driver.idle()

    def _active_driver(self):
        if self.driver is None:
            raise MemoryError("passive memory agent has no driver")
        return self.driver

    async def write(self, address, data):
        await self._active_driver().write(address, data)

    async def write_burst(self, words):
        await self._active_driver().write_burst(words)

    async def read(self, address):
        return await self._active_driver().read(address)

    async def read_burst(self, addresses):
        return await self._active_driver().read_burst(addresses)
