import os
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
READ_LATENCY = 3
INIT_WORD = 0x5A
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


async def cycle(dut, address, data, write, enable):
    await FallingEdge(dut.clk)
    dut.addr.value = address
    dut.din.value = data
    dut.we.value = write
    dut.en.value = (1 << READ_LATENCY) - 1 if enable else 0
    await RisingEdge(dut.clk)
    await ReadOnly()
    return int(dut.dout.value)


@cocotb.test()
async def test_ram_sp_write_first_pipeline_reset_and_enable_holds(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = (1 << READ_LATENCY) - 1
    dut.en.value = 0
    dut.we.value = 0
    dut.addr.value = 0
    dut.din.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 0

    memory = [INIT_WORD] * (1 << ADDR_WIDTH)
    pipeline = [0] * READ_LATENCY
    operations = [
        # Address 1 demonstrates the configured initialization value, and the
        # following write demonstrates WRITE_FIRST read-during-write behavior.
        (1, 0, 0, 1),
        (1, 0x33, 1, 1),
        (1, 0, 0, 1),
        (6, 0xC7, 1, 1),
        (6, 0, 0, 1),
        (0, 0, 0, 1),
        (0, 0, 0, 1),
    ]
    for address, data, write, enable in operations:
        old_word = memory[address]
        stage0 = data if write else old_word
        if enable:
            pipeline = [stage0, *pipeline[:-1]]
            if write:
                memory[address] = data
        expected = pipeline[-1]
        actual = await cycle(dut, address, data, write, enable)
        assert actual == expected

    held = int(dut.dout.value)
    for _ in range(3):
        assert await cycle(dut, 6, 0xFF, 1, 0) == held

    await FallingEdge(dut.clk)
    dut.rst.value = (1 << READ_LATENCY) - 1
    dut.en.value = 0
    await RisingEdge(dut.clk)
    await ReadOnly()
    assert int(dut.dout.value) == 0


def test_ram_sp_write_first_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="ram_sp",
        verilog_sources=resolve_flt(prj_path / "ram.flt"),
        parameters={
            "ADDR_WIDTH": ADDR_WIDTH,
            "DATA_WIDTH": DATA_WIDTH,
            "WRITE_MODE": "WRITE_FIRST",
            "READ_LATENCY": READ_LATENCY,
            "INIT_WORD": INIT_WORD,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="ram_sp",
        hdl_toplevel_lang="verilog",
        test_module="test_ram_sp_write_first",
        test_args=["-suppress", "7061"],
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
