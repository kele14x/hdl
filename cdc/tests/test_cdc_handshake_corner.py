import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"


async def wait_ready(dut):
    for _ in range(100):
        await RisingEdge(dut.src_clk)
        await ReadOnly()
        if int(dut.src_ready.value):
            return
    raise AssertionError(
        "source did not become ready after the acknowledgement round trip"
    )


@cocotb.test()
async def test_cdc_handshake_holds_one_outstanding_transfer_until_consumed(dut):
    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 11, unit="ns").start())
    dut.src_in.value = 0
    dut.src_valid.value = 0
    dut.dest_ready.value = 0
    await ClockCycles(dut.src_clk, 5)
    await wait_ready(dut)

    for value in (0x00, 0xA5, 0x3C):
        await FallingEdge(dut.src_clk)
        dut.src_in.value = value
        dut.src_valid.value = 1
        await ReadOnly()
        assert int(dut.src_ready.value) == 1
        await RisingEdge(dut.src_clk)
        dut.src_valid.value = 0

        # The receiving endpoint is deliberately blocked.  The destination
        # interface must keep valid and data stable rather than overwrite the
        # single outstanding transaction.
        await with_timeout(RisingEdge(dut.dest_valid), 2, "us")
        await ReadOnly()
        assert int(dut.dest_out.value) == value
        for _ in range(4):
            await RisingEdge(dut.dest_clk)
            await ReadOnly()
            assert int(dut.dest_valid.value) == 1
            assert int(dut.dest_out.value) == value

        await FallingEdge(dut.dest_clk)
        dut.dest_ready.value = 1
        await RisingEdge(dut.dest_clk)
        await ReadOnly()
        assert int(dut.dest_valid.value) == 0
        await FallingEdge(dut.dest_clk)
        dut.dest_ready.value = 0
        await wait_ready(dut)


def test_cdc_handshake_corner_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cdc_handshake_f",
        verilog_sources=resolve_flt(prj_path / "cdc.flt"),
        parameters={
            "DEST_EXT_HSK": 1,
            "DEST_SYNC_FF": 2,
            "INIT_SYNC_FF": 1,
            "SRC_SYNC_FF": 2,
            "WIDTH": 8,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="cdc_handshake_f",
        hdl_toplevel_lang="verilog",
        test_module="test_cdc_handshake_corner",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
