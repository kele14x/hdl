#!/usr/bin/env python3

import os
from pathlib import Path
from typing import Tuple

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Combine, RisingEdge
from cocotb_tools.runner import get_runner

ADDR_WIDTH = 10
DATA_WIDTH = 32

AXI_TIMEOUT_CYCLES = 16


async def reset_dut(dut):
    dut.s_axi_aresetn.value = 0
    # AW
    dut.s_axi_awaddr.value = 0
    # dut.s_axi_awprot.value = 0
    dut.s_axi_awvalid.value = 0
    # W
    dut.s_axi_wdata.value = 0
    dut.s_axi_wstrb.value = 0
    dut.s_axi_wvalid.value = 0
    # B
    dut.s_axi_bready.value = 0
    # AR
    dut.s_axi_araddr.value = 0
    # dut.s_axi_arprot.value = 0
    dut.s_axi_arvalid.value = 0
    # R
    dut.s_axi_rready.value = 0
    await ClockCycles(dut.s_axi_aclk, 10)
    dut.s_axi_aresetn.value = 1
    await ClockCycles(dut.s_axi_aclk, 10)


async def axi_aw(dut, addr: int | list[int]):
    if isinstance(addr, int):
        addr = [addr]
    for a in addr:
        dut.s_axi_awaddr.value = a
        dut.s_axi_awvalid.value = 1
        for t in range(AXI_TIMEOUT_CYCLES):
            await RisingEdge(dut.s_axi_aclk)
            if int(dut.s_axi_awready.value):
                break
            elif t == AXI_TIMEOUT_CYCLES - 1:
                raise TimeoutError("AXI AW handshake timeout")
    dut.s_axi_awvalid.value = 0


