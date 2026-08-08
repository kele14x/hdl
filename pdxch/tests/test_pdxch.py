"""Top-level PDXCH smoke test through AXI4-Lite and the O-RAN/radio ports."""

from __future__ import annotations

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from pdxch_test_utils import pdxch_sources, run_test

NUM_CC = 3
NUM_ANT = 2


def _set_idle(dut):
    dut.s_axi_awaddr.value = 0
    dut.s_axi_awprot.value = 0
    dut.s_axi_awvalid.value = 0
    dut.s_axi_wdata.value = 0
    dut.s_axi_wstrb.value = 0
    dut.s_axi_wvalid.value = 0
    dut.s_axi_bready.value = 0
    dut.s_axi_araddr.value = 0
    dut.s_axi_arprot.value = 0
    dut.s_axi_arvalid.value = 0
    dut.s_axi_rready.value = 0
    dut.sync_in.value = 0
    for cc in range(NUM_CC):
        dut.s_dl_sym_num[cc].value = 0
        for ant in range(NUM_ANT):
            dut.m_axis_tready[cc][ant].value = 1
    for ant in range(NUM_ANT):
        dut.s_defm_data_tdata[ant].value = 0
        dut.s_defm_data_tkeep[ant].value = 0
        dut.s_defm_data_tvalid[ant].value = 0
        dut.s_defm_data_tlast[ant].value = 0
        dut.s_defm_data_tuser[ant].value = 0
        dut.s_defm_data_tdest[ant].value = 0


async def _reset(dut):
    _set_idle(dut)
    dut.s_axi_aresetn.value = 0
    dut.rst.value = 1
    dut.rst_eth_xran.value = 1
    await ClockCycles(dut.s_axi_aclk, 6)
    await ClockCycles(dut.clk_eth_xran, 2)
    await ClockCycles(dut.clk, 2)
    dut.s_axi_aresetn.value = 1
    dut.rst.value = 0
    dut.rst_eth_xran.value = 0
    await ClockCycles(dut.s_axi_aclk, 5)
    await ClockCycles(dut.clk, 10)


async def _axi_write(dut, address, data):
    dut.s_axi_awaddr.value = address
    dut.s_axi_awvalid.value = 1
    dut.s_axi_wdata.value = data
    dut.s_axi_wstrb.value = 0xF
    dut.s_axi_wvalid.value = 1
    for _ in range(24):
        await RisingEdge(dut.s_axi_aclk)
        await Timer(1, unit="ps")
        if int(dut.s_axi_awready.value) and int(dut.s_axi_wready.value):
            break
    else:
        raise AssertionError("top-level AXI write was not accepted")
    dut.s_axi_awvalid.value = 0
    dut.s_axi_wvalid.value = 0
    dut.s_axi_bready.value = 1
    for _ in range(24):
        await RisingEdge(dut.s_axi_aclk)
        await Timer(1, unit="ps")
        if int(dut.s_axi_bvalid.value):
            assert int(dut.s_axi_bresp.value) == 0
            break
    else:
        raise AssertionError("top-level AXI write response was not returned")
    await RisingEdge(dut.s_axi_aclk)
    dut.s_axi_bready.value = 0


async def _axi_read(dut, address):
    dut.s_axi_araddr.value = address
    dut.s_axi_arvalid.value = 1
    dut.s_axi_rready.value = 1
    for _ in range(24):
        await RisingEdge(dut.s_axi_aclk)
        await Timer(1, unit="ps")
        if int(dut.s_axi_arready.value):
            break
    else:
        raise AssertionError("top-level AXI read address was not accepted")
    dut.s_axi_arvalid.value = 0
    for _ in range(24):
        await RisingEdge(dut.s_axi_aclk)
        await Timer(1, unit="ps")
        if int(dut.s_axi_rvalid.value):
            data = int(dut.s_axi_rdata.value)
            assert int(dut.s_axi_rresp.value) == 0
            await RisingEdge(dut.s_axi_aclk)
            dut.s_axi_rready.value = 0
            return data
    raise AssertionError("top-level AXI read response was not returned")


@cocotb.test()
async def test_axi_config_sync_and_multi_cc_output_contract(dut):
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await _reset(dut)

    assert await _axi_read(dut, 0x00) == 0x20250106

    # Configure CC0 for the shortest supported NR/BIST smoke path. The other
    # two CCs remain disabled, which also checks that the top-level array
    # wiring does not alias channels.
    await _axi_write(dut, 0x10, 0x00000001)  # dl_en.cc0
    await _axi_write(dut, 0x14, 0x00000002)  # NR 30 kHz
    await _axi_write(dut, 0x18, 0x00000001)  # BIST.cc0
    await _axi_write(dut, 0x1C, 0x00000004)  # 100 MHz class / 4k phase
    await _axi_write(dut, 0x20, 0x00000001)  # one PRB

    assert await _axi_read(dut, 0x10) & 0xFFF == 1
    assert await _axi_read(dut, 0x14) & 0xFFF == 2
    assert await _axi_read(dut, 0x18) & 0xFFF == 1
    assert await _axi_read(dut, 0x20) & 0x1FF == 1

    # Drive one synchronization pulse. Every CC owns a copy of the timing
    # chain, so all three deframer start outputs should pulse once.
    dut.sync_in.value = 1
    await RisingEdge(dut.clk_eth_xran)
    await Timer(1, unit="ps")
    dut.sync_in.value = 0

    starts = [[] for _ in range(NUM_CC)]
    for _ in range(10):
        await RisingEdge(dut.clk_eth_xran)
        await Timer(1, unit="ps")
        for cc in range(NUM_CC):
            starts[cc].append(int(dut.defm_radio_start_10ms[cc].value))
    assert all(sum(pulses) == 1 for pulses in starts)

    # The radio stream endpoints are always-valid by design, and block2stream
    # leaves tlast deasserted. Check all CC/antenna combinations after reset
    # and the initial clock-domain activity have settled.
    for _ in range(20):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
    for cc in range(NUM_CC):
        for ant in range(NUM_ANT):
            assert int(dut.m_axis_tvalid[cc][ant].value) == 1
            assert int(dut.m_axis_tlast[cc][ant].value) == 0
    for ant in range(NUM_ANT):
        assert int(dut.s_defm_data_tready[ant].value) == 1


def test_pdxch_runner():
    run_test(
        hdl_toplevel="pdxch",
        test_module="test_pdxch",
        sources=pdxch_sources("pdxch.flt"),
        parameters={"NUM_CC": NUM_CC, "NUM_ANT": NUM_ANT, "HALF_BLOCK": 1},
        build_name="top",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
