import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM", "verilator")
CLOCK_PERIOD_NS = 10
SYNC_DELAY_CYCLES = 8
RESET_CYCLES = SYNC_DELAY_CYCLES + 4


async def clock_cycle(dut):
    """Wait for a clock edge and allow sequential logic to settle."""
    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")


async def send_sync_word(dut, word):
    """Drive one input word and check its fixed eight-cycle sync delay."""
    observed_data = []

    dut.data_sync_in.value = word
    await clock_cycle(dut)
    assert dut.data_sync_out.value.to_unsigned() == 0
    observed_data.append(dut.data_out.value.to_signed())

    dut.data_sync_in.value = 0
    for _ in range(SYNC_DELAY_CYCLES - 2):
        await clock_cycle(dut)
        assert dut.data_sync_out.value.to_unsigned() == 0
        observed_data.append(dut.data_out.value.to_signed())

    await clock_cycle(dut)
    assert dut.data_sync_out.value.to_unsigned() == word
    observed_data.append(dut.data_out.value.to_signed())

    await clock_cycle(dut)
    assert dut.data_sync_out.value.to_unsigned() == 0
    observed_data.append(dut.data_out.value.to_signed())

    return observed_data


@cocotb.test()
async def test_dummy_source_basic(dut):
    """Check the bounded sync delay and source activation on a symbol start."""
    cocotb.start_soon(Clock(dut.clk, CLOCK_PERIOD_NS, unit="ns").start())

    dut.rst.value = 1
    dut.data_sync_in.value = 0
    dut.ctrl_numerology.value = 1
    dut.ctrl_iq_width.value = 0
    dut.ctrl_shift.value = 1
    dut.ctrl_scalar.value = 8241
    for _ in range(RESET_CYCLES):
        await clock_cycle(dut)

    assert dut.data_sync_out.value.to_unsigned() == 0
    assert dut.data_out.value.to_signed() == 0

    dut.rst.value = 0
    for _ in range(4):
        await clock_cycle(dut)
        assert dut.data_out.value.to_signed() == 0

    # A sync word without bit 4 must not enable the LFSR-driven data source.
    inactive_data = await send_sync_word(dut, 0x03)
    assert all(sample == 0 for sample in inactive_data)

    # Bit 4 is symbol_start. It must enable the source and produce samples.
    active_data = await send_sync_word(dut, 0x15)
    for _ in range(SYNC_DELAY_CYCLES):
        await clock_cycle(dut)
        active_data.append(dut.data_out.value.to_signed())

    assert any(sample != 0 for sample in active_data)


def test_dummy_source_runner():
    hdl_toplevel = "dummy_source"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "dummy_source.flt")

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        build_args=[],
        always=True,
        waves=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_dummy_source",
        waves=True,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
