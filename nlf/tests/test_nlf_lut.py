import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadWrite, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
INDEX_WIDTH = 3
LUT_WIDTH = 8


async def data_tick(dut):
    await RisingEdge(dut.clk)
    await ReadWrite()


async def ctrl_tick(dut):
    await RisingEdge(dut.ctrl_clk)
    await ReadWrite()


async def write_lut(dut, address, value):
    await FallingEdge(dut.ctrl_clk)
    dut.ctrl_lut_addr.value = address
    dut.ctrl_lut_din.value = value
    dut.ctrl_lut_en.value = 1
    dut.ctrl_lut_we.value = 1
    await ctrl_tick(dut)


@cocotb.test()
async def test_nlf_lut_dual_bank_read_latencies_and_reset(dut):
    """Control writes serve both banks; data reads have the documented 3-cycle latency."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 14, unit="ns").start())
    dut.rst.value = 1
    dut.ctrl_rst.value = 1
    dut.bank.value = 0
    dut.index.value = 0
    dut.ctrl_lut_addr.value = 0
    dut.ctrl_lut_din.value = 0
    dut.ctrl_lut_en.value = 0
    dut.ctrl_lut_we.value = 0

    for _ in range(4):
        await data_tick(dut)
    for _ in range(3):
        await ctrl_tick(dut)
    assert int(dut.dout.value) == 0
    assert int(dut.ctrl_lut_dout.value) == 0

    dut.rst.value = 0
    dut.ctrl_rst.value = 0

    contents = {0b001: 0x12, 0b101: 0xA5, 0b111: 0x7E}
    for address, value in contents.items():
        await write_lut(dut, address, value)

    # Disable writes and use the control port as a read port.  READ_FIRST
    # control-port output is one cycle behind its enabled address.
    await FallingEdge(dut.ctrl_clk)
    dut.ctrl_lut_we.value = 0
    dut.ctrl_lut_en.value = 1
    dut.ctrl_lut_addr.value = 0b101
    await ctrl_tick(dut)
    await ctrl_tick(dut)
    assert int(dut.ctrl_lut_dout.value) == contents[0b101]

    # Data port B is permanently enabled and has exactly three registered
    # read stages.  Exercise bank bit, address zero, and a held address.
    requested = [(0, 1), (1, 5), (1, 7), (0, 0), (1, 5)]
    expected = [0, 0, 0]
    for bank, index in requested:
        await FallingEdge(dut.clk)
        dut.bank.value = bank
        dut.index.value = index
        await data_tick(dut)
        expected.append(contents.get((bank << INDEX_WIDTH) | index, 0))
        assert int(dut.dout.value) == expected.pop(0)

    for _ in range(3):
        await data_tick(dut)
        assert int(dut.dout.value) == expected.pop(0)

    # A reset applied only to the data port masks its output without damaging
    # the independently clocked contents written through the control port.
    dut.rst.value = 1
    await data_tick(dut)
    assert int(dut.dout.value) == 0
    dut.rst.value = 0
    # Reset is itself pipelined through the 3-stage read interface, so allow
    # both the reset history and the requested address to drain.
    for _ in range(7):
        await data_tick(dut)


def test_nlf_lut_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="nlf_lut",
        sources=resolve_flt(prj_path / "nlf.flt"),
        parameters={"INDEX_WIDTH": INDEX_WIDTH, "LUT_WIDTH": LUT_WIDTH},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="nlf_lut",
        hdl_toplevel_lang="verilog",
        test_module="test_nlf_lut",
        test_args=["-suppress", "7061"] if SIM == "questa" else [],
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
