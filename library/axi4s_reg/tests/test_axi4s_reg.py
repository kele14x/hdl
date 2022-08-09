import random

import cocotb
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge, ClockCycles


HAS_TKEEP = cocotb.top.HAS_TKEEP.value
HAS_TLAST = cocotb.top.HAS_TLAST.value
HAS_TREADY = cocotb.top.HAS_TREADY.value
HAS_TSTRB = cocotb.top.HAS_TSTRB.value
TDATA_WIDTH = cocotb.top.TDATA_WIDTH.value
TDEST_WIDTH = cocotb.top.TDEST_WIDTH.value
TID_WIDTH = cocotb.top.TID_WIDTH.value
TUSER_WIDTH = cocotb.top.TUSER_WIDTH.value


class AxiStreamTransaction:
    """
    Transaction of an AXI stream interface.
    """

    def __init__(self, tdata: int, tstrb: int, tkeep: int, tlast: int,
                 tid: int, tdest: int, tuser: int):
        self.tdata = tdata
        self.tstrb = tstrb
        self.tkeep = tkeep
        self.tlast = tlast
        self.tid = tid
        self.tdest = tdest
        self.tuser = tuser

    def __str__(self) -> str:
        return f"AxiStreamTransaction(tdata={self.tdata}, " \
               f"tstrb={self.tstrb}, " \
               f"tkeep={self.tkeep}, " \
               f"tlast={self.tlast}, " \
               f"tid={self.tid}, " \
               f"tdest={self.tdest}, " \
               f"tuser={self.tuser})"

    def __eq__(self, other) -> bool:
        if not isinstance(other, AxiStreamTransaction):
            return False

        if self.tdata != other.tdata:
            return False

        return True


class AxiStreamMonitor:
    """
    Simple monitor to read AXI Stream transaction from bus.
    """

    def __init__(self, dut: SimHandleBase, prefix: str):

        self.values = Queue[AxiStreamTransaction]()
        self._dut = dut
        self._prefix = prefix
        self.TVALID = getattr(dut, f"{prefix}_tvalid")
        self.TREADY = getattr(dut, f"{prefix}_tready")
        self.TDATA = getattr(dut, f"{prefix}_tdata")
        self.TSTRB = getattr(dut, f"{prefix}_tstrb")
        self.TKEEP = getattr(dut, f"{prefix}_tkeep")
        self.TLAST = getattr(dut, f"{prefix}_tlast")
        self.TID = getattr(dut, f"{prefix}_tid")
        self.TDEST = getattr(dut, f"{prefix}_tdest")
        self.TUSER = getattr(dut, f"{prefix}_tuser")

        self._coro = None

    def start(self) -> None:
        """Start the monitor."""
        if self._coro is not None:
            raise RuntimeError("Monitor already started")
        self._coro = cocotb.start_soon(self._monitor())

    def stop(self) -> None:
        """Stop the monitor."""
        if self._coro is None:
            raise RuntimeError("Monitor not started")
        self._coro.kill()
        self._coro = None

    async def _monitor(self) -> None:
        while True:
            await RisingEdge(self._dut.aclk)
            if self.TVALID.value and self.TREADY.value:
                self.values.put_nowait(self._sample())

    def _sample(self) -> AxiStreamTransaction:
        """Sample the AXI Stream transaction."""
        return AxiStreamTransaction(
            self.TDATA.value.integer,
            self.TSTRB.value.integer,
            self.TKEEP.value.integer,
            self.TLAST.value.integer,
            self.TID.value.integer,
            self.TDEST.value.integer,
            self.TUSER.value.integer)


class Axi4sRegTester:
    """Checker of a axi4s_reg instance."""

    def __init__(self, dut: SimHandleBase):
        self.dut = dut
        self._checker = None
        self._mst_mon = AxiStreamMonitor(dut, 's_axis')
        self._slv_mon = AxiStreamMonitor(dut, 'm_axis')

    def start(self) -> None:
        """Start the checker."""
        if self._checker is not None:
            raise RuntimeError("Checker already started")
        self._mst_mon.start()
        self._slv_mon.start()
        self._checker = cocotb.start_soon(self._check())

    def stop(self) -> None:
        """Stop the checker."""
        if self._checker is None:
            raise RuntimeError("Checker not started")
        self._mst_mon.stop()
        self._slv_mon.stop()
        self._checker.kill()
        self._checker = None

    async def _check(self) -> None:
        """Checker function."""
        while True:
            mst_trans = await self._mst_mon.values.get()
            slv_trans = await self._slv_mon.values.get()
            assert mst_trans == slv_trans, f"Master and slave transaction " \
                f"mismatch: {mst_trans}, {slv_trans}"


@cocotb.test()
async def test_axi4s_reg_basic(dut):
    """
    Perform some basic test of axi4s_reg module.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.aclk, 10).start())

    # Reset the DUT
    dut.aclken.value = 1
    dut.aresetn.value = 0
    dut.m_axis_tvalid.value = 0
    dut.s_axis_tdata.value = 0
    dut.s_axis_tstrb.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tid.value = 0
    dut.s_axis_tdest.value = 0
    dut.s_axis_tuser.value = 0
    dut.m_axis_tready.value = 0
    await ClockCycles(dut.aclk, 16)
    dut.aresetn.value = 1

    assert dut.m_axis_tvalid.value == 0, "After reset, " \
        "m_axis_tvalid should be 0"


@cocotb.test()
async def test_axi4s_reg_random(dut):
    """
    Perform some random test of axi4s_reg module.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.aclk, 10).start())

    # Reset the DUT
    dut.aclken.value = 1
    dut.aresetn.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tdata.value = 0
    dut.s_axis_tstrb.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tid.value = 0
    dut.s_axis_tdest.value = 0
    dut.s_axis_tuser.value = 0
    dut.m_axis_tready.value = 0
    await ClockCycles(dut.aclk, 16)
    dut.aresetn.value = 1

    # Create the checker
    checker = Axi4sRegTester(dut)
    checker.start()

    # Create the transaction
    for _ in range(1000):
        await RisingEdge(dut.aclk)
        dut.s_axis_tvalid.value = random.randint(0, 1)
        dut.s_axis_tdata.value = random.randint(0, 2**TDATA_WIDTH-1)
        dut.s_axis_tstrb.value = random.randint(0, 1)
        dut.s_axis_tkeep.value = random.randint(0, 1)
        dut.s_axis_tlast.value = random.randint(0, 1)
        dut.s_axis_tid.value = random.randint(0, 1)
        dut.s_axis_tdest.value = random.randint(0, 1)
        dut.s_axis_tuser.value = random.randint(0, 1)
        dut.m_axis_tready.value = random.randint(0, 1)

    await ClockCycles(dut.aclk, 10)
    dut._log.info("Simulation finished")
