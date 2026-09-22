"""Full-top reset, AXI register access, and reset-recovery smoke test."""

import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.axi4lite import AxiLiteAgentConfig, AxiLiteMasterDriver
from hdl_tools.flt_tool import resolve_flt

ROOT = Path(__file__).resolve().parent.parent
CLOCKS = {"clk": 4, "s_axi_aclk": 10, "rx_eth_clk": 8, "tx_eth_clk": 6, "timer_clk": 12}
RESETS = {
    "rst": "clk",
    "s_axi_aresetn": "s_axi_aclk",
    "rx_eth_rst": "rx_eth_clk",
    "tx_eth_rst": "tx_eth_clk",
    "timer_rst": "timer_clk",
}
# Address, test value, writable mask. These registers reset to zero.
REGISTERS = [
    (0x4, 0x12345678, 0xFFFFFFFF),
    (0x8, 0xA5A55A5A, 0xFFFFFFFF),
    (0x318, 0x1234, 0xFFFF),
]
VERSION = 0x20230411


async def reset(dut):
    # Assert each domain's reset immediately after its clock edge.
    for name, clock in RESETS.items():
        await RisingEdge(getattr(dut, clock))
        getattr(dut, name).value = 0 if name.endswith("resetn") else 1
    await ClockCycles(dut.s_axi_aclk, 16)
    for name, clock in RESETS.items():
        await RisingEdge(getattr(dut, clock))
        getattr(dut, name).value = 1 if name.endswith("resetn") else 0
    await ClockCycles(dut.s_axi_aclk, 16)


@cocotb.test(timeout_time=100, timeout_unit="us")
async def test_fh_control_smoke(dut):
    # Initialize inputs and hold resets before starting any clock (also safe
    # for four-state simulators and assertions active on the first edge).
    dut.s_axis_rx_tdata.value = 0
    dut.s_axis_rx_tkeep.value = 0
    dut.s_axis_rx_tvalid.value = 0
    dut.s_axis_rx_tlast.value = 0
    dut.s_axis_rx_tuser.value = 0
    dut.m_axis_tx_tready.value = 1
    dut.rx_ptp_timestamp.value = 0
    dut.rx_ptp_timestamp_valid.value = 0
    dut.tx_ptp_timestamp.value = 0
    dut.tx_ptp_timestamp_tag.value = 0
    dut.tx_ptp_timestamp_valid.value = 0
    dut.pps_in.value = 0
    dut.tod_sec.value = 0
    dut.tod_ns.value = 0
    dut.m_message_tready.value = 1
    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_message_tdata.value = 0
    dut.s_message_tkeep.value = 0
    dut.s_message_tlast.value = 0
    dut.s_message_tvalid.value = 0
    for name in RESETS:
        getattr(dut, name).value = 0 if name.endswith("resetn") else 1
    axi = AxiLiteMasterDriver(dut, AxiLiteAgentConfig(reset="s_axi_aresetn"))
    axi.idle()
    for name, period in CLOCKS.items():
        cocotb.start_soon(
            Clock(getattr(dut, name), period, unit="ns").start(start_high=False)
        )
    await reset(dut)

    assert await axi.read(0) == VERSION
    for address, value, mask in REGISTERS:
        assert await axi.read(address) == 0
        await axi.write(address, value)
        assert await axi.read(address) == value & mask
    for _ in range(16):
        await RisingEdge(dut.tx_eth_clk)
        assert int(dut.m_axis_tx_tvalid.value) == 0, "unexpected idle TX traffic"

    # A second reset must clear written configuration and restore access.
    await reset(dut)
    assert await axi.read(0) == VERSION
    for address, _, _ in REGISTERS:
        assert await axi.read(address) == 0
    address, value, mask = REGISTERS[0]
    await axi.write(address, value)
    assert await axi.read(address) == value & mask


def test_fh_smoke_runner():
    sim = os.environ["SIM"]
    build_dir = ROOT / "sim_build" / sim / "fh_smoke"
    runner = get_runner(sim)
    runner.build(
        hdl_toplevel="fh",
        sources=resolve_flt(ROOT / "fh.flt"),
        build_dir=build_dir,
    )
    runner.test(
        hdl_toplevel="fh",
        test_module=Path(__file__).stem,
        test_dir=build_dir,
    )
