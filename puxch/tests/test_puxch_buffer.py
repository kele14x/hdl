from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from puxch_test_utils import run_cocotb, sample_after_rising

NUM_CC = 2
BUFFER_ID = 2
FFT_SAMPLES = 1024
EXPECTED_WORD = 0xCDAB3412CDAB3412


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
    assert held == (EXPECTED_WORD, 0xFF, 0)

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
    assert [word[0] for word in words] == [EXPECTED_WORD] * 6
    assert [word[1] for word in words] == [0xFF] * 6
    assert [word[2] for word in words] == [0, 0, 0, 0, 0, 1]


def test_puxch_buffer_runner():
    run_cocotb(
        "puxch_buffer",
        Path(__file__).stem,
        parameters={"ID": BUFFER_ID, "NUM_CC": NUM_CC, "HALF_BLOCK": 1},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
