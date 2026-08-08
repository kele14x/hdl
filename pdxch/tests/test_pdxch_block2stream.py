"""Unit tests for the PDXCH block-to-stream ping-pong buffer."""

from __future__ import annotations

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from pdxch_test_utils import PRJ_PATH, pdxch_sources, run_test

NUM_ANT = 2


def _set_input(
    dut,
    *,
    real=0,
    imag=0,
    sf=0,
    sl=0,
    sy=0,
    chn=0,
    dv=0,
    last=0,
):
    dut.din_dr.value = real & 0xFFFF
    dut.din_di.value = imag & 0xFFFF
    dut.din_sf.value = sf
    dut.din_sl.value = sl
    dut.din_sy.value = sy
    dut.din_chn.value = chn
    dut.din_dv.value = dv
    dut.din_last.value = last


def _read_outputs(dut):
    def value_or_none(signal):
        value = signal.value
        return int(value) if value.is_resolvable else None

    return [
        (
            value_or_none(dut.m_axis_tdata[ant]),
            value_or_none(dut.m_axis_tuser[ant]),
            value_or_none(dut.m_axis_tvalid[ant]),
            value_or_none(dut.m_axis_tlast[ant]),
        )
        for ant in range(NUM_ANT)
    ]


async def _reset(dut):
    dut.rst.value = 1
    for ant in range(NUM_ANT):
        dut.m_axis_tready[ant].value = 1
    _set_input(dut)
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0
    # The data/user delay lines are intentionally not reset in the RTL. Feed
    # zeros long enough to make their initial state deterministic.
    await ClockCycles(dut.clk, 8)


async def _clock_with_input(dut, **kwargs):
    _set_input(dut, **kwargs)
    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")
    return _read_outputs(dut)


@cocotb.test()
async def test_direct_path_and_memory_playback(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await _reset(dut)

    # First check that the serialized input reaches the matching antenna and
    # that each output is permanently valid while tlast remains unused.
    direct_words = [
        (0, 0x1111, 0xAAAA, 1),
        (1, 0x2222, 0xBBBB, 0),
        (0, 0x3333, 0xCCCC, 0),
        (1, 0x4444, 0xDDDD, 0),
    ]
    observed = []
    for chn, real, imag, sf in direct_words:
        observed.append(
            await _clock_with_input(
                dut,
                chn=chn,
                real=real,
                imag=imag,
                sf=sf,
                dv=1,
            )
        )
    for _ in range(10):
        observed.append(await _clock_with_input(dut))

    for outputs in observed:
        for data, _, valid, last in outputs:
            if valid is not None:
                assert valid == 1
            if last is not None:
                assert last == 0

    ant0_data = [data for data, _, _, _ in [outputs[0] for outputs in observed]]
    ant1_data = [data for data, _, _, _ in [outputs[1] for outputs in observed]]
    assert 0xAAAA1111 in ant0_data
    assert 0xCCCC3333 in ant0_data
    assert 0xBBBB2222 in ant1_data
    assert 0xDDDD4444 in ant1_data

    # Reset clears the write counters. A start-of-symbol on each serialized
    # antenna arms its read sequencer; subsequent invalid cycles play the
    # corresponding word back from RAM.
    await _reset(dut)
    await _clock_with_input(dut, chn=0, real=0x1357, imag=0x2468, sf=1, sy=1, dv=1)
    await _clock_with_input(dut, chn=1, real=0xABCD, imag=0x0123, sy=1, dv=1)

    playback = []
    for chn in (0, 0, 0, 1, 1, 1, 1):
        playback.append(await _clock_with_input(dut, chn=chn))
    for _ in range(8):
        playback.append(await _clock_with_input(dut, chn=1))

    ant0_playback = [data for data, _, _, _ in [outputs[0] for outputs in playback]]
    ant1_playback = [data for data, _, _, _ in [outputs[1] for outputs in playback]]
    assert 0x24681357 in ant0_playback
    assert 0x0123ABCD in ant1_playback

    # The start-of-frame marker is carried on the matching antenna's user bit.
    assert any(
        user is not None and user & 1
        for _, user, _, _ in [outputs[0] for outputs in observed]
    )


def test_pdxch_block2stream_runner():
    sources = [PRJ_PATH / "rtl" / "pdxch_block2stream.sv"]
    sources += pdxch_sources("../common/common.flt", "../ram/ram.flt")
    run_test(
        hdl_toplevel="pdxch_block2stream",
        test_module="test_pdxch_block2stream",
        sources=sources,
        parameters={"NUM_ANT": NUM_ANT},
        build_name="block2stream",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
