import os
import shutil
import tempfile
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

ADDR_WIDTH = 3
DATA_WIDTH = 8
READ_LATENCY_A = 2
READ_LATENCY_B = 1
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
USE_XPM = os.environ.get("RAM_TDP_USE_XPM", "").lower() in {"1", "true", "yes"}
XPM_MEMORY_SV = os.environ.get("XPM_MEMORY_SV")

if USE_XPM:
    if not XPM_MEMORY_SV:
        raise RuntimeError(
            "RAM_TDP_USE_XPM is enabled, but XPM_MEMORY_SV was not set to "
            "Vivado's installed xpm_memory.sv"
        )
    if not Path(XPM_MEMORY_SV).is_file():
        raise RuntimeError(f"XPM_MEMORY_SV does not name a file: {XPM_MEMORY_SV}")


async def cycle_a(dut, address, data, write, enable):
    await FallingEdge(dut.clka)
    dut.addra.value = address
    dut.dina.value = data
    dut.wea.value = write
    dut.ena.value = (1 << READ_LATENCY_A) - 1 if enable else 0
    await RisingEdge(dut.clka)
    await ReadOnly()
    return int(dut.douta.value)


async def cycle_b(dut, address, data, write, enable):
    await FallingEdge(dut.clkb)
    dut.addrb.value = address
    dut.dinb.value = data
    dut.web.value = write
    dut.enb.value = (1 << READ_LATENCY_B) - 1 if enable else 0
    await RisingEdge(dut.clkb)
    await ReadOnly()
    return int(dut.doutb.value)


@cocotb.test()
async def test_ram_tdp_applies_independent_port_write_modes(dut):
    cocotb.start_soon(Clock(dut.clka, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clkb, 14, unit="ns").start())
    dut.rsta.value = (1 << READ_LATENCY_A) - 1
    dut.rstb.value = (1 << READ_LATENCY_B) - 1
    dut.ena.value = 0
    dut.enb.value = 0
    dut.wea.value = 0
    dut.web.value = 0
    dut.addra.value = 0
    dut.addrb.value = 0
    dut.dina.value = 0
    dut.dinb.value = 0
    await ClockCycles(dut.clka, 2)
    await ClockCycles(dut.clkb, 2)
    dut.rsta.value = 0
    dut.rstb.value = 0

    # Port A is WRITE_FIRST and has a two-stage read pipeline.
    assert await cycle_a(dut, 2, 0x11, 1, 1) == 0
    assert await cycle_a(dut, 2, 0, 0, 1) == 0x11
    assert await cycle_a(dut, 0, 0, 0, 1) == 0x11

    # Port B reads the shared memory.  It is NO_CHANGE, so a write collision
    # preserves the previously read output, while the write itself is stored.
    assert await cycle_b(dut, 2, 0, 0, 1) == 0x11
    assert await cycle_b(dut, 2, 0xC3, 1, 1) == 0x11
    assert await cycle_b(dut, 2, 0, 0, 1) == 0xC3

    held = int(dut.doutb.value)
    for _ in range(2):
        assert await cycle_b(dut, 2, 0, 0, 0) == held


def test_ram_tdp_runner():
    runner = get_runner(SIM)
    with tempfile.TemporaryDirectory(prefix="ram_tdp_") as run_dir:
        sources = list(resolve_flt(prj_path / "ram.flt"))
        defines = {}
        if USE_XPM:
            sources.insert(0, Path(XPM_MEMORY_SV))
            defines["RAM_USE_XPM"] = 1

        runner.build(
            hdl_toplevel="ram_tdp",
            sources=sources,
            defines=defines,
            parameters={
                "ADDR_WIDTH": ADDR_WIDTH,
                "DATA_WIDTH": DATA_WIDTH,
                "WRITE_MODE_A": "WRITE_FIRST",
                "WRITE_MODE_B": "NO_CHANGE",
                "READ_LATENCY_A": READ_LATENCY_A,
                "READ_LATENCY_B": READ_LATENCY_B,
            },
            always=True,
            waves=True,
            build_dir=run_dir,
        )
        runner.test(
            hdl_toplevel="ram_tdp",
            hdl_toplevel_lang="verilog",
            test_module="test_ram_tdp",
            waves=True,
            gui=GUI,
            test_dir=run_dir,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
