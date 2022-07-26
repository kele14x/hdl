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


class MultTester:
    """Checker of a mult instance."""

    def __init__(self, dut: SimHandleBase):
        self.dut = dut
        self._checker = None

        self.input_mon = DataMonitor(
            clk=self.dut.clk,
            signals={
                "a": self.dut.a,
                "b": self.dut.b,
            },
        )

        self.output_mon = DataMonitor(
            clk=self.dut.clk,
            signals={
                "p": self.dut.p,
                "ovf": self.dut.ovf,
            },
            delay=self.dut.Latency.value,
        )

        # Start MATLAB session
        self._eng = matlab.engine.start_matlab("-sd ~/Workspaces/dfe")
        self._eng.setpath(nargout=0)

        # Create MATLAB reference System object
        self._model = self._eng.dfe.Mult(
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

    def model(self, a: float, b: float) -> Tuple[float, bool]:
        """Return the model result of the multiplier."""
        (p, ovf) = self._eng.step(self._model, a, b, nargout=2)
        return (p, ovf)

    async def _check(self) -> None:
        """Checker function."""
        while True:
            input = await self.input_mon.values.get()
            output = await self.output_mon.values.get()
            a = float(input["a"].signed_integer)
            b = float(input["b"].signed_integer)

            p = output["p"].signed_integer
            ovf = output["ovf"].value

            (p_ref, ovf_ref) = self.model(a, b)

            assert p == p_ref, "Output mismatch"
            assert ovf == ovf_ref, "Overflow mismatch"


@cocotb.test()
async def test_mult_basic(dut):
    """
    Perform some basic test of the mult module.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    await ClockCycles(dut.clk, 5)
    assert dut.p.value == 0, "p output should be reset to 0"
    assert dut.ovf.value == 0, "ovf output should be reset to 0"
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    # Send a few values to the DUT
    await RisingEdge(dut.clk)
    dut.a.value = 16384
    dut.b.value = 16384

    # Read the result back from the DUT
    await ClockCycles(dut.clk, dut.Latency.value + 2)
    result = dut.p.value.integer
    expect = 8192
    assert result == expect, f"Result is should be {expect}"

    # Wait for the simulation to finish
    await ClockCycles(dut.clk, 10)
    dut._log.info("Simulation finished")


@cocotb.test()
async def test_mult_advanced(dut):
    """
    Test the cmult module against a MATLAB golden model.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Create a tester
    tester = MultTester(dut)

    # Reset the DUT
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    tester.start()

    # Run test multiple times
    for _ in range(1000):
        await RisingEdge(dut.clk)
        a = random.randint(-2**(A_WIDTH-1), 2**(A_WIDTH-1)-1)
        b = random.randint(-2**(B_WIDTH-1), 2**(B_WIDTH-1)-1)
        dut.a.value = a
        dut.b.value = b

    await ClockCycles(dut.clk, 10)
    dut._log.info("Simulation finished")
