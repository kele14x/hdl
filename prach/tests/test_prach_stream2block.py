"""Focused cocotb tests for the PRACH stream-to-block memory banks."""

from __future__ import annotations

import os
import shutil
import tempfile
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

from tools.flt_tool import resolve_flt


PRJ_PATH = Path(__file__).resolve().parent.parent
NUM_ANT = 4
SEQ_LEN = 1536
CP_SAMPLES = 8
START_SAMPLE = CP_SAMPLES << 4
RAM_BANKS = 3
RAM_BANK_ADDR_WIDTH = 10
READ_GAP = SEQ_LEN + 64

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

_SIMULATOR_BINARIES = {
    "questa": "vsim",
    "modelsim": "vsim",
    "icarus": "iverilog",
    "verilator": "verilator",
}
_simulator_binary = _SIMULATOR_BINARIES.get(SIM.lower())
if _simulator_binary and shutil.which(_simulator_binary) is None:
    raise RuntimeError(
        f"SIM={SIM!r} was selected, but the required executable "
        f"{_simulator_binary!r} is not available on PATH"
    )


def _set_input(dut, *, chn=0, real=0, imag=0, dv=0, sf=0, sl=0, sy=0, last=0):
    dut.din_dr.value = real & 0xFFFF
    dut.din_di.value = imag & 0xFFFF
    dut.din_chn.value = chn
    dut.din_dv.value = dv
    dut.din_sf.value = sf
    dut.din_sl.value = sl
    dut.din_sy.value = sy
    dut.din_last.value = last


async def _reset(dut, *, start_clock=True):
    if start_clock:
        cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.rd_channel_req.value = 0
    dut.ctrl_start_symbol0.value = 0
    dut.ctrl_start_symbol1.value = 0
    dut.ctrl_start_sample.value = START_SAMPLE
    dut.ctrl_num_symbol.value = 2
    _set_input(dut)
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 2)


async def _send_word(dut, *, chn=0, real=0, imag=0, dv=1, sf=0, sl=0, sy=0, last=0):
    _set_input(
        dut,
        chn=chn,
        real=real,
        imag=imag,
        dv=dv,
        sf=sf,
        sl=sl,
        sy=sy,
        last=last,
    )
    await RisingEdge(dut.clk)


async def _send_two_sequence_occasion(dut, requested_sequence=0):
    dut.rd_channel_req.value = 1 if requested_sequence == 0 else 0
    await _send_word(dut, chn=0, dv=0, sf=1)

    for _ in range(CP_SAMPLES):
        for chn in range(NUM_ANT):
            await _send_word(dut, chn=chn, real=0xC000 + chn, imag=0xC000 + chn)

    for sequence in range(2):
        if sequence == 1:
            # Let the first read finish before the second sequence is written.
            # Holding the input on a non-zero channel freezes sample_cnt.
            if requested_sequence == 1:
                dut.rd_channel_req.value = 1
            for gap_cycle in range(READ_GAP):
                if requested_sequence == 0 and gap_cycle == 8:
                    dut.rd_channel_req.value = 0
                await _send_word(dut, chn=1, dv=0)
        for sample in range(SEQ_LEN):
            for chn in range(NUM_ANT):
                value = (sequence << 12) | sample if chn == 0 else (0x7000 | chn)
                await _send_word(dut, chn=chn, real=value, imag=value ^ 0x0555)

    _set_input(dut)
    await ClockCycles(dut.clk, 8)


def _physical_address(sequence, sample):
    """Return the existing contiguous 0..3071 address for a sequence sample."""
    chunk = 3 * sequence + sample // 512
    return (chunk << 9) | (sample & 0x1FF)


