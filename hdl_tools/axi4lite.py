"""Reusable AXI4-Lite verification components for cocotb testbenches.

Channel level: each of the five AXI4-Lite channels has a frozen transaction
dataclass, a sequence container, and an agent with ``drive`` and ``monitor``
coroutines.  Every channel is a valid/ready handshake stream (see
``hdl_tools.handshake``) with fixed payload fields: AR/AW/W are source-side
agents, R/B are sink-side agents.  Drivers only control their own channel
signals; monitors never drive and record every observed handshake in
``observed``.

``WTransaction.strb`` defaults to ``None``, which ``WAgent`` resolves to all
strobe bits set based on the actual ``wstrb`` width of the DUT.

Transaction level: :class:`AxiLiteMasterDriver` and :class:`AxiLiteAgent`
perform complete read/write operations (AW and W issued concurrently,
completed by B; AR completed by R) for register-access style traffic, and
:class:`AxiLiteMonitor` reconstructs complete transactions from the channel
handshakes.  All driving and sampling happens on the rising clock edge.
"""

from __future__ import annotations

from collections import deque
from collections.abc import Iterator, Sequence
from dataclasses import dataclass, field
from enum import Enum

import cocotb
from cocotb.triggers import Combine, Lock, RisingEdge

from .handshake import (
    HandshakeConfig,
    HandshakeItem,
    HandshakeMonitor,
    HandshakeRecord,
    HandshakeSink,
    HandshakeSource,
)
from .tb_base import AgentMode, AnalysisPort

# ---------------------------------------------------------------------------
# AR channel
# ---------------------------------------------------------------------------


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


class ARAgent:
    """AR driver and monitor."""

    def __init__(self, dut, clock: str = "aclk"):
        self.dut = dut
        self.observed: list[ARTransaction] = []
        config = HandshakeConfig(clock=clock)
        self._source = HandshakeSource(
            dut, "arvalid", ["araddr"], ready="arready", config=config
        )
        self._monitor = HandshakeMonitor(
            dut, "arvalid", ["araddr"], ready="arready", config=config
        )

    async def drive(self, sequence: ARSequence) -> None:
        items = [
            HandshakeItem(payload={"araddr": t.address}, gap=t.pre_packet_gap)
            for t in sequence
        ]
        await self._source.drive(items)

    async def monitor(self) -> None:
        self._monitor.transactions.subscribe(self._record)
        await self._monitor.run()

    def _record(self, record: HandshakeRecord) -> None:
        self.observed.append(
            ARTransaction(address=record.payload["araddr"], pre_packet_gap=record.gap)
        )


# ---------------------------------------------------------------------------
# R channel
# ---------------------------------------------------------------------------


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


class RAgent:
    """R driver and monitor."""

    def __init__(self, dut, clock: str = "aclk"):
        self.dut = dut
        self.observed: list[RTransaction] = []
        config = HandshakeConfig(clock=clock)
        self._sink = HandshakeSink(
            dut, "rvalid", ["rdata", "rresp"], ready="rready", config=config
        )
        self._monitor = HandshakeMonitor(
            dut, "rvalid", ["rdata", "rresp"], ready="rready", config=config
        )

    async def drive(self, sequence: RSequence) -> None:
        await self._sink.drive([t.idle_cycles for t in sequence])

    async def monitor(self) -> None:
        self._monitor.transactions.subscribe(self._record)
        await self._monitor.run()

    def _record(self, record: HandshakeRecord) -> None:
        self.observed.append(
            RTransaction(
                idle_cycles=record.latency or 0,
                data=record.payload["rdata"],
                resp=record.payload["rresp"],
            )
        )


# ---------------------------------------------------------------------------
# AW channel
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class AWTransaction:
    """An AXI write-address request.

    ``pre_packet_gap`` is the minimum number of idle clocks between this
    request and the preceding request.  A value of zero permits back-to-back
    AW handshakes.  The actual observed gap can be larger when AWREADY applies
    backpressure.
    """

    address: int
    pre_packet_gap: int = 0

    def __post_init__(self) -> None:
        if self.pre_packet_gap < 0:
            raise ValueError("pre_packet_gap must be non-negative")


