"""Valid/ready handshake primitives for cocotb testbenches.

This is the lowest layer of the shared verification library: every
valid/ready interface (AXI-Stream beats, AXI4-Lite channels, simple
data+valid streams) is built from these components.

- :class:`HandshakeSource` drives payload plus ``valid`` and, when a ready
  signal is configured, completes each transfer with the ready handshake.
  Without ready, ``valid`` pulses for one clock per item.
- :class:`HandshakeSink` drives ``ready`` either sequentially from per-item
  acceptance policies or continuously from a background policy.
- :class:`HandshakeMonitor` passively records every handshake, publishing
  :class:`HandshakeRecord` items on an analysis port.

All driving and sampling happens on the rising clock edge: values read after
``await RisingEdge(clock)`` are the ones that were stable at that edge.
"""

from __future__ import annotations

from collections.abc import Callable, Iterable, Mapping, Sequence
from dataclasses import dataclass, field

import cocotb
from cocotb.triggers import ClockCycles, RisingEdge

from .tb_base import AnalysisPort


class HandshakeError(AssertionError):
    """Raised when a handshake stalls past its timeout."""


@dataclass(frozen=True)
class HandshakeConfig:
    """Shared configuration for handshake components."""

    clock: str = "aclk"
    reset: str | None = None
    reset_active_level: int = 0
    timeout_cycles: int = 1000


@dataclass(frozen=True)
class HandshakeItem:
    """One driven transfer: payload values plus an idle gap before it.

    ``payload`` maps signal names to values; ``gap`` is the number of clocks
    to hold ``valid`` low before asserting the transfer.
    """

    payload: Mapping[str, int] = field(default_factory=dict)
    gap: int = 0

    def __post_init__(self) -> None:
        if self.gap < 0:
            raise ValueError("gap must be non-negative")


@dataclass(frozen=True)
class HandshakeRecord:
    """One observed handshake.

    ``gap`` is the number of idle clocks since the previous handshake (0 for
    back-to-back transfers).  ``latency`` is the number of clocks ``valid``
    waited for ``ready``; it is ``None`` when no ready signal exists.
    """

    payload: Mapping[str, int]
    gap: int = 0
    latency: int | None = None


class _HandshakeComponent:
    def __init__(
        self,
        dut,
        valid: str,
        fields: Sequence[str],
        ready: str | None = None,
        config: HandshakeConfig | None = None,
    ):
        self.dut = dut
        self.config = config or HandshakeConfig()
        self.valid_signal = getattr(dut, valid)
        self.ready_signal = getattr(dut, ready) if ready is not None else None
        self.payload_signals = {name: getattr(dut, name) for name in fields}
        self.clock = getattr(dut, self.config.clock)
        self.reset_signal = (
            getattr(dut, self.config.reset) if self.config.reset else None
        )

    def _in_reset(self) -> bool:
        return self.reset_signal is not None and (
            int(self.reset_signal.value) == self.config.reset_active_level
        )


class HandshakeSource(_HandshakeComponent):
    """Drives payload + valid, completing each transfer with ready if present."""

    def idle(self) -> None:
        self.valid_signal.value = 0
        for signal in self.payload_signals.values():
            signal.value = 0

    async def drive(self, items: Iterable[HandshakeItem]) -> None:
        """Drive every item in order, one handshake (or pulse) per item."""
        self.valid_signal.value = 0
        for item in items:
            self.valid_signal.value = 0
            if item.gap:
                await ClockCycles(self.clock, item.gap)
            for name, signal in self.payload_signals.items():
                signal.value = item.payload[name]
            self.valid_signal.value = 1
            if self.ready_signal is None:
                await RisingEdge(self.clock)
            else:
                await self._wait_for_ready()
        self.valid_signal.value = 0

    async def _wait_for_ready(self) -> None:
        for _ in range(self.config.timeout_cycles):
            await RisingEdge(self.clock)
            if int(self.ready_signal.value):
                return
        raise HandshakeError(
            f"handshake stalled for {self.config.timeout_cycles} cycles "
            "waiting for ready"
        )


