import os
from pathlib import Path

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng()

FIFO_DEPTH = int(os.getenv("FIFO_DEPTH", 16))
FIFO_LATENCY = int(os.getenv("FIFO_LATENCY", 3))
DATA_WIDTH = int(os.getenv("DATA_WIDTH", 8))

GUI = os.getenv("GUI", "False").lower() == "true"


input_queue = Queue()
output_queue = Queue()


async def reset(dut):
    """Reset the DUT"""
    dut.rst.value = 1

    dut.wr_en.value = 0
    dut.wr_din.value = 0
    dut.rd_en.value = 0

    await ClockCycles(dut.wr_clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.wr_clk, 10)


async def input_driver(dut):
    """Drive the write interface of FIFO"""
    await RisingEdge(dut.wr_clk)
    while True:
        await RisingEdge(dut.wr_clk)
        dut.wr_en.value = int(rng.choice([0, 1], p=[0.5, 0.5]))
        dut.wr_din.value = int(rng.integers(0, 2**DATA_WIDTH))


async def output_driver(dut):
    """Drive the read interface of FIFO"""
    await RisingEdge(dut.rd_clk)
    while True:
        await RisingEdge(dut.rd_clk)
        dut.rd_en.value = int(rng.choice([0, 1], p=[0.5, 0.5]))


async def input_monitor(dut):
    """Monitor the write interface of FIFO"""
    while True:
        await RisingEdge(dut.wr_clk)
        if dut.wr_en.value and not dut.wr_full.value:
            input_queue.put_nowait(dut.wr_din.value.integer)


async def output_monitor(dut):
    """Monitor the read interface of FIFO"""
    while True:
        await RisingEdge(dut.rd_clk)
        if dut.rd_en.value and not dut.rd_empty.value:
            output_queue.put_nowait(dut.rd_dout.value.integer)


async def checker():
    """Check the result of FIFO"""
    n = 0
    while True:
        input_data = await input_queue.get()
        output_data = await output_queue.get()
        n += 1

        assert input_data == output_data, (
            f"Result mismatch!\n" f"input = {hex(input_data)}\n" f"output = {hex(output_data)}"
        )


@cocotb.test
async def test_fifo_async(dut):
    """Test case for the FIFO"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.wr_clk, 10).start())
    cocotb.start_soon(Clock(dut.rd_clk, 10).start())

    # Reset the DUT
    await reset(dut)

    cocotb.start_soon(input_driver(dut))
    cocotb.start_soon(output_driver(dut))
    cocotb.start_soon(input_monitor(dut))
    cocotb.start_soon(output_monitor(dut))
    cocotb.start_soon(checker())

    # Run test driver
    await ClockCycles(dut.wr_clk, 10000)
    cocotb.log.info("Simulation finished")


def test_fifo_async_runner():
    """Run the test for FIFO"""
    sim = "questa"

    hdl_toplevel = "fifo_async"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "../cdc/rtl/cdc_async_rst.v",
        prj_path / "../cdc/rtl/cdc_gray.v",
        prj_path / "../ram/rtl/ram_sdp.v",
        prj_path / "rtl/fifo_async.v",
    ]

    test_args = [
        f"-gFIFO_DEPTH={FIFO_DEPTH}",
        f"-gFIFO_LATENCY={FIFO_LATENCY}",
        f"-gDATA_WIDTH={DATA_WIDTH}",
    ]

    runner = get_runner(sim)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_args=test_args,
        test_module="test_fifo_async",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    test_fifo_async_runner()
