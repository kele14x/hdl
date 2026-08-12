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


async def _write_fft_config(dut, *, rat, bw):
    await RisingEdge(dut.ctrl_clk)
    dut.ctrl_rat.value = rat
    dut.ctrl_bw.value = bw
    await RisingEdge(dut.ctrl_clk)


async def _pulse_symbol_boundary(dut):
    await RisingEdge(dut.clk)
    dut.din_sy.value = 1
    await RisingEdge(dut.clk)
    dut.din_sy.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")


async def _wait_pending_fft_config(
    dut,
    *,
    expected_size,
    expected_itlv,
    allowed=None,
):
    expected = (expected_size << 2) | expected_itlv
    for _ in range(80):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        observed = int(dut.ctrl_fft_cfg_pending.value)
        if allowed is not None:
            observed_pair = (observed >> 2, observed & 0x3)
            assert observed_pair in allowed
        if observed == expected:
            return
    raise AssertionError(
        f"FFT configuration did not cross clock domains: observed 0x{observed:x}, "
        f"expected 0x{expected:x}"
    )


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
        await _write_fft_config(dut, rat=rat, bw=bw)
        await _wait_pending_fft_config(
            dut,
            expected_size=expected_size,
            expected_itlv=expected_itlv,
        )

    # The pending configuration becomes active only at the symbol boundary.
    assert (int(dut.ctrl_size.value), int(dut.ctrl_itlv.value)) == (1, 0)
    await _pulse_symbol_boundary(dut)
    assert (int(dut.ctrl_size.value), int(dut.ctrl_itlv.value)) == (2, 2)

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


@cocotb.test()
async def test_fft_config_cdc_is_atomic_and_latest_value_wins(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 14, unit="ns").start())
    await _reset(dut)

    updates = [
        (1, 3, (2, 1)),
        (2, 2, (0, 0)),
        (2, 4, (2, 2)),
    ]
    allowed = {(1, 0)} | {expected for _, _, expected in updates}

    # Change the source faster than one round-trip handshake. Intermediate
    # configurations may be coalesced, but the final value must arrive and no
    # torn size/interleave pair may become active.
    for rat, bw, _ in updates:
        await _write_fft_config(dut, rat=rat, bw=bw)

    final_expected = updates[-1][2]
    await _wait_pending_fft_config(
        dut,
        expected_size=final_expected[0],
        expected_itlv=final_expected[1],
        allowed=allowed,
    )

    assert (int(dut.ctrl_size.value), int(dut.ctrl_itlv.value)) == (1, 0)
    await _pulse_symbol_boundary(dut)
    assert (int(dut.ctrl_size.value), int(dut.ctrl_itlv.value)) == final_expected


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
