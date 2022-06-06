import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock

@cocotb.test()
async def lsft_rst_test(dut):
    """Test reset of LFSR."""

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    #
    dut._log.info(f"Parameters:")
    dut._log.info(f"BIT_WIDTH       : {dut.BIT_WIDTH.value}")
    dut._log.info(f"INITIAL         : {dut.INITIAL.value}")
    dut._log.info(f"POLYNOMIAL      : {dut.POLYNOMIAL.value}")
    dut._log.info(f"STRUCTURE       : {dut.STRUCTURE.value}")
    dut._log.info(f"GATE_TYPE       : {dut.GATE_TYPE.value}")
    dut._log.info(f"PARALLEL_OUTPUT : {dut.PARALLEL_OUTPUT.value}")

    # Initial values
    dut.en.value = 1
    dut.load.value = 0
    dut.din.value = 0

    # Reset DUT
    dut.rst.value = 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst.value = 0

    await RisingEdge(dut.clk)
    dut._log.debug(f"{dut.dout.value}")
    assert dut.dout.value == dut.INITIAL, "dout is not proper reset"

    for _ in range(0, 2 ** dut.BIT_WIDTH.value - 1):
        await RisingEdge(dut.clk)
        dut._log.info(f"{dut.dout.value}")

    await RisingEdge(dut.clk)

