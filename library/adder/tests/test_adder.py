import random
from typing import Tuple

import cocotb
import matlab.engine
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.triggers import ClockCycles, RisingEdge

A_WIDTH = cocotb.top.A_WIDTH.value
B_WIDTH = cocotb.top.B_WIDTH.value
P_WIDTH = cocotb.top.P_WIDTH.value
SRA_BITS = cocotb.top.SRA_BITS.value


class AdderTester:
    """Checker of a adder instance."""

    def __init__(self, dut: SimHandleBase):
        self.dut = dut
        self._checker = None

        # Start MATLAB session
        self._eng = matlab.engine.start_matlab("-sd ~/Workspaces/dfe")
        self._eng.setpath(nargout=0)

        # Create MATLAB reference System object
        self._model = self._eng.dfe.Adder(
            'ADataWidth', float(A_WIDTH),
            'BDataWidth', float(B_WIDTH),
            'PDataWidth', float(P_WIDTH),
            'SraBits', float(SRA_BITS)
        )

    def start(self) -> None:
        """Start the checker."""
        if self._checker is not None:
            raise RuntimeError("Checker already started")
        self._checker = cocotb.start_soon(self._check())

    def stop(self) -> None:
        """Stop the checker."""
        if self._checker is None:
            raise RuntimeError("Checker not started")
        self._checker.kill()
        self._checker = None

    def model(self, a: int, b: int) -> Tuple[int, int]:
        """Return the model result of the adder."""
        (p, ovf) = self._eng.step(self._model, a, b, nargout=2)
        return (p, ovf)

    async def _check(self) -> None:
        """Checker function."""
        await RisingEdge(self.dut.clk)
        while True:
            A = self.dut.a.value.signed_integer
            B = self.dut.b.value.signed_integer
            await RisingEdge(self.dut.clk)
            P = self.dut.p.value.signed_integer
            ovf = self.dut.ovf.value.integer
            (P_ref, ovf_ref) = self.model(A, B)
            assert P == P_ref, "Test failed: P = %d, P_ref = %d" % (P, P_ref)
            assert ovf == ovf_ref, "Test failed: ovf = %d, ovf_ref = %d" % (ovf, ovf_ref)


@cocotb.test()
async def test_adder_basic(dut):
    """
    Perform some basic test of the adder module.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    dut.add_sub.value = 0
    await ClockCycles(dut.clk, 3)
    assert dut.p.value == 0, "P output should be reset to 0"
    assert dut.ovf.value == 0, "OVF output should be reset to 0"
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    # Send a few values to the DUT
    await RisingEdge(dut.clk)
    dut.a.value = 1
    dut.b.value = 1

    # Read the result back from the DUT
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    result = dut.p.value.integer
    expect = 1 + 1
    assert result == 2, f"Result is should be {expect}"

    # Wait for the simulation to finish
    await ClockCycles(dut.clk, 10)
    dut._log.info("Simulation finished")


@cocotb.test()
async def test_adder_advanced(dut):
    """
    Test the adder module against a MATLAB golden model.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Create a tester
    tester = AdderTester(dut)

    # Reset the DUT
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    dut.add_sub.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    tester.start()

    # Run test multiple times
    for _ in range(1000):
        await RisingEdge(dut.clk)
        A = random.randint(-2**(A_WIDTH-1), 2**(A_WIDTH-1)-1)
        B = random.randint(-2**(B_WIDTH-1), 2**(B_WIDTH-1)-1)
        dut.a.value = A
        dut.b.value = B

    await ClockCycles(dut.clk, 10)
    dut._log.info("Simulation finished")
