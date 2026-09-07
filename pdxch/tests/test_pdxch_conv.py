"""Unit tests for the PDXCH frequency-conversion stage."""

from __future__ import annotations

import os

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from pdxch_test_utils import PRJ_PATH, pdxch_sources, run_test

NUM_ANT = int(os.environ.get("NUM_ANT", "2"))
CASES = [1, 2, 4]


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


def _sideband(vector):
    return (
        vector["sf"],
        vector["sl"],
        vector["sy"],
        vector["chn"],
        vector["dv"],
        vector["last"],
    )


@cocotb.test()
async def test_control_table_and_sideband_latency(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.rst.value = 1
    dut.ctrl_rat.value = 0
    dut.ctrl_bw.value = 0
    _set_input(dut)
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0

    # HAS_CDC=0 makes the conversion-size table directly observable in the
    # destination clock domain. Cover all table branches used by PDXCH.
    size_cases = [
        (0, 0, 2),
        (0, 3, 1),
        (1, 2, 2),
        (1, 3, 1),
        (2, 2, 4),
        (2, 3, 2),
        (2, 4, 1),
    ]
    for rat, bw, expected_size in size_cases:
        dut.ctrl_rat.value = rat
        dut.ctrl_bw.value = bw
        await Timer(1, unit="ps")
        assert int(dut.fft_size.value) == expected_size

    # Flush the un-reset delay lines before checking the externally visible
    # sideband pipeline.
    zero = {"sf": 0, "sl": 0, "sy": 0, "chn": 0, "dv": 0, "last": 0}
    pattern = [
        zero,
        {"sf": 1, "sl": 0, "sy": 1, "chn": 0, "dv": 1, "last": 0},
        {"sf": 0, "sl": 1, "sy": 0, "chn": 1 % NUM_ANT, "dv": 1, "last": 0},
        {"sf": 0, "sl": 0, "sy": 0, "chn": 1 % NUM_ANT, "dv": 0, "last": 1},
        {"sf": 0, "sl": 0, "sy": 1, "chn": 0, "dv": 1, "last": 1},
    ]
    stimuli = [zero] * 24 + pattern + [zero] * 20
    current = stimuli[0]
    history = []

    for cycle, vector in enumerate(stimuli):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        history.append(current)

        # delay.DEPTH=13 contains registers [0:12]; an item sampled at an
        # edge is therefore visible at the output 12 edges later.
        if cycle >= 12:
            expected = history[cycle - 12]
            actual = (
                int(dut.dout_sf.value),
                int(dut.dout_sl.value),
                int(dut.dout_sy.value),
                int(dut.dout_chn.value),
                int(dut.dout_dv.value),
                int(dut.dout_last.value),
            )
            assert actual == _sideband(expected)
            if expected["dv"]:
                # Zero input should remain zero after the complex mixer.
                assert int(dut.dout_dr.value) == 0
                assert int(dut.dout_di.value) == 0

        current = vector
        _set_input(dut, **vector)


@cocotb.test()
async def test_nonzero_data_and_sideband_alignment(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.rst.value = 1
    dut.ctrl_rat.value = 0
    dut.ctrl_bw.value = 0
    _set_input(dut)
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0

    # Keep the phase increment at zero so the mixer is unity (cos=1, sin=0),
    # making each non-zero output sample directly identifiable. Flush the NCO
    # and data pipelines before applying the scored sequence.
    for _ in range(24):
        await RisingEdge(dut.clk)
        _set_input(dut)

    samples = [
        {
            "real": 1000 + 37 * index,
            "imag": 2000 + 29 * index,
            "chn": (index // 2 + index // 5) % NUM_ANT,
            "dv": int(index % 3 != 1),
        }
        for index in range(18)
    ]
    pipeline = []
    current = {}

    for vector in samples + [{}] * 13:
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        pipeline.append(current)

        if len(pipeline) > 12:
            expected = pipeline[-13]
            if expected:
                assert int(dut.dout_dr.value) == expected["real"]
                assert int(dut.dout_di.value) == expected["imag"]
                assert int(dut.dout_chn.value) == expected["chn"]
                assert int(dut.dout_dv.value) == expected["dv"]

        if vector:
            _set_input(dut, **vector)
        else:
            _set_input(dut)
        current = vector


@cocotb.test()
async def test_active_phase_wraps_without_saturation(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.rst.value = 1
    dut.ctrl_rat.value = 2
    dut.ctrl_bw.value = 4
    _set_input(dut)
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0

    # With this configuration fft_size=1.  The first group starts the
    # converter with phase increment -11; the second group advances each
    # antenna to bit-reversed index 1 (2048), whose phase is still 0 modulo
    # 128.  This exercises products that overflow the 7-bit phase result.
    total = 2 * NUM_ANT
    expected = [[] for _ in range(NUM_ANT)]
    actual = [[] for _ in range(NUM_ANT)]
    drive_index = 0

    for _ in range(total + 32):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")

        if int(dut.dout_dv.value):
            channel = int(dut.dout_chn.value)
            actual[channel].append(
                (dut.dout_dr.value.to_signed(), dut.dout_di.value.to_signed())
            )

        if drive_index < total:
            channel = drive_index % NUM_ANT
            _set_input(
                dut,
                real=4096,
                sf=int(drive_index == 0),
                sl=int(drive_index < NUM_ANT),
                sy=int(drive_index < NUM_ANT),
                chn=channel,
                dv=1,
                last=int(drive_index == total - 1),
            )
            expected[channel].append((4096, 0))
            drive_index += 1
        else:
            _set_input(dut)

    assert actual == expected


@pytest.mark.parametrize("num_ant", CASES, ids=lambda value: f"num_ant_{value}")
def test_pdxch_conv_runner(num_ant, monkeypatch):
    monkeypatch.setenv("NUM_ANT", str(num_ant))
    sources = [
        PRJ_PATH / "rtl" / "pdxch_conv.sv",
        PRJ_PATH / "rtl" / "pdxch_conv_nco.sv",
    ]
    sources += pdxch_sources(
        "../common/common.flt",
        "../cdc/cdc.flt",
        "../mult/mult.flt",
        "../cmult/cmult.flt",
    )
    run_test(
        hdl_toplevel="pdxch_conv",
        test_module="test_pdxch_conv",
        sources=sources,
        parameters={"HAS_CDC": 0, "NUM_ANT": num_ant},
        build_name=f"conv_num_ant_{num_ant}",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
