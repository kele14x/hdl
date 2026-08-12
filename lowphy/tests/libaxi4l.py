"""Compatibility imports for the shared AXI4-Lite verification agent."""

from hdl_tools.axi4lite import (
    AxiLiteAgent,
    AxiLiteAgentConfig,
    AxiLiteError,
    AxiLiteMaster,
    AxiLiteMasterDriver,
    AxiLiteMonitor,
    AxiLiteOperation,
    AxiLiteTransaction,
)
from hdl_tools.axi4lite import axi_read as _axi_read
from hdl_tools.axi4lite import axi_reset as _axi_reset
from hdl_tools.axi4lite import axi_write as _axi_write


async def axi_reset(dut):
    return await _axi_reset(dut, prefix="s0_axi")


async def axi_write(dut, address, data, wstrb=0xF):
    return await _axi_write(dut, address, data, wstrb, prefix="s0_axi")


async def axi_read(dut, address):
    return await _axi_read(dut, address, prefix="s0_axi")


__all__ = [
    "AxiLiteAgent",
    "AxiLiteAgentConfig",
    "AxiLiteError",
    "AxiLiteMaster",
    "AxiLiteMasterDriver",
    "AxiLiteMonitor",
    "AxiLiteOperation",
    "AxiLiteTransaction",
    "axi_read",
    "axi_reset",
    "axi_write",
]
