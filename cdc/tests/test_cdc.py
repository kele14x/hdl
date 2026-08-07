import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, ReadWrite, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


def is_toplevel(dut, name):
    return dut._name == name


async def wait_for_value(signal, clock, value, cycles=20):
    for _ in range(cycles):
        await RisingEdge(clock)
        await ReadWrite()
        if int(signal.value) == value:
            return
    raise AssertionError(f"{signal._name} did not become {value} within {cycles} cycles")


@cocotb.test()
async def test_cdc_single_synchronizes_both_levels(dut):
    if not is_toplevel(dut, "cdc_single"):
        return

    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 10, unit="ns").start())
    dut.src_in.value = 0
    await ClockCycles(dut.dest_clk, 4)

    dut.src_in.value = 1
    await wait_for_value(dut.dest_out, dut.dest_clk, 1)
    dut.src_in.value = 0
    await wait_for_value(dut.dest_out, dut.dest_clk, 0)


@cocotb.test()
async def test_cdc_array_single_preserves_all_bits(dut):
    if not is_toplevel(dut, "cdc_array_single"):
        return

    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 11, unit="ns").start())
    dut.src_in.value = 0
    await ClockCycles(dut.dest_clk, 4)

    for value in (0b1010, 0b0101, 0b1111):
        dut.src_in.value = value
        await wait_for_value(dut.dest_out, dut.dest_clk, value)


@cocotb.test()
async def test_cdc_gray_transfers_monotonic_counts(dut):
    if not is_toplevel(dut, "cdc_gray"):
        return

    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 13, unit="ns").start())
    dut.src_in_bin.value = 0
    await ClockCycles(dut.dest_clk, 4)

    for value in (1, 3, 7, 12):
        dut.src_in_bin.value = value
        await wait_for_value(dut.dest_out_bin, dut.dest_clk, value)


@cocotb.test()
async def test_cdc_pulse_emits_one_destination_pulse_per_source_event(dut):
    if not is_toplevel(dut, "cdc_pulse"):
        return

    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 11, unit="ns").start())
    dut.src_rst.value = 1
    dut.dest_rst.value = 1
    dut.src_pulse.value = 0
    await ClockCycles(dut.src_clk, 3)
    dut.src_rst.value = 0
    dut.dest_rst.value = 0
    await ClockCycles(dut.dest_clk, 3)

    async def send_pulse():
        dut.src_pulse.value = 1
        await RisingEdge(dut.src_clk)
        dut.src_pulse.value = 0
        await ClockCycles(dut.src_clk, 5)

    sender = cocotb.start_soon(send_pulse())
    pulses = 0
    for _ in range(30):
        await RisingEdge(dut.dest_clk)
        await ReadOnly()
        pulses += int(dut.dest_pulse.value)
        if sender.done() and pulses == 1:
            break

    assert pulses == 1


@cocotb.test()
async def test_cdc_handshake_transfers_data_under_destination_backpressure(dut):
    if not is_toplevel(dut, "cdc_handshake_f"):
        return

    cocotb.start_soon(Clock(dut.src_clk, 8, unit="ns").start())
    cocotb.start_soon(Clock(dut.dest_clk, 11, unit="ns").start())
    dut.src_in.value = 0
    dut.src_valid.value = 0
    dut.dest_ready.value = 0
    await ClockCycles(dut.src_clk, 5)

    expected = [0x15, 0xA2, 0x3C]
    received = []

    async def receive():
        for _ in expected:
            await with_timeout(RisingEdge(dut.dest_valid), 2, "us")
            await ReadOnly()
            received.append(int(dut.dest_out.value))
            await ClockCycles(dut.dest_clk, 2)
            dut.dest_ready.value = 1
            await RisingEdge(dut.dest_clk)
            dut.dest_ready.value = 0

    receiver = cocotb.start_soon(receive())
    for value in expected:
        await wait_for_value(dut.src_ready, dut.src_clk, 1, cycles=50)
        dut.src_in.value = value
        dut.src_valid.value = 1
        await RisingEdge(dut.src_clk)
        dut.src_valid.value = 0

    await with_timeout(receiver, 5, "us")
    assert received == expected


@cocotb.test()
async def test_cdc_sync_rst_assertion_and_deassertion_are_synchronized(dut):
    if not is_toplevel(dut, "cdc_sync_rst"):
        return

    cocotb.start_soon(Clock(dut.dest_clk, 10, unit="ns").start())
    dut.src_rst.value = 0
    await ClockCycles(dut.dest_clk, 4)
    dut.src_rst.value = 1
    await wait_for_value(dut.dest_rst, dut.dest_clk, 1)
    dut.src_rst.value = 0
    await wait_for_value(dut.dest_rst, dut.dest_clk, 0)


@cocotb.test()
async def test_cdc_async_rst_active_high_release_is_synchronized(dut):
    if not is_toplevel(dut, "cdc_async_rst"):
        return

    cocotb.start_soon(Clock(dut.dest_clk, 10, unit="ns").start())
    dut.src_arst.value = 1
    await ClockCycles(dut.dest_clk, 3)
    assert int(dut.dest_arst.value) == 1
    dut.src_arst.value = 0
    await wait_for_value(dut.dest_arst, dut.dest_clk, 0)


def run(top, parameters):
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=top,
        verilog_sources=resolve_flt(prj_path / "cdc.flt"),
        parameters=parameters,
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel=top,
        hdl_toplevel_lang="verilog",
        test_module="test_cdc",
        waves=True,
        gui=GUI,
    )


def test_cdc_single_runner():
    run("cdc_single", {"DEST_SYNC_FF": 2, "INIT_SYNC_FF": 1, "SRC_INPUT_REG": 1})


def test_cdc_array_single_runner():
    run(
        "cdc_array_single",
        {"DEST_SYNC_FF": 2, "INIT_SYNC_FF": 1, "SRC_INPUT_REG": 1, "WIDTH": 4},
    )


def test_cdc_gray_runner():
    run("cdc_gray", {"DEST_SYNC_FF": 2, "INIT_SYNC_FF": 1, "REG_OUTPUT": 1, "WIDTH": 4})


def test_cdc_pulse_runner():
    run("cdc_pulse", {"DEST_SYNC_FF": 2, "INIT_SYNC_FF": 1, "REG_OUTPUT": 1, "RST_USED": 1})


def test_cdc_handshake_runner():
    run(
        "cdc_handshake_f",
        {"DEST_EXT_HSK": 1, "DEST_SYNC_FF": 2, "INIT_SYNC_FF": 1, "SRC_SYNC_FF": 2, "WIDTH": 8},
    )


def test_cdc_sync_rst_runner():
    run("cdc_sync_rst", {"DEST_SYNC_FF": 2, "INIT": 1, "INIT_SYNC_FF": 1})


def test_cdc_async_rst_runner():
    run("cdc_async_rst", {"DEST_SYNC_FF": 2, "INIT_SYNC_FF": 1, "RST_ACTIVE_HIGH": 1})


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
