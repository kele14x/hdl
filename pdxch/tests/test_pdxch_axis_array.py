#!/usr/bin/env python3
"""Check cocotb antenna-array indexing at the PDXCH U-plane boundary."""

from __future__ import annotations

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Combine, RisingEdge
from pdxch_test_utils import pdxch_sources, run_test

from hdl_tools.axis import AxisAgentConfig, AxisBeat, AxisFrame, AxisSourceDriver

NUM_ANT = 4


class _IndexedAxisView:
    def __init__(self, dut, antenna: int):
        self._dut = dut
        self._antenna = antenna

    def __getattr__(self, name):
        signal = getattr(self._dut, name)
        if name.startswith("s_defm_data_"):
            return signal[self._antenna]
        return signal


@cocotb.test()
async def test_axis_driver_index_matches_rtl_generate_index(dut):
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())

    dut.s_axi_aresetn.value = 0
    dut.rst.value = 1
    dut.rst_eth_xran.value = 1
    dut.sync_in.value = 0
    for cc in range(3):
        dut.s_dl_sym_num[cc].value = 0
        for antenna in range(NUM_ANT):
            dut.m_axis_tready[cc][antenna].value = 1

    sources = []
    for antenna in range(NUM_ANT):
        source = AxisSourceDriver(
            _IndexedAxisView(dut, antenna),
            AxisAgentConfig(
                prefix="s_defm_data",
                clock="clk_eth_xran",
                reset="rst_eth_xran",
                reset_active_level=1,
            ),
        )
        source.idle()
        sources.append(source)

    await ClockCycles(dut.clk_eth_xran, 8)
    dut.s_axi_aresetn.value = 1
    dut.rst.value = 0
    dut.rst_eth_xran.value = 0
    await ClockCycles(dut.clk_eth_xran, 8)

    expected = [0xA0B0C000 + antenna for antenna in range(NUM_ANT)]
    observed = [None] * NUM_ANT

    async def monitor_physical_inputs():
        for _ in range(30):
            await RisingEdge(dut.clk_eth_xran)
            for antenna in range(NUM_ANT):
                gearbox = dut.i_pdxch_top.g_ant[antenna].u_pdxch_bfp_gearbox
                if observed[antenna] is None and int(gearbox.s_axis_tvalid.value):
                    observed[antenna] = int(gearbox.s_axis_tdata.value) & 0xFFFFFFFF

    monitor = cocotb.start_soon(monitor_physical_inputs())
    sends = []
    for antenna, data in enumerate(expected):
        # A complete compressed PRB is 28 bytes.  Keep this a legal gearbox
        # packet while putting the lane marker in its first input beat.
        beats = [
            AxisBeat(
                data=data if beat == 0 else 0,
                keep=0xFF if beat < 3 else 0x0F,
                user=0,
                dest=0,
                last=beat == 3,
            )
            for beat in range(4)
        ]
        frame = AxisFrame(beats)
        sends.append(cocotb.start_soon(sources[antenna].send(frame, gap=1)))
    await Combine(*sends)
    await monitor

    assert observed == expected


def test_pdxch_axis_array_runner():
    run_test(
        hdl_toplevel="pdxch",
        test_module="test_pdxch_axis_array",
        sources=pdxch_sources("pdxch.flt"),
        parameters={"NUM_CC": 3, "NUM_ANT": NUM_ANT},
        build_name="axis_array",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
