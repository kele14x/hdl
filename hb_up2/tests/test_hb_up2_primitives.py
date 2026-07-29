import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadWrite, RisingEdge
from cocotb_tools.runner import get_runner


prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
XIN_WIDTH = 16
COE_WIDTH = 16
YOUT_WIDTH = 8
SRA_BITS = 15
COEFFICIENTS = [952, -1609, 3090, -6260, 20622]


def signed(value, width):
    value &= (1 << width) - 1
    return value - (1 << width) if value & (1 << (width - 1)) else value


def bits(value, width):
    return value & ((1 << width) - 1)


def overflow(value, output_width):
    upper = value >> (output_width + SRA_BITS)
    sign = (value >> (output_width + SRA_BITS - 1)) & 1
    return upper != (-1 if sign else 0)


async def tick(dut):
    await RisingEdge(dut.clk)
    await ReadWrite()


class Int2Model:
    def __init__(self):
        self.xin_d = [0] * 20
        self.adreg = [0] * 5
        self.mreg = [0] * 5
        self.preg = [0] * 5

    def step(self, xin):
        old_xin_d = self.xin_d[:]
        old_adreg = self.adreg[:]
        old_mreg = self.mreg[:]
        old_preg = self.preg[:]
        self.xin_d = [signed(xin, XIN_WIDTH)] + old_xin_d[:-1]
        self.adreg = [
            signed(old_xin_d[i + 1] + old_xin_d[-3 * i + 19], XIN_WIDTH + 1)
            for i in range(5)
        ]
        self.mreg = [
            signed(old_adreg[i] * COEFFICIENTS[i], XIN_WIDTH + COE_WIDTH + 1)
            for i in range(5)
        ]
        self.preg = [
            signed(
                old_mreg[i] + (old_preg[i + 1] if i < 4 else (1 << (SRA_BITS - 1))),
                XIN_WIDTH + COE_WIDTH + 1,
            )
            for i in range(5)
        ]
        return (
            bits(old_xin_d[14], YOUT_WIDTH),
            bits(old_preg[0] >> SRA_BITS, YOUT_WIDTH),
            overflow(old_preg[0], YOUT_WIDTH),
        )


class Int2P2Model:
    def __init__(self):
        self.base = 4
        self.xin_d = [0] * 26
        self.adreg0 = [0] * 5
        self.mreg0 = [0] * 5
        self.preg0 = [0] * 5
        self.adreg1 = [0] * 5
        self.mreg1 = [0] * 5
        self.preg1 = [0] * 5

    def x_idx(self, ith, stage):
        value = self.base * 2 - ith - 1
        value = (value // 2) * 4 + (value % 2) + 2
        return value - stage * 2

    def step(self, xin0, xin1):
        old_xin_d = self.xin_d[:]
        old_adreg0, old_mreg0, old_preg0 = self.adreg0[:], self.mreg0[:], self.preg0[:]
        old_adreg1, old_mreg1, old_preg1 = self.adreg1[:], self.mreg1[:], self.preg1[:]
        self.xin_d = [signed(xin1, XIN_WIDTH), signed(xin0, XIN_WIDTH)] + old_xin_d[:-2]
        self.adreg0 = [
            signed(old_xin_d[self.x_idx(s - 4, s)] + old_xin_d[self.x_idx(-s + 5, s)], XIN_WIDTH + 1)
            for s in range(5)
        ]
        self.adreg1 = [
            signed(old_xin_d[self.x_idx(s - 3, s)] + old_xin_d[self.x_idx(-s + 6, s)], XIN_WIDTH + 1)
            for s in range(5)
        ]
        self.mreg0 = [signed(old_adreg0[s] * COEFFICIENTS[s], 33) for s in range(5)]
        self.mreg1 = [signed(old_adreg1[s] * COEFFICIENTS[s], 33) for s in range(5)]
        self.preg0 = [signed(old_mreg0[s] + (old_preg0[s + 1] if s < 4 else (1 << 14)), 33) for s in range(5)]
        self.preg1 = [signed(old_mreg1[s] + (old_preg1[s + 1] if s < 4 else (1 << 14)), 33) for s in range(5)]
        return (
            bits(old_xin_d[21], YOUT_WIDTH),
            bits(old_preg0[0] >> SRA_BITS, YOUT_WIDTH),
            bits(old_xin_d[20], YOUT_WIDTH),
            bits(old_preg1[0] >> SRA_BITS, YOUT_WIDTH),
            overflow(old_preg0[0], YOUT_WIDTH) or overflow(old_preg1[0], YOUT_WIDTH),
        )


@cocotb.test()
async def test_hb_up2_int2_filter_and_overflow(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.xin.value = 0
    for _ in range(40):
        await tick(dut)
    dut.rst.value = 0

    model = Int2Model()
    observed_overflow = False
    visible = (0, 0, False)
    samples = [0, 1, -1, 37, -42, 0, 32767, -32768, 32767, -32768] + [0] * 28
    for sample in samples:
        await FallingEdge(dut.clk)
        dut.xin.value = bits(sample, XIN_WIDTH)
        expected = model.step(sample)
        await tick(dut)
        observed = (int(dut.yout0.value), int(dut.yout1.value), bool(dut.ovf.value))
        assert observed == visible
        visible = expected
        observed_overflow |= observed[2]
    assert observed_overflow


@cocotb.test()
async def test_hb_up2_int2_p2_filter_and_overflow(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.xin0.value = 0
    dut.xin1.value = 0
    for _ in range(50):
        await tick(dut)
    dut.rst.value = 0

    model = Int2P2Model()
    observed_overflow = False
    visible = (0, 0, 0, 0, False)
    pairs = [(0, 0), (1, -1), (37, -42), (0, 0), (32767, -32768), (-32768, 32767)] + [(0, 0)] * 32
    for xin0, xin1 in pairs:
        await FallingEdge(dut.clk)
        dut.xin0.value = bits(xin0, XIN_WIDTH)
        dut.xin1.value = bits(xin1, XIN_WIDTH)
        expected = model.step(xin0, xin1)
        await tick(dut)
        observed = (
            int(dut.yout0.value),
            int(dut.yout1.value),
            int(dut.yout2.value),
            int(dut.yout3.value),
            bool(dut.ovf.value),
        )
        assert observed == visible
        visible = expected
        observed_overflow |= observed[4]
    assert observed_overflow


def run(top, testcase, source):
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=top,
        sources=[source],
        parameters={"YOUT_WIDTH": YOUT_WIDTH},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel=top,
        hdl_toplevel_lang="verilog",
        test_module="test_hb_up2_primitives",
        testcase=testcase,
    )


def test_hb_up2_int2_runner():
    run("hb_up2_int2", "test_hb_up2_int2_filter_and_overflow", prj_path / "rtl" / "hb_up2_int2.sv")


def test_hb_up2_int2_p2_runner():
    run("hb_up2_int2_p2", "test_hb_up2_int2_p2_filter_and_overflow", prj_path / "rtl" / "hb_up2_int2_p2.sv")


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
