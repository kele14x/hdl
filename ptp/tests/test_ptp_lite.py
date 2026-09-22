"""PTP master smoke: emit and check a complete Sync frame after each reset."""

import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

ROOT = Path(__file__).resolve().parent.parent
SRC_MAC = bytes.fromhex("02123456789a")
DOMAIN = 7


def expected_sync():
    # Ethernet + PTP common header + zero originTimestamp. This implementation
    # uses majorSdoId=1 and a two-step clock. Check the whole serialized frame.
    clock_identity = SRC_MAC[:3] + b"\xff\xfe" + SRC_MAC[3:]
    header = bytes([0, 0x12]) + (44).to_bytes(2, "big")
    header += bytes([DOMAIN, 0]) + b"\x02\x00" + bytes(12)
    header += clock_identity + b"\x00\x01" + bytes(4)
    return bytes.fromhex("011b19000000") + SRC_MAC + b"\x88\xf7" + header + bytes(10)


async def receive_sync(dut):
    packet = bytearray()
    stalled = None
    for cycle in range(1024):
        await RisingEdge(dut.clk)
        valid = int(dut.m_axis_tvalid.value)
        beat = (
            (
                int(dut.m_axis_tdata.value),
                int(dut.m_axis_tkeep.value),
                int(dut.m_axis_tlast.value),
                int(dut.m_axis_tuser.value),
            )
            if valid
            else None
        )
        if stalled is not None:
            assert valid and beat == stalled, "PTP output changed under backpressure"
        if valid and int(dut.m_axis_tready.value):
            data, keep, last, user = beat
            assert keep == (3 if last else 15)
            assert user >> 16 == 2, "Sync must request a TX timestamp"
            packet.extend(data.to_bytes(4, "little")[: keep.bit_count()])
            if last:
                return bytes(packet)
        stalled = beat if valid and not int(dut.m_axis_tready.value) else None
        # Drive inputs for capture on the following rising edge.
        dut.m_axis_tready.value = int(cycle % 5 != 0)
    raise AssertionError("no complete PTP Sync frame within 1024 cycles")


@cocotb.test(timeout_time=100, timeout_unit="us")
async def test_ptp_lite_sync_and_reset_recovery(dut):
    dut.rst.value = 1
    for name in (
        "s_axis_tdata",
        "s_axis_tkeep",
        "s_axis_tlast",
        "s_axis_tuser",
        "s_axis_tvalid",
        "tx_ptp_timestamp",
        "tx_ptp_timestamp_tag",
        "tx_ptp_timestamp_valid",
        "ctrl_master_en",
        "ctrl_log_sync_interval",
    ):
        getattr(dut, name).value = 0
    dut.m_axis_tready.value = 1
    dut.ctrl_src_mac.value = int.from_bytes(SRC_MAC, "big")
    dut.ctrl_domain_number.value = DOMAIN
    dut.ctrl_utc_offset.value = 37
    dut.ctrl_log_announce_interval.value = 7
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start(start_high=False))

    for _ in range(2):
        await RisingEdge(dut.clk)
        dut.rst.value = 1
        dut.ctrl_master_en.value = 0
        dut.m_axis_tready.value = 1
        await ClockCycles(dut.clk, 8)
        dut.rst.value = 0
        for _ in range(8):
            await RisingEdge(dut.clk)
            assert int(dut.m_axis_tvalid.value) == 0
        dut.ctrl_master_en.value = 1
        assert await receive_sync(dut) == expected_sync()


def test_ptp_lite_runner():
    sim = os.environ["SIM"]
    build_dir = ROOT / "sim_build" / sim / "ptp_lite_smoke"
    runner = get_runner(sim)
    runner.build(
        hdl_toplevel="ptp_lite",
        sources=resolve_flt(ROOT / "ptp.flt"),
        parameters={"CLK_FREQ": 128},
        build_dir=build_dir,
    )
    runner.test(
        hdl_toplevel="ptp_lite",
        test_module=Path(__file__).stem,
        test_dir=build_dir,
    )
