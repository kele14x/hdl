"""Cocotb integration regression for the six-stage PRACH DDC."""

from __future__ import annotations

import os
import shutil
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb_tools.runner import get_runner
from prach_ddc_model import (
    SIDEBAND_FIELDS,
    halfband4,
    model_decimation_chain,
    signed16,
    unsigned16,
)

from hdl_tools.flt_tool import resolve_flt

PRJ_PATH = Path(__file__).resolve().parent.parent
NUM_ANT = 4
NUM_REAL_LANES = 2 * NUM_ANT
ACTIVE_CYCLES = 32 * 256
TAIL_CYCLES = 1700

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

_SIMULATOR_BINARIES = {
    "questa": "vsim",
    "modelsim": "vsim",
    "icarus": "iverilog",
    "verilator": "verilator",
}
_simulator_binary = _SIMULATOR_BINARIES.get(SIM.lower())
if _simulator_binary and shutil.which(_simulator_binary) is None:
    raise RuntimeError(
        f"SIM={SIM!r} was selected, but the required executable "
        f"{_simulator_binary!r} is not available on PATH"
    )


def _set_input(
    dut,
    *,
    real=0,
    imag=0,
    sf=1,
    sl=0,
    sy=0,
    chn=0,
    dv=0,
    last=0,
):
    dut.din_dr.value = unsigned16(real)
    dut.din_di.value = unsigned16(imag)
    dut.din_sf.value = sf
    dut.din_sl.value = sl
    dut.din_sy.value = sy
    dut.din_chn.value = chn
    dut.din_dv.value = dv
    dut.din_last.value = last


def _read_sideband(prefix, dut) -> dict[str, int]:
    return {
        field: int(getattr(dut, f"{prefix}_{field}").value) for field in SIDEBAND_FIELDS
    }


def _read_complex(prefix, dut) -> tuple[int, int]:
    return (
        signed16(int(getattr(dut, f"{prefix}_dr").value)),
        signed16(int(getattr(dut, f"{prefix}_di").value)),
    )


