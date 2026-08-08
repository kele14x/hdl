import os

import cocotb
import pytest
from cocotb.triggers import Timer
from pdxch_test_utils import PRJ_PATH, run_test

half_block = int(os.environ.get("HALF_BLOCK", "0"))


def expected_addresses(bank, logical_re):
    iq_bank_depth = 1024 if half_block else 1792
    exp_bank_depth = 480 if half_block else 825
    iq_addr = (logical_re >> 1) + (iq_bank_depth if bank else 0)
    exp_addr = (logical_re >> 2) + (exp_bank_depth if bank else 0)
    return iq_addr, exp_addr, logical_re & 1


@cocotb.test()
async def test_fdv_buffer_map(dut):
    max_re = 160 * 12 if half_block else 275 * 12
    test_points = [0, 1, 2, 3, 4, max_re - 4, max_re - 1]

    for bank in (0, 1):
        for logical_re in test_points:
            dut.bank.value = bank
            dut.logical_re.value = logical_re
            await Timer(1, unit="ns")

            expected_iq, expected_exp, expected_half = expected_addresses(
                bank, logical_re
            )
            assert int(dut.iq_addr.value) == expected_iq
            assert int(dut.exp_addr.value) == expected_exp
            assert int(dut.iq_half.value) == expected_half


def test_fdv_buffer_map_runner():
    run_test(
        hdl_toplevel="pdxch_fdv_buffer_map",
        test_module="test_pdxch_fdv_buffer_map",
        sources=[PRJ_PATH / "rtl" / "pdxch_fdv_buffer_map.sv"],
        parameters={"HALF_BLOCK": half_block},
        build_name="fdv_buffer_map",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
