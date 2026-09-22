"""Full-top lowphy integration smoke test.

Both tops run by default. Set ``LOWPHY_TOP`` to select just one top.
"""

import os
from pathlib import Path

import cocotb
import pytest
import register_map as reg
from cocotb_tools.runner import get_runner
from lowphy_tb import LowphyTB

from hdl_tools.flt_tool import resolve_flt

PRJ_PATH = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
SIM = SIM.lower()
GUI = os.environ.get("GUI", "false").lower() == "true"
WAVES = os.environ.get("WAVES", "false").lower() == "true"
REBUILD = os.environ.get("REBUILD", "false").lower() == "true"
LOWPHY_TOP = os.environ.get("LOWPHY_TOP", "lowphy0").lower()

if LOWPHY_TOP not in {"lowphy0", "lowphy1"}:
    raise ValueError("LOWPHY_TOP must be lowphy0 or lowphy1")


@cocotb.test(timeout_time=100, timeout_unit="us")
async def test_lowphy_control_plane_smoke(dut):
    """Check reset, register decode, and representative control fields."""
    tb = LowphyTB(dut, PRJ_PATH / "rtl" / f"{LOWPHY_TOP}.sv")
    await tb.start()

    assert await tb.axi.read(reg.VERSION) == reg.RESET_VALUES[reg.VERSION]
    assert await tb.axi.read(reg.DL_BW) == reg.RESET_VALUES[reg.DL_BW]
    assert await tb.axi.read(reg.UL_BW) == reg.RESET_VALUES[reg.UL_BW]

    for address, value in (
        (reg.SCRATCH0, 0xDEADBEEF),
        (reg.SCRATCH1, 0x12345678),
        (reg.DL_EN, 0x321),
        (reg.UL_EN, 0x123),
    ):
        await tb.axi.write(address, value)
        assert await tb.axi.read(address) == value


@pytest.mark.parametrize(
    "top",
    [LOWPHY_TOP] if "LOWPHY_TOP" in os.environ else ["lowphy0", "lowphy1"],
)
def test_lowphy_smoke_runner(top):
    runner = get_runner(SIM)
    build_args = ["-Wno-WIDTHEXPAND"] if SIM == "verilator" else []
    runner.build(
        hdl_toplevel=top,
        sources=resolve_flt(PRJ_PATH / "lowphy.flt"),
        build_args=build_args,
        always=REBUILD,
        waves=WAVES,
        build_dir=PRJ_PATH / "sim_build" / SIM / top,
    )
    runner.test(
        hdl_toplevel=top,
        hdl_toplevel_lang="verilog",
        test_module=Path(__file__).stem,
        gui=GUI,
        waves=WAVES,
        test_dir=PRJ_PATH / "sim_build" / SIM / top,
        extra_env={"LOWPHY_TOP": top},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
