import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ClockCycles

@cocotb.test()
async def fft_test(dut):
    """Test FFT design."""

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())

    # Reset interface
    dut.rst.value = 1
    dut.data_i_in.value = 0
    dut.data_q_in.value = 0
    dut.data_valid_in.value = 0
    dut.data_last_in.value = 0

    # Reset core
    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0

    FFT_SIZE = dut.FFT_SIZE.value
    INPUT_DATA_WIDTH = dut.INPUT_DATA_WIDTH.value

    xin = np.cos(2*np.pi*np.arange(0, FFT_SIZE)/FFT_SIZE*1)
    xin = xin * (2 ** (INPUT_DATA_WIDTH - 1) - 1)
    xin = np.round(xin)

    await ClockCycles(dut.clk, 10)
    for i in range(0, FFT_SIZE):
        await RisingEdge(dut.clk)
        dut.data_i_in.value = int(np.real(xin[i]))
        dut.data_q_in.value = int(np.imag(xin[i]))
        dut.data_valid_in.value = 1
        if i == FFT_SIZE - 1:
            dut.data_last_in.value = 1
        else:
            dut.data_last_in.value = 0

    await RisingEdge(dut.clk)
    dut.data_i_in.value = 0
    dut.data_q_in.value = 0
    dut.data_valid_in.value = 0
    dut.data_last_in.value = 0

    await ClockCycles(dut.clk, 10000)
