#!/usr/bin/env python3
import os
import shutil
import tempfile
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

from common.tb.memory import MemoryAgent, MemoryAgentConfig, MemoryPortBus
from tools.flt_tool import resolve_flt

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
USE_XPM = os.environ.get("RAM_SDP_USE_XPM", "").lower() in {"1", "true", "yes"}
XPM_MEMORY_SV = os.environ.get("XPM_MEMORY_SV")

if USE_XPM:
    if not XPM_MEMORY_SV:
        raise RuntimeError(
            "RAM_SDP_USE_XPM is enabled, but XPM_MEMORY_SV was not set to "
            "Vivado's installed xpm_memory.sv"
        )
    if not Path(XPM_MEMORY_SV).is_file():
        raise RuntimeError(f"XPM_MEMORY_SV does not name a file: {XPM_MEMORY_SV}")


@cocotb.test()
async def test_ram_sdp_write_read_latency_and_read_enable_hold(dut):
    cocotb.start_soon(Clock(dut.clka, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clkb, 10, unit="ns").start())
    dut.ena.value = 0
    dut.wea.value = 0
    dut.addra.value = 0
    dut.dina.value = 0
    dut.rstb.value = 1
    dut.enb.value = 0
    dut.addrb.value = 0
    await ClockCycles(dut.clka, 3)
    dut.rstb.value = 0

    writer = MemoryAgent(
        MemoryPortBus(
            clock=dut.clka,
            enable=dut.ena,
            address=dut.addra,
            write_enable=dut.wea,
            write_data=dut.dina,
        )
    )
    reader = MemoryAgent(
        MemoryPortBus(
            clock=dut.clkb,
            enable=dut.enb,
            address=dut.addrb,
            read_data=dut.doutb,
        ),
        MemoryAgentConfig(read_latency=READ_LATENCY),
    )
    await writer.start()
    await reader.start()

    memory = {0: 0x26, 2: 0x7D, 4: 0xA4}
    await writer.write_burst(memory.items())

    addresses = [0, 4, 2, 0, 4, 2]
    actual = await reader.read_burst(addresses)
    assert actual == [memory[address] for address in addresses]
    assert [transaction.address for transaction in writer.monitor.observed] == list(
        memory
    )
    assert [response.request.address for response in reader.monitor.read_responses] == (
        addresses
    )

    held = int(dut.doutb.value)
    await ClockCycles(dut.clkb, 3)
    assert int(dut.doutb.value) == held

    reader.stop()
    writer.stop()

    # Out-of-range accesses are undefined: writes have no effect and reads
    # propagate X through the read pipeline in the behavioral model/XPM.
    dut.enb.value = 1
    dut.addrb.value = DEPTH
    await ClockCycles(dut.clkb, 1)
    dut.enb.value = (1 << READ_LATENCY) - 1
    for _ in range(READ_LATENCY):
        await ClockCycles(dut.clkb, 1)
    await ReadOnly()
    assert not dut.doutb.value.is_resolvable

    # The scalar reset always clears the externally visible stage.
    await FallingEdge(dut.clkb)
    dut.enb.value = 0
    dut.rstb.value = 1
    await RisingEdge(dut.clkb)
    await ReadOnly()
    assert int(dut.doutb.value) == 0


def test_ram_sdp_runner():
    runner = get_runner(SIM)
    with tempfile.TemporaryDirectory(prefix="ram_sdp_") as run_dir:
        sources = list(resolve_flt(prj_path / "ram.flt"))
        defines = {}
        if USE_XPM:
            sources.insert(0, Path(XPM_MEMORY_SV))
            defines["RAM_USE_XPM"] = 1

        runner.build(
            hdl_toplevel="ram_sdp",
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
            hdl_toplevel="ram_sdp",
            hdl_toplevel_lang="verilog",
            test_module="test_ram_sdp",
            waves=True,
            gui=GUI,
            test_dir=run_dir,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
