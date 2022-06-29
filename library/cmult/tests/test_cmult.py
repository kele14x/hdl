import random
from typing import Dict, Tuple

import cocotb
import matlab.engine
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge, ClockCycles


A_WIDTH = cocotb.top.A_WIDTH.value
B_WIDTH = cocotb.top.B_WIDTH.value
P_WIDTH = cocotb.top.P_WIDTH.value
SRA_BITS = cocotb.top.SRA_BITS.value


class DataMonitor:
    """
    Simple monitor to read data from a signal.
    """

    def __init__(self, clk: SimHandleBase, signals: Dict[str, SimHandleBase], delay: int = 0):
        self.values = Queue[Dict[str, int]]()
        self._clk = clk
        self._signals = signals
        self._delay = delay
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
        await ClockCycles(self._clk, self._delay)
        while True:
            await RisingEdge(self._clk)
            self.values.put_nowait(self._sample())

    def _sample(self) -> Dict[str, int]:
        return {name: sig.value for name, sig in self._signals.items()}


class CmultTester:
    """Checker of a cmult instance."""

    def __init__(self, dut: SimHandleBase):
        self.dut = dut
        self._checker = None

        self.input_mon = DataMonitor(
            clk=self.dut.clk,
            signals={
                "ar": self.dut.ar,
                "ai": self.dut.ai,
                "br": self.dut.br,
                "bi": self.dut.bi,
            },
        )

        self.output_mon = DataMonitor(
            clk=self.dut.clk,
            signals={
                "pr": self.dut.pr,
                "pi": self.dut.pi,
                "ovf": self.dut.ovf,
            },
            delay=self.dut.Latency.value,
        )

        # Start MATLAB session
        self._eng = matlab.engine.start_matlab("-sd ~/Workspaces/dfe")
        self._eng.setpath(nargout=0)

        # Create MATLAB reference System object
        self._model = self._eng.dfe.CMult(
            'AWidth', float(A_WIDTH),
            'BWidth', float(B_WIDTH),
            'PWidth', float(P_WIDTH),
            'SraBits', float(SRA_BITS)
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

    def model(self, a: complex, b: complex) -> Tuple[complex, bool]:
        """Return the model result of the adder."""
        (p, ovf) = self._eng.step(self._model, a, b, nargout=2)
        return (p, ovf)

    async def _check(self) -> None:
        """Checker function."""
        while True:
            input = await self.input_mon.values.get()
            output = await self.output_mon.values.get()
            ar = input["ar"].signed_integer
            ai = input["ai"].signed_integer
            A = ar + 1j * ai
            br = input["br"].signed_integer
            bi = input["bi"].signed_integer
            B = br + 1j * bi

            pr = output["pr"].signed_integer
            pi = output["pi"].signed_integer
            ovf = output["ovf"].value

            P = pr + 1j * pi
            (p_ref, ovf_ref) = self.model(A, B)

            assert P == p_ref, "Output mismatch"
            assert ovf == ovf_ref, "Overflow mismatch"


@cocotb.test()
async def test_cmult_basic(dut):
    """
    Perform some basic test of the cmult module.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    dut.rst.value = 1
    dut.ar.value = 0
    dut.ai.value = 0
    dut.br.value = 0
    dut.bi.value = 0
    await ClockCycles(dut.clk, 11)
    assert dut.pr.value == 0, "P output should be reset to 0"
    assert dut.pi.value == 0, "P output should be reset to 0"
    assert dut.ovf.value == 0, "OVF output should be reset to 0"
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    # Send a few values to the DUT
    await RisingEdge(dut.clk)
    dut.ar.value = 16384
    dut.ai.value = 16384
    dut.br.value = 16384
    dut.bi.value = 16384

    # Read the result back from the DUT
    await ClockCycles(dut.clk, dut.Latency.value + 2)
    result = dut.pr.value.integer + 1j * dut.pi.value.integer
    expect = 0 + 16384j
    assert result == expect, f"Result is should be {expect}"

    # Wait for the simulation to finish
    await ClockCycles(dut.clk, 10)
    dut._log.info("Simulation finished")


@cocotb.test()
async def test_cmult_advanced(dut):
    """
    Test the cmult module against a MATLAB golden model.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Create a tester
    tester = CmultTester(dut)

    # Reset the DUT
    dut.rst.value = 1
    dut.ar.value = 0
    dut.ai.value = 0
    dut.br.value = 0
    dut.bi.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    tester.start()

    # Run test multiple times
    for _ in range(1000):
        await RisingEdge(dut.clk)
        ar = random.randint(-2**(A_WIDTH-1), 2**(A_WIDTH-1)-1)
        ai = random.randint(-2**(A_WIDTH-1), 2**(A_WIDTH-1)-1)
        br = random.randint(-2**(B_WIDTH-1), 2**(B_WIDTH-1)-1)
        bi = random.randint(-2**(B_WIDTH-1), 2**(B_WIDTH-1)-1)
        dut.ar.value = ar
        dut.ai.value = ai
        dut.br.value = br
        dut.bi.value = bi

    await ClockCycles(dut.clk, 10)
    dut._log.info("Simulation finished")
