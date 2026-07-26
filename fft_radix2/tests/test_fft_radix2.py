import os
import random
from pathlib import Path
from typing import List

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM", "verilator")

LOG_FFT_SIZE = int(os.environ.get("LOG_FFT_SIZE", 10))
INPUT_DATA_WIDTH = int(os.environ.get("INPUT_DATA_WIDTH", 16))
PHASE_WIDTH = int(os.environ.get("PHASE_WIDTH", 16))
OUTPUT_DATA_WIDTH = int(os.environ.get("OUTPUT_DATA_WIDTH", 18))
BIT_REVERSED_INPUT = int(os.environ.get("BIT_REVERSED_INPUT", 1))


def model(x: List[complex]) -> List[complex]:
    """
    Run the model with the given input and return the output.
    """
    y = np.fft.fft(x)
    return y


async def checker(input_queue: Queue, output_queue: Queue) -> None:
    while True:
        x = await input_queue.get()
        y = await output_queue.get()
        y_ref = model(x)
        assert y == y_ref, "Output mismatch"


async def reset_dut(dut: SimHandleBase):
    # Reset core
    dut.rst.value = 1
    dut.data_i_in.value = 0
    dut.data_q_in.value = 0
    dut.data_valid_in.value = 0
    dut.data_last_in.value = 0

    # Wait Reset done
    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0


async def driver(dut: SimHandleBase):
    for _ in range(0, 10):
        data = [0] * 2**LOG_FFT_SIZE
        for i in range(0, len(data)):
            dr = random.randint(
                -(2 ** (INPUT_DATA_WIDTH - 1)), 2 ** (INPUT_DATA_WIDTH - 1) - 1
            )
            di = random.randint(
                -(2 ** (INPUT_DATA_WIDTH - 1)), 2 ** (INPUT_DATA_WIDTH - 1) - 1
            )
            data[i] = dr + 1j * di
        for i in range(0, len(data)):
            dut.data_i_in.value = int(data[i].real)
            dut.data_q_in.value = int(data[i].imag)
            dut.data_valid_in.value = 1
            if i == len(data) - 1:
                dut.data_last_in.value = 1
            else:
                dut.data_last_in.value = 0
            await RisingEdge(dut.clk)
    dut.data_i_in.value = 0
    dut.data_q_in.value = 0
    dut.data_valid_in.value = 0
    dut.data_last_in.value = 0


async def input_monitor(dut: SimHandleBase, queue: Queue):
    data = []
    while True:
        await RisingEdge(dut.clk)
        if not dut.data_valid_in.value:
            continue
        dr = dut.data_i_in.value.signed_integer
        di = dut.data_q_in.value.signed_integer
        data.append(dr + 1j * di)
        if dut.data_last_in.value:
            queue.put(data)
            data = []


async def output_monitor(dut: SimHandleBase, queue: Queue):
    data = []
    while True:
        await RisingEdge(dut.clk)
        if not dut.data_valid_out.value:
            continue
        dr = dut.data_i_out.value.signed_integer
        di = dut.data_q_out.value.signed_integer
        data.append(dr + 1j * di)
        if dut.data_last_out.value:
            queue.put(data)
            data = []


@cocotb.test()
async def test_fft_radix2(dut: SimHandleBase):
    input_queue = Queue()
    output_queue = Queue()

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset DUT
    await reset_dut(dut)

    cocotb.start_soon(input_monitor(dut, input_queue))
    cocotb.start_soon(output_monitor(dut, output_queue))
    cocotb.start_soon(checker(input_queue, output_queue))

    await cocotb.start_soon(driver(dut))
    await Timer(10000, units="ns")


def test_fft_radix2_runner():
    hdl_toplevel = "fft_radix2"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "fft_radix2.flt")

    parameters = {
        "LOG_FFT_SIZE": LOG_FFT_SIZE,
        "INPUT_DATA_WIDTH": INPUT_DATA_WIDTH,
        "PHASE_WIDTH": PHASE_WIDTH,
        "OUTPUT_DATA_WIDTH": OUTPUT_DATA_WIDTH,
        "BIT_REVERSED_INPUT": BIT_REVERSED_INPUT,
    }

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        always=True,
        waves=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_fft_radix2",
        waves=True,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
