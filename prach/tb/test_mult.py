import cocotb
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotb.clock import Clock


async def reset(dut):
    dut.rst_n.value = 0

    dut.a.value = 0
    dut.b.value = 0

    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_mult(dut):
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset(dut)

    dut.a.value = 100
    dut.b.value = -712

    await ClockCycles(dut.clk, 5)
    assert(dut.p.value.signed_integer == -4)

    await Timer(100, units="ns")
