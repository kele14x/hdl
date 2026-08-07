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

ADDR_WIDTH = 3
DATA_WIDTH = 8
DEPTH = 5
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
USE_XPM = os.environ.get("RAM_SP_PIPE_USE_XPM", "").lower() in {"1", "true", "yes"}
XPM_MEMORY_SV = os.environ.get("XPM_MEMORY_SV")

if USE_XPM:
    if not XPM_MEMORY_SV:
        raise RuntimeError(
            "RAM_SP_PIPE_USE_XPM is enabled, but XPM_MEMORY_SV was not set to "
            "Vivado's installed xpm_memory.sv"
        )
    if not Path(XPM_MEMORY_SV).is_file():
        raise RuntimeError(f"XPM_MEMORY_SV does not name a file: {XPM_MEMORY_SV}")

CASES = [
    {"name": f"latency_{read_latency}", "read_latency": read_latency}
    for read_latency in (1, 2, 3)
]


@cocotb.test()
async def test_ram_sp_pipe_scalar_enable_and_reset(dut):
    read_latency = int(os.environ["RAM_SP_PIPE_READ_LATENCY"])
    depth = int(os.environ["RAM_SP_PIPE_DEPTH"])
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.en.value = 0
    dut.we.value = 0
    dut.addr.value = 0
    dut.din.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    memory = {}
    for address in range(depth):
        await FallingEdge(dut.clk)
        dut.en.value = 1
        dut.we.value = 1
        dut.addr.value = address
        dut.din.value = 0x10 + address
        await RisingEdge(dut.clk)
        memory[address] = 0x10 + address
    await FallingEdge(dut.clk)
    dut.en.value = 0
    dut.we.value = 0
    await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, read_latency)

    # Back-to-back reads with the scalar enable appear one per cycle once the
    # control pipeline is full.
    addresses = [1, 4, 3, 0, 2, 1]
    for i, address in enumerate(addresses):
        await FallingEdge(dut.clk)
        dut.en.value = 1
        dut.addr.value = address
        await RisingEdge(dut.clk)
        await ReadOnly()
        if i >= read_latency - 1:
            assert int(dut.dout.value) == memory[addresses[i - (read_latency - 1)]]

    # Deasserting the scalar enable drains the pipeline and then holds it.
    await FallingEdge(dut.clk)
    dut.en.value = 0
    await ClockCycles(dut.clk, read_latency)
    await ReadOnly()
    held = int(dut.dout.value)
    assert held == memory[addresses[-1]]
    await ClockCycles(dut.clk, 3)
    await ReadOnly()
    assert int(dut.dout.value) == held

    # Reset travels through the control pipeline before clearing the visible
    # output stage.
    await FallingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.rst.value = 0
    await ClockCycles(dut.clk, read_latency)
    await ReadOnly()
    assert int(dut.dout.value) == 0

    # The first reads after reset expose the cleared final stage, then valid
    # data once the enables propagate.
    resume = [4, 2, 1]
    for i, address in enumerate(resume):
        await FallingEdge(dut.clk)
        dut.en.value = 1
        dut.addr.value = address
        await RisingEdge(dut.clk)
        await ReadOnly()
        if i < read_latency - 1:
            assert int(dut.dout.value) == 0
        else:
            assert int(dut.dout.value) == memory[resume[i - (read_latency - 1)]]

    # Out-of-range reads are undefined: X on four-state simulators, zero on
    # two-state Verilator.
    await FallingEdge(dut.clk)
    dut.addr.value = depth
    await RisingEdge(dut.clk)
    await ReadOnly()
    for _ in range(read_latency - 1):
        await FallingEdge(dut.clk)
        await RisingEdge(dut.clk)
        await ReadOnly()
    assert_x_or_zero(SIM, dut.dout.value)

    await FallingEdge(dut.clk)
    dut.en.value = 0
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.rst.value = 0
    await ClockCycles(dut.clk, read_latency)
    await ReadOnly()
    assert int(dut.dout.value) == 0


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_ram_sp_pipe_runner(case):
    runner = get_runner(SIM)
    sources = list(resolve_flt(prj_path / "ram.flt"))
    defines = {}
    if USE_XPM:
        sources.insert(0, Path(XPM_MEMORY_SV))
        defines["RAM_USE_XPM"] = 1

    build_dir = prj_path / "sim_build" / f"ram_sp_pipe_{case['name']}"
    runner.build(
        hdl_toplevel="ram_sp_pipe",
        sources=sources,
        defines=defines,
        parameters={
            "ADDR_WIDTH": ADDR_WIDTH,
            "DATA_WIDTH": DATA_WIDTH,
            "READ_LATENCY": case["read_latency"],
            "DEPTH": DEPTH,
        },
        always=True,
        build_dir=build_dir,
        waves=GUI,
    )
    runner.test(
        hdl_toplevel="ram_sp_pipe",
        hdl_toplevel_lang="verilog",
        test_module="test_ram_sp_pipe",
        extra_env={
            "RAM_SP_PIPE_READ_LATENCY": str(case["read_latency"]),
            "RAM_SP_PIPE_DEPTH": str(DEPTH),
        },
        waves=GUI,
        gui=GUI,
        build_dir=build_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
