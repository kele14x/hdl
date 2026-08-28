#!/usr/bin/env python3
import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from puxch_test_utils import PRJ_PATH, run_cocotb, sample_after_rising

from hdl_tools.flt_tool import resolve_flt

FULL_TEST_PAIRS = {
    0: (0, 1),
    1023: (2046, 2047),
    1024: (2048, 2049),
    2047: (4094, 4095),
    2048: (4096, 4097),
    3071: (6142, 6143),
    3072: (6144, 6145),
    3583: (7166, 7167),
}

HALF_TEST_PAIRS = {
    0: (0, 1),
    959: (1918, 1919),
    960: (1920, 1921),
    1919: (3838, 3839),
}

HALF_BLOCK = int(os.environ.get("HALF_BLOCK", "0"))


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
        address
        for pair in (HALF_TEST_PAIRS if HALF_BLOCK else FULL_TEST_PAIRS).values()
        for address in pair
    )
    for address in write_addresses:
        await sample_after_rising(dut.clka)
        dut.wea.value = 1
        dut.addra.value = address
        dut.dina.value = narrow_word(address)
    await sample_after_rising(dut.clka)
    dut.wea.value = 0

    test_pairs = HALF_TEST_PAIRS if HALF_BLOCK else FULL_TEST_PAIRS
    for read_address, (even_address, odd_address) in test_pairs.items():
        await sample_after_rising(dut.clkb)
        dut.enb.value = 0b11
        dut.addrb.value = read_address
        await sample_after_rising(dut.clkb)
        await sample_after_rising(dut.clkb)

        expected = narrow_word(even_address) | (narrow_word(odd_address) << 18)
        assert int(dut.doutb.value) == expected


@pytest.mark.parametrize("half_block", [0, 1])
def test_puxch_iq_ram_runner(half_block, monkeypatch):
    monkeypatch.setenv("HALF_BLOCK", str(half_block))
    sources = [
        *resolve_flt(PRJ_PATH.parent / "ram" / "ram.flt"),
        PRJ_PATH / "rtl" / "puxch_iq_ram.sv",
    ]
    run_cocotb(
        "puxch_iq_ram",
        Path(__file__).stem,
        sources=sources,
        parameters={"HALF_BLOCK": half_block},
        build_name=f"{Path(__file__).stem}_half_block_{half_block}",
        extra_env={"HALF_BLOCK": str(half_block)},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
