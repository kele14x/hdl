import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


@cocotb.test()
async def test_xpm_fifo_axis_is_reset_gated_transparent_stream(dut):
    cocotb.start_soon(Clock(dut.s_aclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.m_aclk, 14, unit="ns").start())
    dut.s_aresetn.value = 0
    dut.s_axis_tdata.value = 0xA1B2C3D4
    dut.s_axis_tdest.value = 2
    dut.s_axis_tid.value = 1
    dut.s_axis_tkeep.value = 0xF
    dut.s_axis_tlast.value = 1
    dut.s_axis_tstrb.value = 0xD
    dut.s_axis_tuser.value = 3
    dut.s_axis_tvalid.value = 1
    dut.m_axis_tready.value = 1
    dut.injectdbiterr_axis.value = 0
    dut.injectsbiterr_axis.value = 0
    await Timer(1, unit="ns")
    assert int(dut.s_axis_tready.value) == 0
    assert int(dut.m_axis_tvalid.value) == 0

    dut.s_aresetn.value = 1
    dut.m_axis_tready.value = 0
    await Timer(1, unit="ns")
    assert int(dut.s_axis_tready.value) == 0
    assert int(dut.m_axis_tvalid.value) == 1
    assert int(dut.m_axis_tdata.value) == 0xA1B2C3D4
    assert int(dut.m_axis_tdest.value) == 2
    assert int(dut.m_axis_tid.value) == 1
    assert int(dut.m_axis_tkeep.value) == 0xF
    assert int(dut.m_axis_tlast.value) == 1
    assert int(dut.m_axis_tstrb.value) == 0xD
    assert int(dut.m_axis_tuser.value) == 3

    dut.m_axis_tready.value = 1
    await Timer(1, unit="ns")
    assert int(dut.s_axis_tready.value) == 1
    assert int(dut.wr_data_count_axis.value) == 0
    assert int(dut.rd_data_count_axis.value) == 0
    assert int(dut.almost_full_axis.value) == 0
    assert int(dut.prog_full_axis.value) == 0
    assert int(dut.almost_empty_axis.value) == 1
    assert int(dut.prog_empty_axis.value) == 1
    assert int(dut.sbiterr_axis.value) == 0
    assert int(dut.dbiterr_axis.value) == 0


def test_xpm_fifo_axis_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="xpm_fifo_axis",
        sources=resolve_flt(prj_path / "xpm.flt"),
        parameters={"TDATA_WIDTH": 32, "TDEST_WIDTH": 2, "TID_WIDTH": 1, "TUSER_WIDTH": 2},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="xpm_fifo_axis",
        hdl_toplevel_lang="verilog",
        test_module="test_xpm_fifo_axis",
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
