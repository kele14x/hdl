import math
import os
import random
from pathlib import Path
import sys

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge

prj_path = Path(__file__).resolve().parent.parent
repo_path = prj_path.parent
sys.path.insert(0, str(repo_path / "tests"))

import libbfp  # noqa: E402

UD_COMP_METH = int(os.environ.get("UD_COMP_WIDTH", 1))
UD_IQ_WIDTH = int(os.environ.get("UD_IQ_WIDTH", 9))
FS_OFFSET = int(os.environ.get("FS_OFFSET", 0))
SIM = os.environ.get("SIM", "verilator")

input_queue = Queue()
output_queue = Queue()


def generate_section(num_prb):
    iq = [random.randint(-(2**15), 2**15 - 1) for _ in range(num_prb * 24)]
    bytes = libbfp.compress_section(iq, width=UD_IQ_WIDTH, fs_offset=FS_OFFSET)
    return bytes


async def reset(dut):
    dut.rst.value = 1

    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tuser.value = 0
    dut.s_axis_tvalid.value = 0

    dut.ctrl_ud_comp_meth.value = UD_COMP_METH
    dut.ctrl_ud_iq_width.value = UD_IQ_WIDTH
    dut.ctrl_fs_offset.value = FS_OFFSET

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    await RisingEdge(dut.clk)
    for _ in range(0, 100):
        num_prb = random.randint(1, 100)
        bytes = generate_section(num_prb)
        num_bytes = len(bytes)
        num_words = math.ceil(num_bytes / 8)
        # Send one section
        i = 0
        while i < num_words:
            # Insert some null word (pause tick) at stream data
            insert_null = 1 if random.randint(1, 100) > 75 else 0
            if insert_null:
                dut.s_axis_tvalid.value = 0
            else:
                data = 0
                keep = 0
                for j in range(8):
                    if i * 8 + j < num_bytes:
                        data |= (bytes[i * 8 + j] & 0xFF) << 8 * j
                        keep |= 1 << j
                dut.s_axis_tdata.value = data
                dut.s_axis_tkeep.value = keep
                dut.s_axis_tlast.value = 1 if i == num_words - 1 else 0
                dut.s_axis_tuser.value = random.randint(0, 100)
                dut.s_axis_tvalid.value = 0 if insert_null else 1
                i = i + 1
            await RisingEdge(dut.clk)
        dut.s_axis_tvalid.value = 0


async def input_monitor(dut):
    await RisingEdge(dut.clk)
    input = []
    while True:
        if dut.s_axis_tvalid.value:
            data = dut.s_axis_tdata.value.integer
            for i in range(8):
                input.append((data >> (8 * i)) & 0xFF)
            if dut.s_axis_tlast.value:
                input_queue.put_nowait(input)
                input = []
        await RisingEdge(dut.clk)


async def output_monitor(dut):
    await RisingEdge(dut.clk)
    output = []
    while True:
        if dut.m_axis_tvalid.value:
            data = dut.m_axis_tdata.value.integer
            for i in range(8):
                d = (((data >> (16 * i)) & 0xFF) << 8) | ((data >> (16 * i + 8)) & 0xFF)
                d = d if d <= 2**15 - 1 else d - 2**16
                output.append(d)
            if dut.m_axis_tlast.value:
                output_queue.put_nowait(output)
                output = []
        await RisingEdge(dut.clk)


async def checker():
    while True:
        input = await input_queue.get()
        output = await output_queue.get()
        output_ref = libbfp.decompress_section(
            input, width=UD_IQ_WIDTH, fs_offset=FS_OFFSET
        )
        assert output == output_ref, (
            f"Result mismatch! input: {input} output: {output} output_ref: {output_ref}"
        )


@cocotb.test()
async def test_bfp_decomp_top(dut):
    # Generate clocks
    cocotb.start_soon(Clock(dut.clk, period=10, units="ns").start())
    # Reset DUT
    await reset(dut)

    # Start monitor and checker
    cocotb.start_soon(input_monitor(dut))
    cocotb.start_soon(output_monitor(dut))
    cocotb.start_soon(checker())

    # Test driver
    await drive(dut)

    # finish
    await ClockCycles(dut.clk, 100)


def test_bfp_decomp_runner():
    hdl_toplevel = "bfp_decomp"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "../cdc/rtl/cdc_array_single.sv",
        prj_path / "../common/rtl/delay.v",
        prj_path / "../util/rtl/srl.sv",
        prj_path / "rtl/bfp_decomp.sv",
    ]

    parameters = {}

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        build_args=["-suppress", "2892"] if SIM == "questa" else [],
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_bfp_decomp",
        test_args=["-suppress", "7061"] if SIM == "questa" else [],
        waves=True,
        gui=False,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
