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
CLOCKS = {"clk": 8, "s_axi_aclk": 10, "eth_clk": 6, "eth_clk2x": 3}
RESETS = {"rst": "clk", "s_axi_aresetn": "s_axi_aclk", "eth_rst": "eth_clk"}
# Address, test value, writable mask. These registers reset to zero.
REGISTERS = [
    (0x10, 0x12345678, 0xFFFFFFFF),
    (0x30, 0x1234, 0xFFFF),
    (0x34, 0xA5A55A5A, 0xFFFFFFFF),
]
VERSION = 0x20230922


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
async def test_pps_top_control_smoke(dut):
    # Initialize inputs and hold resets before starting any clock (also safe
    # for four-state simulators and assertions active on the first edge).
    dut.pps_in.value = 0
    dut.ts_t1.value = 0
    dut.ts_t2.value = 0
    dut.ts_valid.value = 0
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
    # Observe the externally visible timer, not an internal implementation net.
    await RisingEdge(dut.clk)
    before = int(dut.sys_timer_ns.value)
    await ClockCycles(dut.clk, 32)
    assert int(dut.sys_timer_s.value) == 0
    assert before < int(dut.sys_timer_ns.value) < 1_000_000_000

    # A second reset must clear written configuration and restore access.
    await reset(dut)
    assert await axi.read(0) == VERSION
    for address, _, _ in REGISTERS:
        assert await axi.read(address) == 0
    address, value, mask = REGISTERS[0]
    await axi.write(address, value)
    assert await axi.read(address) == value & mask


def test_pps_top_smoke_runner():
    sim = os.environ["SIM"]
    build_dir = ROOT / "sim_build" / sim / "pps_top_smoke"
    runner = get_runner(sim)
    runner.build(
        hdl_toplevel="pps_top",
        sources=resolve_flt(ROOT / "pps_top.flt"),
        build_dir=build_dir,
    )
    runner.test(
        hdl_toplevel="pps_top",
        test_module=Path(__file__).stem,
        test_dir=build_dir,
    )
