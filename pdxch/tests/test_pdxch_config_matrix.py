#!/usr/bin/env python3
"""Top-level PDXCH reference checks across block/FFT configurations."""

from __future__ import annotations

import os

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Combine, RisingEdge, Timer, with_timeout
from pdxch_reference import (
    best_body_alignment,
    pdxch_lte20_reference,
    pdxch_nr_reference,
    qpsk_bfp9_resource_elements,
)
from pdxch_test_utils import pdxch_sources, run_test
from test_pdxch import _axis_sources, _signed16

from hdl_tools.axis import AxisBeat, AxisFrame

NUM_ANT = 4
CASES = [
    {
        "name": "nr100_full_block_full_fft",
        "rat": 2,
        "bw": 4,
        "num_prb": 273,
        "fft_size": 4096,
        "cycles_per_sample": 4,
        "half_block": 0,
        "half_fft": 0,
    },
    {
        "name": "nr50_half_block_full_fft",
        "rat": 2,
        "bw": 3,
        "num_prb": 133,
        "fft_size": 2048,
        "cycles_per_sample": 8,
        "half_block": 1,
        "half_fft": 0,
    },
    {
        "name": "nr20_full_block_half_fft",
        "rat": 2,
        "bw": 2,
        "num_prb": 51,
        "fft_size": 1024,
        "cycles_per_sample": 16,
        "half_block": 0,
        "half_fft": 1,
    },
    {
        "name": "lte20_half_block_half_fft",
        "rat": 0,
        "bw": 2,
        "num_prb": 100,
        "fft_size": 2048,
        "cycles_per_sample": 16,
        "half_block": 1,
        "half_fft": 1,
    },
]


def _case_from_environment():
    return {
        "name": os.environ.get("PDXCH_CASE_NAME", CASES[0]["name"]),
        "rat": int(os.environ.get("PDXCH_RAT", CASES[0]["rat"])),
        "bw": int(os.environ.get("PDXCH_BW", CASES[0]["bw"])),
        "num_prb": int(os.environ.get("PDXCH_NUM_PRB", CASES[0]["num_prb"])),
        "fft_size": int(os.environ.get("PDXCH_FFT_SIZE", CASES[0]["fft_size"])),
        "cycles_per_sample": int(
            os.environ.get("PDXCH_CYCLES_PER_SAMPLE", CASES[0]["cycles_per_sample"])
        ),
    }


def _make_bfp9_frame(case, antenna: int) -> AxisFrame:
    decompressed = qpsk_bfp9_resource_elements(
        num_prb=case["num_prb"],
        cc=0,
        antenna=antenna,
        symbol=0,
    )
    mantissas = (
        np.column_stack((decompressed.real, decompressed.imag)).astype(np.int16) // 128
    )
    stream_bits = []
    for prb in range(case["num_prb"]):
        stream_bits.append("00001111")
        for real, imag in mantissas[prb * 12 : (prb + 1) * 12]:
            stream_bits.append(f"{int(real) & 0x1FF:09b}")
            stream_bits.append(f"{int(imag) & 0x1FF:09b}")
    bit_string = "".join(stream_bits)
    payload = [
        int(bit_string[index : index + 8], 2) for index in range(0, len(bit_string), 8)
    ]
    beats = []
    for offset in range(0, len(payload), 8):
        chunk = payload[offset : offset + 8]
        beats.append(
            AxisBeat(
                data=sum(byte << (8 * lane) for lane, byte in enumerate(chunk)),
                keep=(1 << len(chunk)) - 1,
                user=0,
                dest=0,
                last=offset + len(chunk) == len(payload),
            )
        )
    return AxisFrame(beats)


async def _capture_symbol(dut, case):
    for _ in range(100000):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        users = []
        words = []
        for antenna in range(NUM_ANT):
            user = dut.m_axis_tuser[0][antenna].value
            word = dut.m_axis_tdata[0][antenna].value
            users.append(int(user) if user.is_resolvable else 0)
            words.append(int(word) if word.is_resolvable else 0)
        if any(user & 1 for user in users) or any(words):
            samples = [
                [complex(_signed16(word & 0xFFFF), _signed16(word >> 16))]
                for word in words
            ]
            break
    else:
        raise AssertionError("radio output did not start")

    for _ in range(case["fft_size"] - 1):
        await ClockCycles(dut.clk, case["cycles_per_sample"])
        await Timer(1, unit="ps")
        for antenna in range(NUM_ANT):
            word_value = dut.m_axis_tdata[0][antenna].value
            word = int(word_value) if word_value.is_resolvable else 0
            samples[antenna].append(
                complex(_signed16(word & 0xFFFF), _signed16(word >> 16))
            )
    return [np.asarray(stream, dtype=np.complex128) for stream in samples]


