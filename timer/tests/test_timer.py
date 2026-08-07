import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb_tools.runner import get_runner
from hdl_tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, RisingEdge
from libaxi4l import axi_reset, axi_read, axi_write

# MARK: Env

prj_path = Path(__file__).resolve().parent.parent


SIM_SPEED_UP = int(os.environ.get("SIM_SPEED_UP", 1))
NS_PER_SECOND = 100_000 if SIM_SPEED_UP else 1_000_000_000

GUI = os.environ.get("GUI", "false").lower() == "true"

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")


REG_VERSION = 0x0
REG_SCRATCH0 = 0x4
REG_SCRATCH1 = 0x8
REG_RTC_OFFSET_NS = 0x10
REG_RTC_OFFSET_SEC_L = 0x14
REG_RTC_OFFSET_SEC_H = 0x18
REG_RTC_OFFSET_VALID = 0x1C
REG_RTC_CURRENT_NS = 0x20
REG_RTC_CURRENT_SEC_L = 0x24
REG_RTC_CURRENT_SEC_H = 0x28
REG_RTC_CURRENT_SNAP = 0x2C


# MARK: Helper


async def reset(dut):
    """Reset the DUT"""
    dut.rst.value = 1
    dut.s_axi_aresetn.value = 0

    await axi_reset(dut)

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    dut.s_axi_aresetn.value = 1
    await ClockCycles(dut.clk, 10)


async def config(dut):
    """Configure the DUT"""
    data = await axi_read(dut, REG_VERSION)
    assert data == 0x20241106

    await axi_write(dut, REG_SCRATCH0, 0x12345678)
    data = await axi_read(dut, REG_SCRATCH0)
    assert data == 0x12345678

    await axi_write(dut, REG_SCRATCH1, 0x9ABCDEF0)
    data = await axi_read(dut, REG_SCRATCH1)
    assert data == 0x9ABCDEF0


async def get_offset(dut):
    """Get the current offset"""
    ns = await axi_read(dut, REG_RTC_OFFSET_NS)
    sec_l = await axi_read(dut, REG_RTC_OFFSET_SEC_L)
    sec_h = await axi_read(dut, REG_RTC_OFFSET_SEC_H)
    sec = (sec_h << 16) | sec_l
    return ns, sec


async def set_offset(dut, ns, sec):
    """Set the current offset"""
    await axi_write(dut, REG_RTC_OFFSET_NS, ns)
    await axi_write(dut, REG_RTC_OFFSET_SEC_L, sec & 0xFFFF)
    await axi_write(dut, REG_RTC_OFFSET_SEC_H, (sec >> 16) & 0xFF)
    await axi_write(dut, REG_RTC_OFFSET_VALID, 0x1)


async def get_time(dut):
    """Get the current time"""
    await axi_write(dut, REG_RTC_CURRENT_SNAP, 0x1)
    # Allow both CDC handshakes to return the corresponding snapshot.
    await ClockCycles(dut.s_axi_aclk, 20)
    ns = await axi_read(dut, REG_RTC_CURRENT_NS)
    sec_l = await axi_read(dut, REG_RTC_CURRENT_SEC_L)
    sec_h = await axi_read(dut, REG_RTC_CURRENT_SEC_H)
    sec = (sec_h << 16) | sec_l
    return ns, sec


async def set_time(dut, ns, sec):
    """Set the current time"""
    # Get the current time
    current_ns, current_sec = await get_time(dut)
    offset_ns, offset_sec = await get_offset(dut)

    # Calculate the offset
    offset_ns = int(ns - current_ns + offset_ns)
    offset_sec = int(sec - current_sec + offset_sec)
    if offset_ns < 0:
        offset_ns += NS_PER_SECOND
        offset_sec -= 1
    if offset_ns >= NS_PER_SECOND:
        offset_ns -= NS_PER_SECOND
        offset_sec += 1

    # Set the offset
    await set_offset(dut, offset_ns, offset_sec)


@cocotb.test
async def test_timer(dut):
    """Test the timer"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, unit="ns").start(start_high=False))

    # Reset the DUT
    await reset(dut)
    await config(dut)

    await set_offset(dut, 0, 0)
    await ClockCycles(dut.clk, 64)

    ns_before, sec_before = await get_time(dut)
    await ClockCycles(dut.clk, 64)
    ns_after, sec_after = await get_time(dut)
    elapsed = (sec_after - sec_before) * NS_PER_SECOND + ns_after - ns_before
    assert elapsed > 0, "RTC did not advance"
    assert 0 <= ns_after < NS_PER_SECOND, "RTC nanoseconds are out of range"

    # Place the RTC just before its (accelerated) second boundary, then verify
    # that the carry reaches the seconds counter in a bounded number of cycles.
    await set_time(dut, NS_PER_SECOND - 20, 10)
    await ClockCycles(dut.clk, 128)
    ns, sec = await get_time(dut)
    assert sec >= 11, "RTC second carry did not occur"
    assert 0 <= ns < NS_PER_SECOND, "RTC nanoseconds did not wrap correctly"
    cocotb.log.info("Simulation finished")


def test_timer_runner():
    """Run the test"""
    hdl_toplevel = "timer"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "timer.flt")

    parameters = {
        "SIM_SPEED_UP": SIM_SPEED_UP,
    }

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        build_args=[],
        waves=True,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_timer",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
