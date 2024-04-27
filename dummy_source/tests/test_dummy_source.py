import random
from typing import Dict, Tuple

import cocotb
import matlab.engine
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge, ClockCycles


DATA_WIDTH = cocotb.top.DATA_WIDTH.value


@cocotb.test()
async def test_dummy_source_basic(dut):
    """
    Perform some basic test of the dummy_source module.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 2).start())

    # Reset the DUT
    dut.rst.value = 1
    dut.data_sync_in.value = 0
    dut.ctrl_numerology.value = 0
    dut.ctrl_mask.value = 0
    dut.ctrl_shift.value = 0
    dut.ctrl_scalar.value = 0
    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    dut.data_sync_in.value = 1 << 3
    await RisingEdge(dut.clk)
    dut.data_sync_in.value = 0

    # Wait for the simulation to finish
    await ClockCycles(dut.clk, 2**20)
    dut._log.info("Simulation finished")
