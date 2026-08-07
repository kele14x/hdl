import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb_tools.runner import get_runner
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge
from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"
WIDTH = int(os.environ.get("WIDTH", 16))


async def reset(dut):
    dut.rst.value = 1
    dut.pulse_in.value = 0
    dut.delay.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 2)


async def emit_and_measure(dut, delay):
    dut.delay.value = delay
    await ClockCycles(dut.clk, 2)

    dut.pulse_in.value = 1
    await RisingEdge(dut.clk)
    dut.pulse_in.value = 0

    for latency in range(1, delay + 4):
        await RisingEdge(dut.clk)
        await ReadOnly()
        if dut.pulse_out.value:
            return latency

    raise AssertionError(f"no delayed pulse for delay={delay}")


@cocotb.test()
async def test_pulse_delay(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)

    for delay in (0, 1, 7, 15):
        latency = await emit_and_measure(dut, delay)
        assert latency == delay + 1, (
            f"delay={delay} produced latency={latency}, expected {delay + 1}"
        )
        await ClockCycles(dut.clk, 2)


def test_pulse_delay_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="pulse_delay",
        verilog_sources=resolve_flt(prj_path / "pulse_delay.flt"),
        parameters={"WIDTH": WIDTH},
        waves=True,
        always=True,
    )
    runner.test(
        hdl_toplevel="pulse_delay",
        hdl_toplevel_lang="verilog",
        test_module="test_pulse_delay",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