async def _pulse_sync(dut):
    await RisingEdge(dut.clk_eth_xran)
    dut.sync_in.value = 1
    await RisingEdge(dut.clk_eth_xran)
    dut.sync_in.value = 0


@cocotb.test()
async def test_configured_chain_matches_reference(dut):
    case = _case_from_environment()
    cocotb.start_soon(Clock(dut.ctrl_clk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())

    dut.rst.value = 1
    dut.rst_eth_xran.value = 1
    dut.ctrl_rst.value = 1
    dut.sync_in.value = 0
    dut.s_dl_sym_num[0].value = 0
    dut.ctrl_ud_comp_meth.value = 1
    dut.ctrl_ud_iq_width.value = 9
    dut.ctrl_fs_offset.value = 0
    dut.ctrl_en[0].value = 0xF
    dut.ctrl_rat[0].value = case["rat"]
    dut.ctrl_bist[0].value = 0
    dut.ctrl_bw[0].value = case["bw"]
    dut.ctrl_nprb[0].value = case["num_prb"]
    dut.ctrl_rfs_offset[0].value = 0
    dut.ctrl_phase_comp_addr.value = 0
    dut.ctrl_phase_comp_en.value = 0
    dut.ctrl_phase_comp_we.value = 0
    dut.ctrl_phase_comp_din.value = 0x4000
    for antenna in range(NUM_ANT):
        dut.ctrl_gain[0][antenna].value = 0x4000
        dut.m_axis_tready[0][antenna].value = 1

    sources = _axis_sources(dut)
    for source in sources:
        source.idle()
    await ClockCycles(dut.clk_eth_xran, 8)
    dut.rst.value = 0
    dut.rst_eth_xran.value = 0
    dut.ctrl_rst.value = 0

    if case["rat"] != 0:
        for address in range(16):
            await RisingEdge(dut.ctrl_clk)
            dut.ctrl_phase_comp_addr.value = address
            dut.ctrl_phase_comp_we.value = 1
        await RisingEdge(dut.ctrl_clk)
        dut.ctrl_phase_comp_we.value = 0

    await ClockCycles(dut.clk, 32)
    sends = [
        cocotb.start_soon(source.send(_make_bfp9_frame(case, antenna), gap=1))
        for antenna, source in enumerate(sources)
    ]
    await Combine(*sends)

    capture = cocotb.start_soon(_capture_symbol(dut, case))
    await _pulse_sync(dut)
    actual_streams = await with_timeout(capture, 250, timeout_unit="us")

    for antenna, actual in enumerate(actual_streams):
        if case["rat"] == 0:
            reference = pdxch_lte20_reference(
                cc=0,
                antenna=antenna,
                symbol=0,
                num_prb=case["num_prb"],
            )
        else:
            reference = pdxch_nr_reference(
                cc=0,
                antenna=antenna,
                symbol=0,
                num_prb=case["num_prb"],
                fft_size=case["fft_size"],
            )
        offset, error = best_body_alignment(
            actual,
            reference.fixed_time_domain,
            max_offset=8,
        )
        rms_error = float(np.sqrt(np.mean(np.abs(error) ** 2)))
        assert offset == 0
        assert rms_error == 0, (
            f"{case['name']} antenna {antenna}: fixed RMS error={rms_error:.3f}"
        )

        recovered = np.fft.fft(actual) / 64
        assert np.count_nonzero(np.abs(recovered) > 1024) == case["num_prb"] * 12
        if case["rat"] == 0:
            assert abs(recovered[0]) < 2


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_pdxch_config_matrix_runner(case, monkeypatch):
    monkeypatch.setenv("PDXCH_CASE_NAME", case["name"])
    monkeypatch.setenv("PDXCH_RAT", str(case["rat"]))
    monkeypatch.setenv("PDXCH_BW", str(case["bw"]))
    monkeypatch.setenv("PDXCH_NUM_PRB", str(case["num_prb"]))
    monkeypatch.setenv("PDXCH_FFT_SIZE", str(case["fft_size"]))
    monkeypatch.setenv("PDXCH_CYCLES_PER_SAMPLE", str(case["cycles_per_sample"]))
    run_test(
        hdl_toplevel="pdxch_top",
        test_module="test_pdxch_config_matrix",
        sources=pdxch_sources("pdxch.flt"),
        parameters={
            "NUM_CC": 1,
            "NUM_ANT": NUM_ANT,
            "HALF_BLOCK": case["half_block"],
            "HALF_FFT": case["half_fft"],
        },
        build_name=case["name"],
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
