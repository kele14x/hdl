import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
LUT_FILE = prj_path / "rtl" / "enc_8b10b.mif"

SIM = os.environ.get("SIM", "verilator").lower()
GUI = os.environ.get("GUI", "false").lower() == "true"


def load_reference_table():
    with LUT_FILE.open(encoding="utf-8") as mif_file:
        table = [int(line.strip(), 2) for line in mif_file if line.strip()]
    assert len(table) == 1024
    return table


REFERENCE_TABLE = load_reference_table()


async def drive_input(dut, address, cen):
    await FallingEdge(dut.clk)
    dut.cen.value = cen
    dut.charisk.value = (address >> 9) & 1
    dut.dispin.value = (address >> 8) & 1
    dut.din.value = address & 0xFF


async def check_output(dut, expected):
    await ReadOnly()
    actual_kerr = int(dut.kerr.value)
    actual_dispout = int(dut.dispout.value)
    actual_dout = int(dut.dout.value)
    expected_kerr = (expected >> 11) & 1
    expected_dispout = (expected >> 10) & 1
    expected_dout = expected & 0x3FF

    assert actual_kerr == expected_kerr
    assert actual_dispout == expected_dispout
    if not expected_kerr:
        assert actual_dout == expected_dout


@cocotb.test()
async def test_enc_8b10b(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.rst.value = 1
    dut.cen.value = 0
    dut.din.value = 0
    dut.charisk.value = 0
    dut.dispin.value = 0

    await ClockCycles(dut.clk, 2)
    await ReadOnly()
    assert int(dut.dout.value) == 0b0101010101
    assert int(dut.kerr.value) == 0
    assert int(dut.dispout.value) == 0
    assert int(dut.valid.value) == 0

    await FallingEdge(dut.clk)
    dut.rst.value = 0

    for address, expected in enumerate(REFERENCE_TABLE):
        await drive_input(dut, address, cen=1)
        await RisingEdge(dut.clk)
        await check_output(dut, expected)
        assert int(dut.valid.value) == 1

    held_output = (int(dut.dout.value), int(dut.kerr.value), int(dut.dispout.value))
    await drive_input(dut, 0x3FF, cen=0)
    await RisingEdge(dut.clk)
    await ReadOnly()
    assert (int(dut.dout.value), int(dut.kerr.value), int(dut.dispout.value)) == held_output
    assert int(dut.valid.value) == 0


@pytest.mark.parametrize("use_lut", [0, 1])
def test_enc_8b10b_runner(use_lut, tmp_path):
    runner = get_runner(SIM)
    build_dir = tmp_path / f"enc_8b10b_lut_{use_lut}"
    runner.build(
        hdl_toplevel="enc_8b10b",
        sources=resolve_flt(prj_path / "enc_8b10b.flt"),
        parameters={
            "C_USE_LUT": use_lut,
            "C_LUT_FILE": f'"{LUT_FILE.as_posix()}"',
        },
        build_dir=build_dir,
        build_args=[],
        waves=True,
        always=True,
    )
    runner.test(
        hdl_toplevel="enc_8b10b",
        hdl_toplevel_lang="verilog",
        test_module="test_enc_8b10b",
        test_dir=build_dir,
        gui=GUI,
        waves=True,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
