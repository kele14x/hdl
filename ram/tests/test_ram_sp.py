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

from tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

ADDR_WIDTH = 3
DATA_WIDTH = 8

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
USE_XPM = os.environ.get("RAM_SP_USE_XPM", "").lower() in {"1", "true", "yes"}
XPM_MEMORY_SV = os.environ.get("XPM_MEMORY_SV")

if USE_XPM:
    if not XPM_MEMORY_SV:
        raise RuntimeError(
            "RAM_SP_USE_XPM is enabled, but XPM_MEMORY_SV was not set to "
            "Vivado's installed xpm_memory.sv"
        )
    if not Path(XPM_MEMORY_SV).is_file():
        raise RuntimeError(f"XPM_MEMORY_SV does not name a file: {XPM_MEMORY_SV}")


_base_cases = (
    {
        "name": "write_first_latency_1",
        "write_mode": "WRITE_FIRST",
        "read_latency": 1,
        "ram_style": "AUTO",
    },
    {
        "name": "write_first_latency_2",
        "write_mode": "WRITE_FIRST",
        "read_latency": 2,
        "ram_style": "AUTO",
    },
    {
        "name": "write_first_latency_3",
        "write_mode": "WRITE_FIRST",
        "read_latency": 3,
        "ram_style": "AUTO",
    },
    {
        "name": "read_first_latency_2",
        "write_mode": "READ_FIRST",
        "read_latency": 2,
        "ram_style": "AUTO",
    },
    {
        "name": "no_change_latency_2",
        "write_mode": "NO_CHANGE",
        "read_latency": 2,
        "ram_style": "AUTO",
    },
)

_ram_styles = ("AUTO", "BLOCK", "DISTRIBUTED", "ULTRA")
if not USE_XPM:
    _ram_styles += ("REGISTER",)

_style_cases = tuple(
    {
        "name": f"ram_style_{ram_style.lower()}",
        "write_mode": "READ_FIRST",
        "read_latency": 2,
        "ram_style": ram_style,
    }
    for ram_style in _ram_styles
)

_depth_cases = tuple(
    {
        "name": f"non_power_of_two_depth_latency_{read_latency}",
        "write_mode": "READ_FIRST",
        "read_latency": read_latency,
        "ram_style": "AUTO",
        "depth": 5,
    }
    for read_latency in (1, 2, 3)
)

CASES = _base_cases + _style_cases + _depth_cases


async def drive_cycle(dut, address, data, write, en_mask, reset=0):
    await FallingEdge(dut.clk)
    dut.addr.value = address
    dut.din.value = data
    dut.we.value = write
    dut.en.value = en_mask
    dut.rst.value = reset
    await RisingEdge(dut.clk)
    await ReadOnly()


async def cycle(dut, address, data, write, en_mask, reset=0):
    await drive_cycle(dut, address, data, write, en_mask, reset)
    return int(dut.dout.value)


