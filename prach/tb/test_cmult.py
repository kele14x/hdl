import cocotb
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotb.clock import Clock


async def reset(dut):
    dut.rst_n.value = 0

    dut.ai.value = 0
    dut.ar.value = 0
    dut.br.value = 0
    dut.bi.value = 0

    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_cmult(dut):
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset(dut)

    dut.ar.value = 100
    dut.ai.value = -100
    dut.br.value = 712
    dut.bi.value = 123

    await ClockCycles(dut.clk, 5)
    assert(dut.pr.value.signed_integer == 5)
    assert(dut.pi.value.signed_integer == -4)

    await Timer(100, units="ns")
