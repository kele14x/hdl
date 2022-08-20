from cmath import exp
import cocotb
import matplotlib.pyplot as plt
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


@cocotb.test(skip=cocotb.top.HAS_PHASE_GEN.value)
async def test_dds_lut(dut):
    """Test DDS loop-up table content."""
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())

    # Reset DUT
    dut.rst.value = 1
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    PHASE_WIDTH = dut.PHASE_WIDTH.value
    DATA_WIDTH = dut.DATA_WIDTH.value

    for i in range(2 ** PHASE_WIDTH):
        await RisingEdge(dut.clk)
        dut.phase_in.value = i
        await ClockCycles(dut.clk, 5)

        result = dut.cos_out.value.signed_integer
        expected = np.round(np.cos(2 * np.pi * i / 2 ** PHASE_WIDTH) * 2 ** (DATA_WIDTH - 1))
        assert np.abs(result - expected) <= 1


@cocotb.test()
async def dds_test(dut):
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())

    # Reset DUT
    dut.rst.value = 1
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    for _ in range(100):
        await RisingEdge(dut.clk)
