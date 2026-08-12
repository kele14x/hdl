"""Unit tests for FDV address generation, decompression and BIST readout."""

from __future__ import annotations

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from pdxch_test_utils import PRJ_PATH, pdxch_sources, run_test

NUM_ANT = 2
HALF_BLOCK = 1
IQ_REAL = 1
IQ_IMAG = 2
IQ_WORD = (IQ_REAL << 27) | (IQ_IMAG << 18) | (IQ_REAL << 9) | IQ_IMAG
EXPONENT = 15


def _set_common_inputs(dut):
    dut.start_of_frame.value = 0
    dut.start_of_slot.value = 0
    dut.start_of_symbol.value = 0
    dut.ctrl_en.value = 0
    dut.ctrl_rat.value = 2
    dut.ctrl_bist.value = 0
    dut.ctrl_bw.value = 4
    dut.ctrl_nprb.value = 1
    dut.ctrl_fs_offset.value = 0
    for ant in range(NUM_ANT):
        dut.rd_iq_data[ant].value = IQ_WORD
        dut.rd_exp_data[ant].value = EXPONENT


def _set_controls(dut, *, bist):
    dut.ctrl_en.value = 1
    dut.ctrl_bist.value = bist


def _signed16(value: int) -> int:
    return value - 0x10000 if value & 0x8000 else value


def _packed_iq_word(mantissa: int) -> int:
    pair = ((mantissa & 0x1FF) << 9) | (mantissa & 0x1FF)
    return (pair << 18) | pair


async def _reset(dut):
    dut.rst.value = 1
    _set_common_inputs(dut)
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 5)


async def _start_symbol(dut):
    # RAT=2 selects start_of_symbol[1]. The frame pulse makes the first bank
    # deterministic, while the symbol pulse starts the read counter.
    await RisingEdge(dut.clk)
    dut.start_of_frame.value = 1
    dut.start_of_symbol.value = 2
    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")
    dut.start_of_frame.value = 0
    dut.start_of_symbol.value = 0


async def _collect(dut, cycles):
    samples = []
    for _ in range(cycles):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        dv = dut.dout_dv.value
        if dv.is_resolvable:
            sample = {
                "dv": int(dv),
                "chn": int(dut.dout_chn.value),
                "dr": _signed16(int(dut.dout_dr.value)),
                "di": _signed16(int(dut.dout_di.value)),
                "rd_en": [
                    int(dut.rd_en[ant].value)
                    for ant in range(NUM_ANT)
                    if dut.rd_en[ant].value.is_resolvable
                ],
                "iq_addr": int(dut.rd_iq_addr[0].value),
                "exp_addr": int(dut.rd_exp_addr[0].value),
            }
            samples.append(sample)
    return samples


@cocotb.test()
async def test_memory_readout_and_bist(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await _reset(dut)

    # With exponent 15 and fs_offset 0, BFP9 values 1 and 2 decode to 128 and
    # 256 respectively. Both packed halves are identical, so this also checks
    # that iq_half selection does not alter the decoded result.
    _set_controls(dut, bist=0)
    await ClockCycles(dut.clk, 4)
    await _start_symbol(dut)
    memory_samples = await _collect(dut, 80)

    valid_memory = [sample for sample in memory_samples if sample["dv"]]
    assert valid_memory
    assert any(sample["dr"] == 128 and sample["di"] == 256 for sample in valid_memory)
    assert any(sample["rd_en"] and sample["rd_en"][0] for sample in memory_samples)

    # Re-arm the same readout with BIST enabled. The BIST path must replace the
    # RAM read for the selected antenna with one of the four +/-4210 corners.
    await _reset(dut)
    _set_controls(dut, bist=1)
    await ClockCycles(dut.clk, 4)
    await _start_symbol(dut)
    bist_samples = await _collect(dut, 80)

    corners = {
        (4210, 4210),
        (-4210, 4210),
        (4210, -4210),
        (-4210, -4210),
    }
    bist_values = {
        (sample["dr"], sample["di"])
        for sample in bist_samples
        if sample["dv"] and sample["chn"] == 0
    }
    assert bist_values & corners

    # NUM_ANT=2 and ctrl_en[1]=0 keep the stream on antenna/channel 0.
    assert all(sample["chn"] == 0 for sample in bist_samples if sample["dv"])


@cocotb.test()
async def test_fs_offset_alignment_and_saturation(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    vectors = [
        (1, 0x080, 14, 0x4000, "normal"),
        (1, 0x0FF, 15, 0x7FFF, "saturation"),
        (8, 0x001, 0, 0x0001, "normal"),
        (8, 0x001, 15, 0x7FFF, "saturation"),
        (14, 0x001, 0, 0x0040, "normal"),
        (14, 0x0FF, 15, 0x7FFF, "saturation"),
        (15, 0x001, 0, 0x0080, "normal"),
        (15, 0x0FF, 15, 0x7FFF, "saturation"),
    ]

    for fs_offset, mantissa, exponent, expected, case_name in vectors:
        await _reset(dut)
        word = _packed_iq_word(mantissa)
        for ant in range(NUM_ANT):
            dut.rd_iq_data[ant].value = word
            dut.rd_exp_data[ant].value = exponent
        dut.ctrl_fs_offset.value = fs_offset
        _set_controls(dut, bist=0)
        await ClockCycles(dut.clk, 4)
        await _start_symbol(dut)

        decoded = []
        for _ in range(80):
            await RisingEdge(dut.clk)
            await Timer(1, unit="ps")
            if dut.dout_dv.value.is_resolvable and int(dut.dout_dv.value):
                assert dut.dout_dr.value.is_resolvable
                assert dut.dout_di.value.is_resolvable
                decoded.append((int(dut.dout_dr.value), int(dut.dout_di.value)))

        assert (expected, expected) in decoded, (
            f"fs_offset={fs_offset} {case_name} vector decoded as {decoded}, "
            f"expected 0x{expected:04x}"
        )


def test_pdxch_fdv_buffer_readout_runner():
    sources = [
        PRJ_PATH / "rtl" / "pdxch_fdv_buffer_map.sv",
        PRJ_PATH / "rtl" / "pdxch_fdv_buffer_readout.sv",
    ]
    sources += pdxch_sources(
        "../common/common.flt",
        "../cdc/cdc.flt",
        "../lfsr/lfsr.flt",
    )
    run_test(
        hdl_toplevel="pdxch_fdv_buffer_readout",
        test_module="test_pdxch_fdv_buffer_readout",
        sources=sources,
        parameters={"NUM_ANT": NUM_ANT, "HALF_BLOCK": HALF_BLOCK},
        build_name="fdv_buffer_readout",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
