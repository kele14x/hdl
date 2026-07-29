import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

ADDR_WIDTH_A = 4
DATA_WIDTH_A = 8
ADDR_WIDTH_B = 3
DATA_WIDTH_B = 16
READ_LATENCY_B = 2
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


@cocotb.test()
async def test_ram_sdp_asym_packs_narrow_writes_in_little_endian_word_order(dut):
    cocotb.start_soon(Clock(dut.clka, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clkb, 14, unit="ns").start())
    dut.wea.value = 0
    dut.addra.value = 0
    dut.dina.value = 0
    dut.rstb.value = (1 << READ_LATENCY_B) - 1
    dut.enb.value = 0
    dut.addrb.value = 0
    await ClockCycles(dut.clkb, 2)
    dut.rstb.value = 0

    for address in range(1 << ADDR_WIDTH_A):
        await FallingEdge(dut.clka)
        dut.wea.value = 1
        dut.addra.value = address
        dut.dina.value = address
        await RisingEdge(dut.clka)
    dut.wea.value = 0

    expected_pipeline = [0] * READ_LATENCY_B
    for address in (0, 3, 7, 1):
        expected_word = (2 * address + 1) << 8 | (2 * address)
        await FallingEdge(dut.clkb)
        dut.enb.value = (1 << READ_LATENCY_B) - 1
        dut.addrb.value = address
        await RisingEdge(dut.clkb)
        await ReadOnly()
        expected_pipeline = [expected_word, *expected_pipeline[:-1]]
        assert int(dut.doutb.value) == expected_pipeline[-1]

    await FallingEdge(dut.clkb)
    dut.enb.value = 0
    dut.addrb.value = 2
    held = int(dut.doutb.value)
    await ClockCycles(dut.clkb, 3)
    assert int(dut.doutb.value) == held


def test_ram_sdp_asym_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="ram_sdp_asym",
        verilog_sources=resolve_flt(prj_path / "ram.flt"),
        parameters={
            "ADDR_WIDTH_A": ADDR_WIDTH_A,
            "DATA_WIDTH_A": DATA_WIDTH_A,
            "ADDR_WIDTH_B": ADDR_WIDTH_B,
            "DATA_WIDTH_B": DATA_WIDTH_B,
            "READ_LATENCY_B": READ_LATENCY_B,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="ram_sdp_asym",
        hdl_toplevel_lang="verilog",
        test_module="test_ram_sdp_asym",
        test_args=["-suppress", "7061"],
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
