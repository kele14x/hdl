"""Cross-PRB byte-stream tests for the PRACH BFP9 gearbox."""

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

CASES = [1, 2, 3, 71, 72]
MASK36 = (1 << 36) - 1


def _make_memories(num_prb, seed):
    rng = random.Random(seed)
    iq = [rng.randint(-32768, 32767) for _ in range(num_prb * 24)]
    data_words = []
    exponents = []
    for prb in range(num_prb):
        packed = bfp.compress_prb(iq[24 * prb : 24 * (prb + 1)])
        exponents.append(packed[0])
        mantissas = int.from_bytes(packed[1:], byteorder="big")
        data_words.extend(
            (mantissas >> (36 * (5 - index))) & MASK36 for index in range(6)
        )
    return iq, data_words, exponents


async def _reset(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.start.value = 0
    dut.num_prb.value = 0
    dut.start_tuser.value = 0
    dut.data_rd_data.value = 0
    dut.exp_rd_data.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 2)


async def _monitor_packets(dut, queue):
    packet = []
    keeps = []
    users = []
    while True:
        await RisingEdge(dut.clk)
        if int(dut.m_axis_tvalid.value):
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
                await queue.put((packet, keeps, users))
                packet = []
                keeps = []
                users = []


async def _run_packet(dut, num_prb, data_words, exponents, tuser):
    dut.num_prb.value = num_prb
    dut.start_tuser.value = tuser
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0

    # The first request is captured on the next edge. Both ram_sdp instances
    # then return D0/exp0 after their second enabled read stage.
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.data_rd_data.value = data_words[0]
    dut.exp_rd_data.value = exponents[0]

    for index in range(len(data_words)):
        await RisingEdge(dut.clk)
        if index + 1 < len(data_words):
            next_index = index + 1
            dut.data_rd_data.value = data_words[next_index]
            dut.exp_rd_data.value = exponents[next_index // 6]


@cocotb.test()
async def test_prach_bfp_gearbox(dut):
    await _reset(dut)
    packet_queue = Queue()
    cocotb.start_soon(_monitor_packets(dut, packet_queue))

    for case_index, num_prb in enumerate(CASES):
        iq, data_words, exponents = _make_memories(num_prb, 0x600D + case_index)
        tuser = 0x5A000000 | num_prb
        await _run_packet(dut, num_prb, data_words, exponents, tuser)
        packet, keeps, users = await packet_queue.get()
        expected = bfp.compress_section(iq)

        assert packet == expected
        assert len(keeps) == (num_prb * 28 + 7) // 8
        assert keeps[-1] == (0x0F if num_prb % 2 else 0xFF)
        assert all(keep == 0xFF for keep in keeps[:-1])
        assert users == [tuser] * len(keeps)
        assert not int(dut.busy.value)

        await ClockCycles(dut.clk, 3)


def test_prach_bfp_gearbox_runner():
    run_dir = PRJ_PATH / "sim_build" / "prach_bfp_gearbox"
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="prach_bfp_gearbox",
        sources=[PRJ_PATH / "rtl" / "prach_bfp_gearbox.sv"],
        parameters={"USER_WIDTH": 32},
        build_args=["-suppress", "2892"] if SIM == "questa" else [],
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="prach_bfp_gearbox",
        hdl_toplevel_lang="verilog",
        test_module="test_prach_bfp_gearbox",
        test_args=["-suppress", "7061"] if SIM == "questa" else [],
        waves=True,
        gui=os.environ.get("GUI", "false").lower() == "true",
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
