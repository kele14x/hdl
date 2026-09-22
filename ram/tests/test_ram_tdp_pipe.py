#!/usr/bin/env python3
import os
import shutil
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
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
    dut.rsta.value = 0
    await ClockCycles(dut.clkb, 2)
    dut.rstb.value = 0

    # Write known values through port A.
    memory = {}
    for address in range(DEPTH):
        await RisingEdge(dut.clka)
        dut.ena.value = 1
        dut.wea.value = 1
        dut.addra.value = address
        dut.dina.value = 0x40 + address
        memory[address] = 0x40 + address
    await RisingEdge(dut.clka)
    dut.ena.value = 0
    dut.wea.value = 0

    async def read_burst(clk, en, addr, dout, latency, addresses):
        await RisingEdge(clk)
        for i, address in enumerate(addresses):
            en.value = 1
            addr.value = address
            await RisingEdge(clk)
            # Pre-update sampling adds one observation edge to RAM latency.
            if i >= latency:
                assert int(dout.value) == memory[addresses[i - latency]]
        en.value = 0
        # Check all trailing results while the scalar-enable pipeline drains.
        for i in range(latency):
            await RisingEdge(clk)
            assert int(dout.value) == memory[addresses[len(addresses) - latency + i]]

    # Port A reads back through its scalar-enable pipeline.
    addresses_a = [1, 4, 0, 3]
    await read_burst(
        dut.clka, dut.ena, dut.addra, dut.douta, READ_LATENCY_A, addresses_a
    )

    # Port B observes the same memory through its own pipeline.
    addresses_b = [2, 0, 4, 1]
    await read_burst(
        dut.clkb, dut.enb, dut.addrb, dut.doutb, READ_LATENCY_B, addresses_b
    )

    # Deasserting the scalar enable drains the pipeline and then holds it.
    held = int(dut.doutb.value)
    assert held == memory[addresses_b[-1]]
    await ClockCycles(dut.clkb, 3)
    assert int(dut.doutb.value) == held

    # A write through port B becomes visible to port A reads.
    dut.enb.value = 1
    dut.web.value = 1
    dut.addrb.value = 2
    dut.dinb.value = 0xC3
    await RisingEdge(dut.clkb)
    dut.enb.value = 0
    dut.web.value = 0
    memory[2] = 0xC3

    addresses_a2 = [2, 1]
    await read_burst(
        dut.clka, dut.ena, dut.addra, dut.douta, READ_LATENCY_A, addresses_a2
    )

    # Observe each reset after it reaches the final stage through the control pipeline.
    dut.rsta.value = 1
    await RisingEdge(dut.clka)
    dut.rsta.value = 0
    await ClockCycles(dut.clka, READ_LATENCY_A)
    assert int(dut.douta.value) == 0

    await RisingEdge(dut.clkb)
    dut.rstb.value = 1
    await RisingEdge(dut.clkb)
    dut.rstb.value = 0
    await ClockCycles(dut.clkb, READ_LATENCY_B)
    assert int(dut.doutb.value) == 0

    # Out-of-range reads are undefined: X on four-state simulators, zero on
    # two-state Verilator.
    dut.enb.value = 1
    dut.addrb.value = DEPTH
    await ClockCycles(dut.clkb, READ_LATENCY_B)
    dut.enb.value = 0
    await RisingEdge(dut.clkb)
    assert_x_or_zero(SIM, dut.doutb.value)

    dut.rstb.value = 1
    await RisingEdge(dut.clkb)
    dut.rstb.value = 0
    await ClockCycles(dut.clkb, READ_LATENCY_B)
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
