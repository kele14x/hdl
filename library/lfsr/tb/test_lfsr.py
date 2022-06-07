from xmlrpc.client import Boolean
import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase


class LfsrTester:
    """
    Checker for a LFSR instance.
    """

    def __init__(self, lfsr_entity: SimHandleBase):
        self.dut = lfsr_entity
        self._checker = None

    def start(self) -> None:
        """Starts monitors, model, and checker coroutine."""
        if self._checker is not None:
            raise RuntimeError("Monitor already started")
        self._checker = cocotb.start_soon(self._check())

    def stop(self) -> None:
        """Stops everything."""
        if self._checker is None:
            raise RuntimeError("Monitor never started")
        self._checker.kill()
        self._checker = None

    def model(self, stat: int) -> int:
        BIT_WIDTH = self.dut.BIT_WIDTH.value
        POLYNOMIAL = self.dut.POLYNOMIAL.value
        STRUCTURE = self.dut.STRUCTURE.value
        GATE_TYPE = self.dut.GATE_TYPE.value

        bit = 0
        for i in range(0, BIT_WIDTH):
            if POLYNOMIAL >> i & 1:
                bit = bit ^ ((stat >> i) & 1)

        stat_new = (stat >> 1) | (bit << (BIT_WIDTH - 1))
        return stat_new

    async def _check(self) -> None:
        await RisingEdge(self.dut.clk)
        while True:
            en = self.dut.en.value
            if en == 1:
                stat_previous = self.dut.dout.value
                await RisingEdge(self.dut.clk)
                stat_current = self.dut.dout.value
                expected = self.model(stat_previous.integer)
                assert stat_current == expected


@cocotb.test()
async def lsft_rst_test(dut):
    """Test reset of LFSR."""

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Parameters:")
    dut._log.info(f"BIT_WIDTH       : {dut.BIT_WIDTH.value}")
    dut._log.info(f"INITIAL         : {dut.INITIAL.value}")
    dut._log.info(f"POLYNOMIAL      : {dut.POLYNOMIAL.value}")
    dut._log.info(f"STRUCTURE       : {dut.STRUCTURE.value}")
    dut._log.info(f"GATE_TYPE       : {dut.GATE_TYPE.value}")
    dut._log.info(f"PARALLEL_OUTPUT : {dut.PARALLEL_OUTPUT.value}")

    tester = LfsrTester(dut)

    # Initial values
    dut.en.value = 1
    dut.load.value = 0
    dut.din.value = 0

    # Reset DUT
    dut.rst.value = 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst.value = 0

    tester.start()

    # await RisingEdge(dut.clk)
    # dut._log.debug(f"{dut.dout.value}")
    # assert dut.dout.value == dut.INITIAL, "dout is not proper reset"

    for _ in range(0, 2 ** dut.BIT_WIDTH.value - 1):
        await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)
