import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from puxch_test_utils import run_cocotb, sample_after_rising

NUM_CC = 1
NUM_ANT = 4
HALF_BLOCK = int(os.environ.get("HALF_BLOCK", "1"))
FINAL_BFP9 = int(os.environ.get("FINAL_BFP9", "0"))


async def reset_dut(dut):
    dut.rst.value = 1
    dut.rst_eth_xran.value = 1
    dut.ctrl_rst.value = 1
    dut.sync_in.value = 0
    dut.ctrl_ud_comp_meth.value = FINAL_BFP9
    dut.ctrl_ud_iq_width.value = 9
    dut.ctrl_fs_offset.value = 0
    dut.ctrl_phase_comp_addr.value = 0
    dut.ctrl_phase_comp_en.value = 0
    dut.ctrl_phase_comp_we.value = 0
    dut.ctrl_phase_comp_din.value = 0
    for cc in range(NUM_CC):
        dut.s_ul_sym_num[cc].value = 0
        dut.ctrl_en[cc].value = 0xF
        dut.ctrl_rat[cc].value = 2
        dut.ctrl_bist[cc].value = 0
        dut.ctrl_bw[cc].value = 0
        dut.ctrl_nprb[cc].value = 0
        dut.ctrl_rfs_offset[cc].value = 0
        for antenna in range(NUM_ANT):
            dut.s_axis_tdata[cc][antenna].value = 0
            dut.s_axis_tuser[cc][antenna].value = 0
            dut.s_axis_tlast[cc][antenna].value = 0
            dut.s_axis_tvalid[cc][antenna].value = 1
            dut.ctrl_gain[cc][antenna].value = 0x4000
    for antenna in range(NUM_ANT):
        dut.m_fram_data_tready[antenna].value = 1
        dut.m_fram_data_req[antenna].value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk_eth_xran, 10)
    dut.rst_eth_xran.value = 0
    await ClockCycles(dut.ctrl_clk, 10)
    dut.ctrl_rst.value = 0
    await ClockCycles(dut.ctrl_clk, 5)


async def write_unity_phase_table(dut):
    for symbol in range(16):
        await sample_after_rising(dut.ctrl_clk)
        dut.ctrl_phase_comp_addr.value = symbol
        dut.ctrl_phase_comp_din.value = 0x00004000
        dut.ctrl_phase_comp_en.value = 1
        dut.ctrl_phase_comp_we.value = 1
    await sample_after_rising(dut.ctrl_clk)
    dut.ctrl_phase_comp_we.value = 0
    dut.ctrl_phase_comp_en.value = 0


@cocotb.test()
async def test_top_zero_symbol_to_framer_request(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 3, unit="ns").start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 5, unit="ns").start())
    await reset_dut(dut)
    await write_unity_phase_table(dut)

    dut.ctrl_phase_comp_addr.value = 7
    dut.ctrl_phase_comp_en.value = 1
    await sample_after_rising(dut.ctrl_clk)
    await sample_after_rising(dut.ctrl_clk)
    assert int(dut.ctrl_phase_comp_valid.value) == 1
    assert int(dut.ctrl_phase_comp_dout.value) == 0x00004000
    dut.ctrl_phase_comp_en.value = 0

    await sample_after_rising(dut.clk_eth_xran)
    dut.sync_in.value = 1
    await sample_after_rising(dut.clk_eth_xran)
    dut.sync_in.value = 0

    await ClockCycles(dut.clk, 40000)

    await sample_after_rising(dut.clk_eth_xran)
    dut.m_fram_data_req[0].value = (1 << 24) | (1 << 7)
    await sample_after_rising(dut.clk_eth_xran)
    dut.m_fram_data_req[0].value = 0

    words = []
    for _ in range(96):
        await sample_after_rising(dut.clk_eth_xran)
        if int(dut.m_fram_data_tvalid[0].value):
            words.append(
                (
                    int(dut.m_fram_data_tdata[0].value),
                    int(dut.m_fram_data_tkeep[0].value),
                    int(dut.m_fram_data_tlast[0].value),
                )
            )
        if words and words[-1][2]:
            break

    if FINAL_BFP9:
        assert len(words) == 4
        assert [word[0] for word in words] == [0x08, 0, 0, 0]
        assert [word[1] for word in words] == [0xFF, 0xFF, 0xFF, 0x0F]
        assert [word[2] for word in words] == [0, 0, 0, 1]
    else:
        assert len(words) == 6
        assert [word[0] for word in words] == [0] * 6
        assert [word[1] for word in words] == [0xFF] * 6
        assert [word[2] for word in words] == [0, 0, 0, 0, 0, 1]
    for antenna in range(1, NUM_ANT):
        assert int(dut.m_fram_data_tvalid[antenna].value) == 0


CASES = [
    {"name": "half_raw", "half_block": 1, "final_bfp9": 0},
    {"name": "full_bfp9", "half_block": 0, "final_bfp9": 1},
]


@pytest.mark.parametrize("case", CASES, ids=[case["name"] for case in CASES])
def test_puxch_top_runner(case, monkeypatch):
    monkeypatch.setenv("HALF_BLOCK", str(case["half_block"]))
    monkeypatch.setenv("FINAL_BFP9", str(case["final_bfp9"]))
    run_cocotb(
        "puxch_top",
        Path(__file__).stem,
        parameters={
            "NUM_CC": NUM_CC,
            "NUM_ANT": NUM_ANT,
            "HALF_BLOCK": case["half_block"],
            "HALF_FFT": 1,
        },
        build_name=f"{Path(__file__).stem}_{case['name']}",
        extra_env={
            "HALF_BLOCK": str(case["half_block"]),
            "FINAL_BFP9": str(case["final_bfp9"]),
        },
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
