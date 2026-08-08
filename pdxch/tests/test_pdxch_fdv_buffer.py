"""Integration unit test for the FDV buffer clock-domain glue."""

from __future__ import annotations

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from pdxch_test_utils import PRJ_PATH, pdxch_sources, run_test

NUM_ANT = 2


def _set_inputs(dut):
    dut.sync_in.value = 0
    dut.s_dl_sym_num.value = 0
    dut.ctrl_en.value = 1
    dut.ctrl_rat.value = 2
    dut.ctrl_bist.value = 1
    dut.ctrl_bw.value = 4
    dut.ctrl_nprb.value = 1
    dut.ctrl_rfs_offset.value = 0
    dut.ctrl_fs_offset.value = 0
    for ant in range(NUM_ANT):
        dut.s_axis_tdata[ant].value = 0
        dut.s_axis_exp[ant].value = 0
        dut.s_axis_tvalid[ant].value = 0
        dut.s_axis_tlast[ant].value = 0
        dut.s_axis_tuser[ant].value = 0


async def _reset(dut):
    dut.rst_eth_xran.value = 1
    dut.rst.value = 1
    _set_inputs(dut)
    await ClockCycles(dut.clk_eth_xran, 6)
    dut.rst_eth_xran.value = 0
    dut.rst.value = 0
    await ClockCycles(dut.clk, 8)


@cocotb.test()
async def test_sync_timer_and_bist_readout(dut):
    cocotb.start_soon(Clock(dut.clk_eth_xran, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await _reset(dut)

    # A zero-delay request still traverses the pulse-delay implementation;
    # verify that the first clock-domain boundary emits one 10 ms marker.
    dut.sync_in.value = 1
    await RisingEdge(dut.clk_eth_xran)
    await Timer(1, unit="ps")
    dut.sync_in.value = 0

    first_marker = []
    for _ in range(8):
        await RisingEdge(dut.clk_eth_xran)
        await Timer(1, unit="ps")
        first_marker.append(int(dut.defm_radio_start_10ms.value))
    assert sum(first_marker) == 1

    # The second pulse_delay is intentionally 4000 Ethernet clocks. The
    # symbol timer and radio-side BIST should become active after it crosses
    # the CDC boundary.
    radio_samples = []
    # Observe the whole crossing window so the one-cycle frame/slot/symbol
    # strobes cannot be missed while waiting for the 4000-clock delay.
    for _ in range(4200):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        if dut.dout_dv.value.is_resolvable:
            radio_samples.append(
                (
                    int(dut.dout_dv.value),
                    int(dut.dout_chn.value),
                    int(dut.dout_dr.value),
                    int(dut.dout_di.value),
                    int(dut.dout_sf.value),
                    int(dut.dout_sy.value),
                )
            )

    assert any(sample[4] for sample in radio_samples)
    assert any(sample[5] for sample in radio_samples)
    assert any(sample[0] and sample[1] == 0 for sample in radio_samples)

    corners = {4210, 0x10000 - 4210}
    assert any(
        sample[0] and sample[1] == 0 and sample[2] in corners and sample[3] in corners
        for sample in radio_samples
    )


def test_pdxch_fdv_buffer_runner():
    sources = [
        PRJ_PATH / "rtl" / "pdxch_fdv_buffer.sv",
        PRJ_PATH / "rtl" / "pdxch_fdv_buffer_map.sv",
        PRJ_PATH / "rtl" / "pdxch_fdv_buffer_write.sv",
        PRJ_PATH / "rtl" / "pdxch_fdv_buffer_readout.sv",
    ]
    sources += pdxch_sources(
        "../common/common.flt",
        "../cdc/cdc.flt",
        "../lfsr/lfsr.flt",
        "../pulse_delay/pulse_delay.flt",
        "../symbol_timer/symbol_timer.flt",
        "../ram/ram.flt",
    )
    run_test(
        hdl_toplevel="pdxch_fdv_buffer",
        test_module="test_pdxch_fdv_buffer",
        sources=sources,
        parameters={"CC_ID": 0, "NUM_ANT": NUM_ANT, "HALF_BLOCK": 1},
        build_name="fdv_buffer",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
