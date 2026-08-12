import os

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from pdxch_test_utils import PRJ_PATH, run_test

half_block = int(os.environ.get("HALF_BLOCK", "0"))
cc_id = 3


def packet_user(start_prb, cc=cc_id):
    return (cc << 27) | start_prb


def bank_depths():
    return (1024, 480) if half_block else (1792, 825)


async def reset(dut):
    dut.rst.value = 1
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tdata.value = 0
    dut.s_axis_exp.value = 0
    dut.s_axis_tuser.value = 0
    dut.s_dl_sym_num.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)


async def send_packet(dut, start_prb, bank, words, cc=cc_id):
    iq_bank_depth, exp_bank_depth = bank_depths()
    iq_start = bank * iq_bank_depth + start_prb * 6
    exp_start = bank * exp_bank_depth + start_prb * 3

    dut.s_dl_sym_num.value = bank
    for index, (data, exponent) in enumerate(words):
        dut.s_axis_tdata.value = data
        dut.s_axis_exp.value = exponent
        dut.s_axis_tlast.value = int(index == len(words) - 1)
        dut.s_axis_tuser.value = packet_user(start_prb, cc) if index == 0 else 0x123456
        dut.s_axis_tvalid.value = 1
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")

        # The RAM write interface is registered by one clock cycle.
        expected_iq_addr = iq_start + index
        expected_exp_addr = exp_start + index // 2
        expected_exp_en = index % 2 == 0
        expected_en = cc == cc_id
        assert int(dut.wr_iq_addr.value) == expected_iq_addr
        assert int(dut.wr_iq_en.value) == expected_en
        assert int(dut.wr_iq_data.value) == data
        assert int(dut.wr_exp_addr.value) == expected_exp_addr
        assert int(dut.wr_exp_en.value) == (expected_en and expected_exp_en)
        assert int(dut.wr_exp_data.value) == exponent

    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")
    assert int(dut.wr_iq_en.value) == 0
    assert int(dut.wr_exp_en.value) == 0


@cocotb.test()
async def test_fdv_buffer_write(dut):
    cocotb.start_soon(Clock(dut.clk, period=10, units="ns").start())
    await reset(dut)

    # The first packet has an odd number of words.  The next packet therefore
    # checks that its first exponent write starts at offset zero again.
    await send_packet(
        dut,
        start_prb=7,
        bank=0,
        words=[(0x100 + index, 0xA + index) for index in range(5)],
    )
    await send_packet(
        dut,
        start_prb=12,
        bank=1,
        words=[(0x200 + index, 0x4 + index) for index in range(4)],
    )

    # A packet for another component must not write either RAM.
    await send_packet(
        dut,
        start_prb=2,
        bank=0,
        words=[(0x300, 0x1), (0x301, 0x2)],
        cc=cc_id + 1,
    )


def test_fdv_buffer_write_runner():
    run_test(
        hdl_toplevel="pdxch_fdv_buffer_write",
        test_module="test_pdxch_fdv_buffer_write",
        sources=[PRJ_PATH / "rtl" / "pdxch_fdv_buffer_write.sv"],
        parameters={"CC_ID": cc_id, "HALF_BLOCK": half_block},
        build_name="fdv_buffer_write",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
