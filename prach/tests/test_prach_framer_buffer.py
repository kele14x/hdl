"""Integrated compressed-storage test for the PRACH framer buffer."""

from __future__ import annotations

import os
import random
import sys
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

PRJ_PATH = Path(__file__).resolve().parent.parent
REPO_PATH = PRJ_PATH.parent
sys.path.insert(0, str(REPO_PATH / "common" / "tests"))

import libbfp

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

NUM_ANT = 4
FFT_RE = 1536
CAPTURE_RE = 864
CC_ID = 2
ANT_ID = 5


def _make_fft_section(seed):
    rng = random.Random(seed)
    captured = [
        (rng.randint(-32768, 32767), rng.randint(-32768, 32767))
        for _ in range(CAPTURE_RE)
    ]
    ignored = [
        (0x1234 if index & 1 else -0x2345, -0x3456 if index & 1 else 0x4567)
        for index in range(FFT_RE - CAPTURE_RE)
    ]
    return captured + ignored


async def _reset(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_sf.value = 0
    dut.din_sl.value = 0
    dut.din_sy.value = 0
    dut.din_chn.value = 0
    dut.din_dv.value = 0
    dut.din_last.value = 0
    dut.rd_section_id.value = 0
    dut.ctrl_fs_offset.value = 0
    await ClockCycles(dut.clk, 6)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 4)


async def _monitor_packets(dut, queue):
    packet = []
    keeps = []
    users = []
    words = 0
    while True:
        await RisingEdge(dut.clk)
        if int(dut.m_axis_tvalid.value):
            words += 1
            data = int(dut.m_axis_tdata.value)
            keep = int(dut.m_axis_tkeep.value)
            keeps.append(keep)
            users.append(int(dut.m_axis_tuser.value))
            packet.extend(
                (data >> (8 * byte_index)) & 0xFF
                for byte_index in range(8)
                if keep & (1 << byte_index)
            )
            if int(dut.m_axis_tlast.value):
                await queue.put((packet, keeps, users, words))
                packet = []
                keeps = []
                users = []
                words = 0


async def _monitor_launches(dut, queue):
    cycle = 0
    section_done_cycle = None
    while True:
        await RisingEdge(dut.clk)
        cycle += 1
        if int(dut.section_done.value):
            section_done_cycle = cycle
        if int(dut.gearbox_start.value):
            await queue.put((section_done_cycle, cycle))
            section_done_cycle = None


async def _drive_fft_section(dut, re_values, ant, section_id, fs_offset):
    dut.din_chn.value = ant
    dut.rd_section_id.value = section_id
    dut.ctrl_fs_offset.value = fs_offset

    for index, (real, imag) in enumerate(re_values):
        dut.din_dr.value = real & 0xFFFF
        dut.din_di.value = imag & 0xFFFF
        dut.din_dv.value = 1
        dut.din_sy.value = int(index == 0)
        dut.din_last.value = int(index == FFT_RE - 1)
        await RisingEdge(dut.clk)

    dut.din_dv.value = 0
    dut.din_sy.value = 0
    dut.din_last.value = 0


@cocotb.test()
async def test_prach_framer_buffer(dut):
    await _reset(dut)
    packet_queue = Queue()
    launch_queue = Queue()
    cocotb.start_soon(_monitor_packets(dut, packet_queue))
    cocotb.start_soon(_monitor_launches(dut, launch_queue))

    cases = [(0, 0x321, 0), (2, 0x654, 15)]
    for case_index, (ant, section_id, fs_offset) in enumerate(cases):
        re_values = _make_fft_section(0x8640 + case_index)
        await _drive_fft_section(dut, re_values, ant, section_id, fs_offset)

        packet, keeps, users, words = await packet_queue.get()
        section_done_cycle, launch_cycle = await launch_queue.get()
        captured_iq = [
            sample for re_value in re_values[:CAPTURE_RE] for sample in re_value
        ]
        expected = libbfp.compress_section(captured_iq, fs_offset=fs_offset)
        expected_tuser = (CC_ID << 20) | (ANT_ID << 12) | section_id

        assert packet == expected
        assert words == 252
        assert keeps == [0xFF] * 252
        assert users == [expected_tuser] * 252
        assert section_done_cycle is not None
        assert launch_cycle > section_done_cycle

        await ClockCycles(dut.clk, 4)


def test_prach_framer_buffer_runner():
    run_dir = PRJ_PATH / "sim_build" / "prach_framer_buffer"
    sources = [
        REPO_PATH / "cdc" / "rtl" / "cdc_array_single.sv",
        REPO_PATH / "ram" / "rtl" / "ram_sdp.sv",
        PRJ_PATH / "rtl" / "prach_bfp_compress.sv",
        PRJ_PATH / "rtl" / "prach_bfp_gearbox.sv",
        PRJ_PATH / "rtl" / "prach_framer_buffer.sv",
    ]
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="prach_framer_buffer",
        sources=sources,
        parameters={"CC_ID": CC_ID, "ANT_ID": ANT_ID, "NUM_ANT": NUM_ANT},
        build_args=["-suppress", "2892"] if SIM == "questa" else [],
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="prach_framer_buffer",
        hdl_toplevel_lang="verilog",
        test_module="test_prach_framer_buffer",
        test_args=["-suppress", "7061"] if SIM == "questa" else [],
        waves=True,
        gui=os.environ.get("GUI", "false").lower() == "true",
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
