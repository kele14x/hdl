#!/usr/bin/env python3
import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner
from libcdc import wait_for_value

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"

# Build parameters arrive via extra_env because the runner and the simulator
# are separate Python processes.
DEST_EXT_HSK = int(os.environ.get("DEST_EXT_HSK", "1"))


async def send_values(dut, values):
    for value in values:
        await wait_for_value(dut.src_ready, dut.src_clk, 1, cycles=50)
        dut.src_in.value = value
        dut.src_valid.value = 1
        await RisingEdge(dut.src_clk)
        dut.src_valid.value = 0


@cocotb.test()
async def test_cdc_handshake_transfers_data_under_destination_backpressure(dut):
    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 11, unit="ns").start())
    dut.src_in.value = 0
    dut.src_valid.value = 0
    dut.dest_ready.value = 0
    await ClockCycles(dut.src_clk, 5)

    expected = [0x15, 0xA2, 0x3C]
    received = []

    async def receive():
        for _ in expected:
            await with_timeout(RisingEdge(dut.dest_valid), 2, "us")
            received.append(int(dut.dest_out.value))
            await ClockCycles(dut.dest_clk, 2)
            dut.dest_ready.value = 1
            await RisingEdge(dut.dest_clk)
            dut.dest_ready.value = 0

    receiver = cocotb.start_soon(receive())
    await send_values(dut, expected)

    await with_timeout(receiver, 5, "us")
    assert received == expected


@cocotb.test()
async def test_cdc_handshake_auto_accepts_when_no_ext_hsk(dut):
    if DEST_EXT_HSK != 0:
        return

    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 11, unit="ns").start())
    dut.src_in.value = 0
    dut.src_valid.value = 0
    # With DEST_EXT_HSK=0 the destination accepts automatically, so holding
    # dest_ready low for the whole test must not stall anything.
    dut.dest_ready.value = 0
    await ClockCycles(dut.src_clk, 5)

    expected = [0x5A, 0x6B, 0x7C]
    received = []

    async def receive():
        for _ in expected:
            await with_timeout(RisingEdge(dut.dest_valid), 2, "us")
            received.append(int(dut.dest_out.value))

    receiver = cocotb.start_soon(receive())
    await send_values(dut, expected)

    await with_timeout(receiver, 5, "us")
    assert received == expected


async def wait_ready(dut):
    for _ in range(100):
        await RisingEdge(dut.src_clk)
        if int(dut.src_ready.value):
            return
    raise AssertionError(
        "source did not become ready after the acknowledgement round trip"
    )


@cocotb.test()
async def test_cdc_handshake_holds_one_outstanding_transfer_until_consumed(dut):
    if DEST_EXT_HSK != 1:
        return

    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 11, unit="ns").start())
    dut.src_in.value = 0
    dut.src_valid.value = 0
    dut.dest_ready.value = 0
    await ClockCycles(dut.src_clk, 5)
    await wait_ready(dut)

    for value in (0x00, 0xA5, 0x3C):
        await RisingEdge(dut.src_clk)
        assert int(dut.src_ready.value) == 1
        dut.src_in.value = value
        dut.src_valid.value = 1
        await RisingEdge(dut.src_clk)
        dut.src_valid.value = 0

        # The receiving endpoint is deliberately blocked.  The destination
        # interface must keep valid and data stable rather than overwrite the
        # single outstanding transaction.
        await with_timeout(RisingEdge(dut.dest_valid), 2, "us")
        assert int(dut.dest_out.value) == value
        for _ in range(4):
            await RisingEdge(dut.dest_clk)
            assert int(dut.dest_valid.value) == 1
            assert int(dut.dest_out.value) == value

        await RisingEdge(dut.dest_clk)
        dut.dest_ready.value = 1
        await RisingEdge(dut.dest_clk)
        dut.dest_ready.value = 0
        await RisingEdge(dut.dest_clk)
        assert int(dut.dest_valid.value) == 0
        await wait_ready(dut)


CASES = [
    {
        "name": "hsk1_init1",
        "params": {
            "DEST_EXT_HSK": 1,
            "DEST_SYNC_FF": 2,
            "INIT_SYNC_FF": 1,
            "SRC_SYNC_FF": 2,
            "WIDTH": 8,
        },
    },
    {
        "name": "hsk0_init1",
        "params": {
            "DEST_EXT_HSK": 0,
            "DEST_SYNC_FF": 2,
            "INIT_SYNC_FF": 1,
            "SRC_SYNC_FF": 2,
            "WIDTH": 8,
        },
    },
    {
        "name": "hsk1_init0",
        "params": {
            "DEST_EXT_HSK": 1,
            "DEST_SYNC_FF": 2,
            "INIT_SYNC_FF": 0,
            "SRC_SYNC_FF": 2,
            "WIDTH": 8,
        },
    },
]


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_cdc_handshake_f_runner(case):
    parameters = case["params"]
    run_dir = prj_path / "sim_build" / case["name"]
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="cdc_handshake_f",
        sources=resolve_flt(prj_path / "cdc.flt"),
        parameters=parameters,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="cdc_handshake_f",
        hdl_toplevel_lang="verilog",
        test_module="test_cdc_handshake_f",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
        extra_env={key: str(value) for key, value in parameters.items()},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
