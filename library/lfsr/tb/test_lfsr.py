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

        if STRUCTURE == b"FIBONACCI":
            if GATE_TYPE == b"XOR":
                bit = 0
            else:
                bit = 1
            for i in range(0, BIT_WIDTH):
                if POLYNOMIAL >> i & 1:
                    if GATE_TYPE == b"XOR":
                        bit = (bit ^ (stat >> i)) & 1
                    else:
                        bit = ~(bit ^ (stat >> i)) & 1
            stat_new = (stat >> 1) | (bit << (BIT_WIDTH - 1))
        else:
            bit = stat & 1
            stat_new = stat >> 1
            if bit == 1 and GATE_TYPE == b"XOR":
                stat_new ^= (POLYNOMIAL >> 1)
            if bit == 0 and GATE_TYPE == b"XNOR":
                stat_new = ~(stat_new ^ (POLYNOMIAL >> 1))
            stat_new |= (bit << (BIT_WIDTH - 1))

        return stat_new

    async def _check(self) -> None:
        await RisingEdge(self.dut.clk)
        stat_previous = self.dut.lfsr_regs.value
        while True:
            en = self.dut.en.value
            rst = self.dut.rst.value
            await RisingEdge(self.dut.clk)
            stat_current = self.dut.lfsr_regs.value
            if rst == 1:
                assert stat_current == self.dut.INITIAL.value
                continue
            if en == 1:
                expected = self.model(stat_previous.integer)
                assert stat_current == expected
                stat_previous = stat_current
            else:
                assert stat_current == stat_previous


@cocotb.test()
async def lsft_test(dut):
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
    dut.rst.value = 1

    await RisingEdge(dut.clk)
    tester.start()

    # Reset DUT
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst.value = 0


    # await RisingEdge(dut.clk)
    # dut._log.debug(f"{dut.dout.value}")
    # assert dut.dout.value == dut.INITIAL, "dout is not proper reset"

    for _ in range(0, 2 ** dut.BIT_WIDTH.value - 1):
        await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)
