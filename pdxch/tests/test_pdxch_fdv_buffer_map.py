import os
from pathlib import Path

import cocotb
import pytest
from cocotb_tools.runner import get_runner
from cocotb.triggers import Timer


prj_path = Path(__file__).resolve().parent.parent
half_block = int(os.environ.get("HALF_BLOCK", "0"))
sim = os.environ.get("SIM")
if not sim:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")


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
    runner = get_runner(sim)
    runner.build(
        hdl_toplevel="pdxch_fdv_buffer_map",
        sources=[prj_path / "rtl" / "pdxch_fdv_buffer_map.sv"],
        parameters={"HALF_BLOCK": half_block},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="pdxch_fdv_buffer_map",
        hdl_toplevel_lang="verilog",
        test_module="test_pdxch_fdv_buffer_map",
        waves=True,
        gui=False,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
