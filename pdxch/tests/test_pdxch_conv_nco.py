"""Unit tests for the PDXCH numerically controlled oscillator."""

from __future__ import annotations

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from pdxch_test_utils import PRJ_PATH, run_test


@cocotb.test()
async def test_quadrature_lut_and_pipeline(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # The LUT has 128 entries, so these four phases exercise the cardinal
    # points without relying on a simulator-specific real-to-integer rounding
    # result for the other entries.
    phases = [0, 32, 64, 96, 0, 32, 64, 96]
    expected = {
        0: (0x4000, 0x0000),
        32: (0x0000, 0x4000),
        64: (0xC000, 0x0000),
        96: (0x0000, 0xC000),
    }

    dut.phase.value = phases[0]
    captured_phases = []
    for index, phase in enumerate(phases):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        captured_phases.append(phase)

        # cos_addr -> cos_r1 -> cos_r2 is a three-register pipeline. Since
        # phase is driven before the first edge, the first stable result is
        # visible after two subsequent edges.
        if index >= 2:
            expected_cos, expected_sin = expected[captured_phases[index - 2]]
            assert int(dut.cos.value) == expected_cos
            assert int(dut.sin.value) == expected_sin

        if index + 1 < len(phases):
            dut.phase.value = phases[index + 1]


def test_pdxch_conv_nco_runner():
    run_test(
        hdl_toplevel="pdxch_conv_nco",
        test_module="test_pdxch_conv_nco",
        sources=[PRJ_PATH / "rtl" / "pdxch_conv_nco.sv"],
        build_name="conv_nco",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