class HandshakeSink(_HandshakeComponent):
    """Drives ready; captured transfers are observed by a monitor."""

    def __init__(
        self,
        dut,
        valid: str,
        fields: Sequence[str],
        ready: str,
        config: HandshakeConfig | None = None,
    ):
        super().__init__(dut, valid, fields, ready, config)
        self._task = None
        self._policy: Callable[[int], bool] | None = None

    def idle(self) -> None:
        self.ready_signal.value = 0

    async def drive(self, policies: Iterable[int]) -> None:
        """Accept one transfer per policy, then deassert ready.

        A negative policy asserts ready proactively before valid is seen;
        zero asserts ready as soon as valid is observed; a positive value
        holds ready low for that many clocks after valid is seen.
        """
        self.ready_signal.value = 0
        for policy in policies:
            if policy < 0:
                self.ready_signal.value = 1
            else:
                await self._wait_for_valid()
                if policy:
                    await ClockCycles(self.clock, policy)
                self.ready_signal.value = 1
            await self._wait_for_handshake()
            self.ready_signal.value = 0

    def start(self, policy: Callable[[int], bool] | None = None):
        """Run ready continuously in the background.

        ``policy`` maps a non-reset cycle count to the ready value; ``None``
        holds ready high at all times.
        """
        if self._task is None:
            self._policy = policy
            self._task = cocotb.start_soon(self.run())
        return self._task

    def stop(self) -> None:
        if self._task is not None:
            self._task.cancel()
            self._task = None
        self.idle()

    async def run(self) -> None:
        cycle = 0
        while True:
            await RisingEdge(self.clock)
            if self._in_reset():
                self.ready_signal.value = 0
                continue
            ready = True if self._policy is None else bool(self._policy(cycle))
            self.ready_signal.value = int(ready)
            cycle += 1

    async def _wait_for_valid(self) -> None:
        while not int(self.valid_signal.value):
            await RisingEdge(self.clock)

    async def _wait_for_handshake(self) -> None:
        while True:
            await RisingEdge(self.clock)
            if int(self.valid_signal.value) and int(self.ready_signal.value):
                return


class HandshakeMonitor(_HandshakeComponent):
    """Passively records every handshake with gap and latency measurements."""

    def __init__(
        self,
        dut,
        valid: str,
        fields: Sequence[str],
        ready: str | None = None,
        config: HandshakeConfig | None = None,
    ):
        super().__init__(dut, valid, fields, ready, config)
        self.observed: list[HandshakeRecord] = []
        self.transactions = AnalysisPort[HandshakeRecord]()
        self._task = None

    def start(self):
        if self._task is None:
            self._task = cocotb.start_soon(self.run())
        return self._task

    def stop(self) -> None:
        if self._task is not None:
            self._task.cancel()
            self._task = None

    async def run(self) -> None:
        last_handshake_cycle: int | None = None
        valid_since: int | None = None
        cycle = 0
        while True:
            await RisingEdge(self.clock)
            cycle += 1
            if self._in_reset():
                valid_since = None
                continue

            valid = int(self.valid_signal.value)
            if valid and valid_since is None:
                valid_since = cycle
            ready = (
                True
                if self.ready_signal is None
                else bool(int(self.ready_signal.value))
            )
            if not (valid and ready):
                continue

            payload = {
                name: int(signal.value) for name, signal in self.payload_signals.items()
            }
            gap = (
                0 if last_handshake_cycle is None else cycle - last_handshake_cycle - 1
            )
            latency = (
                None
                if self.ready_signal is None
                else 0
                if valid_since is None
                else cycle - valid_since
            )
            record = HandshakeRecord(payload=payload, gap=gap, latency=latency)
            self.observed.append(record)
            self.transactions.write(record)
            valid_since = None
            last_handshake_cycle = cycle
