"""AXI-Stream transactions, drivers, monitors, and agents.

Built on the valid/ready handshake primitives from ``hdl_tools.handshake``:
a source drives beats (payload plus optional sideband) with valid/tready
handshakes, a sink drives tready from a policy, and a monitor reconstructs
TLAST-delimited frames.  ``tready`` is optional; an interface without it is
treated as always ready.  All driving and sampling happens on the rising
clock edge.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum

import cocotb
from cocotb.triggers import Lock, RisingEdge

from .handshake import (
    HandshakeConfig,
    HandshakeError,
    HandshakeItem,
    HandshakeSink,
    HandshakeSource,
)
from .tb_base import AgentMode, AnalysisPort


class AxisError(AssertionError):
    """Raised for invalid agent use or a stalled AXI-Stream transfer."""


class AxisRole(str, Enum):
    """Interface role driven by an active AXI-Stream agent."""

    SOURCE = "source"
    SINK = "sink"


@dataclass(frozen=True)
class AxisBeat:
    """One AXI-Stream transfer."""

    data: int
    keep: int | None = None
    user: int | None = None
    dest: int | None = None
    last: bool = False


@dataclass
class AxisFrame:
    """A transaction containing all beats through TLAST."""

    beats: list[AxisBeat] = field(default_factory=list)

    def __iter__(self):
        return iter(self.beats)

    def __len__(self):
        return len(self.beats)

    @classmethod
    def from_words(cls, words, *, keep=None, users=None, dest=None):
        words = list(words)
        if users is None:
            users = [None] * len(words)
        else:
            users = list(users)
        if len(users) != len(words):
            raise ValueError("users and words must have the same length")
        return cls(
            [
                AxisBeat(
                    data=word,
                    keep=keep,
                    user=user,
                    dest=dest,
                    last=index == len(words) - 1,
                )
                for index, (word, user) in enumerate(zip(words, users, strict=True))
            ]
        )


@dataclass(frozen=True)
class AxisAgentConfig:
    prefix: str
    clock: str = "aclk"
    reset: str | None = None
    reset_active_level: int = 0
    timeout_cycles: int = 1000
    mode: AgentMode = AgentMode.ACTIVE
    role: AxisRole = AxisRole.SOURCE


class _AxisComponent:
    def __init__(self, dut, config: AxisAgentConfig):
        self.dut = dut
        self.config = config
        self.prefix = config.prefix
        self.clock = getattr(dut, config.clock)
        self.reset_signal = getattr(dut, config.reset) if config.reset else None

    def _name(self, name: str) -> str:
        return f"{self.prefix}_{name}"

    def _sig(self, name):
        return getattr(self.dut, self._name(name))

    def _optional(self, name):
        return getattr(self.dut, self._name(name), None)

    def _in_reset(self) -> bool:
        return self.reset_signal is not None and (
            int(self.reset_signal.value) == self.config.reset_active_level
        )

    def _handshake_config(self) -> HandshakeConfig:
        return HandshakeConfig(
            clock=self.config.clock,
            reset=self.config.reset,
            reset_active_level=self.config.reset_active_level,
            timeout_cycles=self.config.timeout_cycles,
        )


class AxisSourceDriver(_AxisComponent):
    """Active driver for TVALID, payload, and sideband signals."""

    def __init__(self, dut, config: AxisAgentConfig):
        super().__init__(dut, config)
        self._transaction_lock = Lock()
        self._fields = ["tdata"] + [
            name
            for name in ("tkeep", "tuser", "tdest", "tlast")
            if self._optional(name) is not None
        ]
        ready = self._name("tready") if self._optional("tready") is not None else None
        self._source = HandshakeSource(
            dut,
            self._name("tvalid"),
            [self._name(name) for name in self._fields],
            ready=ready,
            config=self._handshake_config(),
        )

    def idle(self):
        self._source.idle()

    def _beat_payload(self, beat: AxisBeat) -> dict[str, int]:
        payload = {self._name("tdata"): beat.data}
        for name, value in (
            ("tuser", beat.user),
            ("tdest", beat.dest),
            ("tlast", int(beat.last)),
        ):
            if self._optional(name) is not None:
                payload[self._name(name)] = 0 if value is None else value
        keep = self._optional("tkeep")
        if keep is not None:
            payload[self._name("tkeep")] = (
                (1 << len(keep)) - 1 if beat.keep is None else beat.keep
            )
        return payload

    async def _drive_frame(self, transaction: AxisFrame, gap):
        if not transaction.beats:
            raise ValueError("cannot drive an empty AXI-Stream frame")
        self.idle()
        items = []
        for index, beat in enumerate(transaction.beats):
            gap_cycles = 0
            if gap is not None:
                gap_cycles = int(gap(index)) if callable(gap) else int(gap)
                if gap_cycles < 0:
                    raise ValueError("AXI-Stream gap must be non-negative")
            items.append(HandshakeItem(self._beat_payload(beat), gap=gap_cycles))
        try:
            await self._source.drive(items)
        except HandshakeError:
            self.idle()
            raise AxisError(
                f"AXI-Stream {self.prefix} stalled for "
                f"{self.config.timeout_cycles} cycles"
            ) from None
        self.idle()
        return transaction

    async def drive(self, transaction: AxisFrame, gap=None):
        """Serialize and drive a frame with optional inter-beat gaps."""
        async with self._transaction_lock:
            return await self._drive_frame(transaction, gap)

    async def send(self, beats, gap=None):
        frame = beats if isinstance(beats, AxisFrame) else AxisFrame(list(beats))
        return await self.drive(frame, gap)


class AxisSinkDriver(_AxisComponent):
    """Active TREADY driver with an optional backpressure policy."""

    def __init__(self, dut, config: AxisAgentConfig, ready_policy=None):
        super().__init__(dut, config)
        self.ready_policy = ready_policy
        self._sink = HandshakeSink(
            dut,
            self._name("tvalid"),
            [],
            ready=self._name("tready"),
            config=self._handshake_config(),
        )

    def idle(self):
        self._sink.idle()

    def start(self):
        # Read the policy lazily so it can be swapped after start.
        return self._sink.start(
            lambda cycle: (
                True if self.ready_policy is None else bool(self.ready_policy(cycle))
            )
        )

    def stop(self):
        self._sink.stop()


class AxisMonitor(_AxisComponent):
    """Passive monitor publishing beats and TLAST-delimited frames."""

    def __init__(self, dut, config: AxisAgentConfig):
        super().__init__(dut, config)
        self.beats = AnalysisPort[AxisBeat]()
        self.frames = AnalysisPort[AxisFrame]()
        self._partial_frame: list[AxisBeat] = []
        self._task = None

    def start(self):
        if self._task is None:
            self._task = cocotb.start_soon(self.run())
        return self._task

    def stop(self):
        if self._task is not None:
            self._task.cancel()
            self._task = None
        self._partial_frame.clear()

    def _sample(self) -> AxisBeat:
        values = {}
        for name in ("tkeep", "tuser", "tdest", "tlast"):
            signal = self._optional(name)
            values[name] = None if signal is None else int(signal.value)
        return AxisBeat(
            data=int(self._sig("tdata").value),
            keep=values["tkeep"],
            user=values["tuser"],
            dest=values["tdest"],
            last=bool(values["tlast"]),
        )

    async def run(self):
        has_tlast = self._optional("tlast") is not None
        ready_signal = self._optional("tready")
        while True:
            await RisingEdge(self.clock)
            if self._in_reset():
                self._partial_frame.clear()
                continue
            if not int(self._sig("tvalid").value):
                continue
            if ready_signal is not None and not int(ready_signal.value):
                continue

            beat = self._sample()
            self.beats.write(beat)
            self._partial_frame.append(beat)
            if beat.last or not has_tlast:
                self.frames.write(AxisFrame(self._partial_frame.copy()))
                self._partial_frame.clear()


class AxisAgent:
    """AXI-Stream agent combining a passive monitor with an optional driver."""

    def __init__(self, dut, config=None, ready_policy=None, **config_overrides):
        if config is None:
            config = AxisAgentConfig(**config_overrides)
        elif config_overrides:
            raise TypeError("pass either config or keyword overrides, not both")
        self.config = config
        self.monitor = AxisMonitor(dut, config)
        self.driver = None
        if AgentMode(config.mode) is AgentMode.ACTIVE:
            if AxisRole(config.role) is AxisRole.SOURCE:
                self.driver = AxisSourceDriver(dut, config)
            else:
                self.driver = AxisSinkDriver(dut, config, ready_policy)

    async def start(self):
        self.monitor.start()
        if self.driver is not None:
            self.driver.idle()
            if isinstance(self.driver, AxisSinkDriver):
                self.driver.start()

    def stop(self):
        self.monitor.stop()
        if isinstance(self.driver, AxisSinkDriver):
            self.driver.stop()
        elif self.driver is not None:
            self.driver.idle()

    async def send(self, transaction, gap=None):
        if not isinstance(self.driver, AxisSourceDriver):
            raise AxisError("send requires an active source agent")
        return await self.driver.send(transaction, gap)

    async def receive(self):
        if AxisRole(self.config.role) is not AxisRole.SINK:
            raise AxisError("receive requires a sink agent")
        return await self.monitor.frames.get()
