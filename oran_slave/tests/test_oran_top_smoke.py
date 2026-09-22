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
CLOCKS = {"clk": 8, "s_axi_aclk": 10, "eth_clk": 6}
RESETS = {"rst": "clk", "s_axi_aresetn": "s_axi_aclk", "eth_rst": "eth_clk"}
# Address, test value, writable mask, reset value (TX MAC configuration).
REGISTERS = [
    (0x208, 0x12345678, 0xFFFFFFFF, 0x22334455),
    (0x20C, 0x1234, 0xFFFF, 0x0011),
    (0x210, 0xA5A55A5A, 0xFFFFFFFF, 0x22334466),
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
async def test_oran_top_control_smoke(dut):
    # Initialize inputs and hold resets before starting any clock (also safe
    # for four-state simulators and assertions active on the first edge).
    dut.rx_axis_tdata.value = 0
    dut.rx_axis_tkeep.value = 0
    dut.rx_axis_tvalid.value = 0
    dut.rx_axis_tlast.value = 0
    dut.rx_axis_tuser.value = 0
    dut.tx_axis_tready.value = 1
    dut.timer_frame.value = 0
    dut.timer_sof.value = 0
    dut.timer_sos.value = 0
    dut.timer_frac.value = 0
    for lane in dut.ul_syml_frame:
        lane.value = 0
    for lane in dut.ul_syml_sof:
        lane.value = 0
    for lane in dut.ul_syml_sos:
        lane.value = 0
    for lane in dut.ul_syml_data:
        lane.value = 0
    for lane in dut.ul_syml_valid:
        lane.value = 0
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
    for address, value, mask, reset_value in REGISTERS:
        assert await axi.read(address) == reset_value
        await axi.write(address, value)
        assert await axi.read(address) == value & mask
    for _ in range(16):
        await RisingEdge(dut.eth_clk)
        assert int(dut.tx_axis_tvalid.value) == 0, "unexpected idle TX traffic"

    # A second reset must clear written configuration and restore access.
    await reset(dut)
    assert await axi.read(0) == VERSION
    for address, _, _, reset_value in REGISTERS:
        assert await axi.read(address) == reset_value
    address, value, mask, _ = REGISTERS[0]
    await axi.write(address, value)
    assert await axi.read(address) == value & mask


def test_oran_top_smoke_runner():
    sim = os.environ["SIM"]
    build_dir = ROOT / "sim_build" / sim / "oran_top_smoke"
    runner = get_runner(sim)
    runner.build(
        hdl_toplevel="oran_top",
        sources=resolve_flt(ROOT / "oran_slave.flt"),
        build_dir=build_dir,
    )
    runner.test(
        hdl_toplevel="oran_top",
        test_module=Path(__file__).stem,
        test_dir=build_dir,
    )
