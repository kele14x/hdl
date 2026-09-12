"""Directed test for prach_ctrl C-Plane capture.

One C-Plane bus is broadcast to every CC channel, so a section ID may only be
loaded by a message for this instance's own CC and antennas. A message for
another CC must not relabel a section that this channel still has in flight.
"""

from __future__ import annotations

import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

PRJ_PATH = Path(__file__).resolve().parent.parent
REPO_PATH = PRJ_PATH.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

# Parameters reach the cocotb process only through the environment because the
# runner and the simulator are separate processes.
CASE_NAME = os.environ.get("PRACH_CTRL_CASE", "ant0")

CLK_PERIOD_NS = 10
ETH_CLK_PERIOD_NS = 6

# One build/test pair per c_plane_match branch: the ANT_ID == 0 instance owns
# every antenna of its CC, the other starts the window at ANT_ID.
CASES = {
    "ant0": {"CC_ID": 1, "ANT_ID": 0, "NUM_ANT": 4},
    "antn": {"CC_ID": 2, "ANT_ID": 1, "NUM_ANT": 2},
}

CP_FIELDS = [
    "s_prach_rtc_pc_id",
    "s_prach_cc",
    "s_prach_ss",
    "s_prach_section_id",
    "s_prach_return_port",
    "s_prach_filter_index",
    "s_prach_f",
    "s_prach_sf",
    "s_prach_sl",
    "s_prach_sy",
    "s_prach_time_offset",
    "s_prach_frame_structure",
    "s_prach_cp_length",
    "s_prach_udcomphdr",
    "s_prach_rb",
    "s_prach_syminc",
    "s_prach_start_prbc",
    "s_prach_num_prbc",
    "s_prach_remask",
    "s_prach_num_symbol",
    "s_prach_beamid",
    "s_prach_freqoffset",
]


def _field(value, width):
    return value & ((1 << width) - 1)


async def _reset(dut):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, ETH_CLK_PERIOD_NS, unit="ns").start())
    dut.rst.value = 1
    dut.rst_eth_xran.value = 0
    dut.ctrl_clk.value = 0
    dut.ctrl_rst.value = 0
    dut.s_prach_tvalid.value = 0
    for name in CP_FIELDS:
        getattr(dut, name).value = 0
    await ClockCycles(dut.clk, 6)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 4)


async def _settle(dut):
    """Let the source-side handshake retire the transfer before the next one."""
    for _ in range(200):
        await RisingEdge(dut.clk_eth_xran)
        if not int(dut.prach_src_ready.value):
            break
    await ClockCycles(dut.clk, 12)


async def _push_c_plane(dut, **fields):
    """Present one C-Plane message and wait for the handshake to accept it."""
    for _ in range(200):
        await RisingEdge(dut.clk_eth_xran)
        if int(dut.prach_src_ready.value):
            break
    else:
        raise AssertionError("prach_src_ready did not assert")

    for name in CP_FIELDS:
        getattr(dut, name).value = 0
    for name, value in fields.items():
        getattr(dut, name).value = value
    dut.s_prach_tvalid.value = 1
    await RisingEdge(dut.clk_eth_xran)
    dut.s_prach_tvalid.value = 0
    await _settle(dut)


async def _check_section(dut, expected):
    observed = int(dut.rd_section_id.value)
    assert observed == expected, (
        f"rd_section_id is 0x{observed:03x}, expected 0x{expected:03x}"
    )


async def _run_case(dut, cc_id, ant_id, num_ant):
    await _reset(dut)

    if ant_id == 0:
        outside_ants = [_field(num_ant, 8)]  # first antenna outside the window
    else:
        outside_ants = [0, _field(ant_id + num_ant, 8)]

    # A C-Plane message for this CC loads the section ID.
    await _push_c_plane(
        dut, s_prach_cc=cc_id, s_prach_ss=ant_id, s_prach_section_id=0x321
    )
    await _check_section(dut, 0x321)

    # Another CC sharing the bus must not relabel the pending section.
    await _push_c_plane(
        dut,
        s_prach_cc=_field(cc_id + 1, 4),
        s_prach_ss=ant_id,
        s_prach_section_id=0x654,
    )
    await _check_section(dut, 0x321)

    # Antennas outside this instance's window are not ours either.
    for ss in outside_ants:
        await _push_c_plane(
            dut, s_prach_cc=cc_id, s_prach_ss=ss, s_prach_section_id=0x777
        )
        await _check_section(dut, 0x321)

    # Our own CC still tracks a new section.
    await _push_c_plane(
        dut, s_prach_cc=cc_id, s_prach_ss=ant_id, s_prach_section_id=0x0AB
    )
    await _check_section(dut, 0x0AB)


@cocotb.test()
async def test_prach_ctrl_section_id(dut):
    case = CASES[CASE_NAME]
    await _run_case(dut, case["CC_ID"], case["ANT_ID"], case["NUM_ANT"])


def _run_case_runner(name, case):
    run_dir = PRJ_PATH / "sim_build" / f"prach_ctrl_{name}"
    sources = [
        REPO_PATH / "cdc" / "rtl" / "cdc_array_single.sv",
        REPO_PATH / "cdc" / "rtl" / "cdc_handshake_f.sv",
        REPO_PATH / "cdc" / "rtl" / "cdc_single.sv",
        PRJ_PATH / "rtl" / "prach_ctrl.sv",
    ]
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="prach_ctrl",
        sources=sources,
        parameters={
            "CC_ID": case["CC_ID"],
            "ANT_ID": case["ANT_ID"],
            "NUM_ANT": case["NUM_ANT"],
        },
        build_args=["-suppress", "2892"] if SIM == "questa" else [],
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="prach_ctrl",
        hdl_toplevel_lang="verilog",
        test_module="test_prach_ctrl",
        test_args=["-suppress", "7061"] if SIM == "questa" else [],
        waves=True,
        gui=os.environ.get("GUI", "false").lower() == "true",
        test_dir=run_dir,
        extra_env={
            "PRACH_CTRL_CASE": name,
            "CC_ID": str(case["CC_ID"]),
            "ANT_ID": str(case["ANT_ID"]),
            "NUM_ANT": str(case["NUM_ANT"]),
        },
    )


@pytest.mark.parametrize("name", list(CASES))
def test_prach_ctrl_runner(name):
    _run_case_runner(name, CASES[name])


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
