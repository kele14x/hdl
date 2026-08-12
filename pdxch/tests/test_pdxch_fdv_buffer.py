"""Integration unit test for the FDV buffer clock-domain glue."""

from __future__ import annotations

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from pdxch_test_utils import PRJ_PATH, pdxch_sources, run_test

NUM_ANT = 2


def _iq_word(real, imag):
    pair = ((real & 0x1FF) << 9) | (imag & 0x1FF)
    return (pair << 18) | pair


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


@cocotb.test()
async def test_real_ram_read_address_alignment(dut):
    cocotb.start_soon(Clock(dut.clk_eth_xran, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await _reset(dut)

    dut.ctrl_bist.value = 0

    # Fill IQ addresses 0..5 with address-specific values. Both packed halves
    # are identical so each decoded result identifies the RAM address alone.
    expected_by_addr = {}
    await RisingEdge(dut.clk_eth_xran)
    for addr in range(6):
        real = 20 + addr
        imag = 60 + addr
        expected_by_addr[addr] = (real * 128, imag * 128)
        dut.s_axis_tdata[0].value = _iq_word(real, imag)
        dut.s_axis_exp[0].value = 15
        dut.s_axis_tvalid[0].value = 1
        dut.s_axis_tlast[0].value = int(addr == 5)
        dut.s_axis_tuser[0].value = 0
        await RisingEdge(dut.clk_eth_xran)

    dut.s_axis_tvalid[0].value = 0
    dut.s_axis_tlast[0].value = 0

    # Start the timer/readout path. The first symbol reads bank 0, which was
    # just populated above.
    dut.sync_in.value = 1
    await RisingEdge(dut.clk_eth_xran)
    dut.sync_in.value = 0

    pending = {}
    requested_addresses = []
    for cycle in range(18000):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")

        if cycle in pending:
            expected = pending.pop(cycle)
            actual = (int(dut.dout_dr.value), int(dut.dout_di.value))
            assert actual == expected

        if int(dut.rd_en[0].value):
            addr = int(dut.rd_iq_addr[0].value)
            assert addr in expected_by_addr
            requested_addresses.append(addr)
            pending[cycle + 4] = expected_by_addr[addr]

        if len(set(requested_addresses)) >= 3 and not pending:
            break

    assert len(set(requested_addresses)) >= 3


@cocotb.test()
async def test_write_drops_packet_at_half_block_boundary(dut):
    cocotb.start_soon(Clock(dut.clk_eth_xran, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await _reset(dut)

    start_prb = 159
    packet_words = 4 * 6
    observed_iq_addresses = []
    observed_exp_addresses = []

    for index in range(packet_words):
        await RisingEdge(dut.clk_eth_xran)
        dut.s_axis_tdata[0].value = _iq_word(index + 1, index + 2)
        dut.s_axis_exp[0].value = index & 0xF
        dut.s_axis_tvalid[0].value = 1
        dut.s_axis_tlast[0].value = int(index == packet_words - 1)
        dut.s_axis_tuser[0].value = start_prb if index == 0 else 0
        await Timer(1, unit="ps")

        iq_en = int(dut.wr_iq_en[0].value)
        exp_en = int(dut.wr_exp_en[0].value)
        if iq_en:
            iq_addr = int(dut.wr_iq_addr[0].value)
            observed_iq_addresses.append(iq_addr)
            assert iq_addr < 1024
        if exp_en:
            exp_addr = int(dut.wr_exp_addr[0].value)
            observed_exp_addresses.append(exp_addr)
            assert exp_addr < 480

        assert iq_en == int(index < 6)
        assert exp_en == int(index < 6 and index % 2 == 0)

    await RisingEdge(dut.clk_eth_xran)
    dut.s_axis_tvalid[0].value = 0
    dut.s_axis_tlast[0].value = 0

    assert observed_iq_addresses == list(range(159 * 6, 160 * 6))
    assert observed_exp_addresses == list(range(159 * 3, 160 * 3))


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
