import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
LUT_FILE = prj_path / "rtl" / "dec_8b10b.mif"

SIM = os.environ.get("SIM", "verilator").lower()
GUI = os.environ.get("GUI", "false").lower() == "true"


def load_reference_table():
    with LUT_FILE.open(encoding="utf-8") as mif_file:
        table = [int(line.strip(), 2) for line in mif_file if line.strip()]
    assert len(table) == 1024
    return table


REFERENCE_TABLE = load_reference_table()


async def drive_input(dut, address, dispin, cen):
    await FallingEdge(dut.clk)
    dut.cen.value = cen
    dut.din.value = address
    dut.dispin.value = dispin


async def check_output(dut, expected, dispin):
    await ReadOnly()
    assert int(dut.notintable.value) == ((expected >> 9) & 1)

    if not int(dut.notintable.value):
        assert int(dut.dout.value) == (expected & 0xFF)
        assert int(dut.charisk.value) == ((expected >> 8) & 1)
        assert int(dut.dispout.value) == ((expected >> (10 + (dispin * 2))) & 1)
        assert int(dut.disperr.value) == ((expected >> (11 + (dispin * 2))) & 1)


@cocotb.test()
async def test_dec_8b10b(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.rst.value = 1
    dut.cen.value = 0
    dut.din.value = 0
    dut.dispin.value = 0

    await ClockCycles(dut.clk, 2)
    await ReadOnly()
    assert int(dut.dout.value) == 0
    assert int(dut.charisk.value) == 0
    assert int(dut.dispout.value) == 0
    assert int(dut.disperr.value) == 0
    assert int(dut.notintable.value) == 0
    assert int(dut.valid.value) == 0

    await FallingEdge(dut.clk)
    dut.rst.value = 0

    for dispin in range(2):
        for address, expected in enumerate(REFERENCE_TABLE):
            await drive_input(dut, address, dispin, cen=1)
            await RisingEdge(dut.clk)
            await check_output(dut, expected, dispin)
            assert int(dut.valid.value) == 1

    held_output = (
        int(dut.dout.value),
        int(dut.charisk.value),
        int(dut.dispout.value),
        int(dut.disperr.value),
        int(dut.notintable.value),
    )
    await drive_input(dut, 0x3FF, dispin=1, cen=0)
    await RisingEdge(dut.clk)
    await ReadOnly()
    assert (
        int(dut.dout.value),
        int(dut.charisk.value),
        int(dut.dispout.value),
        int(dut.disperr.value),
        int(dut.notintable.value),
    ) == held_output
    assert int(dut.valid.value) == 0


@pytest.mark.parametrize("use_lut", [0, 1])
def test_dec_8b10b_runner(use_lut, tmp_path):
    runner = get_runner(SIM)
    build_dir = tmp_path / f"dec_8b10b_lut_{use_lut}"
    runner.build(
        hdl_toplevel="dec_8b10b",
        sources=resolve_flt(prj_path / "dec_8b10b.flt"),
        parameters={
            "C_USE_LUT": use_lut,
            "C_LUT_FILE": LUT_FILE.as_posix(),
        },
        build_dir=build_dir,
        always=True,
    )
    runner.test(
        hdl_toplevel="dec_8b10b",
        hdl_toplevel_lang="verilog",
        test_module="test_dec_8b10b",
        test_dir=build_dir,
        gui=GUI,
        waves=True,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
