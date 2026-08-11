import os
from collections import deque
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

WIDTH = 36
DEPTH = 8192
OUTPUT_DELAY = DEPTH + 1
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"
USE_XPM = os.environ.get("SHIFT_RAM_USE_XPM", "").lower() in {"1", "true", "yes"}
XPM_MEMORY_SV = os.environ.get("XPM_MEMORY_SV")

if USE_XPM:
    if not XPM_MEMORY_SV:
        raise RuntimeError(
            "SHIFT_RAM_USE_XPM is enabled, but XPM_MEMORY_SV was not set"
        )
    if not Path(XPM_MEMORY_SV).is_file():
        raise RuntimeError(f"XPM_MEMORY_SV does not name a file: {XPM_MEMORY_SV}")


def sample_value(index):
    return ((index * 0x12345) ^ (index << 25) ^ 0x155555555) & ((1 << WIDTH) - 1)


@cocotb.test()
async def test_shift_ram_packed_uram_full_address_range_and_hold(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.cen.value = 1
    dut.din.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    # Run through the logical memory twice. This checks both halves of every
    # physical 72-bit word after the first complete 8192-sample delay.
    expected = deque([0] * OUTPUT_DELAY)
    for index in range(1, 2 * DEPTH + 33):
        value = sample_value(index)
        await RisingEdge(dut.clk)
        dut.cen.value = 1
        dut.din.value = value
        assert int(dut.dout.value) == expected.popleft()
        expected.append(value)

    # The packed read word and its half-select pipeline must freeze together.
    await RisingEdge(dut.clk)
    dut.cen.value = 0
    dut.din.value = 0
    assert int(dut.dout.value) == expected.popleft()

    await RisingEdge(dut.clk)
    held = int(dut.dout.value)
    assert held == expected.popleft()

    for _ in range(3):
        await RisingEdge(dut.clk)
        assert int(dut.dout.value) == held


@cocotb.test()
async def test_shift_ram_packed_uram_matches_standard_with_clock_enable(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.cen.value = 1
    dut.din.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    for index in range(1, 2 * DEPTH + 257):
        await RisingEdge(dut.clk)
        assert int(dut.dout_packed.value) == int(dut.dout_standard.value)
        dut.cen.value = index % 11 not in {4, 5, 9}
        dut.din.value = sample_value(index)


def test_shift_ram_packed_uram_runner():
    runner = get_runner(SIM)
    run_dir = (
        prj_path
        / "sim_build"
        / ("shift_ram_packed_uram_xpm" if USE_XPM else "shift_ram_packed_uram")
    )
    sources = list(resolve_flt(prj_path / "shift_ram.flt"))
    defines = {}
    if USE_XPM:
        sources.insert(0, Path(XPM_MEMORY_SV))
        defines["RAM_USE_XPM"] = 1

    runner.build(
        hdl_toplevel="shift_ram",
        sources=sources,
        defines=defines,
        parameters={
            "WIDTH": WIDTH,
            "DEPTH": DEPTH,
            "INPUT_REG": 1,
            "PACKED_URAM": 1,
        },
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="shift_ram",
        hdl_toplevel_lang="verilog",
        test_module="test_shift_ram_packed_uram",
        testcase="test_shift_ram_packed_uram_full_address_range_and_hold",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
    )


def test_shift_ram_packed_compare_runner():
    runner = get_runner(SIM)
    run_dir = prj_path / "sim_build" / "shift_ram_packed_compare"
    sources = list(resolve_flt(prj_path / "shift_ram.flt"))
    sources.append(prj_path / "tb" / "shift_ram_packed_compare.sv")
    runner.build(
        hdl_toplevel="shift_ram_packed_compare",
        sources=sources,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="shift_ram_packed_compare",
        hdl_toplevel_lang="verilog",
        test_module="test_shift_ram_packed_uram",
        testcase="test_shift_ram_packed_uram_matches_standard_with_clock_enable",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
