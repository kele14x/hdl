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


async def tick(dut):
    await RisingEdge(dut.clk)
    await ReadWrite()


async def initialize(dut):
    dut.rst.value = 1
    dut.ctrl_rst.value = 1
    dut.data_i_in.value = 0
    dut.data_q_in.value = 0
    dut.peak_i_in.value = 0
    dut.peak_q_in.value = 0
    dut.peak_phase_in.value = 0
    dut.peak_valid_in.value = 0
    dut.ctrl_cpw_addr.value = 0
    dut.ctrl_cpw_en.value = 0
    dut.ctrl_cpw_we.value = 0
    dut.ctrl_cpw_wr_data_i.value = 0
    dut.ctrl_cpw_wr_data_q.value = 0
    for _ in range(5):
        await tick(dut)
    assert int(dut.peak_valid_out.value) == 0
    dut.rst.value = 0
    dut.ctrl_rst.value = 0


async def drive_peak(dut, i_value, q_value, phase, valid):
    await FallingEdge(dut.clk)
    dut.peak_i_in.value = i_value
    dut.peak_q_in.value = q_value
    dut.peak_phase_in.value = phase
    dut.peak_valid_in.value = valid


async def check_busy_forwards_second_peak(dut):
    await drive_peak(dut, 12, -9, 1, 1)
    await tick(dut)
    assert int(dut.peak_valid_out.value) == 0

    await drive_peak(dut, 23, 7, 0, 1)
    await tick(dut)
    # Once a pulse is active, a competing peak must be passed to the next CPG.
    assert int(dut.peak_valid_out.value) == 1

    await drive_peak(dut, 0, 0, 0, 0)
    await tick(dut)
    assert int(dut.peak_valid_out.value) == 0


@cocotb.test()
async def test_cfr_pc_cpg_busy_peak_forwarding_and_reset(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 14, unit="ns").start())
    await initialize(dut)
    await check_busy_forwards_second_peak(dut)


@cocotb.test()
async def test_cfr_pc_softclipper_cpg_stage_busy_forwarding_and_reset(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 14, unit="ns").start())
    await initialize(dut)
    await check_busy_forwards_second_peak(dut)


def sources():
    return (
        resolve_flt(prj_path / "cfr_pc.flt")
        + resolve_flt(repo_path / "cmult" / "cmult.flt")
        + resolve_flt(repo_path / "adder" / "adder.flt")
    )


def run(top, testcase, extra_parameters=None):
    if SIM == "questa":
        pytest.skip(
            "Questa Starter denied elaboration after the full CPG dependency set "
            "was compiled; the leaf test remains available for an unrestricted license."
        )
    parameters = {"CSR": 1, "PHASE_WIDTH": 1, "DATA_WIDTH": 8, "CPW_ADDR_WIDTH": 2}
    if extra_parameters:
        parameters.update(extra_parameters)
    runner = get_runner(SIM)
    runner.build(hdl_toplevel=top, sources=sources(), parameters=parameters, always=True, waves=True)
    runner.test(
        hdl_toplevel=top,
        hdl_toplevel_lang="verilog",
        test_module="test_cfr_pc_cpg",
        testcase=testcase,
    )


def test_cfr_pc_cpg_runner():
    run("cfr_pc_cpg", "test_cfr_pc_cpg_busy_peak_forwarding_and_reset")


def test_cfr_pc_softclipper_runner():
    run(
        "cfr_pc_softclipper",
        "test_cfr_pc_softclipper_cpg_stage_busy_forwarding_and_reset",
        {"NUM_CPG": 1},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