@cocotb.test()
async def test_ram_sp_modes_reset_enable_and_init(dut):
    write_mode = os.environ["RAM_SP_WRITE_MODE"]
    read_latency = int(os.environ["RAM_SP_READ_LATENCY"])
    ram_style = os.environ["RAM_SP_RAM_STYLE"]
    depth = int(os.environ["RAM_SP_DEPTH"])

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    all_stages = (1 << read_latency) - 1
    dut.rst.value = 1
    dut.en.value = 0
    dut.we.value = 0
    dut.addr.value = 0
    dut.din.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 0
    await ReadOnly()
    assert int(dut.dout.value) == 0

    # Reset intentionally leaves all earlier stages untouched. Flush any
    # unknown power-up values through the pipeline before checking read data.
    for _ in range(read_latency):
        await drive_cycle(dut, 0, 0, 0, all_stages, 0)
    assert int(dut.dout.value) == 0

    memory = [0] * depth
    pipeline = [0] * read_latency

    def advance_model(address, data, write, en_mask, reset):
        old_pipeline = pipeline.copy()
        address_in_range = address < depth
        old_word = memory[address] if address_in_range else None

        if (en_mask & 1) and write and address_in_range:
            memory[address] = data

        if reset and read_latency == 1:
            pipeline[0] = 0
        elif en_mask & 1:
            if not address_in_range:
                pipeline[0] = None
            elif write and write_mode == "WRITE_FIRST":
                pipeline[0] = data
            elif write and write_mode == "NO_CHANGE":
                pipeline[0] = old_pipeline[0]
            else:
                pipeline[0] = old_word

        for stage in range(1, read_latency):
            if reset and stage == read_latency - 1:
                pipeline[stage] = 0
            elif en_mask & (1 << stage):
                pipeline[stage] = old_pipeline[stage - 1]

        return pipeline[-1]

    # The first read establishes a value different from the contents written
    # to address 1, making READ_FIRST and NO_CHANGE observably distinct.
    operations = (
        (2, 0, 0, all_stages, 0),
        (1, 0x33, 1, all_stages, 0),
        (2, 0, 0, all_stages, 0),
        (1, 0xC7, 1, all_stages, 0),
        (1, 0, 0, all_stages, 0),
    )
    for address, data, write, en_mask, reset in operations:
        expected = advance_model(address, data, write, en_mask, reset)
        actual = await cycle(dut, address, data, write, en_mask, reset)
        assert actual == expected, (
            ram_style,
            write_mode,
            read_latency,
            address,
            expected,
            actual,
        )

    held = int(dut.dout.value)
    for _ in range(2):
        expected = advance_model(6, 0xFF, 1, 0, 0)
        actual = await cycle(dut, 6, 0xFF, 1, 0, 0)
        assert actual == expected == held

    # Stage 0 can hold independently of the later output stages.
    stage0_hold_en = all_stages & ~1
    expected = advance_model(3, 0xEE, 1, stage0_hold_en, 0)
    actual = await cycle(dut, 3, 0xEE, 1, stage0_hold_en, 0)
    assert actual == expected

    # A later pipeline stage can hold while stage 0 continues to operate.
    if read_latency > 1:
        stage1_hold_en = all_stages & ~(1 << 1)
        expected = advance_model(3, 0x19, 1, stage1_hold_en, 0)
        actual = await cycle(dut, 3, 0x19, 1, stage1_hold_en, 0)
        assert actual == expected

    # Fill every read stage with a known nonzero value.
    for _ in range(read_latency):
        expected = advance_model(1, 0, 0, all_stages, 0)
        actual = await cycle(dut, 1, 0, 0, all_stages, 0)
        assert actual == expected
    assert expected == 0xC7

    # The scalar reset has priority over the final stage enable and clears
    # only the externally visible stage.
    expected = advance_model(0, 0, 0, 0, 1)
    actual = await cycle(dut, 0, 0, 0, 0, 1)
    assert actual == expected == 0

    # For a multistage path, expose the retained penultimate value to prove
    # reset did not also clear an earlier pipeline stage.
    if read_latency > 1:
        final_stage_enable = 1 << (read_latency - 1)
        expected = advance_model(0, 0, 0, final_stage_enable, 0)
        actual = await cycle(dut, 0, 0, 0, final_stage_enable, 0)
        assert actual == expected == 0xC7

    if depth < (1 << ADDR_WIDTH):
        out_of_range_address = depth
        guard_address = depth - 1

        # An out-of-range write is ignored. It still represents an invalid
        # read on the single port, so do not observe the pipeline yet.
        await drive_cycle(dut, out_of_range_address, 0xA5, 1, 1, 0)

        # Propagate an out-of-range read through every enabled read stage.
        for _ in range(read_latency):
            await drive_cycle(dut, out_of_range_address, 0, 0, all_stages, 0)
        assert not dut.dout.value.is_resolvable

        # Reset recovers the visible output even though earlier stages may
        # still contain X, then valid reads flush those stages.
        await drive_cycle(dut, 0, 0, 0, 0, 1)
        assert int(dut.dout.value) == 0
        for _ in range(read_latency):
            await drive_cycle(dut, guard_address, 0, 0, all_stages, 0)
        assert int(dut.dout.value) == 0


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_ram_sp_runner(case):
    try:
        runner = get_runner(SIM)
    except Exception as exc:  # pragma: no cover - simulator-specific failure
        pytest.fail(f"SIM={SIM!r} is not a supported cocotb simulator: {exc}")

    sources = list(resolve_flt(prj_path / "ram.flt"))
    defines = {}
    if USE_XPM:
        # The vendor source is supplied by the caller, never copied into this
        # repository or added to ram.flt.
        sources.insert(0, Path(XPM_MEMORY_SV))
        defines["RAM_USE_XPM"] = 1

    depth = case.get("depth", 1 << ADDR_WIDTH)
    build_name = (
        f"ram_sp_{'xpm_' if USE_XPM else ''}{case['name']}_{case['ram_style'].lower()}"
    )
    build_dir = Path(tempfile.gettempdir()) / "hdl-ram-sp-cocotb" / build_name
    runner.build(
        hdl_toplevel="ram_sp",
        verilog_sources=sources,
        defines=defines,
        parameters={
            "ADDR_WIDTH": ADDR_WIDTH,
            "DATA_WIDTH": DATA_WIDTH,
            "WRITE_MODE": case["write_mode"],
            "READ_LATENCY": case["read_latency"],
            "RAM_STYLE": case["ram_style"],
            "DEPTH": depth,
        },
        always=True,
        build_dir=build_dir,
        waves=GUI,
    )
    runner.test(
        hdl_toplevel="ram_sp",
        hdl_toplevel_lang="verilog",
        test_module="test_ram_sp",
        extra_env={
            "RAM_SP_WRITE_MODE": case["write_mode"],
            "RAM_SP_READ_LATENCY": str(case["read_latency"]),
            "RAM_SP_RAM_STYLE": case["ram_style"],
            "RAM_SP_DEPTH": str(depth),
        },
        waves=GUI,
        gui=GUI,
        build_dir=build_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
