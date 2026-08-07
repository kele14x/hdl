#!/usr/bin/env python3
import os
import shutil
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt
from hdl_tools.sim import assert_x_or_zero

prj_path = Path(__file__).resolve().parent.parent

ADDR_WIDTH_A = 4
DATA_WIDTH_A = 8
ADDR_WIDTH_B = 3
DATA_WIDTH_B = 16
DEPTH = 10
READ_LATENCY_A = 1
READ_LATENCY_B = 2
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

_simulator_binaries = {
    "questa": "vsim",
    "modelsim": "vsim",
    "verilator": "verilator",
    "icarus": "iverilog",
}
simulator_binary = _simulator_binaries.get(SIM.lower())
if simulator_binary and shutil.which(simulator_binary) is None:
    raise RuntimeError(
        f"SIM={SIM!r} was selected, but the required executable "
        f"{simulator_binary!r} is not available on PATH"
    )

GUI = os.environ.get("GUI", "false").lower() == "true"
USE_XPM = os.environ.get("RAM_TDP_ASYM_USE_XPM", "").lower() in {"1", "true", "yes"}
XPM_MEMORY_SV = os.environ.get("XPM_MEMORY_SV")

if USE_XPM:
    if not XPM_MEMORY_SV:
        raise RuntimeError(
            "RAM_TDP_ASYM_USE_XPM is enabled, but XPM_MEMORY_SV was not set to "
            "Vivado's installed xpm_memory.sv"
        )
    if not Path(XPM_MEMORY_SV).is_file():
        raise RuntimeError(f"XPM_MEMORY_SV does not name a file: {XPM_MEMORY_SV}")


@cocotb.test()
async def test_ram_tdp_asym_packs_narrow_writes_in_little_endian_word_order(dut):
    cocotb.start_soon(Clock(dut.clka, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clkb, 14, unit="ns").start())
    dut.rsta.value = 1
    dut.rstb.value = 1
    dut.ena.value = 0
    dut.enb.value = 0
    dut.wea.value = 0
    dut.web.value = 0
    dut.addra.value = 0
    dut.addrb.value = 0
    dut.dina.value = 0
    dut.dinb.value = 0
    await ClockCycles(dut.clkb, 2)
    dut.rstb.value = 0

    for address in range(DEPTH):
        await FallingEdge(dut.clka)
        dut.ena.value = 1
        dut.wea.value = 1
        dut.addra.value = address
        dut.dina.value = address
        await RisingEdge(dut.clka)
    dut.ena.value = 0
    dut.wea.value = 0

    # Reset only clears the final stage, so establish a known value in the
    # preceding stage before checking the pipelined output.
    dut.enb.value = 1
    dut.addrb.value = 0
    await ClockCycles(dut.clkb, 1)

    expected_pipeline = [1 << 8, 0]
    for address in (0, 3, 4, 1):
        expected_word = (2 * address + 1) << 8 | (2 * address)
        await FallingEdge(dut.clkb)
        dut.enb.value = (1 << READ_LATENCY_B) - 1
        dut.addrb.value = address
        await RisingEdge(dut.clkb)
        await ReadOnly()
        expected_pipeline = [expected_word, *expected_pipeline[:-1]]
        assert int(dut.doutb.value) == expected_pipeline[-1]

    await FallingEdge(dut.clkb)
    dut.enb.value = 0
    dut.addrb.value = 2
    held = int(dut.doutb.value)
    await ClockCycles(dut.clkb, 3)
    assert int(dut.doutb.value) == held

    await FallingEdge(dut.clkb)
    dut.enb.value = 1
    dut.web.value = 0
    dut.addrb.value = DEPTH // 2
    await RisingEdge(dut.clkb)
    await ReadOnly()
    await FallingEdge(dut.clkb)
    dut.enb.value = (1 << READ_LATENCY_B) - 1
    await RisingEdge(dut.clkb)
    await ReadOnly()
    assert_x_or_zero(SIM, dut.doutb.value)
    await FallingEdge(dut.clkb)
    dut.enb.value = 0
    dut.rstb.value = 1
    await RisingEdge(dut.clkb)
    await ReadOnly()
    assert int(dut.doutb.value) == 0


def test_ram_tdp_asym_runner():
    runner = get_runner(SIM)
    run_dir = prj_path / "sim_build" / "ram_tdp_asym"
    sources = list(resolve_flt(prj_path / "ram.flt"))
    defines = {}
    if USE_XPM:
        sources.insert(0, Path(XPM_MEMORY_SV))
        defines["RAM_USE_XPM"] = 1

    runner.build(
        hdl_toplevel="ram_tdp_asym",
        sources=sources,
        defines=defines,
        parameters={
            "ADDR_WIDTH_A": ADDR_WIDTH_A,
            "DATA_WIDTH_A": DATA_WIDTH_A,
            "ADDR_WIDTH_B": ADDR_WIDTH_B,
            "DATA_WIDTH_B": DATA_WIDTH_B,
            "READ_LATENCY_A": READ_LATENCY_A,
            "READ_LATENCY_B": READ_LATENCY_B,
            "DEPTH": DEPTH,
        },
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="ram_tdp_asym",
        hdl_toplevel_lang="verilog",
        test_module="test_ram_tdp_asym",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
