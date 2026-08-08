"""Unit tests for PDXCH channel control decoding and stream framing."""

from __future__ import annotations

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from pdxch_test_utils import pdxch_sources, run_test

NUM_ANT = 2


def _set_data_input(dut, *, chn=0, dv=0, sf=0, sl=0, sy=0, last=0):
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_chn.value = chn
    dut.din_dv.value = dv
    dut.din_sf.value = sf
    dut.din_sl.value = sl
    dut.din_sy.value = sy
    dut.din_last.value = last


async def _reset(dut):
    dut.rst.value = 1
    dut.ctrl_rst.value = 1
    dut.ctrl_rat.value = 0
    dut.ctrl_bw.value = 0
    dut.ctrl_phase_comp_addr.value = 0
    dut.ctrl_phase_comp_we.value = 0
    dut.ctrl_phase_comp_din.value = 0
    _set_data_input(dut)
    for ant in range(NUM_ANT):
        dut.ctrl_gain[ant].value = 0x4000
        dut.m_axis_tready[ant].value = 1
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0
    dut.ctrl_rst.value = 0
    await ClockCycles(dut.clk, 8)


@cocotb.test()
async def test_rate_bandwidth_table_and_output_contract(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 14, unit="ns").start())
    await _reset(dut)

    cases = [
        (0, 0, 1, 0),
        (0, 4, 1, 0),
        (1, 2, 1, 0),
        (1, 3, 2, 1),
        (2, 2, 0, 0),
        (2, 3, 1, 1),
        (2, 4, 2, 2),
        (2, 15, 2, 2),
    ]
    for rat, bw, expected_size, expected_itlv in cases:
        dut.ctrl_rat.value = rat
        dut.ctrl_bw.value = bw
        await RisingEdge(dut.ctrl_clk)
        await Timer(1, unit="ps")
        assert int(dut.ctrl_size.value) == expected_size
        assert int(dut.ctrl_itlv.value) == expected_itlv

    # The block-to-stream endpoint is intentionally always-valid and never
    # asserts tlast; check this contract after all delay lines have flushed.
    outputs = []
    for _ in range(20):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        outputs.append(
            [
                (int(dut.m_axis_tvalid[ant].value), int(dut.m_axis_tlast[ant].value))
                for ant in range(NUM_ANT)
            ]
        )
    for cycle in outputs[8:]:
        assert cycle == [(1, 0)] * NUM_ANT


def test_pdxch_channel_runner():
    run_test(
        hdl_toplevel="pdxch_channel",
        test_module="test_pdxch_channel",
        sources=pdxch_sources("pdxch.flt"),
        parameters={"HAS_CDC": 0, "NUM_ANT": NUM_ANT, "HALF_BLOCK": 1},
        build_name="channel",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
