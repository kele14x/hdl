import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


@cocotb.test()
async def test_symbol_timer(dut):
    """
    Test the symbol_timer module.
    """
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 2, units="ns").start())

    # Reset the DUT
    dut.rst.value = 1
    dut.ctrl_numerology.value = 0
    dut.ctrl_extended_cp.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    # Run test multiple times
    await RisingEdge(dut.clk)
    dut.radio_frame_start_10ms_in.value = 1
    await RisingEdge(dut.clk)
    dut.radio_frame_start_10ms_in.value = 0

    await ClockCycles(dut.clk, 4915200*2)
    dut._log.info("Simulation finished")
