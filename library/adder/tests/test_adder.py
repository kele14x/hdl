from inspect import Parameter
from cocotb_test.simulator import run
import pytest
import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

tests_dir = os.path.dirname(__file__)


@cocotb.test()
async def test_adder(dut):
    """
    Test the adder module.
    """
    # Create a new clock domain and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    dut.add_sub.value = 0
    await ClockCycles(dut.clk, 10)
    assert dut.p.value == 0, "P output should be reset to 0"
    assert dut.ovf.value == 0, "OVF output should be reset to 0"
    dut.rst = 0

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


@pytest.mark.parametrize(
    "parameters", [{"A_WIDTH": 8, "B_WIDTH": 8, "P_WIDTH": 8}]
)
def test_adder_testcase(parameters):
    run(
        verilog_sources=[os.path.join(tests_dir, "../rtl/adder.v")],
        toplevel="adder",
        module="test_adder",
        parameter=parameters,
        waves=True,
        sim_build="sim_build/"
        + "_".join(("{}={}".format(*i) for i in parameters.items())),
    )
