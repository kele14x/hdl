#! /usr/bin/env python3
"""Fast unit tests for the generated lowphy AXI4-Lite register block."""

import os
from pathlib import Path

import cocotb
import pytest
import register_map as reg
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb_tools.runner import get_runner
from lowphy_ral import create_lowphy_ral
from lowphy_tb import input_port_names

from hdl_tools.axi4lite import (
    AxiLiteAgent,
    AxiLiteAgentConfig,
    AxiLiteOperation,
)

PRJ_PATH = Path(__file__).resolve().parent.parent
RTL_PATH = PRJ_PATH / "rtl" / "lowphy_regs.v"
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
SIM = SIM.lower()
GUI = os.environ.get("GUI", "false").lower() == "true"
WAVES = os.environ.get("WAVES", "false").lower() == "true"
REBUILD = os.environ.get("REBUILD", "false").lower() == "true"


async def setup_register_tb(dut):
    """Initialize hardware-owned inputs and reset the AXI register block."""
    agent = AxiLiteAgent(
        dut,
        AxiLiteAgentConfig(reset="s_axi_aresetn"),
    )
    for name in input_port_names(RTL_PATH):
        if name not in {"s_axi_aclk", "s_axi_aresetn"}:
            getattr(dut, name).value = 0

    dut.s_axi_aresetn.value = 0
    await agent.start()
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, unit="ns").start())
    await ClockCycles(dut.s_axi_aclk, 8)
    dut.s_axi_aresetn.value = 1
    await ClockCycles(dut.s_axi_aclk, 4)
    return agent


@cocotb.test()
async def test_reset_values(dut):
    """Check reset values across DL, UL, and PRACH register regions."""
    agent = await setup_register_tb(dut)
    ral = create_lowphy_ral(agent)
    await ral.check_reset()


@cocotb.test()
async def test_writable_fields_and_outputs(dut):
    """Check field masks plus representative RTL control outputs."""
    agent = await setup_register_tb(dut)
    ral = create_lowphy_ral(agent)
    cases = (
        (reg.SCRATCH0, 0xFFFFFFFF, 0xFFFFFFFF),
        (reg.DL_EN, 0xFFFFFFFF, 0x00000FFF),
        (reg.DL_RAT, 0xFFFFFFFF, 0x00000333),
        (reg.DL_NPRB[0], 0xFFFFFFFF, 0x000001FF),
        (reg.DL_UD, 0xFFFFFFFF, 0x00000FFF),
        (reg.DL_GAIN[0], 0xFFFFFFFF, 0x0001FFFF),
        (reg.PRACH_BIST, 0xFFFFFFFF, 0x0FFF0FFF),
    )
    for address, value, expected in cases:
        register = ral.at(address)
        await register.write(value)
        assert await register.read() == expected
        assert register.mirrored_value == expected

    assert int(dut.dl_en_cc0_out.value) == 0xF
    assert int(dut.dl_en_cc1_out.value) == 0xF
    assert int(dut.dl_en_cc2_out.value) == 0xF
    assert int(dut.dl_nprb_0_val_out.value) == 0x1FF
    assert int(dut.dl_gain_0_0_val_out.value) == 0x1FFFF


@cocotb.test()
async def test_hardware_status_fields(dut):
    """Check packing of hardware-written PRACH message inspection fields."""
    agent = await setup_register_tb(dut)
    ral = create_lowphy_ral(agent)

    dut.prach_msg0_0_symbol_id_in.value = 0x2A
    dut.prach_msg0_0_slot_id_in.value = 0x15
    dut.prach_msg0_0_subframe_id_in.value = 0xC
    dut.prach_msg1_0_time_offset_in.value = 0x1234
    dut.prach_msg1_0_cp_length_in.value = 0xABCD
    dut.prach_msg2_0_num_symbol_in.value = 0x7
    dut.prach_msg2_0_freq_offset_in.value = 0x654321
    await ClockCycles(dut.s_axi_aclk, 2)

    assert await ral.prach_msg0_0.read() == 0x000C152A
    assert await ral.prach_msg1_0.read() == 0xABCD1234
    assert await ral.prach_msg2_0.read() == 0x06543217
    assert ral.prach_msg0_0.symbol_id.mirrored_value == 0x2A
    assert ral.prach_msg1_0.cp_length.mirrored_value == 0xABCD
    assert ral.prach_msg2_0.freq_offset.mirrored_value == 0x654321


@cocotb.test()
async def test_axi_monitor_transactions(dut):
    """Check that the passive monitor reconstructs reads and writes."""
    agent = await setup_register_tb(dut)
    ral = create_lowphy_ral(agent)
    subscribed = []
    agent.monitor.transactions.subscribe(subscribed.append)
    await agent.write(reg.SCRATCH0, 0x89ABCDEF)
    assert await agent.read(reg.SCRATCH0) == 0x89ABCDEF

    write = await agent.monitor.transactions.get()
    read = await agent.monitor.transactions.get()
    assert write.operation is AxiLiteOperation.WRITE
    assert (write.address, write.data, write.strobe, write.response) == (
        reg.SCRATCH0,
        0x89ABCDEF,
        0xF,
        0,
    )
    assert read.operation is AxiLiteOperation.READ
    assert (read.address, read.data, read.response) == (
        reg.SCRATCH0,
        0x89ABCDEF,
        0,
    )
    assert subscribed == [write, read]
    assert ral.scratch0.mirrored_value == 0x89ABCDEF


def test_lowphy_regs_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="lowphy_regs",
        sources=[RTL_PATH],
        always=REBUILD,
        waves=WAVES,
        build_dir=PRJ_PATH / "sim_build" / SIM / "lowphy_regs",
    )
    runner.test(
        hdl_toplevel="lowphy_regs",
        hdl_toplevel_lang="verilog",
        test_module=Path(__file__).stem,
        gui=GUI,
        waves=WAVES,
        test_dir=PRJ_PATH / "sim_build" / SIM / "lowphy_regs",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
