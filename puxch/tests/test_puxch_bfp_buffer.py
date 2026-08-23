# ruff: noqa: I001

from __future__ import annotations

import sys
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer, with_timeout

from puxch_test_utils import PRJ_PATH, run_cocotb

sys.path.insert(0, str(PRJ_PATH.parent / "common" / "tests"))
from libbfp import compress_section


NUM_PRB = 2
NUM_RE = NUM_PRB * 12
FFT_ADDR_WIDTH = 5
FFT_SIZE = 1 << FFT_ADDR_WIDTH


def bit_reverse(value: int, width: int) -> int:
    return int(f"{value:0{width}b}"[::-1], 2)


def pack_word(data: list[int], start: int) -> int:
    word = 0
    for lane in range(8):
        if start + lane < len(data):
            word |= int(data[start + lane]) << (8 * lane)
    return word


async def reset_dut(dut):
    dut.rst.value = 1
    dut.rst_eth_xran.value = 1
    dut.m_fram_data_req.value = 0
    dut.ctrl_fs_offset.value = 0
    dut.ctrl_ud_iq_width.value = 9
    dut.s_ul_sym_num[0].value = 1
    dut.ctrl_rat[0].value = 2
    dut.ctrl_bw[0].value = 4
    dut.din_dr[0].value = 0
    dut.din_di[0].value = 0
    dut.din_sf[0].value = 0
    dut.din_sl[0].value = 0
    dut.din_sy[0].value = 0
    dut.din_chn[0].value = 0
    dut.din_dv[0].value = 0
    dut.m_axis_tready.value = 1

    await ClockCycles(dut.clk, 8)
    await ClockCycles(dut.clk_eth_xran, 8)
    dut.rst.value = 0
    dut.rst_eth_xran.value = 0
    await ClockCycles(dut.clk, 4)
    await ClockCycles(dut.clk_eth_xran, 4)


async def write_fft_frame(dut, real: list[int], imag: list[int]):
    # The DUT reverses the write counter, so present physical samples in the
    # order that produces natural RE addresses 0..NUM_RE-1.
    await RisingEdge(dut.clk)

    for physical in range(FFT_SIZE):
        natural = bit_reverse(physical, FFT_ADDR_WIDTH)
        if natural < NUM_RE:
            real_value = real[natural]
            imag_value = imag[natural]
        else:
            real_value = 0
            imag_value = 0

        dut.din_dr[0].value = real_value & 0xFFFF
        dut.din_di[0].value = imag_value & 0xFFFF
        dut.din_dv[0].value = 1
        dut.din_sf[0].value = 0
        dut.din_sy[0].value = int(physical == 0)
        await RisingEdge(dut.clk)

    dut.din_dv[0].value = 0
    dut.din_sf[0].value = 0
    dut.din_sy[0].value = 0
    await ClockCycles(dut.clk, 4)


async def receive_packet(dut) -> list[tuple[int, int, int]]:
    request = (1 << 24) | (NUM_PRB << 7)
    await RisingEdge(dut.clk_eth_xran)
    dut.m_fram_data_req.value = request
    await RisingEdge(dut.clk_eth_xran)
    dut.m_fram_data_req.value = 0
    packet = []
    for _ in range(300):
        await RisingEdge(dut.clk_eth_xran)
        await Timer(1, unit="ps")
        if int(dut.m_axis_tvalid.value):
            packet.append(
                (
                    int(dut.m_axis_tdata.value),
                    int(dut.m_axis_tkeep.value),
                    int(dut.m_axis_tlast.value),
                )
            )
            if packet[-1][2]:
                return packet

    raise AssertionError("timed out waiting for BFP output packet")


@cocotb.test()
async def test_two_pass_bfp_buffer(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 2, unit="ns").start())
    await reset_dut(dut)
    dut.ctrl_fs_offset.value = 2
    await ClockCycles(dut.clk_eth_xran, 4)

    real = [100] * NUM_RE
    imag = [-100] * NUM_RE
    real[0] = 16384
    imag[13] = -16384
    await write_fft_frame(dut, real, imag)
    packet = await with_timeout(receive_packet(dut), 10, timeout_unit="us")

    iq = []
    for re in range(NUM_RE):
        iq.extend((real[re], imag[re]))
    expected_bytes = compress_section(iq, fs_offset=2)
    expected = []
    for start in range(0, len(expected_bytes), 8):
        keep = 0xFF if start + 8 <= len(expected_bytes) else 0x0F
        expected.append(
            (
                pack_word(expected_bytes, start),
                keep,
                int(start + 8 >= len(expected_bytes)),
            )
        )

    assert packet == expected


def test_puxch_bfp_buffer_runner():
    run_cocotb(
        "puxch_bfp_buffer",
        Path(__file__).stem,
        parameters={
            "NUM_CC": 1,
            "FFT_ADDR_WIDTH": FFT_ADDR_WIDTH,
            "ACTIVE_RE_COUNT": NUM_RE,
        },
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
