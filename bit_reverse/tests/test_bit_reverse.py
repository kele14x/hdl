#!/usr/bin/env python3
import os
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"

# Build parameters arrive via extra_env because the runner and the
# simulator are separate Python processes.
NUM_INLV = int(os.environ.get("NUM_INLV", "4"))
LOG_FFT_SIZE = int(os.environ.get("LOG_FFT_SIZE", "11"))
DATA_WIDTH = int(os.environ.get("DATA_WIDTH", "16"))

NUM_TESTS = 4

CASES = [
    ("inlv4_fft11", {"NUM_INLV": 4, "LOG_FFT_SIZE": 11, "DATA_WIDTH": 16}),
    # Stage delays straddle the 128-tap delay/shift_ram threshold
    ("inlv1_fft10", {"NUM_INLV": 1, "LOG_FFT_SIZE": 10, "DATA_WIDTH": 16}),
    ("inlv2_fft6_dw8", {"NUM_INLV": 2, "LOG_FFT_SIZE": 6, "DATA_WIDTH": 8}),
    # Small FFT sizes use only the register based delay
    ("inlv1_fft4_delay", {"NUM_INLV": 1, "LOG_FFT_SIZE": 4, "DATA_WIDTH": 16}),
    ("inlv1_fft2_delay", {"NUM_INLV": 1, "LOG_FFT_SIZE": 2, "DATA_WIDTH": 16}),
]


def bitrevorder(x):
    """Bit-reverse order the input data."""
    if len(x) < 2:
        return x
    return np.concatenate([bitrevorder(x[0::2]), bitrevorder(x[1::2])])


async def reset(dut):
    dut.rst.value = 1
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_id.value = 0
    dut.din_valid.value = 0
    dut.din_last.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut, packets):
    """Drive packets of (dr, di) sample arrays with inter-packet gaps."""
    rng = np.random.default_rng(987654321)
    for dr, di in packets:
        for i in range(len(dr)):
            for lane in range(NUM_INLV):
                dut.din_dr.value = int(dr[i])
                dut.din_di.value = int(di[i])
                dut.din_id.value = lane
                dut.din_valid.value = 1
                dut.din_last.value = int(i == len(dr) - 1)
                await RisingEdge(dut.clk)
            dut.din_valid.value = 0
        for _ in range(int(rng.integers(1, 10))):
            for lane in range(NUM_INLV):
                dut.din_id.value = lane
                await RisingEdge(dut.clk)
    dut.din_valid.value = 0


async def sample_monitor(dut, valid, last, dr, di, lane_id, queue):
    """Reconstruct packets from lane 0; every lane carries the same data."""
    size = 2**LOG_FFT_SIZE
    data = np.zeros(size, dtype=np.complex64)
    index = 0
    while True:
        await RisingEdge(dut.clk)
        if int(valid.value) and int(lane_id.value) == 0:
            data[index] = dr.value.signed_integer + 1j * di.value.signed_integer
            index += 1
            if int(last.value):
                queue.put_nowait(data)
                data = np.zeros(size, dtype=np.complex64)
                index = 0


@cocotb.test()
async def test_bit_reverse(dut):
    """Every packet must emerge in bit-reversed sample order."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)

    rng = np.random.default_rng(1234567890)
    size = 2**LOG_FFT_SIZE
    low = -(2 ** (DATA_WIDTH - 1))
    high = 2 ** (DATA_WIDTH - 1)
    packets = []
    for _ in range(NUM_TESTS):
        dr = rng.integers(low, high, size=size)
        di = rng.integers(low, high, size=size)
        packets.append((dr, di))

    input_queue = Queue()
    output_queue = Queue()
    cocotb.start_soon(
        sample_monitor(
            dut,
            dut.din_valid,
            dut.din_last,
            dut.din_dr,
            dut.din_di,
            dut.din_id,
            input_queue,
        )
    )
    cocotb.start_soon(
        sample_monitor(
            dut,
            dut.dout_valid,
            dut.dout_last,
            dut.dout_dr,
            dut.dout_di,
            dut.dout_id,
            output_queue,
        )
    )

    driver = cocotb.start_soon(drive(dut, packets))
    await with_timeout(driver, 10 * NUM_TESTS * size * (NUM_INLV + 10), "ns")

    # Pipeline latency is bounded by the total delay line depth, which is
    # below one packet period, so a few packet periods cover the drain.
    timeout_ns = 10 * (NUM_TESTS + 3) * size * NUM_INLV
    for index in range(NUM_TESTS):
        input_data = await with_timeout(input_queue.get(), timeout_ns, "ns")
        output_data = await with_timeout(output_queue.get(), timeout_ns, "ns")
        cocotb.log.info("Packet %d / %d", index + 1, NUM_TESTS)
        ref_data = bitrevorder(input_data)
        assert (output_data == ref_data).all(), (
            "Bit-reverse mismatch\n"
            f"Input: {input_data}\n"
            f"Output: {output_data}\n"
            f"Reference output: {ref_data}"
        )


@pytest.mark.parametrize("case_name,params", CASES, ids=[name for name, _ in CASES])
def test_bit_reverse_runner(case_name, params):
    """Build and run one parameter corner per case."""
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="bit_reverse",
        sources=resolve_flt(prj_path / "bit_reverse.flt"),
        parameters=params,
        build_dir=str(prj_path / "sim_build" / case_name),
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="bit_reverse",
        hdl_toplevel_lang="verilog",
        test_module="test_bit_reverse",
        build_dir=str(prj_path / "sim_build" / case_name),
        extra_env={key: str(value) for key, value in params.items()},
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
