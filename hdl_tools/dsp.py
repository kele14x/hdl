"""Transaction-level agent for the repository's valid-qualified IQ streams."""

from dataclasses import dataclass, field

import cocotb
from cocotb.triggers import ClockCycles, First, Lock, RisingEdge

from .tb_base import AgentMode, AnalysisPort

__all__ = [
    "DspSample",
    "DspSampleAgent",
    "DspSampleAgentConfig",
    "DspSampleDriver",
    "DspSampleError",
    "DspSampleMonitor",
    "DspSampleSignals",
]


class DspSampleError(AssertionError):
    """Raised for invalid use or a sample-stream timeout."""


@dataclass(frozen=True)
class DspSample:
    """One cycle of a valid-qualified complex sample stream."""

    i: int = 0
    q: int = 0
    channel: int = 0
    start_frame: bool = False
    start_slot: bool = False
    start_symbol: bool = False
    valid: bool = True
    cycle: int | None = field(default=None, compare=False)


@dataclass(frozen=True)
class DspSampleSignals:
    """Map transaction fields to DUT signal names."""

    i: str
    q: str | None
    valid: str
    channel: str | None = None
    start_frame: str | None = None
    start_slot: str | None = None
    start_symbol: str | None = None
    ready: str | None = None

    @classmethod
    def from_prefix(cls, prefix):
        """Build the repository-standard ``din_*`` or ``dout_*`` mapping."""
        return cls(
            i=f"{prefix}_dr",
            q=f"{prefix}_di",
            valid=f"{prefix}_dv",
            channel=f"{prefix}_chn",
            start_frame=f"{prefix}_sf",
            start_slot=f"{prefix}_sl",
            start_symbol=f"{prefix}_sy",
        )


@dataclass(frozen=True)
class DspSampleAgentConfig:
    signals: DspSampleSignals
    clock: str = "clk"
    reset: str | None = None
    reset_active_level: int = 1
    timeout_cycles: int = 1000
    mode: AgentMode = AgentMode.ACTIVE
    signed_iq: bool = True


class _DspSampleComponent:
    def __init__(self, dut, config):
        self.dut = dut
        self.config = config
        self.signals = config.signals
        self.clock = getattr(dut, config.clock)
        self.reset_signal = getattr(dut, config.reset) if config.reset else None

    def _required(self, name):
        return getattr(self.dut, name)

    def _optional(self, name):
        return None if name is None else getattr(self.dut, name)

    def _in_reset(self):
        return self.reset_signal is not None and (
            int(self.reset_signal.value) == self.config.reset_active_level
        )

    @staticmethod
    def _signed(signal):
        value = int(signal.value)
        sign_bit = 1 << (len(signal) - 1)
        return value - (1 << len(signal)) if value & sign_bit else value


class DspSampleDriver(_DspSampleComponent):
    """Active source driver for a valid-qualified sample stream."""

    def __init__(self, dut, config):
        super().__init__(dut, config)
        self._transaction_lock = Lock()

    def idle(self):
        self._required(self.signals.valid).value = 0
        for name in (
            self.signals.i,
            self.signals.q,
            self.signals.channel,
            self.signals.start_frame,
            self.signals.start_slot,
            self.signals.start_symbol,
        ):
            signal = self._optional(name)
            if signal is not None:
                signal.value = 0

    def _drive_payload(self, sample):
        values = (
            (self.signals.i, sample.i),
            (self.signals.q, sample.q),
            (self.signals.channel, sample.channel),
            (self.signals.start_frame, int(sample.start_frame)),
            (self.signals.start_slot, int(sample.start_slot)),
            (self.signals.start_symbol, int(sample.start_symbol)),
        )
        for name, value in values:
            signal = self._optional(name)
            if signal is not None:
                signal.value = value

    async def _drive_samples(self, samples, gap):
        self.idle()
        ready = self._optional(self.signals.ready)
        for index, sample in enumerate(samples):
            if gap is not None:
                gap_cycles = int(gap(index))
                if gap_cycles < 0:
                    raise ValueError("DSP sample gap must be non-negative")
                self._required(self.signals.valid).value = 0
                if gap_cycles:
                    await ClockCycles(self.clock, gap_cycles)

            self._drive_payload(sample)
            self._required(self.signals.valid).value = int(sample.valid)
            if not sample.valid or ready is None:
                await RisingEdge(self.clock)
                continue

            for _ in range(self.config.timeout_cycles):
                await RisingEdge(self.clock)
                if int(ready.value):
                    break
            else:
                self.idle()
                raise DspSampleError(
                    f"DSP sample stream stalled for {self.config.timeout_cycles} "
                    f"cycles at sample {index}"
                )
        self.idle()

    async def drive(self, samples, gap=None):
        async with self._transaction_lock:
            await self._drive_samples(list(samples), gap)


class DspSampleMonitor(_DspSampleComponent):
    """Passive monitor publishing valid samples through an analysis port."""

    def __init__(self, dut, config):
        super().__init__(dut, config)
        self.samples = AnalysisPort[DspSample]()
        self._task = None

    def start(self):
        if self._task is None:
            self._task = cocotb.start_soon(self.run())
        return self._task

    def stop(self):
        if self._task is not None:
            self._task.cancel()
            self._task = None

    def _sample_value(self, name, *, signed=False, default=0):
        signal = self._optional(name)
        if signal is None:
            return default
        return self._signed(signal) if signed else int(signal.value)

    async def run(self):
        cycle = 0
        ready = self._optional(self.signals.ready)
        while True:
            await RisingEdge(self.clock)
            cycle += 1
            if self._in_reset():
                continue
            if not int(self._required(self.signals.valid).value):
                continue
            if ready is not None and not int(ready.value):
                continue
            self.samples.write(
                DspSample(
                    i=self._sample_value(
                        self.signals.i,
                        signed=self.config.signed_iq,
                    ),
                    q=self._sample_value(
                        self.signals.q,
                        signed=self.config.signed_iq,
                    ),
                    channel=self._sample_value(self.signals.channel),
                    start_frame=bool(self._sample_value(self.signals.start_frame)),
                    start_slot=bool(self._sample_value(self.signals.start_slot)),
                    start_symbol=bool(self._sample_value(self.signals.start_symbol)),
                    cycle=cycle,
                )
            )


class DspSampleAgent:
    """DSP sample agent containing a monitor and optional source driver."""

    def __init__(self, dut, config):
        self.config = config
        self.monitor = DspSampleMonitor(dut, config)
        self.driver = (
            DspSampleDriver(dut, config)
            if AgentMode(config.mode) is AgentMode.ACTIVE
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

    async def send(self, samples, gap=None):
        if self.driver is None:
            raise DspSampleError("passive DSP sample agent has no driver")
        await self.driver.drive(samples, gap)

    async def receive(self, timeout_cycles=None):
        timeout_cycles = timeout_cycles or self.config.timeout_cycles
        task = cocotb.start_soon(self.monitor.samples.get())
        await First(task, ClockCycles(self.monitor.clock, timeout_cycles))
        if not task.done():
            task.cancel()
            raise DspSampleError(
                f"DSP sample monitor timed out after {timeout_cycles} cycles"
            )
        return task.result()
