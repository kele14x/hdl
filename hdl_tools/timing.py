"""Radio frame/slot/symbol timing agent."""

from __future__ import annotations

from dataclasses import dataclass

import cocotb
from cocotb.triggers import ClockCycles, First, Lock, RisingEdge

from .tb_base import AgentMode, AnalysisPort

__all__ = [
    "RadioTimingAgent",
    "RadioTimingAgentConfig",
    "RadioTimingDriver",
    "RadioTimingError",
    "RadioTimingEvent",
    "RadioTimingMonitor",
    "RadioTimingSignals",
]


class RadioTimingError(AssertionError):
    """Raised for an invalid timing operation or event timeout."""


@dataclass(frozen=True)
class RadioTimingEvent:
    """One observed frame, slot, or selected-numerology symbol boundary."""

    cycle: int
    frame: int
    slot: int
    symbol: int
    start_frame: bool
    start_slot: bool
    start_symbol: bool
    symbol_mask: int


@dataclass(frozen=True)
class RadioTimingSignals:
    clock: str = "clk"
    reset: str | None = "rst"
    sync: str | None = "sync"
    start_frame: str = "start_of_frame"
    start_slot: str = "start_of_slot"
    start_symbol: str = "start_of_symbol"


@dataclass(frozen=True)
class RadioTimingAgentConfig:
    signals: RadioTimingSignals = RadioTimingSignals()
    numerology: int = 0
    symbols_per_slot: int = 14
    slots_per_frame: int = 10
    reset_active_level: int = 1
    timeout_cycles: int = 100_000
    mode: AgentMode = AgentMode.ACTIVE

    def __post_init__(self):
        if self.numerology < 0:
            raise ValueError("numerology must be non-negative")
        if self.symbols_per_slot <= 0 or self.slots_per_frame <= 0:
            raise ValueError("radio timing dimensions must be positive")


class _RadioTimingComponent:
    def __init__(self, dut, config):
        self.dut = dut
        self.config = config
        self.signals = config.signals
        self.clock = getattr(dut, self.signals.clock)
        self.reset = (
            getattr(dut, self.signals.reset) if self.signals.reset is not None else None
        )

    def _in_reset(self):
        return self.reset is not None and (
            int(self.reset.value) == self.config.reset_active_level
        )


class RadioTimingDriver(_RadioTimingComponent):
    """Drives the external frame synchronization input."""

    def __init__(self, dut, config):
        super().__init__(dut, config)
        if self.signals.sync is None:
            raise RadioTimingError("radio timing signal map has no sync input")
        self.sync_signal = getattr(dut, self.signals.sync)
        self._transaction_lock = Lock()

    def idle(self):
        self.sync_signal.value = 0

    async def pulse_sync(self, delay_cycles=0, high_cycles=1):
        if delay_cycles < 0 or high_cycles <= 0:
            raise ValueError("sync delay must be non-negative and width positive")
        async with self._transaction_lock:
            self.idle()
            if delay_cycles:
                await ClockCycles(self.clock, delay_cycles)
            await RisingEdge(self.clock)
            self.sync_signal.value = 1
            await ClockCycles(self.clock, high_cycles)
            self.sync_signal.value = 0


class RadioTimingMonitor(_RadioTimingComponent):
    """Publishes hierarchical radio timing events from boundary strobes."""

    def __init__(self, dut, config):
        super().__init__(dut, config)
        self.events = AnalysisPort[RadioTimingEvent]()
        self.frames = AnalysisPort[RadioTimingEvent]()
        self.slots = AnalysisPort[RadioTimingEvent]()
        self.symbols = AnalysisPort[RadioTimingEvent]()
        self.observed: list[RadioTimingEvent] = []
        self._task = None

    def start(self):
        if self._task is None:
            self._task = cocotb.start_soon(self.run())
        return self._task

    def stop(self):
        if self._task is not None:
            self._task.cancel()
            self._task = None

    async def run(self):
        cycle = 0
        frame = -1
        slot = 0
        symbol = 0
        frame_signal = getattr(self.dut, self.signals.start_frame)
        slot_signal = getattr(self.dut, self.signals.start_slot)
        symbol_signal = getattr(self.dut, self.signals.start_symbol)

        while True:
            await RisingEdge(self.clock)
            cycle += 1
            if self._in_reset():
                frame = -1
                slot = 0
                symbol = 0
                continue

            start_frame = bool(int(frame_signal.value))
            start_slot = bool(int(slot_signal.value))
            symbol_mask = int(symbol_signal.value)
            start_symbol = bool(symbol_mask & (1 << self.config.numerology))
            if not (start_frame or start_slot or start_symbol):
                continue

            if start_frame:
                frame += 1
                slot = 0
                symbol = 0
            elif start_slot:
                slot = (slot + 1) % self.config.slots_per_frame
                symbol = 0
            elif start_symbol:
                symbol = (symbol + 1) % self.config.symbols_per_slot

            event = RadioTimingEvent(
                cycle=cycle,
                frame=max(frame, 0),
                slot=slot,
                symbol=symbol,
                start_frame=start_frame,
                start_slot=start_slot,
                start_symbol=start_symbol,
                symbol_mask=symbol_mask,
            )
            self.observed.append(event)
            self.events.write(event)
            if start_frame:
                self.frames.write(event)
            if start_slot:
                self.slots.write(event)
            if start_symbol:
                self.symbols.write(event)


class RadioTimingAgent:
    """Radio timing monitor with an optional external-sync driver."""

    def __init__(self, dut, config=None):
        self.config = config or RadioTimingAgentConfig()
        self.monitor = RadioTimingMonitor(dut, self.config)
        self.driver = (
            RadioTimingDriver(dut, self.config)
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

    async def pulse_sync(self, delay_cycles=0, high_cycles=1):
        if self.driver is None:
            raise RadioTimingError("passive radio timing agent has no sync driver")
        await self.driver.pulse_sync(delay_cycles, high_cycles)

    async def _receive(self, port, timeout_cycles):
        timeout_cycles = timeout_cycles or self.config.timeout_cycles
        task = cocotb.start_soon(port.get())
        await First(task, ClockCycles(self.monitor.clock, timeout_cycles))
        if not task.done():
            task.cancel()
            raise RadioTimingError(
                f"radio timing event timed out after {timeout_cycles} cycles"
            )
        return task.result()

    async def wait_event(self, timeout_cycles=None):
        return await self._receive(self.monitor.events, timeout_cycles)

    async def wait_frame(self, timeout_cycles=None):
        return await self._receive(self.monitor.frames, timeout_cycles)

    async def wait_slot(self, timeout_cycles=None):
        return await self._receive(self.monitor.slots, timeout_cycles)

    async def wait_symbol(self, timeout_cycles=None):
        return await self._receive(self.monitor.symbols, timeout_cycles)
