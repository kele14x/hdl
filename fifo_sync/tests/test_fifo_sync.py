import random
import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge

prj_path = Path(__file__).resolve().parent.parent


FIFO_DEPTH = int(os.getenv("FIFO_DEPTH", 16))
FIFO_LATENCY = int(os.getenv("FIFO_LATENCY", 3))
DATA_WIDTH = int(os.getenv("DATA_WIDTH", 16))

GUI = os.getenv("GUI", "False").lower() == "true"
SIM = os.environ.get("SIM", "verilator")

input_queue = Queue()
output_queue = Queue()


async def reset(dut):
    # Reset the DUT
    dut.rst.value = 1

    dut.wren.value = 0
    dut.din.value = 0
    dut.rden.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    for _ in range(10000):
        await RisingEdge(dut.clk)
        dut.wren.value = random.randint(0, 1)
        dut.din.value = random.randint(0, 2**DATA_WIDTH - 1)
        dut.rden.value = random.randint(0, 1)


async def input_monitor(dut):
    while True:
        await RisingEdge(dut.clk)
        if dut.wren.value and not dut.full.value:
            input_queue.put_nowait(dut.din.value.integer)


async def output_monitor(dut):
    while True:
        await RisingEdge(dut.clk)
        if dut.rden.value and not dut.empty.value:
            output_queue.put_nowait(dut.dout.value.integer)


async def checker():
    n = 0
    while True:
        input = await input_queue.get()
        output = await output_queue.get()
        n += 1

        assert input == output, (
            f"Result mismatch! input = {hex(input)}, "
            f"output = {hex(output)}"
        )


@cocotb.test()
async def test_fifo_sync(dut):
    dut._log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    await reset(dut)

    cocotb.start_soon(input_monitor(dut))
    cocotb.start_soon(output_monitor(dut))
    cocotb.start_soon(checker())

    # Run test driver
    await drive(dut)

    await ClockCycles(dut.clk, 10)
    dut._log.info("Simulation finished")


def test_fifo_sync_runner():
    hdl_toplevel = "fifo_sync"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "../ram/rtl/ram_sdp.v",
        prj_path / "rtl/fifo_sync.v",
    ]

    parameters = {
        "FIFO_DEPTH": FIFO_DEPTH,
        "FIFO_LATENCY": FIFO_LATENCY,
        "DATA_WIDTH": DATA_WIDTH,
    }

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_fifo_sync",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
