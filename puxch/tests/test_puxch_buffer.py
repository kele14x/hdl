import os
import random
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from puxch_test_utils import run_cocotb, sample_after_rising

NUM_CC = 2
BUFFER_ID = 2
FFT_SAMPLES = 1024
HALF_BLOCK = int(os.environ.get("HALF_BLOCK", "0"))


def _msb_position(value):
    value &= 0xFFFF
    for index in range(15, 0, -1):
        if ((value >> index) ^ (value >> (index - 1))) & 1:
            return index
    return 0


def _internal_bfp9(real, imag):
    msb = max(_msb_position(real), _msb_position(imag))
    shift = min(15 - msb, 7)
    exponent = 15 - shift

    def compress_component(value):
        rounded = ((value & 0xFFFF) << shift) & 0xFFFF
        rounded |= 0x003F
        if rounded != 0x7FFF:
            rounded = (rounded + 1) & 0xFFFF
        return (rounded >> 7) & 0x1FF

    return compress_component(real), compress_component(imag), exponent


def _packed_bfp9_word(real, imag):
    real_m, imag_m, exponent = _internal_bfp9(real, imag)
    iq = real_m | (imag_m << 9) | (real_m << 18) | (imag_m << 27)
    exponents = exponent | (exponent << 4)
    return iq | (exponents << 36)


def expected_word():
    return _packed_bfp9_word(0x1234, 0xABCD)


async def reset_dut(dut):
    dut.rst.value = 1
    dut.rst_eth_xran.value = 1
    dut.m_axis_tready.value = 0
    dut.m_fram_data_req.value = 0
    for cc in range(NUM_CC):
        dut.din_dr[cc].value = 0
        dut.din_di[cc].value = 0
        dut.din_sf[cc].value = 0
        dut.din_sl[cc].value = 0
        dut.din_sy[cc].value = 0
        dut.din_chn[cc].value = 0
        dut.din_dv[cc].value = 0
        dut.s_ul_sym_num[cc].value = 0
        dut.ctrl_rat[cc].value = 2
        dut.ctrl_bw[cc].value = 0
    await ClockCycles(dut.clk, 8)
    dut.rst.value = 0
    await ClockCycles(dut.clk_eth_xran, 8)
    dut.rst_eth_xran.value = 0
    await ClockCycles(dut.clk, 5)


async def fill_cc1_bank_zero(dut):
    await sample_after_rising(dut.clk)
    dut.din_sf[1].value = 1
    dut.din_sy[1].value = 1
    await sample_after_rising(dut.clk)
    dut.din_sf[1].value = 0
    dut.din_sy[1].value = 0

    for _ in range(FFT_SAMPLES):
        await sample_after_rising(dut.clk)
        dut.din_dr[1].value = 0x1234
        dut.din_di[1].value = 0xABCD
        dut.din_chn[1].value = BUFFER_ID
        dut.din_dv[1].value = 1

    await sample_after_rising(dut.clk)
    dut.din_dv[1].value = 0
    await sample_after_rising(dut.clk)


async def fill_cc1_symbol(dut, *, first_symbol, real, imag, samples):
    await sample_after_rising(dut.clk)
    dut.din_sf[1].value = int(first_symbol)
    dut.din_sy[1].value = 1
    dut.din_chn[1].value = 0
    await sample_after_rising(dut.clk)
    dut.din_sf[1].value = 0
    dut.din_sy[1].value = 0

    for _ in range(samples):
        await sample_after_rising(dut.clk)
        dut.din_dr[1].value = real
        dut.din_di[1].value = imag
        dut.din_chn[1].value = BUFFER_ID
        dut.din_dv[1].value = 1

    await sample_after_rising(dut.clk)
    dut.din_dv[1].value = 0
    await sample_after_rising(dut.clk)


async def request_words(dut, *, start_prb, num_prb, cc=1):
    await sample_after_rising(dut.clk_eth_xran)
    dut.m_fram_data_req.value = (1 << 24) | (start_prb << 15) | (num_prb << 7) | cc
    await sample_after_rising(dut.clk_eth_xran)
    dut.m_fram_data_req.value = 0

    words = []
    for _ in range(256):
        await sample_after_rising(dut.clk_eth_xran)
        if int(dut.m_axis_tvalid.value):
            words.append(
                (
                    int(dut.m_axis_tdata.value),
                    int(dut.m_axis_tkeep.value),
                    int(dut.m_axis_tlast.value),
                )
            )
        if words and words[-1][2]:
            break
    return words


