import os
from collections import deque
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadWrite, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
DATA_WIDTH = 8
LOG_FFT_SIZE = 4
NUM_ANT = 4


async def tick(dut):
    await RisingEdge(dut.clk)
    await ReadWrite()


async def drive(dut, real=0, imag=0, valid=0):
    await FallingEdge(dut.clk)
    dut.din_dr.value = real
    dut.din_di.value = imag
    dut.din_dv.value = valid


async def reset(dut, bypass=0):
    dut.rst.value = 1
    dut.ctrl_itlv.value = 0b10
    dut.ctrl_bypass.value = bypass
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_dv.value = 0
    for _ in range(5):
        await tick(dut)
    dut.rst.value = 0


@cocotb.test()
async def test_fft_ct_coarse_rotation_boundaries_and_bypass(dut):
    """Exercise the 180/270-degree coarse-twiddle boundary per antenna group."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)

    await drive(dut, 0, 0, 0)
    await tick(dut)
    assert int(dut.dout_dv.value) == 0

    # Four samples form one interleaved antenna group.  A frame contains both
    # normal and coarse -j regions; using a fixed non-symmetric vector avoids
    # coupling the check to the one-register output timing.
    normal = (12, -9)
    rotated = (-9, -12)
    saw_normal = False
    saw_rotated = False
    for _ in range(68):
        await drive(dut, *normal, 1)
        await tick(dut)
        if dut.dout_dv.value.is_resolvable and int(dut.dout_dv.value):
            observed = (dut.dout_dr.value.to_signed(), dut.dout_di.value.to_signed())
            assert observed in (normal, rotated)
            saw_normal |= observed == normal
            saw_rotated |= observed == rotated
    assert saw_normal
    assert saw_rotated

    # Bypass clears the sequence state and passes I/Q through without a stale
    # coarse rotation.  The valid flag follows the input register boundary.
    await drive(dut, 0, 0, 0)
    await tick(dut)
    dut.ctrl_bypass.value = 1
    for _ in range(5):
        real, imag = -33, 19
        await drive(dut, real, imag, 1)
        await tick(dut)
        if dut.dout_dv.value.is_resolvable and int(dut.dout_dv.value):
            assert dut.dout_dr.value.to_signed() == real
            assert dut.dout_di.value.to_signed() == imag


@cocotb.test()
async def test_fft_bf2_bypass_and_normal_overflow(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut, bypass=1)

    visible = (0, 0, 0)
    for real, imag in [(0, 0), (31, -17), (-128, 127), (42, 19)]:
        await drive(dut, real, imag, 1)
        await tick(dut)
        assert int(dut.dout_dv.value) == visible[0]
        if visible[0]:
            assert dut.dout_dr.value.to_signed() == visible[1]
            assert dut.dout_di.value.to_signed() == visible[2]
        visible = (1, real, imag)

    # A full normal-mode frame with extreme values reaches the second-half
    # add/subtract path and must raise the arithmetic overflow status.
    dut.ctrl_bypass.value = 0
    saw_valid = False
    saw_overflow = False
    for _ in range(96):
        await drive(dut, 127, -128, 1)
        await tick(dut)
        saw_valid |= bool(dut.dout_dv.value)
        if dut.stat_ovf.value.is_resolvable:
            saw_overflow |= bool(dut.stat_ovf.value)
    assert saw_valid
    assert saw_overflow


@cocotb.test()
async def test_fft_twiddle_valid_latency_bypass_and_reset(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut, bypass=0b11)

    # Both delay instances intentionally have INIT=0 and reset tied off.
    # Flush their power-up history before observing the valid contract.
    for _ in range(12):
        await drive(dut, 0, 0, 0)
        await tick(dut)

    expected_valid = deque([0] * 9)
    valid_pattern = [1, 0, 1, 1, 0, 0, 1] + [0] * 12
    for valid in valid_pattern:
        await drive(dut, 0, 0, valid)
        expected_valid.append(valid)
        await tick(dut)
        expected = expected_valid.popleft()
        assert int(dut.dout_dv.value) == expected


@cocotb.test()
async def test_fft_stage_bypass_valid_pipeline(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut, bypass=0b11)

    for _ in range(20):
        await drive(dut, 0, 0, 0)
        await tick(dut)

    # Twiddle valid delay (9) plus the bypassed BF/CT/BF register boundaries.
    expected_valid = deque([0] * 12)
    valid_pattern = [1, 1, 0, 1, 0, 0, 1] + [0] * 16
    for valid in valid_pattern:
        await drive(dut, 0, 0, valid)
        expected_valid.append(valid)
        await tick(dut)
        expected = expected_valid.popleft()
        assert int(dut.dout_dv.value) == expected


def run(top, testcase):
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=top,
        sources=resolve_flt(prj_path / "fft.flt"),
        parameters={"NUM_ANT": NUM_ANT, "LOG_FFT_SIZE": LOG_FFT_SIZE, "DATA_WIDTH": DATA_WIDTH},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel=top,
        hdl_toplevel_lang="verilog",
        test_module="test_fft_primitives",
        testcase=testcase,
    )


def test_fft_ct_runner():
    run("fft_ct", "test_fft_ct_coarse_rotation_boundaries_and_bypass")


def test_fft_bf2_runner():
    run("fft_bf2", "test_fft_bf2_bypass_and_normal_overflow")


def test_fft_twiddle_runner():
    run("fft_twiddle", "test_fft_twiddle_valid_latency_bypass_and_reset")


def test_fft_stage_runner():
    run("fft_stage", "test_fft_stage_bypass_valid_pipeline")


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
