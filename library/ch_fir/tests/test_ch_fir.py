import random
from typing import Dict, Tuple

import cocotb
import matlab.engine
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge, ClockCycles


CSR_SUPPORT = cocotb.top.CSR_SUPPORT.value
NUM_STAGES = cocotb.top.NUM_STAGES.value
DATA_WIDTH = cocotb.top.DATA_WIDTH.value
COE_DATA_WIDTH = cocotb.top.COE_DATA_WIDTH.value
SRA_BITS = cocotb.top.SRA_BITS.value


@cocotb.test()
async def test_ch_fir_basic(dut):
    """
    Perform some basic test of the ch_fir module.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 2).start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 10).start())

    # Reset the DUT
    dut.rst.value = 1
    dut.ctrl_rst.value = 1
    dut.data_in.value = 0
    dut.ctrl_coe_en.value = 0
    dut.ctrl_coe_we.value = 0
    dut.ctrl_coe_addr.value = 0
    dut.ctrl_coe_data_in.value = 0
    await ClockCycles(dut.ctrl_clk, 100)
    # assert dut.data_out.value == 0, "data_out port should be reset to 0"
    # assert dut.ctrl_coe_data_out.value == 0, "ctrl_coe_data_out port should be reset to 0"
    dut.rst.value = 0
    dut.ctrl_rst.value = 0
    await ClockCycles(dut.ctrl_clk, 10)

    # Configure coefficients
    for i in range(NUM_STAGES):
        await RisingEdge(dut.ctrl_clk)
        dut.ctrl_coe_en.value = 1
        dut.ctrl_coe_we.value = 1
        dut.ctrl_coe_addr.value = i
        dut.ctrl_coe_data_in.value = 100+i*2

    # Coefficient read back
    for i in range(NUM_STAGES):
        await RisingEdge(dut.ctrl_clk)
        dut.ctrl_coe_en.value = 1
        dut.ctrl_coe_we.value = 0
        dut.ctrl_coe_addr.value = i
        dut.ctrl_coe_data_in.value = 0
        await RisingEdge(dut.ctrl_clk)
        await RisingEdge(dut.ctrl_clk)
        assert dut.ctrl_coe_data_out.value == 100+i*2, "coe_data_out should be 100+i*2"

    await RisingEdge(dut.ctrl_clk)
    dut.ctrl_coe_en.value = 0
    dut.ctrl_coe_we.value = 0
    dut.ctrl_coe_addr.value = 0
    dut.ctrl_coe_data_in.value = 0

    # Test impulse response
    await RisingEdge(dut.clk)
    dut.data_in.value = 16384
    await RisingEdge(dut.clk)
    dut.data_in.value = 0

    # Wait for the simulation to finish
    await ClockCycles(dut.clk, 1000)
    dut._log.info("Simulation finished")
