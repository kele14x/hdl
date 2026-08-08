"""Bit-accurate cocotb regression tests for ``prach_hb4``."""

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
from prach_ddc_model import hb4_sample, unsigned16

PRJ_PATH = Path(__file__).resolve().parent.parent
REPO_PATH = PRJ_PATH.parent
DELAY_BASE = int(os.environ.get("PRACH_HB4_DELAY_BASE", "128"))
LATENCY = 3 * DELAY_BASE + 10
CASES = [
    pytest.param(128, id="hb4-delay-128"),
    pytest.param(256, id="hb5-delay-256"),
]

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
    dp1=0,
    dp2=0,
    sf=0,
    sl=0,
    sy=0,
    chn=0,
    dv=0,
    last=0,
):
    dut.din_dp1.value = unsigned16(dp1)
    dut.din_dp2.value = unsigned16(dp2)
    dut.din_sf.value = sf
    dut.din_sl.value = sl
    dut.din_sy.value = sy
    dut.din_chn.value = chn
    dut.din_dv.value = dv
    dut.din_last.value = last


def _read_output(dut) -> tuple[int, int, int, int, int, int, int]:
    return (
        int(dut.dout_dq.value),
        int(dut.dout_sf.value),
        int(dut.dout_sl.value),
        int(dut.dout_sy.value),
        int(dut.dout_chn.value),
        int(dut.dout_dv.value),
        int(dut.dout_last.value),
    )


async def _flush_unknown_state(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    dut.rst.value = 1
    dut.ctrl_bypass.value = 0
    _set_input(dut)
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0

    # rst is intentionally unused by the datapath.  Zero-fill the longest
    # xp2 delay and arithmetic pipeline before making any assertions.
    await ClockCycles(dut.clk, 7 * DELAY_BASE + 20)


def _make_filter_vectors():
    rng = np.random.default_rng(0x484234 + DELAY_BASE)
    length = 16 * DELAY_BASE
    dp1 = [int(value) for value in rng.integers(-30000, 30001, size=length)]
    dp2 = [int(value) for value in rng.integers(-30000, 30001, size=length)]
    vectors = []

    for index in range(length):
        vectors.append(
            {
                "dp1": dp1[index],
                "dp2": dp2[index],
                "chn": index & 0xFF,
                "dv": 0,
                "sf": 0,
                "sl": 0,
                "sy": 0,
                "last": 0,
            }
        )

    valid_indices = []
    event = 0
    # Each burst is eight real lanes (I/Q for four PRACH channels).  dp1/dp2
    # carry the even/odd time samples for one lane in the same clock cycle.
    # Populate every epoch so all taps used by the checked outputs are valid.
    for epoch in range(16):
        for lane in range(8):
            index = epoch * DELAY_BASE + lane
            channel_base = 128 if DELAY_BASE == 128 and epoch & 1 else 0
            vectors[index].update(
                chn=channel_base + lane,
                dv=1,
                sf=int(event == 0),
                sl=(event >> 0) & 1,
                sy=(event >> 1) & 1,
                last=(event >> 2) & 1,
            )
            if 4 <= epoch < 12:
                valid_indices.append(index)
            event += 1

    expected = {
        index + LATENCY: (
            unsigned16(hb4_sample(dp1, dp2, index, DELAY_BASE)),
            vectors[index]["sf"],
            vectors[index]["sl"],
            vectors[index]["sy"],
            vectors[index]["chn"],
            int(not (DELAY_BASE == 128 and vectors[index]["chn"] >= 128)),
            vectors[index]["last"],
        )
        for index in valid_indices
    }
    allowed_dv = {
        epoch * DELAY_BASE + lane + LATENCY for epoch in range(16) for lane in range(8)
    }
    return vectors, expected, allowed_dv


def _make_bypass_vectors():
    rng = np.random.default_rng(0x425950 + DELAY_BASE)
    length = 8 * DELAY_BASE
    vectors = []
    expected = {}
    event = 0

    for index in range(length):
        dp1 = int(rng.integers(-32768, 32768))
        vector = {
            "dp1": dp1,
            "dp2": int(rng.integers(-32768, 32768)),
            "chn": index & 0xFF,
            "dv": 0,
            "sf": 0,
            "sl": 0,
            "sy": 0,
            "last": 0,
        }
        lane = index % DELAY_BASE
        epoch = index // DELAY_BASE
        if lane < 8:
            channel_base = 128 if DELAY_BASE == 128 and epoch & 1 else 0
            vector.update(
                chn=channel_base + lane,
                dv=1,
                sf=int(event == 0),
                sl=(event >> 0) & 1,
                sy=(event >> 1) & 1,
                last=(event >> 2) & 1,
            )
            if epoch < 4:
                expected[index + LATENCY] = (
                    unsigned16(dp1),
                    vector["sf"],
                    vector["sl"],
                    vector["sy"],
                    vector["chn"],
                    int(not (DELAY_BASE == 128 and channel_base == 128)),
                    vector["last"],
                )
            event += 1
        vectors.append(vector)

    allowed_dv = {
        epoch * DELAY_BASE + lane + LATENCY for epoch in range(8) for lane in range(8)
    }
    return vectors, expected, allowed_dv


async def _drive_and_check(dut, vectors, expected, allowed_dv):
    total_cycles = len(vectors) + LATENCY + 2
    for cycle in range(total_cycles):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")

        actual = _read_output(dut)
        if cycle in expected:
            assert actual == expected[cycle], (
                f"cycle {cycle}: HB output mismatch; "
                f"actual={actual}, expected={expected[cycle]}"
            )
        elif cycle not in allowed_dv:
            assert actual[5] == 0, f"cycle {cycle}: unexpected dout_dv"

        if cycle < len(vectors):
            _set_input(dut, **vectors[cycle])
        else:
            _set_input(dut)


@cocotb.test()
async def test_filter_and_bypass_are_bit_exact(dut):
    await _flush_unknown_state(dut)

    vectors, expected, allowed_dv = _make_filter_vectors()
    await _drive_and_check(dut, vectors, expected, allowed_dv)

    dut.rst.value = 1
    _set_input(dut)
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0
    dut.ctrl_bypass.value = 1
    await ClockCycles(dut.clk, 4)

    vectors, expected, allowed_dv = _make_bypass_vectors()
    await _drive_and_check(dut, vectors, expected, allowed_dv)


@pytest.mark.parametrize("delay_base", CASES)
def test_prach_hb4_runner(delay_base, monkeypatch):
    monkeypatch.setenv("PRACH_HB4_DELAY_BASE", str(delay_base))
    runner = get_runner(SIM)
    run_dir = PRJ_PATH / "sim_build" / f"prach_hb4_d{delay_base}"
    runner.build(
        hdl_toplevel="prach_hb4",
        sources=[
            REPO_PATH / "common" / "rtl" / "delay.sv",
            REPO_PATH / "cdc" / "rtl" / "cdc_single.sv",
            PRJ_PATH / "rtl" / "prach_hb4.sv",
        ],
        parameters={"DELAY_BASE": delay_base},
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="prach_hb4",
        hdl_toplevel_lang="verilog",
        test_module="test_prach_hb4",
        waves=True,
        gui=os.environ.get("GUI", "false").lower() == "true",
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