async def axi_w(dut, data: int | list[int]):
    if isinstance(data, int):
        data = [data]
    for d in data:
        dut.s_axi_wdata.value = d
        dut.s_axi_wstrb.value = (2 ** (DATA_WIDTH // 8)) - 1
        dut.s_axi_wvalid.value = 1
        for t in range(AXI_TIMEOUT_CYCLES):
            await RisingEdge(dut.s_axi_aclk)
            if int(dut.s_axi_wready.value):
                break
            elif t == AXI_TIMEOUT_CYCLES - 1:
                raise TimeoutError("AXI W handshake timeout")
    dut.s_axi_wvalid.value = 0


async def axi_b(dut, n: int = 1) -> int | list[int]:
    bresp = []
    for i in range(n):
        dut.s_axi_bready.value = 1
        for t in range(AXI_TIMEOUT_CYCLES):
            await RisingEdge(dut.s_axi_aclk)
            if int(dut.s_axi_bvalid.value):
                bresp.append(int(dut.s_axi_bresp.value))
                break
            elif t == AXI_TIMEOUT_CYCLES - 1:
                raise TimeoutError("AXI B handshake timeout")
    dut.s_axi_bready.value = 0
    return bresp[0] if n == 1 else bresp


async def axi_ar(dut, addr: int | list[int]):
    if isinstance(addr, int):
        addr = [addr]
    for a in addr:
        dut.s_axi_araddr.value = a
        dut.s_axi_arvalid.value = 1
        for t in range(AXI_TIMEOUT_CYCLES):
            await RisingEdge(dut.s_axi_aclk)
            if int(dut.s_axi_arready.value):
                break
            elif t == AXI_TIMEOUT_CYCLES - 1:
                raise TimeoutError("AXI AR handshake timeout")
    dut.s_axi_arvalid.value = 0


async def axi_r(dut, n: int = 1) -> tuple[int, int] | list[tuple[int, int]]:
    res = []
    for i in range(n):
        dut.s_axi_rready.value = 1
        for t in range(AXI_TIMEOUT_CYCLES):
            await RisingEdge(dut.s_axi_aclk)
            if int(dut.s_axi_rvalid.value):
                rdata = int(dut.s_axi_rdata.value)
                rresp = int(dut.s_axi_rresp.value)
                res.append((rdata, rresp))
                break
            elif t == AXI_TIMEOUT_CYCLES - 1:
                raise TimeoutError("AXI R handshake timeout")
    dut.s_axi_rready.value = 0
    return res[0] if n == 1 else res


async def axi_write(
    dut, addr: int | list[int], data: int | list[int]
) -> int | list[int]:
    data_len = 1 if isinstance(data, int) else len(data)
    addr_len = 1 if isinstance(addr, int) else len(addr)
    assert addr_len == data_len, "Address and data length mismatch"
    aw = cocotb.start_soon(axi_aw(dut, addr))
    w = cocotb.start_soon(axi_w(dut, data))
    b = cocotb.start_soon(axi_b(dut, addr_len))
    await Combine(aw, w, b)
    return b.result()


async def axi_read(
    dut, addr: int | list[int]
) -> tuple[int, int] | list[tuple[int, int]]:
    addr_len = 1 if isinstance(addr, int) else len(addr)
    ar = cocotb.start_soon(axi_ar(dut, addr))
    r = cocotb.start_soon(axi_r(dut, addr_len))
    await Combine(ar, r)
    return r.result()


async def model(dut):
    mem = {}
    write_ack = False
    write_err = False
    read_ack = False
    read_err = False
    read_data = 0
    while True:
        await RisingEdge(dut.s_axi_aclk)
        # Reset condition
        if not dut.s_axi_aresetn.value:
            mem = {}
            write_ack = False
            write_err = False
            read_ack = False
            read_err = False
            read_data = 0
            dut.int_wr_ack.value = 0
            dut.int_wr_err.value = 0
            dut.int_rd_ack.value = 0
            dut.int_rd_err.value = 0
            dut.int_rd_data.value = 0
            continue

        # Write operation
        if int(dut.int_wr_en.value):
            addr = int(dut.int_addr.value)
            data = int(dut.int_wr_data.value)
            mem[addr] = data
            write_ack = True
            write_err = False
        # Read operation
        if int(dut.int_rd_en.value):
            addr = int(dut.int_addr.value)
            read_ack = True
            read_err = False
            read_data = mem[addr] if addr in mem else 0

        # Write response
        dut.int_wr_ack.value = 1 if write_ack else 0
        dut.int_wr_err.value = 1 if write_err else 0
        write_ack = False
        # Read response
        dut.int_rd_ack.value = 1 if read_ack else 0
        dut.int_rd_err.value = 1 if read_err else 0
        dut.int_rd_data.value = read_data
        read_ack = False


@cocotb.test()
async def test_axi4l_ipif_simple_one_write(dut):
    # Start clock and model
    Clock(dut.s_axi_aclk, 10, unit="ns").start()
    cocotb.start_soon(model(dut))

    # Reset DUT
    await reset_dut(dut)

    # Simple write test
    test_addr = 0x04
    test_data = 0xDEADBEEF
    bresp = await axi_write(dut, test_addr, test_data)
    assert bresp == 0, f"AXI write response error: bresp={bresp}"

    # Recovery
    await ClockCycles(dut.s_axi_aclk, 10)


@cocotb.test()
async def test_axi4l_ipif_simple_b2b_write(dut):
    # Start clock and model
    Clock(dut.s_axi_aclk, 10, unit="ns").start()
    cocotb.start_soon(model(dut))

    # Reset DUT
    await reset_dut(dut)

    # Simple write test
    test_addr = [0x04 + i * 4 for i in range(5)]
    test_data = [0xDEADBEEF + i for i in range(5)]
    bresp = await axi_write(dut, test_addr, test_data)
    assert isinstance(bresp, list), "AXI write response should be a list"
    assert all(b == 0 for b in bresp), f"AXI write response error: bresp={bresp}"

    # Recovery
    await ClockCycles(dut.s_axi_aclk, 10)


def test_axi4l_ipif_runner():
    sim = os.getenv("SIM", "verilator")

    proj_path = Path(__file__).resolve().parent
    sources = [
        proj_path / "../rtl/axi4l_ipif.sv",
    ]
    hdl_toplevel = "axi4l_ipif"

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        parameters={
            "ADDR_WIDTH": ADDR_WIDTH,
            "DATA_WIDTH": DATA_WIDTH,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module="test_axi4l_ipif",
        waves=True,
    )


if __name__ == "__main__":
    test_axi4l_ipif_runner()
