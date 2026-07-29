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
GUI = os.environ.get("GUI", "false").lower() == "true"

NUM_TAPS = 3
INPUT_DATA_WIDTH = 8
COE_WIDTH = 8
OUTPUT_DATA_WIDTH = 12
SRA_BITS = 4


async def tick(dut):
    await RisingEdge(dut.clk)
    await ReadWrite()


async def write_coefficient(dut, index, i_value, q_value):
    await FallingEdge(dut.clk)
    dut.ctrl_coe_idx.value = index
    dut.ctrl_coe_i_in.value = i_value
    dut.ctrl_coe_q_in.value = q_value
    dut.ctrl_coe_valid.value = 1
    await tick(dut)
    await FallingEdge(dut.clk)
    dut.ctrl_coe_valid.value = 0


@cocotb.test()
async def test_equalizer_coefficient_update_and_tap_alignment(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.data_i_in.value = 0
    dut.data_q_in.value = 0
    dut.ctrl_coe_valid.value = 0
    dut.ctrl_coe_idx.value = 0
    dut.ctrl_coe_i_in.value = 0
    dut.ctrl_coe_q_in.value = 0
    for _ in range(3):
        await tick(dut)
    assert dut.data_i_out.value.to_signed() == 0
    assert dut.data_q_out.value.to_signed() == 0

    dut.rst.value = 0
    for index in range(NUM_TAPS):
        await write_coefficient(dut, index, 0, 0)
    await write_coefficient(dut, 1, 8, -4)

    for _ in range(12):
        await tick(dut)

    await FallingEdge(dut.clk)
    dut.data_i_in.value = 16
    dut.data_q_in.value = 12
    await tick(dut)
    await FallingEdge(dut.clk)
    dut.data_i_in.value = 0
    dut.data_q_in.value = 0

    expected_i = (16 * 8 - 12 * -4 + (1 << (SRA_BITS - 1))) >> SRA_BITS
    expected_q = (16 * -4 + 12 * 8 + (1 << (SRA_BITS - 1))) >> SRA_BITS
    latency = NUM_TAPS + 5 + 1
    for cycle in range(1, latency + 2):
        await tick(dut)
        if cycle == latency:
            assert dut.data_i_out.value.to_signed() == expected_i
            assert dut.data_q_out.value.to_signed() == expected_q
            assert int(dut.ovf.value) == 0
        else:
            assert dut.data_i_out.value.to_signed() == 0
            assert dut.data_q_out.value.to_signed() == 0


def test_equalizer_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="equalizer",
        sources=resolve_flt(prj_path / "equalizer.flt"),
        parameters={
            "NUM_TAPS": NUM_TAPS,
            "INPUT_DATA_WIDTH": INPUT_DATA_WIDTH,
            "COE_WIDTH": COE_WIDTH,
            "OUTPUT_DATA_WIDTH": OUTPUT_DATA_WIDTH,
            "SRA_BITS": SRA_BITS,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="equalizer",
        hdl_toplevel_lang="verilog",
        test_module="test_equalizer",
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
