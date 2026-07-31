"""UVM-style AXI4-Lite transaction, driver, monitor, and agent."""

from collections import deque
from dataclasses import dataclass
from enum import Enum

import cocotb
from cocotb.triggers import Combine, FallingEdge, Lock, ReadOnly, RisingEdge

from .base import AgentMode, AnalysisPort

__all__ = [
    "AxiLiteAgent",
    "AxiLiteAgentConfig",
    "AxiLiteError",
    "AxiLiteMaster",
    "AxiLiteMasterDriver",
    "AxiLiteMonitor",
    "AxiLiteOperation",
    "AxiLiteTransaction",
    "axi_read",
    "axi_reset",
    "axi_write",
]


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

    def _sig(self, name):
        return getattr(self.dut, f"{self.prefix}_{name}")

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
            self._sig(name).value = 0

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
        self._sig("awprot").value = transaction.protection
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
        self._sig("arprot").value = transaction.protection
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

    async def run(self):
        while True:
            # Signals are stable during the falling half-cycle and describe
            # the transfer accepted at the following rising edge.
            await FallingEdge(self.clock)
            await ReadOnly()
            if self._in_reset():
                self._clear_pending()
                continue

            if int(self._sig("awvalid").value) and int(self._sig("awready").value):
                self._aw.append(
                    (int(self._sig("awaddr").value), int(self._sig("awprot").value))
                )
            if int(self._sig("wvalid").value) and int(self._sig("wready").value):
                self._w.append(
                    (int(self._sig("wdata").value), int(self._sig("wstrb").value))
                )
            if int(self._sig("arvalid").value) and int(self._sig("arready").value):
                self._ar.append(
                    (int(self._sig("araddr").value), int(self._sig("arprot").value))
                )

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
