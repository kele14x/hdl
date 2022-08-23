from numbers import Complex
import random
from typing import Tuple

import cocotb
import matlab.engine
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.triggers import ClockCycles, RisingEdge
from tester import DataMonitor

PHASE_FRACTION_WIDTH = cocotb.top.PHASE_FRACTION_WIDTH.value
PHASE_ENTRIES = cocotb.top.PHASE_ENTRIES.value
DATA_WIDTH = cocotb.top.DATA_WIDTH.value
LFSR_INITIAL = cocotb.top.LFSR_INITIAL.value
LFSR_POLYNOMIAL = cocotb.top.LFSR_POLYNOMIAL.value


class NcoTester:
    """
    Tester of a NCO instance.
    """

    def __init__(self, dut: SimHandleBase):
        self.dut = dut
        self._checker = None

        self.input_mon = DataMonitor(
            dut=dut,
            signals=['sync']
        )

        self.output_mon = DataMonitor(
            dut=dut,
            signals=['cos', 'sin'],
            delay=self.dut.Latency.value
        )

        # Start MATLAB session
        self._eng = matlab.engine.start_matlab('-sd ~/Workspaces/dfe')
        self._eng.setpath(nargout=0)

        # Create MATLAB reference System object
        self._model = self._eng.dfe.NCO(
            'PhaseFractionWidth', float(PHASE_FRACTION_WIDTH),
            'PhaseEntries', float(PHASE_ENTRIES),
            'DataWidth', float(DATA_WIDTH),
            'LFSRInitial', float(LFSR_INITIAL),
            'LFSRPolynomial', float(LFSR_POLYNOMIAL)
        )

    def start(self) -> None:
        """Start the checker."""
        if self._checker is not None:
            raise RuntimeError("Checker already started")
        self.input_mon.start()
        self.output_mon.start()
        self._checker = cocotb.start_soon(self._check())

    def stop(self) -> None:
        """Stop the checker."""
        if self._checker is None:
            raise RuntimeError("Checker not started")
        self.input_mon.stop()
        self.output_mon.stop()
        self._checker.kill()
        self._checker = None

    def model(self, sync) -> Complex:
        """The golden model of the NCO."""
        result = self._eng.step(self._model, 1, sync)
        return result

    async def _check(self) -> None:
        """Checker function."""
        while True:
            input = await self.input_mon.values.get()
            output = await self.output_mon.values.get()

            # Simulation output
            sync = input["sync"].integer
            cos = output["cos"].integer
            sin = output["sin"].integer
            result = cos + sin * 1j

            # Golden output
            ref = self.model(sync)

            assert result == ref, f"Output mismatch: result = {result}, ref = {ref}"


@cocotb.test()
async def test_nco_basic(dut):
    """
    Perform some basic test of NCO.
    """

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10).start(start_high=False))

    # Reset DUT
    dut.rst.value = 1
    dut.sync.value = 0
    dut.ctrl_pinc.value = 0
    dut.ctrl_poff.value = 0
    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0

    dut.sync.value = 1
    await RisingEdge(dut.clk)
    dut.sync.value = 0
    await ClockCycles(dut.clk, 3)
    assert dut.cos.value == 2 ** (DATA_WIDTH - 1) - 2
    assert dut.sin.value == 0


@cocotb.test()
async def test_nco_advanced(dut):
    """
    Test NCO instance against with MATLAB model.
    """

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10).start(start_high=False))

    # Create tester
    nco_tester = NcoTester(dut=dut)
    nco_tester._eng.set(nco_tester._model, 'PhaseIncrement', 400000, nargout=0)
    nco_tester._eng.set(nco_tester._model, 'PhaseOffset', 100000, nargout=0)

    # Reset DUT
    dut.rst.value = 1
    dut.sync.value = 0
    dut.ctrl_pinc.value = 400000
    dut.ctrl_poff.value = 100000
    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0

    nco_tester.start()

    await ClockCycles(dut.clk, 100)
