"""Bit-exact cocotb regression tests for the streaming PRACH 1536-point FFT."""

from __future__ import annotations

import os
import shutil
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner
from prach_fft_model import prach_fft_fixed

from hdl_tools.flt_tool import resolve_flt

PRJ_PATH = Path(__file__).resolve().parent.parent
FFT_SIZE = 1536

CASES = [
    pytest.param("low-level", 0xF17, id="low-level"),
    pytest.param("full-range", 0xC0C07B, id="full-range"),
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

_VECTOR_MODE = os.environ.get("PRACH_FFT_VECTOR_MODE", "low-level")
_VECTOR_SEED = int(os.environ.get("PRACH_FFT_SEED", "0xF17"), 0)


def _make_input(seed: int, amplitude: int) -> tuple[np.ndarray, np.ndarray]:
    """Generate one natural-order I/Q block within +/- amplitude."""
    rng = np.random.default_rng(seed)
    real = rng.integers(-amplitude, amplitude + 1, size=FFT_SIZE, dtype=np.int64)
    imag = rng.integers(-amplitude, amplitude + 1, size=FFT_SIZE, dtype=np.int64)
    return real, imag


def _s16(value: int) -> int:
    value &= 0xFFFF
    return value - (1 << 16) if value >= (1 << 15) else value


@cocotb.test()
async def test_prach_fft_matches_fixed_model(dut):
    """Stream one 1536-sample block and compare bit-exactly with the model."""

    if _VECTOR_MODE == "full-range":
        amplitude = 1 << 15
    else:
        amplitude = 64
    real, imag = _make_input(_VECTOR_SEED, amplitude)
    expected_r, expected_i = prach_fft_fixed(real, imag, PRJ_PATH / "rtl")

    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    dut.rst.value = 1
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_dv.value = 0
    dut.din_sf.value = 0
    dut.din_sl.value = 0
    dut.din_sy.value = 0
    dut.din_chn.value = 0
    dut.din_last.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 2)

    outputs: list[tuple[int, int]] = []
    last_samples: list[int] = []
    sy_samples: list[int] = []

    for index in range(FFT_SIZE):
        await RisingEdge(dut.clk)
        dut.din_dr.value = int(real[index]) & 0xFFFF
        dut.din_di.value = int(imag[index]) & 0xFFFF
        dut.din_dv.value = 1
        dut.din_sy.value = int(index == 0)
        dut.din_last.value = int(index == FFT_SIZE - 1)
        if int(dut.dout_dv.value):
            outputs.append((_s16(int(dut.dout_dr.value)), _s16(int(dut.dout_di.value))))
        if int(dut.dout_last.value):
            last_samples.append(len(outputs))
        if int(dut.dout_sy.value):
            sy_samples.append(len(outputs))
    await RisingEdge(dut.clk)
    dut.din_dv.value = 0
    dut.din_sy.value = 0
    dut.din_last.value = 0

    for _ in range(FFT_SIZE + 2000):
        await RisingEdge(dut.clk)
        if int(dut.dout_dv.value):
            outputs.append((_s16(int(dut.dout_dr.value)), _s16(int(dut.dout_di.value))))
        if int(dut.dout_last.value):
            last_samples.append(len(outputs))
        if int(dut.dout_sy.value):
            sy_samples.append(len(outputs))
        if len(outputs) >= FFT_SIZE:
            break

    assert len(outputs) == FFT_SIZE, (
        f"expected {FFT_SIZE} output samples, got {len(outputs)}"
    )
    assert sy_samples == [1], f"dout_sy expected on the first sample, got {sy_samples}"
    assert last_samples == [FFT_SIZE], (
        f"dout_last expected on the last sample, got {last_samples}"
    )

    mismatches = [
        (index, got, (int(expected_r[index]), int(expected_i[index])))
        for index, got in enumerate(outputs)
        if got != (int(expected_r[index]), int(expected_i[index]))
    ]
    assert not mismatches, (
        f"{len(mismatches)} output samples differ from the fixed-point model; "
        f"first at index {mismatches[0][0]}: got {mismatches[0][1]}, "
        f"expected {mismatches[0][2]}"
    )


@pytest.mark.parametrize(("vector_mode", "seed"), CASES)
def test_prach_fft_runner(vector_mode, seed, monkeypatch):
    monkeypatch.setenv("PRACH_FFT_VECTOR_MODE", vector_mode)
    monkeypatch.setenv("PRACH_FFT_SEED", f"0x{seed:X}")
    runner = get_runner(SIM)
    run_dir = PRJ_PATH / "sim_build" / f"prach_fft_{vector_mode}"
    runner.build(
        hdl_toplevel="prach_fft",
        sources=resolve_flt(PRJ_PATH / "prach.flt"),
        parameters={"FFT_SIZE": FFT_SIZE, "DATA_WIDTH": 16},
        build_args=["-suppress", "2892"] if SIM == "questa" else [],
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    # The twiddle ROMs are loaded with $readmemh relative to the simulator
    # working directory, which is the test directory.
    for mem in (PRJ_PATH / "rtl").glob("prach_fft_*.mem"):
        shutil.copy(mem, run_dir)
    runner.test(
        hdl_toplevel="prach_fft",
        hdl_toplevel_lang="verilog",
        test_module="test_prach_fft",
        test_args=["-suppress", "7061"] if SIM == "questa" else [],
        waves=True,
        gui=os.environ.get("GUI", "false").lower() == "true",
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
