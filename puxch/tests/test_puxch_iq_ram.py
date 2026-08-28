#!/usr/bin/env python3
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from puxch_test_utils import PRJ_PATH, run_cocotb, sample_after_rising

from hdl_tools.flt_tool import resolve_flt

TEST_PAIRS = {
    0: (0, 1),
    1023: (2046, 2047),
    1024: (2048, 2049),
    2047: (4094, 4095),
    2048: (4096, 4097),
    3071: (6142, 6143),
    3072: (6144, 6145),
    3583: (7166, 7167),
}


def narrow_word(address):
    return ((address * 0x21) ^ 0x15555) & ((1 << 18) - 1)


@cocotb.test()
async def test_segment_boundaries_and_asymmetric_packing(dut):
    cocotb.start_soon(Clock(dut.clka, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clkb, 3, unit="ns").start())

    dut.wea.value = 0
    dut.addra.value = 0
    dut.dina.value = 0
    dut.rstb.value = 1
    dut.enb.value = 0
    dut.addrb.value = 0
    await sample_after_rising(dut.clkb)
    await sample_after_rising(dut.clkb)
    dut.rstb.value = 0

    write_addresses = sorted(
        address for pair in TEST_PAIRS.values() for address in pair
    )
    for address in write_addresses:
        await sample_after_rising(dut.clka)
        dut.wea.value = 1
        dut.addra.value = address
        dut.dina.value = narrow_word(address)
    await sample_after_rising(dut.clka)
    dut.wea.value = 0

    for read_address, (even_address, odd_address) in TEST_PAIRS.items():
        await sample_after_rising(dut.clkb)
        dut.enb.value = 0b11
        dut.addrb.value = read_address
        await sample_after_rising(dut.clkb)
        await sample_after_rising(dut.clkb)

        expected = narrow_word(even_address) | (narrow_word(odd_address) << 18)
        assert int(dut.doutb.value) == expected


def test_puxch_iq_ram_runner():
    sources = [
        *resolve_flt(PRJ_PATH.parent / "ram" / "ram.flt"),
        PRJ_PATH / "rtl" / "puxch_iq_ram.sv",
    ]
    run_cocotb(
        "puxch_iq_ram",
        Path(__file__).stem,
        sources=sources,
        build_name=Path(__file__).stem,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
