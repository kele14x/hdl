import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadWrite, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")

NUM_UNITS = 3
DELAY_WIDTH = 3
DATA_WIDTH = 8
DEPTH = 1 << DELAY_WIDTH


async def tick(dut):
    await RisingEdge(dut.clk)
    await ReadWrite()


async def drive(dut, value, delays):
    await FallingEdge(dut.clk)
    dut.data_in.value = value
    for unit, delay in enumerate(delays):
        dut.delay[unit].value = delay


@cocotb.test()
async def test_nlf_delay_line_per_unit_delay_and_reset(dut):
    """Each tap has its own programmable latency, including the SRL output FF."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    delays = [0, 2, DEPTH - 1]
    dut.rst.value = 1
    await drive(dut, 0, delays)

    # The SRLs are initialized, while reset must also mask their output FFs.
    # Reset does not clear the inter-unit registers, so keep it asserted for
    # the longest programmable path before beginning value comparisons.
    for _ in range(NUM_UNITS + DEPTH + 2):
        await tick(dut)
        assert [int(dut.data_out[i].value) for i in range(NUM_UNITS)] == [0, 0, 0]

    dut.rst.value = 0

    # Cycle-accurate model of the two register layers in each delay-line unit.
    data_s = [0] * NUM_UNITS
    srl = [[0] * DEPTH for _ in range(NUM_UNITS)]
    dout = [0] * NUM_UNITS
    visible_dout = [0] * NUM_UNITS

    async def step(value, active_delays, reset=False):
        nonlocal data_s, srl, dout, visible_dout
        await drive(dut, value, active_delays)
        old_data_s = data_s[:]
        old_srl = [line[:] for line in srl]
        next_dout = [0 if reset else old_srl[i][active_delays[i]] for i in range(NUM_UNITS)]
        data_s = [value] + old_data_s[:-1]
        srl = [[old_data_s[i]] + old_srl[i][:-1] for i in range(NUM_UNITS)]
        dout = next_dout
        if reset:
            visible_dout = [0] * NUM_UNITS
        await tick(dut)
        if reset:
            return
        observed = [int(dut.data_out[i].value) for i in range(NUM_UNITS)]
        # The unit's input register precedes the SRL's registered output.
        assert observed == visible_dout
        visible_dout = dout

    values = [0x11, 0x80, 0x7F, 0x00, 0xA5, 0x42]
    for value in values:
        await step(value, delays)

    # Changing the tap selection is immediate at the registered output boundary.
    for value, active_delays in [(0x33, [1, 0, 3]), (0xCC, [7, 7, 0]), (0x55, [0, 4, 6])]:
        await step(value, active_delays)
        delays = active_delays

    # Reset is asserted mid-stream: outputs are cleared, but the always-enabled
    # pipeline continues to accept samples as specified by the implementation.
    dut.rst.value = 1
    for value in (0x12, 0x34):
        await step(value, delays, reset=True)
    dut.rst.value = 0
    # Reset only clears each SRL's output FF; it intentionally does not clear
    # the shift storage.  Flush that retained history before ending the test.
    for _ in range(NUM_UNITS + DEPTH + 2):
        await drive(dut, 0, delays)
        await tick(dut)


def test_nlf_delay_line_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="nlf_delay_line",
        sources=resolve_flt(prj_path / "nlf.flt"),
        parameters={
            "NUM_UNITS": NUM_UNITS,
            "DELAY_WIDTH": DELAY_WIDTH,
            "DATA_WIDTH": DATA_WIDTH,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="nlf_delay_line",
        hdl_toplevel_lang="verilog",
        test_module="test_nlf_delay_line",
        test_args=["-suppress", "7061"] if SIM == "questa" else [],
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
