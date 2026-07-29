import os
import sys
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadWrite, RisingEdge
from cocotb_tools.runner import get_runner


prj_path = Path(__file__).resolve().parent.parent
repo_path = prj_path.parent
sys.path.insert(0, str(repo_path / "hb_up2" / "tests"))
from test_hb_up2_primitives import Int2Model, XIN_WIDTH, bits  # noqa: E402


SIM = os.environ.get("SIM", "verilator")
YOUT_WIDTH = 8


async def tick(dut):
    await RisingEdge(dut.clk)
    await ReadWrite()


@cocotb.test()
async def test_fir_rc_u3d2_int2_impulse_corner_and_overflow(dut):
    """The archived RC interpolator has the same exact systolic FIR contract."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.xin.value = 0
    for _ in range(40):
        await tick(dut)
    dut.rst.value = 0

    model = Int2Model()
    visible = (0, 0, False)
    saw_overflow = False
    samples = [0, 1, -1, 0, 0, 32767, -32768, 32767, -32768] + [0] * 30
    for sample in samples:
        await FallingEdge(dut.clk)
        dut.xin.value = bits(sample, XIN_WIDTH)
        expected = model.step(sample)
        await tick(dut)
        observed = (int(dut.yout0.value), int(dut.yout1.value), bool(dut.ovf.value))
        assert observed == visible
        visible = expected
        saw_overflow |= observed[2]
    assert saw_overflow


def test_fir_rc_u3d2_int2_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="hb_up2_int2",
        sources=[prj_path / "rtl" / "fir_rc_u3d2_int2.sv"],
        parameters={"YOUT_WIDTH": YOUT_WIDTH},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="hb_up2_int2",
        hdl_toplevel_lang="verilog",
        test_module="test_fir_rc_u3d2_int2",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