@cocotb.test()
async def test_buffer_read_request_data_and_backpressure(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 3, unit="ns").start())
    await reset_dut(dut)
    await fill_cc1_bank_zero(dut)

    await sample_after_rising(dut.clk_eth_xran)
    dut.m_fram_data_req.value = (1 << 24) | (1 << 7) | 1
    await sample_after_rising(dut.clk_eth_xran)
    dut.m_fram_data_req.value = 0

    held = None
    for _ in range(64):
        await sample_after_rising(dut.clk_eth_xran)
        if int(dut.m_axis_tvalid.value):
            held = (
                int(dut.m_axis_tdata.value),
                int(dut.m_axis_tkeep.value),
                int(dut.m_axis_tlast.value),
            )
            break
    assert held is not None
    assert held == (expected_word(), 0xFF, 0)

    for _ in range(4):
        await sample_after_rising(dut.clk_eth_xran)
        assert int(dut.m_axis_tvalid.value) == 1
        assert (
            int(dut.m_axis_tdata.value),
            int(dut.m_axis_tkeep.value),
            int(dut.m_axis_tlast.value),
        ) == held

    words = [held]
    dut.m_axis_tready.value = 1
    for _ in range(64):
        await sample_after_rising(dut.clk_eth_xran)
        if int(dut.m_axis_tvalid.value):
            word = (
                int(dut.m_axis_tdata.value),
                int(dut.m_axis_tkeep.value),
                int(dut.m_axis_tlast.value),
            )
            words.append(word)
        if len(words) >= 6 and words[-1][2]:
            break

    assert len(words) == 6
    assert [word[0] for word in words] == [expected_word()] * 6
    assert [word[1] for word in words] == [0xFF] * 6
    assert [word[2] for word in words] == [0, 0, 0, 0, 0, 1]


@cocotb.test()
async def test_buffer_read_stall_and_toggle_tready(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 3, unit="ns").start())
    await reset_dut(dut)
    await fill_cc1_bank_zero(dut)

    num_prb = 4
    await sample_after_rising(dut.clk_eth_xran)
    dut.m_fram_data_req.value = (1 << 24) | (1 << 15) | (num_prb << 7) | 1
    await sample_after_rising(dut.clk_eth_xran)
    dut.m_fram_data_req.value = 0

    # Hold tready low long enough to fill the output FIFO and stall the
    # read pipeline mid-burst
    dut.m_axis_tready.value = 0
    await ClockCycles(dut.clk_eth_xran, 32)

    rng = random.Random(24)
    words = []
    prev_valid = 0
    prev_ready = 0
    prev_word = (0, 0, 0)
    for _ in range(512):
        # The beat sampled last cycle transfers now if it was valid and the
        # tready driven last cycle was high
        if prev_valid and prev_ready:
            words.append(prev_word)
            if prev_word[2]:
                break
        prev_valid = int(dut.m_axis_tvalid.value)
        prev_word = (
            int(dut.m_axis_tdata.value),
            int(dut.m_axis_tkeep.value),
            int(dut.m_axis_tlast.value),
        )
        prev_ready = rng.randint(0, 1)
        dut.m_axis_tready.value = prev_ready
        await sample_after_rising(dut.clk_eth_xran)

    assert len(words) == num_prb * 6
    assert [word[0] for word in words] == [expected_word()] * (num_prb * 6)
    assert [word[1] for word in words] == [0xFF] * (num_prb * 6)
    assert [word[2] for word in words] == [0] * (num_prb * 6 - 1) + [1]


@cocotb.test()
async def test_last_prb_in_second_bank(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 3, unit="ns").start())
    await reset_dut(dut)

    max_prb = 160 if HALF_BLOCK else 275
    samples = 2048 if HALF_BLOCK else 4096
    dut.ctrl_rat[1].value = 1 if HALF_BLOCK else 2
    dut.ctrl_bw[1].value = 0 if HALF_BLOCK else 4
    await fill_cc1_symbol(
        dut,
        first_symbol=True,
        real=0x1111,
        imag=0xEEEE,
        samples=samples,
    )
    await fill_cc1_symbol(
        dut,
        first_symbol=False,
        real=0x0183,
        imag=0xF234,
        samples=samples,
    )

    dut.s_ul_sym_num[1].value = 1
    dut.m_axis_tready.value = 1
    words = await request_words(dut, start_prb=max_prb - 1, num_prb=1)

    expected = _packed_bfp9_word(0x0183, 0xF234)
    assert len(words) == 6
    assert [word[0] for word in words] == [expected] * 6
    assert [word[1] for word in words] == [0xFF] * 6
    assert [word[2] for word in words] == [0, 0, 0, 0, 0, 1]


@pytest.mark.parametrize("half_block", [0, 1])
def test_puxch_buffer_runner(half_block, monkeypatch):
    monkeypatch.setenv("HALF_BLOCK", str(half_block))
    run_cocotb(
        "puxch_buffer",
        Path(__file__).stem,
        parameters={"ID": BUFFER_ID, "NUM_CC": NUM_CC, "HALF_BLOCK": half_block},
        build_name=f"{Path(__file__).stem}_half_block_{half_block}",
        extra_env={"HALF_BLOCK": str(half_block)},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
