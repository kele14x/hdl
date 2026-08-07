import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb_tools.runner import get_runner
from hdl_tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, RisingEdge

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


async def reset(dut):
    dut.rst_n.value = 0

    for cc in range(0, 1):
        for band in range(0, 1):
            dut.din0_dr[cc][band].value = 0
            dut.din0_di[cc][band].value = 0
            dut.din0_chn[cc][band].value = 0
            dut.din0_sym[cc][band].value = 0
            dut.din0_dv[cc][band].value = 0
            dut.din0_sync[cc][band].value = 0

            dut.din1_dr[cc][band].value = 0
            dut.din1_di[cc][band].value = 0
            dut.din1_chn[cc][band].value = 0
            dut.din1_sym[cc][band].value = 0
            dut.din1_dv[cc][band].value = 0
            dut.din1_sync[cc][band].value = 0

    dut.rst_csr_n.value = 0

    for cc in range(0, 1):
        for band in range(0, 1):
            dut.ctrl_mu[cc][band].value = 0

    dut.ctrl_cc_sel.value = 0
    dut.ctrl_band_sel.value = 0
    dut.ctrl_ant_sel.value = 0
    dut.ctrl_pos_sel.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    await ClockCycles(dut.clk_csr, 10)
    dut.rst_csr_n.value = 1


async def drive_slot(dut, symbol, cycles):
    for _ in range(cycles):
        dut.din0_dr[0][0].value = 16384
        dut.din0_di[0][0].value = 0
        dut.din0_chn[0][0].value = 0
        dut.din0_sym[0][0].value = symbol
        dut.din0_dv[0][0].value = 1
        await RisingEdge(dut.clk)

    dut.din0_dv[0][0].value = 0


@cocotb.test()
async def test_power_meter(dut):
    # Generate clocks
    cocotb.start_soon(Clock(dut.clk, period=4, units="ns").start())
    cocotb.start_soon(Clock(dut.clk_csr, period=10, units="ns").start())

    # Reset DUT
    await reset(dut)
    # Allow the control selection to cross to the sample clock domain.
    await ClockCycles(dut.clk, 6)

    # Accumulate known slot-0 samples, then advance to slot 1 to commit the
    # accumulated value to stat_power[0].
    await drive_slot(dut, symbol=0, cycles=8)
    await drive_slot(dut, symbol=7, cycles=1)

    await ClockCycles(dut.clk, 12)
    await ClockCycles(dut.clk_csr, 8)

    assert dut.stat_power[0].value.is_resolvable
    assert int(dut.stat_power[0].value) > 0


def test_power_meter_runner():
    hdl_toplevel = "power_meter"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "power_meter.flt")

    parameters = {
        "NUM_CC": 1,
        "NUM_BAND": 1,
    }

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        build_args=[],
        waves=True,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_power_meter",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
