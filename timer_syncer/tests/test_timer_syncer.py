import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"


async def wait_for_tod(dut, signal, seconds, nanoseconds):
    for _ in range(100):
        await RisingEdge(dut.rx_eth_clk)
        await ReadOnly()
        value = int(signal.value)
        if (value >> 32) == seconds and (value & 0xFFFFFFFF) >= nanoseconds:
            return value
    raise AssertionError("timer did not receive the programmed ToD")


@cocotb.test()
async def test_timer_syncer_loads_tod_and_runs_in_both_eth_domains(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.rx_eth_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.tx_eth_clk, 12, unit="ns").start())
    cocotb.start_soon(Clock(dut.ctrl_clk, 14, unit="ns").start())

    dut.rst.value = 1
    dut.pps_in.value = 1
    dut.tod_sec.value = 0x1234
    dut.tod_ns.value = 100
    dut.rx_eth_rst.value = 1
    dut.tx_eth_rst.value = 1
    dut.ctrl_rst.value = 1
    await ClockCycles(dut.rx_eth_clk, 4)
    assert int(dut.ctl_rx_systemtimer.value) == 0
    assert int(dut.ctl_tx_systemtimer.value) == 0

    dut.rst.value = 0
    dut.rx_eth_rst.value = 0
    dut.tx_eth_rst.value = 0
    dut.ctrl_rst.value = 0

    await wait_for_tod(
        dut, dut.ctl_rx_systemtimer, int(dut.tod_sec.value), int(dut.tod_ns.value)
    )
    tx_value = 0
    for _ in range(100):
        await RisingEdge(dut.tx_eth_clk)
        await ReadOnly()
        tx_value = int(dut.ctl_tx_systemtimer.value)
        if (tx_value >> 32) == int(dut.tod_sec.value):
            break
    assert (tx_value >> 32) == int(dut.tod_sec.value)

    # The transmit-domain wait above can span several receive clocks. Sample
    # the receive counter again before checking its per-clock increment.
    previous_ns = int(dut.ctl_rx_systemtimer.value) & 0xFFFFFFFF
    for _ in range(4):
        await RisingEdge(dut.rx_eth_clk)
        await ReadOnly()
        current = int(dut.ctl_rx_systemtimer.value)
        assert (current >> 32) == int(dut.tod_sec.value)
        delta = (current & 0xFFFFFFFF) - previous_ns
        assert delta in {2, 3, 4, 6, 7}
        previous_ns = current & 0xFFFFFFFF

    await ClockCycles(dut.ctrl_clk, 20)
    assert int(dut.stat_rx_resync_cnt.value) >= 1
    assert int(dut.stat_tx_resync_cnt.value) >= 1


@pytest.mark.parametrize("freq_mode", [0, 1, 2])
def test_timer_syncer_runner(freq_mode):
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="timer_syncer",
        sources=resolve_flt(prj_path / "timer_syncer.flt"),
        parameters={"FREQ_MODE": freq_mode, "SIM_SPEEDUP": 1},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="timer_syncer",
        hdl_toplevel_lang="verilog",
        test_module="test_timer_syncer",
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
