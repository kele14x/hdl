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

prj_path = Path(__file__).resolve().parent.parent

ADDR_WIDTH_A = 4
DATA_WIDTH_A = 8
ADDR_WIDTH_B = 3
DATA_WIDTH_B = 16
DEPTH = 10
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
USE_XPM = os.environ.get("RAM_SDP_ASYM_USE_XPM", "").lower() in {"1", "true", "yes"}
XPM_MEMORY_SV = os.environ.get("XPM_MEMORY_SV")

if USE_XPM:
    if not XPM_MEMORY_SV:
        raise RuntimeError(
            "RAM_SDP_ASYM_USE_XPM is enabled, but XPM_MEMORY_SV was not set to "
            "Vivado's installed xpm_memory.sv"
        )
    if not Path(XPM_MEMORY_SV).is_file():
        raise RuntimeError(f"XPM_MEMORY_SV does not name a file: {XPM_MEMORY_SV}")


@cocotb.test()
async def test_ram_sdp_asym_packs_narrow_writes_in_little_endian_word_order(dut):
    cocotb.start_soon(Clock(dut.clka, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clkb, 14, unit="ns").start())
    dut.wea.value = 0
    dut.addra.value = 0
    dut.dina.value = 0
    dut.rstb.value = 1
    dut.enb.value = 0
    dut.addrb.value = 0
    await ClockCycles(dut.clkb, 2)
    dut.rstb.value = 0

    for address in range(DEPTH):
        await FallingEdge(dut.clka)
        dut.wea.value = 1
        dut.addra.value = address
        dut.dina.value = address
        await RisingEdge(dut.clka)
    dut.wea.value = 0

    # Reset only clears the final stage, so establish a known value in the
    # preceding stage before checking the pipelined output.
    dut.enb.value = 1
    dut.addrb.value = 0
    await ClockCycles(dut.clkb, 1)

    expected_pipeline = [0, 0]
    expected_pipeline[0] = 1 << 8
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

    # The first unused wide-port address is out of range and reads as X.
    await FallingEdge(dut.clkb)
    dut.enb.value = 1
    dut.addrb.value = DEPTH // 2
    await RisingEdge(dut.clkb)
    await ReadOnly()
    await FallingEdge(dut.clkb)
    dut.enb.value = (1 << READ_LATENCY_B) - 1
    await RisingEdge(dut.clkb)
    await ReadOnly()
    assert not dut.doutb.value.is_resolvable

    await FallingEdge(dut.clkb)
    dut.rstb.value = 1
    dut.enb.value = 0
    await RisingEdge(dut.clkb)
    await ReadOnly()
    assert int(dut.doutb.value) == 0


def test_ram_sdp_asym_runner():
    runner = get_runner(SIM)
    sources = list(resolve_flt(prj_path / "ram.flt"))
    defines = {}
    if USE_XPM:
        sources.insert(0, Path(XPM_MEMORY_SV))
        defines["RAM_USE_XPM"] = 1

    runner.build(
        hdl_toplevel="ram_sdp_asym",
        sources=sources,
        defines=defines,
        parameters={
            "ADDR_WIDTH_A": ADDR_WIDTH_A,
            "DATA_WIDTH_A": DATA_WIDTH_A,
            "ADDR_WIDTH_B": ADDR_WIDTH_B,
            "DATA_WIDTH_B": DATA_WIDTH_B,
            "DEPTH": DEPTH,
            "READ_LATENCY_B": READ_LATENCY_B,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="ram_sdp_asym",
        hdl_toplevel_lang="verilog",
        test_module="test_ram_sdp_asym",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
