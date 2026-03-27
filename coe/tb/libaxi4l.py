"""AXI4 Lite interface helpers"""

import cocotb
from cocotb.triggers import RisingEdge, Combine


async def axi_reset(dut):
    """Reset the AXI interface"""
    dut.s_axi_awaddr.value = 0
    dut.s_axi_awprot.value = 0
    dut.s_axi_awvalid.value = 0
    #
    dut.s_axi_wdata.value = 0
    dut.s_axi_wstrb.value = 0
    dut.s_axi_wvalid.value = 0
    #
    dut.s_axi_bready.value = 0
    #
    dut.s_axi_araddr.value = 0
    dut.s_axi_arprot.value = 0
    dut.s_axi_arvalid.value = 0
    #
    dut.s_axi_rready.value = 0


async def axi_aw(dut, addr):
    """Send an AXI write address"""
    dut.s_axi_awaddr.value = addr
    dut.s_axi_awvalid.value = 1
    while True:
        await RisingEdge(dut.s_axi_aclk)
        if dut.s_axi_awready.value:
            break
    dut.s_axi_awvalid.value = 0


async def axi_w(dut, data):
    """Send an AXI write data"""
    dut.s_axi_wdata.value = data
    dut.s_axi_wvalid.value = 1
    while True:
        await RisingEdge(dut.s_axi_aclk)
        if dut.s_axi_wready.value:
            break
    dut.s_axi_wvalid.value = 0


async def axi_b(dut):
    """Wait for an AXI write response"""
    dut.s_axi_bready.value = 1
    while True:
        await RisingEdge(dut.s_axi_aclk)
        if dut.s_axi_bvalid.value:
            assert dut.s_axi_bresp.value == 0
            break
    dut.s_axi_bready.value = 0


async def axi_ar(dut, addr):
    """Send an AXI read address"""
    dut.s_axi_araddr.value = addr
    dut.s_axi_arvalid.value = 1
    while True:
        await RisingEdge(dut.s_axi_aclk)
        if dut.s_axi_arready.value:
            break
    dut.s_axi_arvalid.value = 0


async def axi_r(dut):
    """Wait for an AXI read response"""
    dut.s_axi_rready.value = 1
    while True:
        await RisingEdge(dut.s_axi_aclk)
        if dut.s_axi_rvalid.value:
            assert dut.s_axi_rresp.value == 0
            break
    dut.s_axi_rready.value = 0
    return dut.s_axi_rdata.value.integer


async def axi_write(dut, addr, data):
    """Send an AXI write transaction"""
    aw = cocotb.start_soon(axi_aw(dut, addr))
    w = cocotb.start_soon(axi_w(dut, data))
    b = cocotb.start_soon(axi_b(dut))
    await Combine(aw, w, b)
    cocotb.log.info("AXI write: %s <- %s", hex(addr), hex(data))


async def axi_read(dut, addr):
    """Send an AXI read transaction"""
    ar = cocotb.start_soon(axi_ar(dut, addr))
    r = cocotb.start_soon(axi_r(dut))
    await Combine(ar, r)
    cocotb.log.info("AXI read: %s -> %s", hex(addr), hex(r.result()))
    return r.result()
