#!/usr/bin/env python3
import os
import random
import shutil
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

DEPTH = 8192
DATA_WIDTH = 36
DATA_MASK = (1 << DATA_WIDTH) - 1

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
USE_XPM = os.environ.get("RAM_SP_URAM_8K36_USE_XPM", "").lower() in {
    "1",
    "true",
    "yes",
}
XPM_MEMORY_SV = os.environ.get("XPM_MEMORY_SV")

if USE_XPM:
    if not XPM_MEMORY_SV:
        raise RuntimeError(
            "RAM_SP_URAM_8K36_USE_XPM is enabled, but XPM_MEMORY_SV was not "
            "set to Vivado's installed xpm_memory.sv"
        )
    if not Path(XPM_MEMORY_SV).is_file():
        raise RuntimeError(f"XPM_MEMORY_SV does not name a file: {XPM_MEMORY_SV}")


async def cycle(dut, address, data=0, write=0, enable=0b11):
    dut.addr.value = address
    dut.din.value = data
    dut.we.value = write
    dut.en.value = enable
    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")
    return dut.dout.value


@cocotb.test()
async def test_ram_sp_uram_8k36_read_first_packing_and_enables(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.en.value = 0
    dut.we.value = 0
    dut.addr.value = 0
    dut.din.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")

    memory = [0] * DEPTH
    read_pipeline = [0, 0]

    def advance_model(address, data, write, enable):
        old_first_stage = read_pipeline[0]

        if enable & 0b01:
            # Capture the old word before applying a write: READ_FIRST mode.
            read_pipeline[0] = memory[address]
            if write:
                memory[address] = data & DATA_MASK

        if enable & 0b10:
            read_pipeline[1] = old_first_stage

        return read_pipeline[1]

    async def check_cycle(address, data=0, write=0, enable=0b11, check=True):
        expected = advance_model(address, data, write, enable)
        actual = await cycle(dut, address, data, write, enable)
        if check:
            assert int(actual) == expected, (
                address,
                data,
                write,
                enable,
                expected,
                int(actual),
            )

    # Flush unknown power-up values from the two read stages.
    await check_cycle(0, check=False)
    await check_cycle(0)

    # Each adjacent logical-address pair shares one physical 72-bit URAM word.
    # Include both ends of the address range to catch packing and address bugs.
    packed_writes = (
        (0, 0x012345678),
        (1, 0x123456789),
        (2, 0x23456789A),
        (3, 0x3456789AB),
        (4094, 0x456789ABC),
        (4095, 0x56789ABCD),
        (4096, 0x6789ABCDE),
        (4097, 0x789ABCDEF),
        (8190, 0x89ABCDEF0),
        (8191, 0x9ABCDEF01),
    )
    for address, data in packed_writes:
        await check_cycle(address, data, write=1)

    for address, _ in packed_writes:
        await check_cycle(address)
    await check_cycle(0)
    await check_cycle(0)

    # A same-address write must return the previous contents, then expose the
    # replacement on a later read.
    await check_cycle(4096, 0x0BADCAFFE, write=1)
    await check_cycle(4096)
    await check_cycle(4097)
    await check_cycle(4097)

    # Verify that write/read and pipeline enables are independently honored.
    await check_cycle(2, 0x0FFFFFFFF, write=1, enable=0)
    await check_cycle(2)
    await check_cycle(3, enable=0b01)
    await check_cycle(0, enable=0b10)
    await check_cycle(0, enable=0)

    # Exercise changing half selects, back-to-back operations, and all enable
    # combinations with a deterministic randomized sequence.
    rng = random.Random(0x8A36)
    addresses = [
        0,
        1,
        2,
        3,
        62,
        63,
        64,
        65,
        4094,
        4095,
        4096,
        4097,
        8190,
        8191,
    ]
    for _ in range(200):
        await check_cycle(
            rng.choice(addresses),
            rng.getrandbits(DATA_WIDTH),
            write=rng.randrange(3) == 0,
            enable=rng.choice((0b00, 0b01, 0b10, 0b11, 0b11, 0b11)),
        )

    await check_cycle(0)
    await check_cycle(0)


def test_ram_sp_uram_8k36_runner():
    runner = get_runner(SIM)
    sources = list(resolve_flt(prj_path / "ram.flt"))
    defines = {}
    if USE_XPM:
        sources.insert(0, Path(XPM_MEMORY_SV))
        defines["RAM_USE_XPM"] = 1

    build_name = f"ram_sp_uram_8k36{'_xpm' if USE_XPM else ''}"
    build_dir = prj_path / "sim_build" / build_name
    runner.build(
        hdl_toplevel="ram_sp_uram_8k36",
        sources=sources,
        defines=defines,
        always=True,
        waves=True,
        build_dir=build_dir,
    )
    runner.test(
        hdl_toplevel="ram_sp_uram_8k36",
        hdl_toplevel_lang="verilog",
        test_module="test_ram_sp_uram_8k36",
        waves=True,
        gui=GUI,
        build_dir=build_dir,
        test_dir=build_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
