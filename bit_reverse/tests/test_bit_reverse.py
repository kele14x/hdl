import os
import numpy as np
from pathlib import Path

import pytest
import cocotb
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from hdl_tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, RisingEdge


# MARK: Env

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(1234567890)


NUM_INLV = int(os.environ.get("NUM_INLV", 4))
LOG_FFT_SIZE = int(os.environ.get("LOG_FFT_SIZE", 11))
DATA_WIDTH = int(os.environ.get("DATA_WIDTH", 16))

GUI = os.environ.get("GUI", "false").lower() == "true"

NUM_TESTS = int(os.environ.get("NUM_TESTS", 10))

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")


# MARK: Helper

input_queue = Queue()
output_queue = Queue()


def bitrevorder(x):
    """Bit-reverse order the input data"""
    if len(x) < 2:
        return x
    return np.concatenate([bitrevorder(x[0::2]), bitrevorder(x[1::2])])


async def reset(dut):
    # Reset the DUT
    dut.rst.value = 1

    dut.din_dr.value = 0
    dut.din_di.value = 0
    # dut.din_id.value = 0
    dut.din_valid.value = 0
    dut.din_last.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    """Drive the input data"""
    for _ in range(NUM_TESTS):
        dr = rng.integers(
            -(2 ** (DATA_WIDTH - 1)), 2 ** (DATA_WIDTH - 1), size=2**LOG_FFT_SIZE
        )
        di = rng.integers(
            -(2 ** (DATA_WIDTH - 1)), 2 ** (DATA_WIDTH - 1), size=2**LOG_FFT_SIZE
        )
        for i in range(2**LOG_FFT_SIZE):
            for id in range(NUM_INLV):
                dut.din_dr.value = int(dr[i])
                dut.din_di.value = int(di[i])
                dut.din_id.value = id
                dut.din_valid.value = 1
                dut.din_last.value = 1 if i == 2**LOG_FFT_SIZE - 1 else 0
                await RisingEdge(dut.clk)
            dut.din_valid.value = 0
        # Done for the packet, send some gap cycles
        gap = rng.integers(1, 10)
        for _ in range(gap):
            for id in range(NUM_INLV):
                dut.din_id.value = id
                await RisingEdge(dut.clk)


async def input_monitor(dut):
    """Monitor the input data"""
    input_data = np.zeros(2**LOG_FFT_SIZE, dtype=np.complex64)
    i = 0
    while True:
        await RisingEdge(dut.clk)
        if dut.din_valid.value and dut.din_id.value == 0:
            input_data[i] = (
                dut.din_dr.value.signed_integer + 1j * dut.din_di.value.signed_integer
            )
            i += 1
            if dut.din_last.value:
                input_queue.put_nowait(input_data)
                input_data = np.zeros(2**LOG_FFT_SIZE, dtype=np.complex64)
                i = 0


async def output_monitor(dut):
    """Monitor the output data"""
    output_data = np.zeros(2**LOG_FFT_SIZE, dtype=np.complex64)
    i = 0
    while True:
        await RisingEdge(dut.clk)
        if dut.dout_valid.value and dut.dout_id.value == 0:
            output_data[i] = (
                dut.dout_dr.value.signed_integer + 1j * dut.dout_di.value.signed_integer
            )
            i += 1
            if dut.dout_last.value:
                output_queue.put_nowait(output_data)
                output_data = np.zeros(2**LOG_FFT_SIZE, dtype=np.complex64)
                i = 0


async def checker():
    """Check the output data"""
    n = 0
    while True:
        input_data = await input_queue.get()
        output_data = await output_queue.get()
        n += 1
        cocotb.log.info("# %d / %d", n, NUM_TESTS)

        ref_data = bitrevorder(input_data)
        assert (output_data == ref_data).all(), (
            "Result error too large! \n"
            f"Input: {input_data}, \n"
            f"Output: {output_data}, \n"
            f"Reference output: {ref_data}, \n"
        )


# MARK: Tests


@cocotb.test
async def test_bit_reverse(dut):
    """Test the bit-reverse operation"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    await reset(dut)

    # Start monitor and checker
    cocotb.start_soon(input_monitor(dut))
    cocotb.start_soon(output_monitor(dut))
    cocotb.start_soon(checker())

    # Run test multiple times
    await drive(dut)

    await ClockCycles(dut.clk, 10)
    cocotb.log.info("Simulation finished")


def test_bit_reverse_runner():
    """Run the bit-reverse test"""
    hdl_toplevel = "bit_reverse"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "bit_reverse.flt")

    parameters = {
        "NUM_INLV": NUM_INLV,
        "LOG_FFT_SIZE": LOG_FFT_SIZE,
        "DATA_WIDTH": DATA_WIDTH,
    }

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        build_args=[],
        waves=True,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_bit_reverse",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
