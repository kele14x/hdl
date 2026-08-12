#!/usr/bin/env python3
"""Directed data/channel alignment test for the PDXCH phase-compensation stage."""

from __future__ import annotations

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from pdxch_test_utils import pdxch_sources, run_test

NUM_ANT = 4
UNITY_Q14 = 0x00004000


def _drive_idle(dut):
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_sf.value = 0
    dut.din_sl.value = 0
    dut.din_sy.value = 0
    dut.din_chn.value = 0
    dut.din_dv.value = 0
    dut.din_last.value = 0


@cocotb.test()
async def test_phase_comp_data_matches_channel_tag(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 14, unit="ns").start())

    dut.rst.value = 1
    dut.ctrl_rst.value = 1
    dut.ctrl_rat.value = 2
    dut.ctrl_phase_comp_addr.value = 0
    dut.ctrl_phase_comp_we.value = 0
    dut.ctrl_phase_comp_din.value = 0
    _drive_idle(dut)
    await ClockCycles(dut.clk, 8)
    dut.rst.value = 0
    dut.ctrl_rst.value = 0

    for address in range(16):
        await RisingEdge(dut.ctrl_clk)
        dut.ctrl_phase_comp_addr.value = address
        dut.ctrl_phase_comp_din.value = UNITY_Q14
        dut.ctrl_phase_comp_we.value = 1
    await RisingEdge(dut.ctrl_clk)
    dut.ctrl_phase_comp_we.value = 0
    await ClockCycles(dut.clk, 8)

    received = []
    expected = []

    async def monitor():
        for _ in range(120):
            await RisingEdge(dut.clk)
            await Timer(1, unit="ps")
            if dut.dout_dv.value.is_resolvable and int(dut.dout_dv.value):
                received.append(
                    (
                        int(dut.dout_chn.value),
                        dut.dout_dr.value.to_signed(),
                        dut.dout_di.value.to_signed(),
                    )
                )

    monitor_task = cocotb.start_soon(monitor())
    for cycle in range(64):
        await RisingEdge(dut.clk)
        channel = cycle % NUM_ANT
        real = 1000 + 7 * cycle
        imag = 2000 - 11 * cycle
        dut.din_dr.value = real
        dut.din_di.value = imag
        dut.din_sf.value = int(cycle < NUM_ANT)
        dut.din_sl.value = int(cycle < NUM_ANT)
        dut.din_sy.value = int(cycle < NUM_ANT)
        dut.din_chn.value = channel
        dut.din_dv.value = 1
        dut.din_last.value = 0
        expected.append((channel, real, imag))
    await RisingEdge(dut.clk)
    _drive_idle(dut)
    await monitor_task

    first_nonzero = next(
        (index for index, (_, real, imag) in enumerate(received) if real or imag),
        None,
    )
    assert received == expected, (
        f"first_nonzero={first_nonzero}, "
        f"received_head={received[:12]}, received_tail={received[-12:]}"
    )


def test_pdxch_phase_comp_alignment_runner():
    run_test(
        hdl_toplevel="phase_comp",
        test_module="test_pdxch_phase_comp_alignment",
        sources=pdxch_sources("../phase_comp/phase_comp.flt"),
        parameters={"HAS_CDC": 0, "NUM_ANT": NUM_ANT},
        build_name="phase_comp_alignment",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
