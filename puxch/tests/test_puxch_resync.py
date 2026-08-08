from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from puxch_test_utils import run_cocotb, sample_after_rising

NUM_ANT = 4


async def reset_dut(dut):
    dut.rst.value = 1
    dut.sync_in.value = 0
    dut.ctrl_en.value = 0b0101
    dut.ctrl_rat.value = 2
    dut.ctrl_bist.value = 0
    dut.ctrl_bw.value = 0
    for antenna in range(NUM_ANT):
        dut.s_axis_tdata[antenna].value = ((0x2000 + antenna) << 16) | (
            0x1000 + antenna
        )
        dut.s_axis_tuser[antenna].value = antenna
        dut.s_axis_tlast[antenna].value = 0
        dut.s_axis_tvalid[antenna].value = 1
    await ClockCycles(dut.clk, 8)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 5)


@cocotb.test()
async def test_resync_schedules_antennas_and_markers(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    await reset_dut(dut)

    assert [int(dut.s_axis_tready[i].value) for i in range(NUM_ANT)] == [1] * NUM_ANT

    await sample_after_rising(dut.clk)
    dut.sync_in.value = 1
    await sample_after_rising(dut.clk)
    dut.sync_in.value = 0

    marked_group = []
    following_group = []
    saw_marked_group = False
    for _ in range(80):
        await sample_after_rising(dut.clk)
        if not int(dut.dout_dv.value):
            continue
        sample = (
            int(dut.dout_chn.value),
            int(dut.dout_dr.value),
            int(dut.dout_di.value),
            int(dut.dout_sf.value),
            int(dut.dout_sl.value),
            int(dut.dout_sy.value),
        )
        if int(dut.dout_sf.value):
            saw_marked_group = True
            marked_group.append(sample)
        elif saw_marked_group and len(following_group) < NUM_ANT:
            following_group.append(sample)
        if len(marked_group) == NUM_ANT and len(following_group) == NUM_ANT:
            break

    assert [sample[0] for sample in marked_group] == list(range(NUM_ANT))
    assert [sample[3:] for sample in marked_group] == [(1, 1, 1)] * NUM_ANT
    assert [sample[1:3] for sample in marked_group] == [
        (0x1000, 0x2000),
        (0, 0),
        (0x1002, 0x2002),
        (0, 0),
    ]
    assert [sample[0] for sample in following_group] == list(range(NUM_ANT))
    assert [sample[3:] for sample in following_group] == [(0, 0, 0)] * NUM_ANT
    assert int(dut.dout_last.value) == 0


def test_puxch_resync_runner():
    run_cocotb(
        "puxch_resync",
        Path(__file__).stem,
        parameters={"NUM_ANT": NUM_ANT},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
