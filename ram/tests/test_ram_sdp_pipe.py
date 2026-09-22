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
READ_LATENCY = 3
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
USE_XPM = os.environ.get("RAM_SDP_PIPE_USE_XPM", "").lower() in {"1", "true", "yes"}
XPM_MEMORY_SV = os.environ.get("XPM_MEMORY_SV")

if USE_XPM:
    if not XPM_MEMORY_SV:
        raise RuntimeError(
            "RAM_SDP_PIPE_USE_XPM is enabled, but XPM_MEMORY_SV was not set to "
            "Vivado's installed xpm_memory.sv"
        )
    if not Path(XPM_MEMORY_SV).is_file():
        raise RuntimeError(f"XPM_MEMORY_SV does not name a file: {XPM_MEMORY_SV}")


@cocotb.test()
async def test_ram_sdp_pipe_scalar_enable_and_reset(dut):
    cocotb.start_soon(Clock(dut.clka, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clkb, 14, unit="ns").start())
    dut.wea.value = 0
    dut.addra.value = 0
    dut.dina.value = 0
    dut.rstb.value = 1
    dut.enb.value = 0
    dut.addrb.value = 0
    await ClockCycles(dut.clkb, 3)
    dut.rstb.value = 0

    memory = {address: 0x26 + address for address in range(DEPTH)}
    for address, data in memory.items():
        await RisingEdge(dut.clka)
        dut.wea.value = 1
        dut.addra.value = address
        dut.dina.value = data
    await RisingEdge(dut.clka)
    dut.wea.value = 0

    # Observe each read one edge after its registered latency.
    await RisingEdge(dut.clkb)
    addresses = [0, 3, 4, 1, 2, 0]
    for i, address in enumerate(addresses):
        dut.enb.value = 1
        dut.addrb.value = address
        await RisingEdge(dut.clkb)
        if i >= READ_LATENCY:
            assert int(dut.doutb.value) == memory[addresses[i - READ_LATENCY]]

    # Deasserting the scalar enable drains every pending result, then holds.
    dut.enb.value = 0
    for i in range(READ_LATENCY):
        await RisingEdge(dut.clkb)
        assert (
            int(dut.doutb.value) == memory[addresses[len(addresses) - READ_LATENCY + i]]
        )
    held = int(dut.doutb.value)
    assert held == memory[addresses[-1]]
    await ClockCycles(dut.clkb, 3)
    assert int(dut.doutb.value) == held

    # Observe reset one edge after it reaches the final stage through the control pipeline.
    dut.rstb.value = 1
    await RisingEdge(dut.clkb)
    dut.rstb.value = 0
    await ClockCycles(dut.clkb, READ_LATENCY)
    assert int(dut.doutb.value) == 0

    # The first reads after reset expose the cleared final stage, then valid
    # data once the enables propagate.
    resume = [4, 2, 0, 3]
    for i, address in enumerate(resume):
        dut.enb.value = 1
        dut.addrb.value = address
        await RisingEdge(dut.clkb)
        if i < READ_LATENCY:
            assert int(dut.doutb.value) == 0
        else:
            assert int(dut.doutb.value) == memory[resume[i - READ_LATENCY]]

    # Check the valid pipeline tail before the following out-of-range reads produce X.
    dut.addrb.value = DEPTH
    for i in range(READ_LATENCY):
        await RisingEdge(dut.clkb)
        assert int(dut.doutb.value) == memory[resume[len(resume) - READ_LATENCY + i]]
    dut.enb.value = 0
    await RisingEdge(dut.clkb)
    assert_x_or_zero(SIM, dut.doutb.value)

    dut.rstb.value = 1
    await RisingEdge(dut.clkb)
    dut.rstb.value = 0
    await ClockCycles(dut.clkb, READ_LATENCY)
    assert int(dut.doutb.value) == 0


def test_ram_sdp_pipe_runner():
    runner = get_runner(SIM)
    run_dir = prj_path / "sim_build" / "ram_sdp_pipe"
    sources = list(resolve_flt(prj_path / "ram.flt"))
    defines = {}
    if USE_XPM:
        sources.insert(0, Path(XPM_MEMORY_SV))
        defines["RAM_USE_XPM"] = 1

    runner.build(
        hdl_toplevel="ram_sdp_pipe",
        sources=sources,
        defines=defines,
        parameters={
            "ADDR_WIDTH": ADDR_WIDTH,
            "DATA_WIDTH": DATA_WIDTH,
            "DEPTH": DEPTH,
            "READ_LATENCY": READ_LATENCY,
        },
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="ram_sdp_pipe",
        hdl_toplevel_lang="verilog",
        test_module="test_ram_sdp_pipe",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
