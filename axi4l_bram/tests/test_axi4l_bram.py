#!/usr/bin/env python3
"""Cocotb regression for the shared AXI4-Lite BRAM adapter."""

from __future__ import annotations

from collections import deque
import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadWrite, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt


PRJ_PATH = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
ADDR_WIDTH = int(os.environ.get("ADDR_WIDTH", "32"))
DATA_WIDTH = int(os.environ.get("DATA_WIDTH", "32"))
DATA_XOR = 0xDEAD_BEEF


async def reset(dut) -> None:
    dut.aresetn.value = 0
    dut.awvalid.value = 0
    dut.wvalid.value = 0
    dut.arvalid.value = 0
    dut.bready.value = 0
    dut.rready.value = 0
    dut.bram_ack.value = 0
    dut.bram_rdata.value = 0
    await ClockCycles(dut.aclk, 4)
    dut.aresetn.value = 1
    await ClockCycles(dut.aclk, 2)


async def send(dut, prefix: str, value: int) -> None:
    getattr(dut, f"{prefix}valid").value = 1
    if prefix in {"aw", "ar"}:
        getattr(dut, f"{prefix}addr").value = value
    else:
        dut.wdata.value = value
        dut.wstrb.value = (1 << (DATA_WIDTH // 8)) - 1
    while True:
        await RisingEdge(dut.aclk)
        if int(getattr(dut, f"{prefix}ready").value):
            break
    getattr(dut, f"{prefix}valid").value = 0


async def bram_model(dut, issued: list[tuple[bool, int, int]]) -> None:
    pending: deque[tuple[bool, int]] = deque()
    dut.bram_ack.value = 0
    while True:
        await RisingEdge(dut.aclk)
        await ReadWrite()
        dut.bram_ack.value = 0
        if int(dut.bram_en.value):
            is_write = bool(int(dut.bram_we.value))
            address = int(dut.bram_addr.value)
            data = int(dut.bram_wdata.value) if is_write else 0
            issued.append((is_write, address, data))
            pending.append((is_write, address))
        if pending:
            is_write, address = pending.popleft()
            dut.bram_rdata.value = address ^ DATA_XOR
            dut.bram_ack.value = 1


@cocotb.test()
async def test_mixed_read_write_traffic(dut) -> None:
    """Read and write responses retain command order on one BRAM port."""
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    await reset(dut)
    issued: list[tuple[bool, int, int]] = []
    cocotb.start_soon(bram_model(dut, issued))

    dut.bready.value = 1
    dut.rready.value = 1
    writes = [(0x200, 0x1234_5678), (0x204, 0xCAFE_BABE)]
    reads = [0x100, 0x104]
    for address, data in writes:
        await with_timeout(
            cocotb.start_soon(send(dut, "aw", address)), 2, "us"
        )
        await with_timeout(cocotb.start_soon(send(dut, "w", data)), 2, "us")
    for address in reads:
        await with_timeout(cocotb.start_soon(send(dut, "ar", address)), 2, "us")

    got_b = 0
    got_r: list[int] = []
    for _ in range(100):
        await RisingEdge(dut.aclk)
        if int(dut.bvalid.value):
            assert int(dut.bresp.value) == 0
            got_b += 1
        if int(dut.rvalid.value):
            assert int(dut.rresp.value) == 0
            got_r.append(int(dut.rdata.value))
        if got_b == len(writes) and len(got_r) == len(reads):
            break
    assert got_b == len(writes)
    assert got_r == [address ^ DATA_XOR for address in reads]
    # The arbiter flips preference after every allocation, so the buffered
    # traffic is interleaved while both reads and writes are available.
    assert issued == [
        (True, writes[0][0], writes[0][1]),
        (False, reads[0], 0),
        (True, writes[1][0], writes[1][1]),
        (False, reads[1], 0),
    ]


def test_axi4l_bram_runner() -> None:
    """Build and execute the cocotb regression."""
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="axi4l_bram",
        sources=resolve_flt(PRJ_PATH / "axi4l_bram.flt"),
        parameters={"ADDR_WIDTH": ADDR_WIDTH, "DATA_WIDTH": DATA_WIDTH},
        always=True,
        waves=True,
    )
    runner.test(hdl_toplevel="axi4l_bram", test_module="test_axi4l_bram", waves=True)


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
