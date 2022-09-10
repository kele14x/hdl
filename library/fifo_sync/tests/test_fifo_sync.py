import random
from typing import Tuple

import cocotb
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.triggers import ClockCycles, RisingEdge

FIFO_DEPTH = cocotb.top.FIFO_DEPTH.value
FIFO_LATENCY = cocotb.top.FIFO_LATENCY.value
DATA_WIDTH = cocotb.top.DATA_WIDTH.value
FWFT_MODE = cocotb.top.FWFT_MODE.value


@cocotb.test()
async def test_fifo_basic(dut):
    """
    Perform some basic test of the fifo module.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    dut.rst.value = 1
    dut.wren.value = 0
    dut.din.value = 0
    dut.rden.value = 0
    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    # Send a few values to the DUT
    for i in range(0, 100):
        await RisingEdge(dut.clk)
        dut.wren.value = 1
        dut.din.value = i+100
    await RisingEdge(dut.clk)
    dut.wren.value = 0
    dut.din.value = 0

    # Read the result back from the DUT
    for i in range(0, 100):
        await RisingEdge(dut.clk)
        dut.rden.value = 1
    await RisingEdge(dut.clk)
    dut.rden.value = 0

    await ClockCycles(dut.clk, 10)
    dut._log.info("Simulation finished")
