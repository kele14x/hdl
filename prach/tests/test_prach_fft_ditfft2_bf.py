#!/usr/bin/env python3
"""Focused overflow tests for the radix-2 PRACH FFT butterfly."""

from __future__ import annotations

import os
import shutil
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

PRJ_PATH = Path(__file__).resolve().parent.parent
FFT_SIZE = 4
DATA_WIDTH = 18

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


@cocotb.test()
async def test_subtraction_only_overflow_is_reported(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    dut.rst.value = 1
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_dv.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    maximum = (1 << (DATA_WIDTH - 1)) - 1
    vectors = [maximum, 0, -1, 0]
    observed_overflow = []

    for real in vectors:
        await RisingEdge(dut.clk)
        dut.din_dr.value = real & ((1 << DATA_WIDTH) - 1)
        dut.din_di.value = 0
        dut.din_dv.value = 1
        observed_overflow.append(str(dut.ovf.value) == "1")

    await RisingEdge(dut.clk)
    dut.din_dv.value = 0
    observed_overflow.append(str(dut.ovf.value) == "1")
    await RisingEdge(dut.clk)
    observed_overflow.append(str(dut.ovf.value) == "1")

    assert any(observed_overflow), (
        "131071 - (-1) overflows 18 bits while 131071 + (-1) does not"
    )


def test_prach_fft_ditfft2_bf_runner():
    runner = get_runner(SIM)
    run_dir = PRJ_PATH / "sim_build" / "prach_fft_ditfft2_bf"
    runner.build(
        hdl_toplevel="prach_fft_ditfft2_bf",
        sources=resolve_flt(PRJ_PATH / "prach.flt"),
        parameters={"FFT_SIZE": FFT_SIZE, "DATA_WIDTH": DATA_WIDTH},
        build_args=["-suppress", "2892"] if SIM == "questa" else [],
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="prach_fft_ditfft2_bf",
        hdl_toplevel_lang="verilog",
        test_module="test_prach_fft_ditfft2_bf",
        test_args=["-suppress", "7061"] if SIM == "questa" else [],
        waves=True,
        gui=os.environ.get("GUI", "false").lower() == "true",
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
