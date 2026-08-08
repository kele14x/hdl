"""Unit tests for the PDXCH frequency-conversion stage."""

from __future__ import annotations

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from pdxch_test_utils import PRJ_PATH, pdxch_sources, run_test


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
        {"sf": 0, "sl": 1, "sy": 0, "chn": 1, "dv": 1, "last": 0},
        {"sf": 0, "sl": 0, "sy": 0, "chn": 1, "dv": 0, "last": 1},
        {"sf": 0, "sl": 0, "sy": 1, "chn": 0, "dv": 1, "last": 1},
    ]
    stimuli = [zero] * 24 + pattern + [zero] * 20
    current = stimuli[0]
    history = []

    for cycle, vector in enumerate(stimuli):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        history.append(current)

        # delay.DEPTH=15 contains registers [0:14]; an item sampled at an
        # edge is therefore visible at the output 14 edges later.
        if cycle >= 14:
            expected = history[cycle - 14]
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


def test_pdxch_conv_runner():
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
        parameters={"HAS_CDC": 0, "NUM_ANT": 2},
        build_name="conv",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
