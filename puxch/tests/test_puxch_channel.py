from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from puxch_test_utils import run_cocotb, sample_after_rising

NUM_ANT = 4


async def reset_dut(dut):
    dut.rst.value = 1
    dut.rst_eth_xran.value = 1
    dut.ctrl_rst.value = 1
    dut.sync_in.value = 0
    dut.ctrl_en.value = 0
    dut.ctrl_rat.value = 2
    dut.ctrl_bist.value = 0
    dut.ctrl_bw.value = 0
    dut.ctrl_nprb.value = 0
    dut.ctrl_rfs_offset.value = 3
    dut.ctrl_phase_comp_addr.value = 0
    dut.ctrl_phase_comp_we.value = 0
    dut.ctrl_phase_comp_din.value = 0x00004000
    for antenna in range(NUM_ANT):
        dut.s_axis_tdata[antenna].value = 0
        dut.s_axis_tuser[antenna].value = 0
        dut.s_axis_tlast[antenna].value = 0
        dut.s_axis_tvalid[antenna].value = 1
        dut.ctrl_gain[antenna].value = 0x4000
    await ClockCycles(dut.clk, 8)
    dut.rst.value = 0
    await ClockCycles(dut.clk_eth_xran, 8)
    dut.rst_eth_xran.value = 0
    await ClockCycles(dut.ctrl_clk, 8)
    dut.ctrl_rst.value = 0
    await ClockCycles(dut.ctrl_clk, 4)


@cocotb.test()
async def test_channel_configuration_and_radio_start_delay(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 3, unit="ns").start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 5, unit="ns").start())
    await reset_dut(dut)

    cases = (
        (0, 0, 0b01, 0b00),
        (1, 3, 0b10, 0b01),
        (2, 0, 0b00, 0b00),
        (2, 3, 0b01, 0b01),
        (2, 4, 0b10, 0b10),
    )
    for rat, bandwidth, expected_size, expected_itlv in cases:
        await sample_after_rising(dut.ctrl_clk)
        dut.ctrl_rat.value = rat
        dut.ctrl_bw.value = bandwidth
        await sample_after_rising(dut.ctrl_clk)
        assert int(dut.ctrl_size.value) == expected_size
        assert int(dut.ctrl_itlv.value) == expected_itlv

    dut.ctrl_rat.value = 2
    dut.ctrl_bw.value = 0
    await ClockCycles(dut.clk_eth_xran, 5)
    await sample_after_rising(dut.clk_eth_xran)
    dut.sync_in.value = 1
    await sample_after_rising(dut.clk_eth_xran)
    dut.sync_in.value = 0

    sync_cycle = None
    radio_cycle = None
    for cycle in range(27450):
        await sample_after_rising(dut.clk_eth_xran)
        if int(dut.sync_s.value) and sync_cycle is None:
            sync_cycle = cycle
        if int(dut.fram_radio_start_10ms.value):
            radio_cycle = cycle
            break

    assert sync_cycle is not None
    assert radio_cycle is not None
    assert radio_cycle - sync_cycle in range(27341, 27344)
    assert [int(dut.s_axis_tready[i].value) for i in range(NUM_ANT)] == [1] * NUM_ANT


def test_puxch_channel_runner():
    run_cocotb(
        "puxch_channel",
        Path(__file__).stem,
        parameters={"NUM_ANT": NUM_ANT, "HALF_BLOCK": 1},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
