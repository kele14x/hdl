"""Bit-exact tests for the PRACH write-side BFP9 compressor."""

from __future__ import annotations

import os
import random
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools import bfp

PRJ_PATH = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

NUM_ANT = 4
NUM_PRB = 72
SECTION_RE = NUM_PRB * 12
MASK36 = (1 << 36) - 1


def _prb_words(iq, fs_offset):
    packed = bfp.compress_prb(iq, fs_offset=fs_offset)
    mantissas = int.from_bytes(packed[1:], byteorder="big")
    words = [(mantissas >> (36 * (5 - index))) & MASK36 for index in range(6)]
    return packed[0], words


def _make_section(seed):
    rng = random.Random(seed)
    directed = [
        [0] * 24,
        [1] * 24,
        [-1] * 24,
        [-32768] * 24,
        [32767] * 24,
        [-32768, 32767] * 12,
    ]
    random_prbs = [
        [rng.randint(-32768, 32767) for _ in range(24)]
        for _ in range(NUM_PRB - len(directed))
    ]
    iq = [sample for prb in directed + random_prbs for sample in prb]
    return [(iq[index], iq[index + 1]) for index in range(0, len(iq), 2)]


async def _reset(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_dv.value = 0
    dut.din_sy.value = 0
    dut.din_chn.value = 0
    dut.ctrl_fs_offset.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 2)


async def _monitor_sections(dut, queue):
    writes = []
    exponents = []
    while True:
        await RisingEdge(dut.clk)
        wr_we = int(dut.wr_we.value)
        if wr_we:
            writes.append((wr_we, int(dut.wr_addr.value), int(dut.wr_data.value)))
        exp_we = int(dut.exp_we.value)
        if exp_we:
            exponents.append(
                (exp_we, int(dut.exp_addr.value), int(dut.exp_wdata.value))
            )
        section_done = int(dut.section_done.value)
        if section_done:
            await queue.put((section_done, writes, exponents))
            writes = []
            exponents = []


async def _drive_section(dut, re_values, fs_offset, ant):
    assert len(re_values) == SECTION_RE
    dut.ctrl_fs_offset.value = fs_offset
    dut.din_chn.value = ant

    for index, (real, imag) in enumerate(re_values):
        await RisingEdge(dut.clk)
        dut.din_dr.value = real & 0xFFFF
        dut.din_di.value = imag & 0xFFFF
        dut.din_dv.value = 1
        dut.din_sy.value = int(index == 0)

    await RisingEdge(dut.clk)
    dut.din_dv.value = 0
    dut.din_sy.value = 0


@cocotb.test()
async def test_prach_bfp_compress(dut):
    await _reset(dut)
    section_queue = Queue()
    cocotb.start_soon(_monitor_sections(dut, section_queue))

    for section_index, fs_offset in enumerate((0, 8, 15)):
        ant = (0, 1, 3)[section_index]
        re_values = _make_section(0xBFF9 + section_index)
        await _drive_section(dut, re_values, fs_offset, ant)
        section_done, writes, exponents = await section_queue.get()

        iq = [sample for re_value in re_values for sample in re_value]
        expected_words = []
        expected_exponents = []
        for prb in range(NUM_PRB):
            exp, words = _prb_words(iq[24 * prb : 24 * (prb + 1)], fs_offset)
            expected_words.extend(words)
            expected_exponents.append(exp)

        assert section_done == 1 << ant
        assert [write_enable for write_enable, _, _ in writes] == [1 << ant] * 432
        assert [address for _, address, _ in writes] == list(range(432))
        assert [data for _, _, data in writes] == expected_words
        assert [write_enable for write_enable, _, _ in exponents] == [1 << ant] * 72
        assert [address for _, address, _ in exponents] == list(range(72))
        assert [data for _, _, data in exponents] == expected_exponents

        await ClockCycles(dut.clk, 4)


def test_prach_bfp_compress_runner():
    run_dir = PRJ_PATH / "sim_build" / "prach_bfp_compress"
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="prach_bfp_compress",
        sources=[PRJ_PATH / "rtl" / "prach_bfp_compress.sv"],
        parameters={"NUM_ANT": NUM_ANT},
        build_args=["-suppress", "2892"] if SIM == "questa" else [],
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="prach_bfp_compress",
        hdl_toplevel_lang="verilog",
        test_module="test_prach_bfp_compress",
        test_args=["-suppress", "7061"] if SIM == "questa" else [],
        waves=True,
        gui=os.environ.get("GUI", "false").lower() == "true",
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
