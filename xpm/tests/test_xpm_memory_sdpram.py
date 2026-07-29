import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


async def tick(signal):
    await RisingEdge(signal)
    await Timer(1, unit="ps")


async def write_word(dut, address, data, wea=1):
    await FallingEdge(dut.clka)
    dut.addra.value = address
    dut.dina.value = data
    dut.wea.value = wea
    dut.ena.value = 1
    await tick(dut.clka)
    await FallingEdge(dut.clka)
    dut.ena.value = 0
    dut.wea.value = 0


@cocotb.test()
async def test_xpm_memory_sdpram_read_pipeline_reset_and_regce(dut):
    cocotb.start_soon(Clock(dut.clka, 10, unit="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.clkb, 14, unit="ns").start(start_high=False))
    dut.ena.value = 0
    dut.wea.value = 0
    dut.addra.value = 0
    dut.dina.value = 0
    dut.enb.value = 0
    dut.regceb.value = 1
    dut.addrb.value = 0
    dut.rstb.value = 1
    dut.injectdbiterra.value = 0
    dut.injectsbiterra.value = 0
    dut.sleep.value = 0
    await tick(dut.clkb)
    assert int(dut.doutb.value) == 0
    dut.rstb.value = 0

    # The behavioural model uses any asserted byte-enable bit to write the
    # complete word, matching the simple XPM compatibility implementation.
    await write_word(dut, 3, 0xABCD, wea=0b10)
    await write_word(dut, 4, 0x1234, wea=0b01)

    await FallingEdge(dut.clkb)
    dut.addrb.value = 3
    dut.enb.value = 1
    dut.regceb.value = 1
    await tick(dut.clkb)
    assert int(dut.doutb.value) == 0
    await tick(dut.clkb)
    assert int(dut.doutb.value) == 0xABCD

    # regceb holds the last read-latency stage while port B keeps accepting a
    # new address into its first stage.
    await FallingEdge(dut.clkb)
    dut.addrb.value = 4
    dut.regceb.value = 0
    await tick(dut.clkb)
    assert int(dut.doutb.value) == 0xABCD
    await FallingEdge(dut.clkb)
    dut.regceb.value = 1
    await tick(dut.clkb)
    assert int(dut.doutb.value) == 0x1234

    dut.rstb.value = 1
    await tick(dut.clkb)
    assert int(dut.doutb.value) == 0
    assert int(dut.dbiterrb.value) == 0
    assert int(dut.sbiterrb.value) == 0


def test_xpm_memory_sdpram_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="xpm_memory_sdpram",
        sources=resolve_flt(prj_path / "xpm.flt"),
        parameters={
            "ADDR_WIDTH_A": 3,
            "ADDR_WIDTH_B": 3,
            "BYTE_WRITE_WIDTH_A": 8,
            "WRITE_DATA_WIDTH_A": 16,
            "READ_DATA_WIDTH_B": 16,
            "READ_LATENCY_B": 2,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="xpm_memory_sdpram",
        hdl_toplevel_lang="verilog",
        test_module="test_xpm_memory_sdpram",
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
