import os
import random
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools import bfp
from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

UD_COMP_METH = int(os.environ.get("UD_COMP_METH", "0"))
UD_IQ_WIDTH = int(os.environ.get("UD_IQ_WIDTH", "9"))
FS_OFFSET = int(os.environ.get("FS_OFFSET", "0"))
USER_WIDTH = int(os.environ.get("USER_WIDTH", "17"))
CONTINUOUS_INPUT = os.environ.get("CONTINUOUS_INPUT", "false").lower() == "true"


GUI = os.environ.get("GUI", "false").lower() == "true"
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

input_queue = Queue()
output_queue = Queue()


def generate_section(num_prb):
    section = [np.random.randint(-(2**15), 2**15) for _ in range(num_prb * 24)]
    return section


def signed(value, width):
    value &= (1 << width) - 1
    return value - (1 << width) if value & (1 << (width - 1)) else value


def msb_position(value):
    value &= 0xFFFF
    for index in range(15, 0, -1):
        if ((value >> index) ^ (value >> (index - 1))) & 1:
            return index
    return 0


def internal_bfp9(real, imag):
    shift = min(15 - max(msb_position(real), msb_position(imag)), 7)
    exponent = 15 - shift

    def compress(value):
        rounded = ((value & 0xFFFF) << shift) & 0xFFFF
        rounded |= 0x003F
        if rounded != 0x7FFF:
            rounded = (rounded + 1) & 0xFFFF
        return (rounded >> 7) & 0x1FF

    return compress(real), compress(imag), exponent


def pack_internal_pair(values):
    i0, q0, exp0 = internal_bfp9(values[0], values[1])
    i1, q1, exp1 = internal_bfp9(values[2], values[3])
    return i0 | (q0 << 9) | (i1 << 18) | (q1 << 27) | (exp0 << 36) | (exp1 << 40)


async def reset(dut):
    dut.rst.value = 1

    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tuser.value = 0

    dut.ctrl_ud_comp_meth.value = UD_COMP_METH
    dut.ctrl_ud_iq_width.value = UD_IQ_WIDTH
    dut.ctrl_fs_offset.value = FS_OFFSET

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def drive(dut):
    await RisingEdge(dut.clk)
    for _ in range(100):
        num_prb = random.randint(1, 100)
        section = generate_section(num_prb)
        num_words = len(section) // 4
        tuser = random.randrange(1 << USER_WIDTH)
        # Send one section. CONTINUOUS_INPUT exposes the no-backpressure
        # requirement by removing every bubble and inter-packet gap.
        i = 0
        while i < num_words:
            insert_null = not CONTINUOUS_INPUT and random.randint(1, 100) > 75
            if insert_null:
                dut.s_axis_tvalid.value = 0
            else:
                data = pack_internal_pair(section[i * 4 : i * 4 + 4])
                dut.s_axis_tdata.value = data
                dut.s_axis_tkeep.value = 255
                dut.s_axis_tvalid.value = 1
                dut.s_axis_tlast.value = 1 if i == num_words - 1 else 0
                dut.s_axis_tuser.value = tuser
                i = i + 1
            await RisingEdge(dut.clk)
        dut.s_axis_tvalid.value = 0
        if not CONTINUOUS_INPUT:
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)


async def input_monitor(dut):
    await RisingEdge(dut.clk)
    input = []
    tuser = 0
    while True:
        if dut.s_axis_tvalid.value:
            if not input:
                tuser = dut.s_axis_tuser.value.integer
            data = dut.s_axis_tdata.value.integer
            exp0 = (data >> 36) & 0xF
            exp1 = (data >> 40) & 0xF
            input.extend(
                [
                    signed(data, 9) << (exp0 - 8),
                    signed(data >> 9, 9) << (exp0 - 8),
                    signed(data >> 18, 9) << (exp1 - 8),
                    signed(data >> 27, 9) << (exp1 - 8),
                ]
            )
            if dut.s_axis_tlast.value:
                input_queue.put_nowait((input, tuser))
                input = []
        await RisingEdge(dut.clk)


async def output_monitor(dut):
    await RisingEdge(dut.clk)
    output = []
    tuser = 0
    while True:
        if dut.m_axis_tvalid.value:
            if not output:
                tuser = dut.m_axis_tuser.value.integer
            data = dut.m_axis_tdata.value.integer
            for i in range(8):
                if (dut.m_axis_tkeep.value.integer >> i) & 0x1:
                    output.append((data >> (8 * i)) & 0xFF)
            if dut.m_axis_tlast.value:
                output_queue.put_nowait((output, tuser))
                output = []
        await RisingEdge(dut.clk)


async def checker():
    n = 0
    while True:
        input, input_tuser = await input_queue.get()
        output, output_tuser = await output_queue.get()
        output_ref = bfp.compress_section(input, fs_offset=FS_OFFSET)

        n += 1
        cocotb.log.info(f"Processing packet #{n}")

        assert output_tuser == input_tuser, (
            f"TUSER mismatch, output: 0x{output_tuser:x}, input: 0x{input_tuser:x}"
        )

        assert len(output) == len(output_ref), (
            f"Result length not correct, output: {len(output)}, reference: {len(output_ref)}"
        )

        assert output == output_ref, (
            "Result mismatch!\n"
            f"input: {input}\n\n"
            f"output: {output}\n\n"
            f"output_ref: {output_ref}\n"
        )


@cocotb.test()
async def test_bfp_comp_top(dut):
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


def test_bfp_comp_runner():
    hdl_toplevel = "bfp_comp"
    hdl_toplevel_lang = "verilog"

    sources = resolve_flt(prj_path / "bfp_comp.flt")

    parameters = {"USER_WIDTH": USER_WIDTH}

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        sources=sources,
        parameters=parameters,
        build_args=["-suppress", "2892"] if SIM == "questa" else [],
        waves=True,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_bfp_comp",
        test_args=["-suppress", "7061"] if SIM == "questa" else [],
        waves=True,
        gui=False,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
