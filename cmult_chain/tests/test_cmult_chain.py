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
A_WIDTH = 8
B_WIDTH = 8
P_WIDTH = 12
SRA_BITS = 4


async def drive_taps(dut, values):
    for index, (ar, ai, br, bi) in enumerate(values):
        dut.ar[index].value = ar
        dut.ai[index].value = ai
        dut.br[index].value = br
        dut.bi[index].value = bi


async def tick(dut):
    await RisingEdge(dut.clk)
    await ReadWrite()


def product(ar, ai, br, bi):
    rounding = 1 << (SRA_BITS - 1)
    return (
        (ar * br - ai * bi + rounding) >> SRA_BITS,
        (ar * bi + ai * br + rounding) >> SRA_BITS,
    )


@cocotb.test()
async def test_cmult_chain_tap_latency_and_signed_arithmetic(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    zeros = [(0, 0, 0, 0)] * NUM_TAPS
    dut.rst.value = 1
    await drive_taps(dut, zeros)
    for _ in range(3):
        await tick(dut)
    assert dut.pr.value.to_signed() == 0
    assert dut.pi.value.to_signed() == 0
    assert int(dut.ovf.value) == 0

    dut.rst.value = 0
    for _ in range(10):
        await tick(dut)

    vectors = [
        (0, (24, -8, 12, 5)),
        (NUM_TAPS - 1, (-32, 16, -7, 9)),
    ]
    for tap, vector in vectors:
        await FallingEdge(dut.clk)
        values = list(zeros)
        values[tap] = vector
        await drive_taps(dut, values)
        await tick(dut)

        await FallingEdge(dut.clk)
        await drive_taps(dut, zeros)

        latency = NUM_TAPS + 4 - tap
        expected_pr, expected_pi = product(*vector)
        for cycle in range(1, latency + 2):
            await tick(dut)
            if cycle == latency:
                assert dut.pr.value.to_signed() == expected_pr
                assert dut.pi.value.to_signed() == expected_pi
                assert int(dut.ovf.value) == 0
            else:
                assert dut.pr.value.to_signed() == 0
                assert dut.pi.value.to_signed() == 0


def test_cmult_chain_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cmult_chain",
        sources=resolve_flt(prj_path / "cmult_chain.flt"),
        parameters={
            "NUM_TAPS": NUM_TAPS,
            "A_WIDTH": A_WIDTH,
            "B_WIDTH": B_WIDTH,
            "P_WIDTH": P_WIDTH,
            "SRA_BITS": SRA_BITS,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="cmult_chain",
        hdl_toplevel_lang="verilog",
        test_module="test_cmult_chain",
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
