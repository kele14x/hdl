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
READ_LATENCY_A = 2
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
USE_XPM = os.environ.get("RAM_TDP_PIPE_USE_XPM", "").lower() in {"1", "true", "yes"}
XPM_MEMORY_SV = os.environ.get("XPM_MEMORY_SV")

if USE_XPM:
    if not XPM_MEMORY_SV:
        raise RuntimeError(
            "RAM_TDP_PIPE_USE_XPM is enabled, but XPM_MEMORY_SV was not set to "
            "Vivado's installed xpm_memory.sv"
        )
    if not Path(XPM_MEMORY_SV).is_file():
        raise RuntimeError(f"XPM_MEMORY_SV does not name a file: {XPM_MEMORY_SV}")


@cocotb.test()
async def test_ram_tdp_pipe_scalar_enables_and_resets(dut):
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
    await ClockCycles(dut.clka, 2)
    await ClockCycles(dut.clkb, 2)
    dut.rsta.value = 0
    dut.rstb.value = 0

    # Write known values through port A.
    memory = {}
    for address in range(DEPTH):
        await FallingEdge(dut.clka)
        dut.ena.value = 1
        dut.wea.value = 1
        dut.addra.value = address
        dut.dina.value = 0x40 + address
        await RisingEdge(dut.clka)
        memory[address] = 0x40 + address
    await FallingEdge(dut.clka)
    dut.ena.value = 0
    dut.wea.value = 0

    # Port A reads back through its scalar-enable pipeline.
    addresses_a = [1, 4, 0, 3]
    for i, address in enumerate(addresses_a):
        await FallingEdge(dut.clka)
        dut.ena.value = 1
        dut.addra.value = address
        await RisingEdge(dut.clka)
        await ReadOnly()
        if i >= READ_LATENCY_A - 1:
            assert int(dut.douta.value) == memory[addresses_a[i - (READ_LATENCY_A - 1)]]
    await FallingEdge(dut.clka)
    dut.ena.value = 0

    # Port B observes the same memory through its own pipeline.
    addresses_b = [2, 0, 4, 1]
    for i, address in enumerate(addresses_b):
        await FallingEdge(dut.clkb)
        dut.enb.value = 1
        dut.addrb.value = address
        await RisingEdge(dut.clkb)
        await ReadOnly()
        if i >= READ_LATENCY_B - 1:
            assert int(dut.doutb.value) == memory[addresses_b[i - (READ_LATENCY_B - 1)]]

    # Deasserting the scalar enable drains the pipeline and then holds it.
    await FallingEdge(dut.clkb)
    dut.enb.value = 0
    await ClockCycles(dut.clkb, READ_LATENCY_B)
    await ReadOnly()
    held = int(dut.doutb.value)
    assert held == memory[addresses_b[-1]]
    await ClockCycles(dut.clkb, 3)
    await ReadOnly()
    assert int(dut.doutb.value) == held

    # A write through port B becomes visible to port A reads.
    await FallingEdge(dut.clkb)
    dut.enb.value = 1
    dut.web.value = 1
    dut.addrb.value = 2
    dut.dinb.value = 0xC3
    await RisingEdge(dut.clkb)
    await FallingEdge(dut.clkb)
    dut.enb.value = 0
    dut.web.value = 0
    memory[2] = 0xC3

    addresses_a2 = [2, 1]
    for i, address in enumerate(addresses_a2):
        await FallingEdge(dut.clka)
        dut.ena.value = 1
        dut.addra.value = address
        await RisingEdge(dut.clka)
        await ReadOnly()
        if i >= READ_LATENCY_A - 1:
            assert (
                int(dut.douta.value) == memory[addresses_a2[i - (READ_LATENCY_A - 1)]]
            )
    await FallingEdge(dut.clka)
    dut.ena.value = 0

    # Each reset travels through its control pipeline before clearing the
    # visible output stage of its port.
    await FallingEdge(dut.clka)
    dut.rsta.value = 1
    await RisingEdge(dut.clka)
    await FallingEdge(dut.clka)
    dut.rsta.value = 0
    await ClockCycles(dut.clka, READ_LATENCY_A)
    await ReadOnly()
    assert int(dut.douta.value) == 0

    await FallingEdge(dut.clkb)
    dut.rstb.value = 1
    await RisingEdge(dut.clkb)
    await FallingEdge(dut.clkb)
    dut.rstb.value = 0
    await ClockCycles(dut.clkb, READ_LATENCY_B)
    await ReadOnly()
    assert int(dut.doutb.value) == 0

    # Out-of-range reads are undefined: X on four-state simulators, zero on
    # two-state Verilator.
    await FallingEdge(dut.clkb)
    dut.enb.value = 1
    dut.addrb.value = DEPTH
    await RisingEdge(dut.clkb)
    await ReadOnly()
    for _ in range(READ_LATENCY_B - 1):
        await FallingEdge(dut.clkb)
        await RisingEdge(dut.clkb)
        await ReadOnly()
    assert_x_or_zero(SIM, dut.doutb.value)

    await FallingEdge(dut.clkb)
    dut.enb.value = 0
    dut.rstb.value = 1
    await RisingEdge(dut.clkb)
    await FallingEdge(dut.clkb)
    dut.rstb.value = 0
    await ClockCycles(dut.clkb, READ_LATENCY_B)
    await ReadOnly()
    assert int(dut.doutb.value) == 0


def test_ram_tdp_pipe_runner():
    runner = get_runner(SIM)
    run_dir = prj_path / "sim_build" / "ram_tdp_pipe"
    sources = list(resolve_flt(prj_path / "ram.flt"))
    defines = {}
    if USE_XPM:
        sources.insert(0, Path(XPM_MEMORY_SV))
        defines["RAM_USE_XPM"] = 1

    runner.build(
        hdl_toplevel="ram_tdp_pipe",
        sources=sources,
        defines=defines,
        parameters={
            "ADDR_WIDTH": ADDR_WIDTH,
            "DATA_WIDTH": DATA_WIDTH,
            "READ_LATENCY_A": READ_LATENCY_A,
            "READ_LATENCY_B": READ_LATENCY_B,
            "DEPTH": DEPTH,
        },
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="ram_tdp_pipe",
        hdl_toplevel_lang="verilog",
        test_module="test_ram_tdp_pipe",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
