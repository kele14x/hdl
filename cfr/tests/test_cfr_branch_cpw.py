import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadWrite, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
repo_path = prj_path.parent
SIM = os.environ.get("SIM", "verilator")
DATA_WIDTH = 8


async def ctrl_tick(dut):
    await RisingEdge(dut.ctrl_clk)
    await ReadWrite()


async def write_cpw(dut, address, i_value, q_value):
    await FallingEdge(dut.ctrl_clk)
    dut.ctrl_pc_cfr_cpw_addr.value = address
    dut.ctrl_pc_cfr_cpw_wr_data_i.value = i_value
    dut.ctrl_pc_cfr_cpw_wr_data_q.value = q_value
    dut.ctrl_pc_cfr_cpw_en.value = 1
    dut.ctrl_pc_cfr_cpw_we.value = 1
    await ctrl_tick(dut)


@cocotb.test()
async def test_cfr_branch_cpw_readback_reset_and_bank_boundaries(dut):
    """Exercise the branch-local CPW readback RAM without changing the data path."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 14, unit="ns").start())
    dut.rst.value = 1
    dut.ctrl_rst.value = 1
    dut.data_i_in.value = 0
    dut.data_q_in.value = 0
    dut.ctrl_pc_cfr_enable.value = 0
    dut.ctrl_pc_cfr_spacing.value = 0
    dut.ctrl_pc_cfr_clipping_threshold.value = 0
    dut.ctrl_pc_cfr_detect_threshold.value = 0
    dut.ctrl_hc_enable.value = 0
    dut.ctrl_hc_threshold.value = 0
    dut.ctrl_pc_cfr_cpw_addr.value = 0
    dut.ctrl_pc_cfr_cpw_en.value = 0
    dut.ctrl_pc_cfr_cpw_we.value = 0
    dut.ctrl_pc_cfr_cpw_wr_data_i.value = 0
    dut.ctrl_pc_cfr_cpw_wr_data_q.value = 0

    for _ in range(4):
        await ctrl_tick(dut)
    assert int(dut.ctrl_pc_cfr_cpw_rd_data_i.value) == 0
    assert int(dut.ctrl_pc_cfr_cpw_rd_data_q.value) == 0
    dut.rst.value = 0
    dut.ctrl_rst.value = 0

    values = {0: (0x12, 0xE7), 3: (0x80, 0x7F)}
    for address, (i_value, q_value) in values.items():
        await write_cpw(dut, address, i_value, q_value)

    # The readback port is a one-cycle READ_FIRST RAM.  Hold each boundary
    # address across an enabled non-write transaction before sampling it.
    for address, expected in values.items():
        await FallingEdge(dut.ctrl_clk)
        dut.ctrl_pc_cfr_cpw_addr.value = address
        dut.ctrl_pc_cfr_cpw_en.value = 1
        dut.ctrl_pc_cfr_cpw_we.value = 0
        await ctrl_tick(dut)
        await ctrl_tick(dut)
        assert int(dut.ctrl_pc_cfr_cpw_rd_data_i.value) == expected[0]
        assert int(dut.ctrl_pc_cfr_cpw_rd_data_q.value) == expected[1]

    # Address zero retains its value after an independent control reset.
    dut.ctrl_rst.value = 1
    await ctrl_tick(dut)
    assert int(dut.ctrl_pc_cfr_cpw_rd_data_i.value) == 0
    assert int(dut.ctrl_pc_cfr_cpw_rd_data_q.value) == 0


def test_cfr_branch_cpw_runner():
    if SIM == "questa":
        pytest.skip(
            "Questa rejects cfr_pc_upx's 5-element COE_NUMS literal for its "
            "NUM_UNIQUE_COE=3 instantiations (vopt-13173/vopt-121)."
        )
    sources = [repo_path / "hb_up2" / "rtl" / "hb_up2_int2.sv"]
    sources += resolve_flt(prj_path / "cfr.flt")
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cfr_branch",
        sources=sources,
        parameters={
            "DATA_WIDTH": DATA_WIDTH,
            "CPW_ADDR_WIDTH": 2,
            "CPW_DATA_WIDTH": DATA_WIDTH,
            "NUM_CPG": 1,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="cfr_branch",
        hdl_toplevel_lang="verilog",
        test_module="test_cfr_branch_cpw",
        test_args=["-suppress", "7061"] if SIM == "questa" else [],
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