@cocotb.test()
async def test_three_explicit_banks_follow_the_existing_address_mapping(dut):
    await _reset(dut)

    banks = [dut.g_ant[0].g_bank[index].u_ram for index in range(RAM_BANKS)]
    assert len(banks) == RAM_BANKS
    assert all(len(bank.addra.value) == RAM_BANK_ADDR_WIDTH for bank in banks)

    observed_banks = set()
    observed_addresses = []
    observed_writes = 0
    monitor_done = False

    async def monitor_writes():
        nonlocal observed_writes, monitor_done
        while not monitor_done:
            await RisingEdge(dut.clk)
            await ReadOnly()
            write_enable = int(dut.wr_we.value) & 1
            if not write_enable:
                continue

            physical_address = int(dut.wr_addr.value)
            selected = [int(bank.ena.value) for bank in banks]
            assert sum(selected) == 1
            selected_bank = selected.index(1)
            assert selected_bank == physical_address >> RAM_BANK_ADDR_WIDTH
            assert int(banks[selected_bank].addra.value) == (
                physical_address & ((1 << RAM_BANK_ADDR_WIDTH) - 1)
            )
            observed_banks.add(selected_bank)
            observed_addresses.append(physical_address)
            observed_writes += 1

    monitor = cocotb.start_soon(monitor_writes())
    await _send_two_sequence_occasion(dut)
    monitor_done = True
    monitor.cancel()

    assert observed_writes >= 2 * SEQ_LEN
    assert observed_banks == {0, 1, 2}
    assert observed_addresses == list(range(2 * SEQ_LEN))


@cocotb.test()
async def test_readback_preserves_bit_reverse_order_across_all_memory_banks(dut):
    received_by_sequence = []
    memory_by_sequence = []

    for requested_sequence in range(2):
        await _reset(dut, start_clock=requested_sequence == 0)
        received = []

        async def monitor_readback():
            while True:
                await RisingEdge(dut.clk)
                await ReadOnly()
                if int(dut.dout_dv.value):
                    received.append(
                        (
                            int(dut.dout_chn.value),
                            int(dut.dout_dr.value),
                            int(dut.dout_di.value),
                        )
                    )

        monitor = cocotb.start_soon(monitor_readback())
        await _send_two_sequence_occasion(dut, requested_sequence)
        await ClockCycles(dut.clk, SEQ_LEN + 64)
        monitor.cancel()

        banks = [dut.g_ant[0].g_bank[index].u_ram for index in range(RAM_BANKS)]
        memory = {
            physical_address: int(
                banks[physical_address >> RAM_BANK_ADDR_WIDTH]
                .MEM[physical_address & ((1 << RAM_BANK_ADDR_WIDTH) - 1)]
                .value
            )
            for physical_address in range(2 * SEQ_LEN)
        }
        received_by_sequence.append(received)
        memory_by_sequence.append(memory)

    for received in received_by_sequence:
        assert len(received) == SEQ_LEN
        assert {channel for channel, _, _ in received} == {0}

    expected = []
    read_count = 0
    while len(expected) < SEQ_LEN:
        rd_count = read_count
        if rd_count & 0x3 == 0x3:
            read_count += 1
            continue

        reversed_count = 0
        for bit in range(9):
            reversed_count |= ((rd_count >> (10 - bit)) & 1) << bit
        reversed_count |= (rd_count & 0x3) << 9
        expected.append(reversed_count)
        read_count += 1

    for sequence, received in enumerate(received_by_sequence):
        expected_words = [
            memory_by_sequence[sequence][_physical_address(sequence, sample)]
            for sample in expected
        ]
        assert [real | (imag << 16) for _, real, imag in received] == expected_words


def test_prach_stream2block_runner():
    runner = get_runner(SIM)
    with tempfile.TemporaryDirectory(prefix="prach_stream2block_") as run_dir:
        runner.build(
            hdl_toplevel="prach_stream2block",
            sources=resolve_flt(PRJ_PATH / "prach.flt"),
            parameters={"NUM_ANT": NUM_ANT},
            always=True,
            waves=True,
            build_dir=run_dir,
        )
        runner.test(
            hdl_toplevel="prach_stream2block",
            hdl_toplevel_lang="verilog",
            test_module="test_prach_stream2block",
            waves=True,
            gui=os.environ.get("GUI", "false").lower() == "true",
            test_dir=run_dir,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
