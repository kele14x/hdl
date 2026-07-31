import os
import tempfile
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb_tools.runner import get_runner

from common.tb.memory import MemoryAgent, MemoryAgentConfig, MemoryPortBus
from tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

ADDR_WIDTH = 3
DATA_WIDTH = 8
READ_LATENCY = 3
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


@cocotb.test()
async def test_ram_sdp_write_read_latency_and_read_enable_hold(dut):
    cocotb.start_soon(Clock(dut.clka, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clkb, 10, unit="ns").start())
    dut.ena.value = 0
    dut.wea.value = 0
    dut.addra.value = 0
    dut.dina.value = 0
    dut.rstb.value = (1 << READ_LATENCY) - 1
    dut.enb.value = 0
    dut.addrb.value = 0
    await ClockCycles(dut.clka, 3)
    dut.rstb.value = 0

    writer = MemoryAgent(
        MemoryPortBus(
            clock=dut.clka,
            enable=dut.ena,
            address=dut.addra,
            write_enable=dut.wea,
            write_data=dut.dina,
        )
    )
    reader = MemoryAgent(
        MemoryPortBus(
            clock=dut.clkb,
            enable=dut.enb,
            address=dut.addrb,
            read_data=dut.doutb,
        ),
        MemoryAgentConfig(read_latency=READ_LATENCY),
    )
    await writer.start()
    await reader.start()

    memory = {0: 0x26, 2: 0x7D, 5: 0xA4, 7: 0x11}
    await writer.write_burst(memory.items())

    addresses = [0, 5, 2, 7, 0, 5, 2, 7]
    actual = await reader.read_burst(addresses)
    assert actual == [memory[address] for address in addresses]
    assert [transaction.address for transaction in writer.monitor.observed] == list(
        memory
    )
    assert [response.request.address for response in reader.monitor.read_responses] == (
        addresses
    )

    held = int(dut.doutb.value)
    await ClockCycles(dut.clkb, 3)
    assert int(dut.doutb.value) == held


def test_ram_sdp_runner():
    runner = get_runner(SIM)
    with tempfile.TemporaryDirectory(prefix="ram_sdp_") as run_dir:
        runner.build(
            hdl_toplevel="ram_sdp",
            sources=resolve_flt(prj_path / "ram.flt"),
            parameters={
                "ADDR_WIDTH": ADDR_WIDTH,
                "DATA_WIDTH": DATA_WIDTH,
                "READ_LATENCY": READ_LATENCY,
                "INIT_WORD": 0,
            },
            always=True,
            waves=True,
            build_dir=run_dir,
        )
        runner.test(
            hdl_toplevel="ram_sdp",
            hdl_toplevel_lang="verilog",
            test_module="test_ram_sdp",
            waves=True,
            gui=GUI,
            test_dir=run_dir,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
