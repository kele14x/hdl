"""UVM-style AXI-Stream transaction, driver, monitor, and agent."""

from dataclasses import dataclass, field
from enum import Enum

import cocotb
from cocotb.triggers import FallingEdge, Lock, ReadOnly, RisingEdge

from .base import AgentMode, AnalysisPort

__all__ = [
    "AxisAgent",
    "AxisAgentConfig",
    "AxisBeat",
    "AxisError",
    "AxisFrame",
    "AxisMonitor",
    "AxisRole",
    "AxisSink",
    "AxisSinkDriver",
    "AxisSource",
    "AxisSourceDriver",
]


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

    def _sig(self, name):
        return getattr(self.dut, f"{self.prefix}_{name}")

    def _optional(self, name):
        return getattr(self.dut, f"{self.prefix}_{name}", None)

    def _in_reset(self):
        return self.reset_signal is not None and (
            int(self.reset_signal.value) == self.config.reset_active_level
        )


class AxisSourceDriver(_AxisComponent):
    """Active driver for TVALID, payload, and sideband signals."""

    def __init__(self, dut, config):
        super().__init__(dut, config)
        self._transaction_lock = Lock()

    def idle(self):
        self._sig("tvalid").value = 0
        for name in ("tdata", "tkeep", "tuser", "tdest", "tlast"):
            signal = self._optional(name)
            if signal is not None:
                signal.value = 0

    def _drive_beat(self, beat):
        self._sig("tdata").value = beat.data
        for name, value in (
            ("tuser", beat.user),
            ("tdest", beat.dest),
            ("tlast", int(beat.last)),
        ):
            signal = self._optional(name)
            if signal is not None:
                signal.value = 0 if value is None else value

        keep = self._optional("tkeep")
        if keep is not None:
            keep.value = (1 << len(keep)) - 1 if beat.keep is None else beat.keep

    async def _drive_frame(self, transaction, gap):
        if not transaction.beats:
            raise ValueError("cannot drive an empty AXI-Stream frame")
        self.idle()
        for index, beat in enumerate(transaction.beats):
            if gap is not None:
                gap_cycles = int(gap(index))
                if gap_cycles < 0:
                    raise ValueError("AXI-Stream gap must be non-negative")
                if gap_cycles:
                    self._sig("tvalid").value = 0
                for _ in range(gap_cycles):
                    await RisingEdge(self.clock)
            self._drive_beat(beat)
            self._sig("tvalid").value = 1
            for _ in range(self.config.timeout_cycles):
                await RisingEdge(self.clock)
                if int(self._sig("tready").value):
                    break
            else:
                self.idle()
                raise AxisError(
                    f"AXI-Stream {self.prefix} stalled for "
                    f"{self.config.timeout_cycles} cycles at beat {index}"
                )
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

    def __init__(self, dut, config, ready_policy=None):
        super().__init__(dut, config)
        self.ready_policy = ready_policy
        self._task = None

    def idle(self):
        self._sig("tready").value = 0

    def start(self):
        if self._task is None:
            self._task = cocotb.start_soon(self.run())
        return self._task

    def stop(self):
        if self._task is not None:
            self._task.kill()
            self._task = None
        self.idle()

    async def run(self):
        cycle = 0
        while True:
            await FallingEdge(self.clock)
            if self._in_reset():
                self._sig("tready").value = 0
            else:
                ready = (
                    True
                    if self.ready_policy is None
                    else bool(self.ready_policy(cycle))
                )
                self._sig("tready").value = int(ready)
                cycle += 1


class AxisMonitor(_AxisComponent):
    """Passive monitor publishing beats and TLAST-delimited frames."""

    def __init__(self, dut, config):
        super().__init__(dut, config)
        self.beats = AnalysisPort[AxisBeat]()
        self.frames = AnalysisPort[AxisFrame]()
        self._partial_frame = []
        self._task = None

    def start(self):
        if self._task is None:
            self._task = cocotb.start_soon(self.run())
        return self._task

    def stop(self):
        if self._task is not None:
            self._task.kill()
            self._task = None
        self._partial_frame.clear()

    def _sample(self):
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
        while True:
            await FallingEdge(self.clock)
            await ReadOnly()
            if self._in_reset():
                self._partial_frame.clear()
                continue
            if not (int(self._sig("tvalid").value) and int(self._sig("tready").value)):
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


class AxisSource(AxisSourceDriver):
    """Compatibility constructor for the previous standalone source."""

    def __init__(self, dut, prefix, clock="internal_bus_clk", timeout_cycles=1000):
        clock_name = clock if isinstance(clock, str) else "internal_bus_clk"
        super().__init__(
            dut,
            AxisAgentConfig(
                prefix=prefix,
                clock=clock_name,
                timeout_cycles=timeout_cycles,
                role=AxisRole.SOURCE,
            ),
        )
        if not isinstance(clock, str):
            self.clock = clock


class AxisSink:
    """Compatibility facade combining a sink driver and monitor."""

    def __init__(self, dut, prefix, clock="internal_bus_clk", timeout_cycles=1000):
        clock_name = clock if isinstance(clock, str) else "internal_bus_clk"
        config = AxisAgentConfig(
            prefix=prefix,
            clock=clock_name,
            timeout_cycles=timeout_cycles,
            role=AxisRole.SINK,
        )
        self.agent = AxisAgent(dut, config)
        if not isinstance(clock, str):
            self.agent.monitor.clock = clock
            self.agent.driver.clock = clock
        self._started = False

    def idle(self):
        self.agent.driver.idle()

    async def receive_frame(self, ready=None, max_beats=None):
        if ready is not None:
            self.agent.driver.ready_policy = ready
        if not self._started:
            await self.agent.start()
            self._started = True
        if max_beats is None:
            return (await self.agent.receive()).beats

        beats = []
        while len(beats) < max_beats:
            beats.append(await self.agent.monitor.beats.get())
            if beats[-1].last:
                break
        return beats