@dataclass(frozen=True)
class AWSequence:
    """The AW-channel test vector."""

    transactions: Sequence[AWTransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[AWTransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


class AWAgent:
    """AW driver and monitor."""

    def __init__(self, dut, clock: str = "aclk"):
        self.dut = dut
        self.observed: list[AWTransaction] = []
        config = HandshakeConfig(clock=clock)
        self._source = HandshakeSource(
            dut, "awvalid", ["awaddr"], ready="awready", config=config
        )
        self._monitor = HandshakeMonitor(
            dut, "awvalid", ["awaddr"], ready="awready", config=config
        )

    async def drive(self, sequence: AWSequence) -> None:
        items = [
            HandshakeItem(payload={"awaddr": t.address}, gap=t.pre_packet_gap)
            for t in sequence
        ]
        await self._source.drive(items)

    async def monitor(self) -> None:
        self._monitor.transactions.subscribe(self._record)
        await self._monitor.run()

    def _record(self, record: HandshakeRecord) -> None:
        self.observed.append(
            AWTransaction(address=record.payload["awaddr"], pre_packet_gap=record.gap)
        )


# ---------------------------------------------------------------------------
# W channel
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class WTransaction:
    """An AXI write-data request.

    ``strb`` of ``None`` selects every strobe bit; ``WAgent`` resolves it
    against the DUT's ``wstrb`` width.  ``pre_packet_gap`` has the same
    meaning as in :class:`AWTransaction`, measured on the W channel.
    """

    data: int
    strb: int | None = None
    pre_packet_gap: int = 0

    def __post_init__(self) -> None:
        if self.pre_packet_gap < 0:
            raise ValueError("pre_packet_gap must be non-negative")


@dataclass(frozen=True)
class WSequence:
    """The W-channel test vector."""

    transactions: Sequence[WTransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[WTransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


class WAgent:
    """W driver and monitor."""

    def __init__(self, dut, clock: str = "aclk"):
        self.dut = dut
        self.observed: list[WTransaction] = []
        config = HandshakeConfig(clock=clock)
        self._source = HandshakeSource(
            dut, "wvalid", ["wdata", "wstrb"], ready="wready", config=config
        )
        self._monitor = HandshakeMonitor(
            dut, "wvalid", ["wdata", "wstrb"], ready="wready", config=config
        )

    def full_strb(self) -> int:
        """All strobe bits set, sized by the DUT's ``wstrb`` width."""
        return (1 << len(self.dut.wstrb)) - 1

    async def drive(self, sequence: WSequence) -> None:
        items = [
            HandshakeItem(
                payload={
                    "wdata": t.data,
                    "wstrb": self.full_strb() if t.strb is None else t.strb,
                },
                gap=t.pre_packet_gap,
            )
            for t in sequence
        ]
        await self._source.drive(items)

    async def monitor(self) -> None:
        self._monitor.transactions.subscribe(self._record)
        await self._monitor.run()

    def _record(self, record: HandshakeRecord) -> None:
        self.observed.append(
            WTransaction(
                data=record.payload["wdata"],
                strb=record.payload["wstrb"],
                pre_packet_gap=record.gap,
            )
        )


# ---------------------------------------------------------------------------
# B channel
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class BTransaction:
    """A B-channel acceptance policy, or a monitored B transfer.

    For a vector, only ``idle_cycles`` is supplied.  A positive value keeps
    BREADY low for that many clocks after BVALID is seen; zero asserts BREADY
    in the same cycle BVALID is observed; a negative value asserts BREADY
    proactively, before waiting for BVALID.  Monitors additionally fill in
    ``resp`` for completed transfers.
    """

    idle_cycles: int = 0
    resp: int | None = None


@dataclass(frozen=True)
class BSequence:
    """The B-channel test vector."""

    transactions: Sequence[BTransaction] = field(default_factory=tuple)

    def __iter__(self) -> Iterator[BTransaction]:
        return iter(self.transactions)

    def __len__(self) -> int:
        return len(self.transactions)


class BAgent:
    """B driver and monitor."""

    def __init__(self, dut, clock: str = "aclk"):
        self.dut = dut
        self.observed: list[BTransaction] = []
        config = HandshakeConfig(clock=clock)
        self._sink = HandshakeSink(
            dut, "bvalid", ["bresp"], ready="bready", config=config
        )
        self._monitor = HandshakeMonitor(
            dut, "bvalid", ["bresp"], ready="bready", config=config
        )

    async def drive(self, sequence: BSequence) -> None:
        await self._sink.drive([t.idle_cycles for t in sequence])

    async def monitor(self) -> None:
        self._monitor.transactions.subscribe(self._record)
        await self._monitor.run()

    def _record(self, record: HandshakeRecord) -> None:
        self.observed.append(
            BTransaction(idle_cycles=record.latency or 0, resp=record.payload["bresp"])
        )


# ---------------------------------------------------------------------------
# Transaction level
# ---------------------------------------------------------------------------


class AxiLiteError(AssertionError):
    """Raised for an AXI response error, protocol error, or timeout."""


class AxiLiteOperation(str, Enum):
    READ = "read"
    WRITE = "write"


@dataclass
class AxiLiteTransaction:
    """One completed AXI4-Lite read or write transaction."""

    operation: AxiLiteOperation
    address: int
    data: int | None = None
    strobe: int | None = None
    protection: int = 0
    response: int | None = None

    @classmethod
    def read(cls, address, protection=0):
        return cls(AxiLiteOperation.READ, address, protection=protection)

    @classmethod
    def write(cls, address, data, strobe=None, protection=0):
        return cls(
            AxiLiteOperation.WRITE,
            address,
            data=data,
            strobe=strobe,
            protection=protection,
        )


@dataclass(frozen=True)
class AxiLiteAgentConfig:
    prefix: str = "s_axi"
    clock: str = "s_axi_aclk"
    reset: str | None = None
    reset_active_level: int = 0
    timeout_cycles: int = 100
    mode: AgentMode = AgentMode.ACTIVE


class _AxiLiteComponent:
    def __init__(self, dut, config: AxiLiteAgentConfig):
        self.dut = dut
        self.config = config
        self.prefix = config.prefix
        self.clock = getattr(dut, config.clock)
        self.reset_signal = getattr(dut, config.reset) if config.reset else None

    def _name(self, name: str) -> str:
        return name if not self.prefix else f"{self.prefix}_{name}"

    def _sig(self, name):
        return getattr(self.dut, self._name(name))

    def _optional(self, name):
        return getattr(self.dut, self._name(name), None)

    def _in_reset(self):
        return self.reset_signal is not None and (
            int(self.reset_signal.value) == self.config.reset_active_level
        )


class AxiLiteMasterDriver(_AxiLiteComponent):
    """Active AXI4-Lite master driver."""

    def __init__(self, dut, config):
        super().__init__(dut, config)
        self._transaction_lock = Lock()

    def idle(self):
        for name in (
            "awaddr",
            "awprot",
            "awvalid",
            "wdata",
            "wstrb",
            "wvalid",
            "bready",
            "araddr",
            "arprot",
            "arvalid",
            "rready",
        ):
            signal = self._optional(name)
            if signal is not None:
                signal.value = 0

    async def reset(self):
        self.idle()

    async def _handshake(self, ready, channel):
        for _ in range(self.config.timeout_cycles):
            await RisingEdge(self.clock)
            if int(ready.value):
                return
        raise AxiLiteError(
            f"AXI-Lite {self.prefix} {channel} timeout after "
            f"{self.config.timeout_cycles} cycles"
        )

    async def _send_aw(self, transaction):
        self._sig("awaddr").value = transaction.address
        prot = self._optional("awprot")
        if prot is not None:
            prot.value = transaction.protection
        self._sig("awvalid").value = 1
        await self._handshake(self._sig("awready"), "AW")
        self._sig("awvalid").value = 0

    async def _send_w(self, transaction):
        strobe = transaction.strobe
        if strobe is None:
            strobe = (1 << len(self._sig("wstrb"))) - 1
        self._sig("wdata").value = transaction.data
        self._sig("wstrb").value = strobe
        self._sig("wvalid").value = 1
        await self._handshake(self._sig("wready"), "W")
        self._sig("wvalid").value = 0

    async def _recv_b(self):
        self._sig("bready").value = 1
        await self._handshake(self._sig("bvalid"), "B")
        response = int(self._sig("bresp").value)
        self._sig("bready").value = 0
        return response

    async def _send_ar(self, transaction):
        self._sig("araddr").value = transaction.address
        prot = self._optional("arprot")
        if prot is not None:
            prot.value = transaction.protection
        self._sig("arvalid").value = 1
        await self._handshake(self._sig("arready"), "AR")
        self._sig("arvalid").value = 0

    async def _recv_r(self):
        self._sig("rready").value = 1
        await self._handshake(self._sig("rvalid"), "R")
        data = int(self._sig("rdata").value)
        response = int(self._sig("rresp").value)
        self._sig("rready").value = 0
        return data, response

    async def _drive_transaction(self, transaction, expected_response):
        operation = AxiLiteOperation(transaction.operation)
        if operation is AxiLiteOperation.WRITE:
            if transaction.data is None:
                raise ValueError("write transaction requires data")
            aw_task = cocotb.start_soon(self._send_aw(transaction))
            w_task = cocotb.start_soon(self._send_w(transaction))
            b_task = cocotb.start_soon(self._recv_b())
            await Combine(aw_task, w_task, b_task)
            transaction.response = b_task.result()
        elif operation is AxiLiteOperation.READ:
            ar_task = cocotb.start_soon(self._send_ar(transaction))
            r_task = cocotb.start_soon(self._recv_r())
            await Combine(ar_task, r_task)
            transaction.data, transaction.response = r_task.result()
        else:
            raise ValueError(f"unsupported AXI-Lite operation {transaction.operation}")

        if transaction.response != expected_response:
            raise AxiLiteError(
                f"AXI-Lite {transaction.operation.value} {transaction.address:#x} "
                f"returned response={transaction.response:#x}, "
                f"expected {expected_response:#x}"
            )
        return transaction

    async def drive(self, transaction, expected_response=0):
        """Serialize and drive one transaction."""
        async with self._transaction_lock:
            return await self._drive_transaction(transaction, expected_response)

    async def write(
        self,
        address,
        data,
        strobe=None,
        protection=0,
        expected_response=0,
    ):
        transaction = AxiLiteTransaction.write(address, data, strobe, protection)
        await self.drive(transaction, expected_response)
        cocotb.log.debug("AXI write %s: %#x <- %#x", self.prefix, address, data)
        return transaction.response

    async def read(self, address, protection=0, expected_response=0):
        transaction = AxiLiteTransaction.read(address, protection)
        await self.drive(transaction, expected_response)
        cocotb.log.debug(
            "AXI read %s: %#x -> %#x", self.prefix, address, transaction.data
        )
        return transaction.data


class AxiLiteMonitor(_AxiLiteComponent):
    """Passive monitor that reconstructs complete read/write transactions."""

    def __init__(self, dut, config: AxiLiteAgentConfig):
        super().__init__(dut, config)
        self.transactions = AnalysisPort[AxiLiteTransaction]()
        self._task = None
        self._aw = deque()
        self._w = deque()
        self._ar = deque()

    def _clear_pending(self):
        self._aw.clear()
        self._w.clear()
        self._ar.clear()

    def start(self):
        if self._task is None:
            self._task = cocotb.start_soon(self.run())
        return self._task

    def stop(self):
        if self._task is not None:
            self._task.kill()
            self._task = None

    def _prot(self, name: str) -> int:
        signal = self._optional(name)
        return 0 if signal is None else int(signal.value)

    async def run(self):
        while True:
            await RisingEdge(self.clock)
            if self._in_reset():
                self._clear_pending()
                continue

            if int(self._sig("awvalid").value) and int(self._sig("awready").value):
                self._aw.append((int(self._sig("awaddr").value), self._prot("awprot")))
            if int(self._sig("wvalid").value) and int(self._sig("wready").value):
                self._w.append(
                    (int(self._sig("wdata").value), int(self._sig("wstrb").value))
                )
            if int(self._sig("arvalid").value) and int(self._sig("arready").value):
                self._ar.append((int(self._sig("araddr").value), self._prot("arprot")))

            if int(self._sig("bvalid").value) and int(self._sig("bready").value):
                if not self._aw or not self._w:
                    raise AxiLiteError("write response observed without AW and W")
                address, protection = self._aw.popleft()
                data, strobe = self._w.popleft()
                transaction = AxiLiteTransaction.write(
                    address, data, strobe, protection
                )
                transaction.response = int(self._sig("bresp").value)
                self.transactions.write(transaction)

            if int(self._sig("rvalid").value) and int(self._sig("rready").value):
                if not self._ar:
                    raise AxiLiteError("read response observed without AR")
                address, protection = self._ar.popleft()
                self.transactions.write(
                    AxiLiteTransaction(
                        operation=AxiLiteOperation.READ,
                        address=address,
                        data=int(self._sig("rdata").value),
                        protection=protection,
                        response=int(self._sig("rresp").value),
                    )
                )


class AxiLiteAgent:
    """AXI4-Lite agent containing a monitor and optional master driver."""

    def __init__(self, dut, config=None, **config_overrides):
        if config is None:
            config = AxiLiteAgentConfig(**config_overrides)
        elif config_overrides:
            raise TypeError("pass either config or keyword overrides, not both")
        self.config = config
        self.monitor = AxiLiteMonitor(dut, config)
        self.driver = (
            AxiLiteMasterDriver(dut, config)
            if AgentMode(config.mode) is AgentMode.ACTIVE
            else None
        )

    async def start(self):
        if self.driver is not None:
            self.driver.idle()
        self.monitor.start()

    def stop(self):
        self.monitor.stop()

    async def write(self, *args, **kwargs):
        if self.driver is None:
            raise AxiLiteError("passive AXI-Lite agent has no driver")
        return await self.driver.write(*args, **kwargs)

    async def read(self, *args, **kwargs):
        if self.driver is None:
            raise AxiLiteError("passive AXI-Lite agent has no driver")
        return await self.driver.read(*args, **kwargs)


class AxiLiteMaster(AxiLiteMasterDriver):
    """Compatibility constructor for the previous standalone master class."""

    def __init__(
        self,
        dut,
        prefix="s_axi",
        clock="s_axi_aclk",
        timeout_cycles=100,
    ):
        super().__init__(
            dut,
            AxiLiteAgentConfig(
                prefix=prefix,
                clock=clock if isinstance(clock, str) else "s_axi_aclk",
                timeout_cycles=timeout_cycles,
            ),
        )
        if not isinstance(clock, str):
            self.clock = clock


async def axi_reset(dut, prefix="s_axi", clock="s_axi_aclk"):
    await AxiLiteMaster(dut, prefix, clock).reset()


async def axi_write(
    dut, address, data, strobe=None, prefix="s_axi", clock="s_axi_aclk"
):
    return await AxiLiteMaster(dut, prefix, clock).write(address, data, strobe)


async def axi_read(dut, address, prefix="s_axi", clock="s_axi_aclk"):
    return await AxiLiteMaster(dut, prefix, clock).read(address)
