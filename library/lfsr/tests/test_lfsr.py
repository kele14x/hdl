from numbers import Complex
import random

import cocotb
import matlab.engine
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.triggers import ClockCycles, RisingEdge
from tester import DataMonitor


BIT_WIDTH = cocotb.top.BIT_WIDTH.value
INITIAL = cocotb.top.INITIAL.value
POLYNOMIAL = cocotb.top.POLYNOMIAL.value
STRUCTURE = cocotb.top.STRUCTURE.value
GATE_TYPE = cocotb.top.GATE_TYPE.value
PARALLEL_OUTPUT = cocotb.top.PARALLEL_OUTPUT.value


class LfsrTester:
    """
    Checker for a LFSR instance.
    """

    def __init__(self, dut: SimHandleBase):
        self.dut = dut
        self._checker = None

        self.input_mon = DataMonitor(
            dut=self.dut,
            signals=['rst']
        )

        self.output_mon = DataMonitor(
            dut=self.dut,
            signals=['dout'],
            delay=1
        )

        # Start MATLAB session
        self._eng = matlab.engine.start_matlab('-sd ~/Workspaces/dfe')
        self._eng.setpath(nargout=0)

        # Create MATLAB reference System object
        self._model = self._eng.dfe.LFSR(
            'BitWidth', float(BIT_WIDTH),
            'Initial', float(INITIAL),
            'Polynomial', float(POLYNOMIAL),
            'Structure', str(STRUCTURE, 'utf-8').title(),
            'GateType', str(GATE_TYPE, 'utf-8'),
            'PalleralOutput', PARALLEL_OUTPUT
        )

    def start(self) -> None:
        """Starts monitors, model, and checker coroutine."""
        if self._checker is not None:
            raise RuntimeError('Monitor already started')
        self.input_mon.start()
        self.output_mon.start()
        self._checker = cocotb.start_soon(self._check())

    def stop(self) -> None:
        """Stops everything."""
        if self._checker is None:
            raise RuntimeError('Monitor never started')
        self.input_mon.stop()
        self.output_mon.stop()
        self._checker.kill()
        self._checker = None

    def model(self, rstSeq: float) -> Complex:
        """Golden reference model."""
        stat = self._eng.step(self._model, 1, rstSeq)
        return stat

    async def _check(self) -> None:
        """Checker function."""
        while True:
            input = await self.input_mon.values.get()
            output = await self.output_mon.values.get()
            rstSeq = input['rst'].value
            ref = self.model(float(rstSeq))
            result = output['dout'].value
            assert ref == result, f"ref= {ref}, result={result}"


@cocotb.test()
async def test_lfsr_basic(dut):
    """Perform some basic test of LFSR module."""

    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start(start_high=False))

    # Reset DUT
    dut.rst.value = 1
    dut.en.value = 1
    dut.load.value = 0
    dut.din.value = 0
    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    # `dout` should be reset to initial value
    assert dut.dout.value == INITIAL


@cocotb.test()
async def test_lfsr_advanced(dut):
    """Test LFSR against a MATLAB model."""

    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start(start_high=False))

    # Create Python tester
    tester = LfsrTester(dut)

    # Reset DUT
    dut.rst.value = 1
    dut.en.value = 1
    dut.load.value = 0
    dut.din.value = 0
    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0

    # Reset DUT
    tester.start()
    await ClockCycles(dut.clk, 100)
