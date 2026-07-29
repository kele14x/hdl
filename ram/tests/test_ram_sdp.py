import os
from collections import deque
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadWrite, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

ADDR_WIDTH = 3
DATA_WIDTH = 8
READ_LATENCY = 3
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


@cocotb.test()
async def test_ram_sdp_write_read_latency_and_read_enable_hold(dut):
    cocotb.start_soon(Clock(dut.clka, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clkb, 10, unit="ns").start())
    dut.ena.value = 0
    dut.wea.value = 0
    dut.addra.value = 0
    dut.dina.value = 0
    dut.rstb.value = (1 << READ_LATENCY) - 1
    dut.enb.value = 0
    dut.addrb.value = 0
    await ClockCycles(dut.clka, 3)
    dut.rstb.value = 0

    memory = {0: 0x26, 2: 0x7D, 5: 0xA4, 7: 0x11}
    for address, value in memory.items():
        await FallingEdge(dut.clka)
        dut.ena.value = 1
        dut.wea.value = 1
        dut.addra.value = address
        dut.dina.value = value
        await RisingEdge(dut.clka)

    await FallingEdge(dut.clka)
    dut.ena.value = 0
    dut.wea.value = 0
    dut.enb.value = (1 << READ_LATENCY) - 1

    expected = deque()
    addresses = [0, 5, 2, 7, 0, 5, 2, 7]
    for address in addresses:
        dut.addrb.value = address
        await RisingEdge(dut.clkb)
        await ReadWrite()
        expected.append(memory[address])
        if len(expected) > READ_LATENCY:
            assert int(dut.doutb.value) == expected.popleft()

    await FallingEdge(dut.clkb)
    dut.enb.value = 0
    dut.addrb.value = 5
    await ClockCycles(dut.clkb, 3)
    held = int(dut.doutb.value)
    await ClockCycles(dut.clkb, 3)
    assert int(dut.doutb.value) == held


def test_ram_sdp_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="ram_sdp",
        verilog_sources=resolve_flt(prj_path / "ram.flt"),
        parameters={
            "ADDR_WIDTH": ADDR_WIDTH,
            "DATA_WIDTH": DATA_WIDTH,
            "READ_LATENCY": READ_LATENCY,
            "INIT_WORD": 0,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="ram_sdp",
        hdl_toplevel_lang="verilog",
        test_module="test_ram_sdp",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
