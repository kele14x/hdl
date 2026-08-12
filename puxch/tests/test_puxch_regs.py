from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from puxch_test_utils import PRJ_PATH, run_cocotb, sample_after_rising

from hdl_tools.axi4lite import AxiLiteAgent, AxiLiteAgentConfig


async def memory_model(dut):
    memory = [0] * 64
    while True:
        await sample_after_rising(dut.s_axi_aclk)
        dut.ul_phase_comp_valid.value = 0
        if int(dut.ul_phase_comp_en.value):
            address = int(dut.ul_phase_comp_addr.value)
            if int(dut.ul_phase_comp_we.value):
                memory[address] = int(dut.ul_phase_comp_din.value)
            else:
                dut.ul_phase_comp_dout.value = memory[address]
                dut.ul_phase_comp_valid.value = 1


async def setup_dut(dut):
    dut.ul_phase_comp_dout.value = 0
    dut.ul_phase_comp_valid.value = 0
    dut.s_axi_aresetn.value = 0
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, unit="ns").start())
    cocotb.start_soon(memory_model(dut))
    agent = AxiLiteAgent(dut, AxiLiteAgentConfig(reset="s_axi_aresetn"))
    await agent.start()
    await ClockCycles(dut.s_axi_aclk, 8)
    dut.s_axi_aresetn.value = 1
    await ClockCycles(dut.s_axi_aclk, 4)
    return agent


@cocotb.test()
async def test_register_reset_write_and_memory_window(dut):
    agent = await setup_dut(dut)

    assert await agent.read(0x000) == 0x20250106
    assert await agent.read(0x21C) == 0x222
    assert await agent.read(0x220) == 100
    assert await agent.read(0x258) == 0x091
    assert await agent.read(0x300) == 0x4000

    cases = (
        (0x004, 0xDEADBEEF, 0xDEADBEEF),
        (0x210, 0xFFFFFFFF, 0x00000FFF),
        (0x214, 0xFFFFFFFF, 0x00000333),
        (0x21C, 0xABC, 0x00000ABC),
        (0x224, 0xFFFFFFFF, 0x000001FF),
        (0x234, 0xFFFFFFFF, 0x007FFFFF),
        (0x258, 0xFED, 0x00000FED),
        (0x31C, 0xFFFFFFFF, 0x0001FFFF),
    )
    for address, value, expected in cases:
        await agent.write(address, value)
        assert await agent.read(address) == expected

    assert int(dut.ul_en_cc0_out.value) == 0xF
    assert int(dut.ul_en_cc1_out.value) == 0xF
    assert int(dut.ul_en_cc2_out.value) == 0xF
    assert int(dut.ul_rat_cc0_out.value) == 0x3
    assert int(dut.ul_nprb_1_val_out.value) == 0x1FF
    assert int(dut.ul_gain_1_3_val_out.value) == 0x1FFFF

    for index, value in ((0, 0x40000000), (17, 0x1234ABCD), (63, 0x89ABCDEF)):
        address = 0xA00 + 4 * index
        await agent.write(address, value)
        assert await agent.read(address) == value


def test_puxch_regs_runner():
    run_cocotb(
        "puxch_regs",
        Path(__file__).stem,
        sources=[PRJ_PATH / "rtl" / "puxch_regs.v"],
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