async def _reset_and_flush(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    dut.rst.value = 1
    dut.ctrl_fcw.value = 0
    dut.ctrl_bw.value = 0xF
    _set_input(dut)
    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0

    # None of the HB/reshape delay lines use rst.  A complete zero flush makes
    # the beginning of the captured sequence equivalent to zero padding.
    # Clearing unknown data takes longer than the valid-sample group delay:
    # each current HB still shifts all 3*D/7*D clock slots, including invalid
    # ones, before its downstream stage becomes deterministic.
    await ClockCycles(dut.clk, 4000)


def _make_vector(index: int, rng) -> dict[str, int]:
    phase = index & 0xFF
    phase_lane = phase & 0x7F
    valid = int(phase_lane < NUM_REAL_LANES)
    event = (index // 128) * NUM_REAL_LANES + min(phase_lane, NUM_REAL_LANES - 1)
    return {
        "real": int(rng.integers(-24000, 24001)),
        "imag": int(rng.integers(-24000, 24001)),
        "sf": 1,
        "sl": ((event >> 0) & 1) if valid else 0,
        "sy": ((event >> 1) & 1) if valid else 0,
        "chn": phase,
        "dv": valid,
        "last": ((event >> 2) & 1) if valid else 0,
    }


def _assert_eight_lane_bursts(
    sideband: dict[str, list[int]], name: str, channel_bases: set[int]
):
    valid_samples = [
        (cycle, sideband["chn"][cycle])
        for cycle, valid in enumerate(sideband["dv"])
        if valid
    ]
    assert valid_samples, f"{name}: no valid samples observed"
    assert len(valid_samples) % NUM_REAL_LANES == 0

    for offset in range(0, len(valid_samples), NUM_REAL_LANES):
        burst = valid_samples[offset : offset + NUM_REAL_LANES]
        first_cycle = burst[0][0]
        channel_base = burst[0][1]
        assert channel_base in channel_bases, (
            f"{name}: unexpected channel base {channel_base} at cycle {first_cycle}"
        )
        assert burst == [
            (first_cycle + lane, channel_base + lane) for lane in range(NUM_REAL_LANES)
        ], f"{name}: malformed eight-lane burst at cycle {first_cycle}: {burst}"


@cocotb.test()
async def test_six_stage_chain_matches_cycle_accurate_model(dut):
    await _reset_and_flush(dut)
    rng = np.random.default_rng(0x444443)

    hb4 = dut.g_stage[4].g_hb4.u_hb4
    hb5 = dut.g_stage[5].g_hb5.u_hb5
    sparse_stages = {}
    for name in ("hb4", "hb5"):
        sparse_stages[name] = {
            "din_dp1": [],
            "din_dp2": [],
            "din_sideband": {field: [] for field in SIDEBAND_FIELDS},
            "dout_dq": [],
            "dout_sideband": {field: [] for field in SIDEBAND_FIELDS},
        }

    mixer_real = []
    mixer_imag = []
    mixer_sideband = {field: [] for field in SIDEBAND_FIELDS}
    conv_input_real = []
    conv_input_imag = []
    conv_input_sideband = {field: [] for field in SIDEBAND_FIELDS}
    conv_output = []
    top_output = []

    for cycle in range(ACTIVE_CYCLES + TAIL_CYCLES):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")

        real, imag = _read_complex("mixer_dout", dut)
        mixer_real.append(real)
        mixer_imag.append(imag)
        sideband = _read_sideband("mixer_dout", dut)
        for field in SIDEBAND_FIELDS:
            mixer_sideband[field].append(sideband[field])

        real, imag = _read_complex("conv_din", dut)
        conv_input_real.append(real)
        conv_input_imag.append(imag)
        sideband = _read_sideband("conv_din", dut)
        for field in SIDEBAND_FIELDS:
            conv_input_sideband[field].append(sideband[field])

        conv_output.append(
            (*_read_complex("conv_dout", dut), _read_sideband("conv_dout", dut))
        )
        top_output.append((*_read_complex("dout", dut), _read_sideband("dout", dut)))

        for name, stage in (("hb4", hb4), ("hb5", hb5)):
            trace = sparse_stages[name]
            trace["din_dp1"].append(signed16(int(stage.din_dp1.value)))
            trace["din_dp2"].append(signed16(int(stage.din_dp2.value)))
            sideband = _read_sideband("din", stage)
            for field in SIDEBAND_FIELDS:
                trace["din_sideband"][field].append(sideband[field])
            trace["dout_dq"].append(signed16(int(stage.dout_dq.value)))
            sideband = _read_sideband("dout", stage)
            for field in SIDEBAND_FIELDS:
                trace["dout_sideband"][field].append(sideband[field])

        if cycle < ACTIVE_CYCLES:
            _set_input(dut, **_make_vector(cycle, rng))
        else:
            _set_input(dut, chn=cycle & 0xFF)

    model_trace = {}
    expected_real, expected_imag, expected_sideband = model_decimation_chain(
        mixer_real, mixer_imag, mixer_sideband, trace=model_trace
    )

    for name in ("hb4", "hb5"):
        trace = sparse_stages[name]
        expected_dp1, expected_dp2, expected_input_sideband = model_trace[f"{name}_in"]
        input_cycles = sorted(
            {
                cycle
                for cycle, valid in enumerate(expected_input_sideband["dv"])
                if valid
            }
            | {
                cycle
                for cycle, valid in enumerate(trace["din_sideband"]["dv"])
                if valid
            }
        )
        for cycle in input_cycles[: -3 * NUM_REAL_LANES]:
            for field in SIDEBAND_FIELDS:
                assert (
                    trace["din_sideband"][field][cycle]
                    == expected_input_sideband[field][cycle]
                ), (
                    f"{name} cycle {cycle}: modeled input {field} mismatch; "
                    f"actual={trace['din_sideband'][field][cycle]}, "
                    f"expected={expected_input_sideband[field][cycle]}"
                )
            assert (
                trace["din_dp1"][cycle],
                trace["din_dp2"][cycle],
            ) == (expected_dp1[cycle], expected_dp2[cycle]), (
                f"{name} cycle {cycle}: modeled input mismatch; "
                f"actual={(trace['din_dp1'][cycle], trace['din_dp2'][cycle])}, "
                f"expected={(expected_dp1[cycle], expected_dp2[cycle])}"
            )

    for name, delay_base in (("hb4", 128), ("hb5", 256)):
        trace = sparse_stages[name]
        expected_dq, expected_stage_sideband = halfband4(
            trace["din_dp1"],
            trace["din_dp2"],
            trace["din_sideband"],
            delay_base,
        )
        expected_stage_cycles = [
            cycle for cycle, valid in enumerate(expected_stage_sideband["dv"]) if valid
        ]
        for cycle in expected_stage_cycles[: -3 * NUM_REAL_LANES]:
            assert trace["dout_dq"][cycle] == expected_dq[cycle], (
                f"{name} cycle {cycle}: data mismatch; "
                f"actual={trace['dout_dq'][cycle]}, expected={expected_dq[cycle]}"
            )
            expected_dv = int(
                delay_base == 256 or expected_stage_sideband["chn"][cycle] < 8
            )
            assert trace["dout_sideband"]["dv"][cycle] == expected_dv, (
                f"{name} cycle {cycle}: dout_dv mismatch"
            )
    expected_valid_cycles = [
        cycle for cycle, valid in enumerate(expected_sideband["dv"]) if valid
    ]
    # Compare the steady-state outputs emitted while active input is still
    # present. The finite-vector tail lacks future lane events and therefore
    # has no semantic equivalent in the continuous radio stream.
    checked_valid_cycles = {
        cycle for cycle in expected_valid_cycles if cycle < ACTIVE_CYCLES
    }

    checked = 0
    for cycle in range(len(expected_real)):
        expected_dv = expected_sideband["dv"][cycle]
        actual_dv = conv_input_sideband["dv"][cycle]
        if not expected_dv:
            assert actual_dv == 0, f"cycle {cycle}: unexpected conv_din_dv"
            continue
        if cycle not in checked_valid_cycles:
            continue

        assert actual_dv == 1, f"cycle {cycle}: missing conv_din_dv"
        checked += 1
        assert (conv_input_real[cycle], conv_input_imag[cycle]) == (
            expected_real[cycle],
            expected_imag[cycle],
        ), (
            f"cycle {cycle}: conv input data mismatch; "
            f"actual={(conv_input_real[cycle], conv_input_imag[cycle])}, "
            f"expected={(expected_real[cycle], expected_imag[cycle])}"
        )
        for field in SIDEBAND_FIELDS:
            assert (
                conv_input_sideband[field][cycle] == expected_sideband[field][cycle]
            ), (
                f"cycle {cycle}: conv_din_{field} mismatch; "
                f"actual={conv_input_sideband[field][cycle]}, "
                f"expected={expected_sideband[field][cycle]}"
            )

    assert checked >= 32, f"too few valid DDC outputs were checked: {checked}"

    _assert_eight_lane_bursts(mixer_sideband, "mixer output", {0, 128})
    _assert_eight_lane_bursts(conv_input_sideband, "HB chain output", {0})

    # The final DDC register gates invalid channels but otherwise delays the
    # conversion output by exactly one clock.
    for cycle in range(1, len(top_output)):
        previous_real, previous_imag, previous_sideband = conv_output[cycle - 1]
        actual_real, actual_imag, actual_sideband = top_output[cycle]
        channel_valid = previous_sideband["chn"] < NUM_ANT
        assert actual_real == (previous_real if channel_valid else 0)
        assert actual_imag == (previous_imag if channel_valid else 0)
        assert actual_sideband["dv"] == (previous_sideband["dv"] and channel_valid)
        for field in ("sf", "sl", "sy", "chn", "last"):
            assert actual_sideband[field] == previous_sideband[field]


def test_prach_ddc_runner():
    runner = get_runner(SIM)
    run_dir = PRJ_PATH / "sim_build" / "prach_ddc"
    runner.build(
        hdl_toplevel="prach_ddc",
        sources=resolve_flt(PRJ_PATH / "prach.flt"),
        parameters={"NUM_ANT": NUM_ANT, "NUM_STAGE": 6},
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="prach_ddc",
        hdl_toplevel_lang="verilog",
        test_module="test_prach_ddc",
        waves=True,
        gui=os.environ.get("GUI", "false").lower() == "true",
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
