import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.queue import Queue

FIFO_DEPTH = cocotb.top.FIFO_DEPTH.value
DATA_WIDTH = cocotb.top.DATA_WIDTH.value


async def input_monitor(dut, queue):
    while True:
        await RisingEdge(dut.clk)
        if dut.wren.value == 1 and dut.full.value == 0:
            queue.put_nowait(dut.din.value)


async def output_monitor(dut, queue):
    while True:
        await RisingEdge(dut.clk)
        if dut.rden.value == 1 and dut.empty.value == 0:
            queue.put_nowait(dut.dout.value)


async def scoreboard(dut):
    input_queue = Queue()
    output_queue = Queue()
    cocotb.start_soon(input_monitor(dut, input_queue))
    cocotb.start_soon(output_monitor(dut, output_queue))
    while True:
        din = await input_queue.get()
        dout = await output_queue.get()
        assert din == dout, f"{din.hex()} != {dout.hex()}"


async def input_driver(dut):
    """
    Write some data to fifo, randomly
    """
    while True:
        await RisingEdge(dut.clk)
        dut.wren.value = random.randint(0, 1)
        dut.din.value = random.randint(0, 2**DATA_WIDTH-1)


async def output_driver(dut):
    """
    Read some data form fifo, randomly
    """
    while True:
        await RisingEdge(dut.clk)
        dut.rden.value = random.randint(0, 1)


async def test(dut):
    cocotb.start_soon(input_driver(dut))
    cocotb.start_soon(output_driver(dut))
    cocotb.start_soon(scoreboard(dut))


@cocotb.test()
async def test_fifo_srl(dut):
    """
    Perform some test of the fifo_srl module.
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

    cocotb.start_soon(test(dut))

    # Wait for the simulation to finish
    await ClockCycles(dut.clk, 100)
    dut._log.info("Simulation finished")
