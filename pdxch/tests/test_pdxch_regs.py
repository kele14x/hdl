"""AXI4-Lite and field decode tests for the generated PDXCH registers."""

from __future__ import annotations

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from pdxch_test_utils import PRJ_PATH, run_test


def _set_idle(dut):
    dut.s_axi_awaddr.value = 0
    dut.s_axi_awprot.value = 0
    dut.s_axi_awvalid.value = 0
    dut.s_axi_wdata.value = 0
    dut.s_axi_wstrb.value = 0
    dut.s_axi_wvalid.value = 0
    dut.s_axi_bready.value = 0
    dut.s_axi_araddr.value = 0
    dut.s_axi_arprot.value = 0
    dut.s_axi_arvalid.value = 0
    dut.s_axi_rready.value = 0
    dut.dl_phase_comp_dout.value = 0
    dut.dl_phase_comp_valid.value = 0


async def _reset(dut):
    _set_idle(dut)
    dut.s_axi_aresetn.value = 0
    await ClockCycles(dut.s_axi_aclk, 4)
    dut.s_axi_aresetn.value = 1
    await ClockCycles(dut.s_axi_aclk, 3)


async def _axi_write(dut, address, data, strobe=0xF):
    dut.s_axi_awaddr.value = address
    dut.s_axi_awvalid.value = 1
    dut.s_axi_wdata.value = data
    dut.s_axi_wstrb.value = strobe
    dut.s_axi_wvalid.value = 1

    for _ in range(20):
        await RisingEdge(dut.s_axi_aclk)
        await Timer(1, unit="ps")
        if int(dut.s_axi_awready.value) and int(dut.s_axi_wready.value):
            break
    else:
        raise AssertionError("AXI write channels did not become ready")

    dut.s_axi_awvalid.value = 0
    dut.s_axi_wvalid.value = 0
    dut.s_axi_bready.value = 1
    for _ in range(20):
        await RisingEdge(dut.s_axi_aclk)
        await Timer(1, unit="ps")
        if int(dut.s_axi_bvalid.value):
            assert int(dut.s_axi_bresp.value) == 0
            break
    else:
        raise AssertionError("AXI write response did not arrive")
    await RisingEdge(dut.s_axi_aclk)
    dut.s_axi_bready.value = 0


async def _axi_read(dut, address):
    dut.s_axi_araddr.value = address
    dut.s_axi_arvalid.value = 1
    dut.s_axi_rready.value = 1
    for _ in range(20):
        await RisingEdge(dut.s_axi_aclk)
        await Timer(1, unit="ps")
        if int(dut.s_axi_arready.value):
            break
    else:
        raise AssertionError("AXI read address channel did not become ready")

    dut.s_axi_arvalid.value = 0
    for _ in range(20):
        await RisingEdge(dut.s_axi_aclk)
        await Timer(1, unit="ps")
        if int(dut.s_axi_rvalid.value):
            data = int(dut.s_axi_rdata.value)
            assert int(dut.s_axi_rresp.value) == 0
            await RisingEdge(dut.s_axi_aclk)
            dut.s_axi_rready.value = 0
            return data
    raise AssertionError("AXI read response did not arrive")


@cocotb.test()
async def test_axi_registers_and_field_outputs(dut):
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, unit="ns").start())
    await _reset(dut)

    assert await _axi_read(dut, 0x00) == 0x20250106
    assert await _axi_read(dut, 0x04) == 0
    assert int(dut.dl_bw_cc0_out.value) == 2
    assert int(dut.dl_gain_0_0_val_out.value) == 0x4000

    await _axi_write(dut, 0x04, 0xA5A51234)
    await _axi_write(dut, 0x08, 0x55AA0F0F)
    assert await _axi_read(dut, 0x04) == 0xA5A51234
    assert await _axi_read(dut, 0x08) == 0x55AA0F0F

    # Three CC fields share one register, followed by the indexed PRB and
    # gain registers.
    await _axi_write(dut, 0x10, 0x00000B21)
    assert int(dut.dl_en_cc0_out.value) == 1
    assert int(dut.dl_en_cc1_out.value) == 2
    assert int(dut.dl_en_cc2_out.value) == 0xB
    assert await _axi_read(dut, 0x10) & 0xFFF == 0xB21

    await _axi_write(dut, 0x20, 0x00000155)
    assert int(dut.dl_nprb_0_val_out.value) == 0x155
    assert await _axi_read(dut, 0x20) & 0x1FF == 0x155

    await _axi_write(dut, 0x100, 0x00012345)
    assert int(dut.dl_gain_0_0_val_out.value) == 0x12345
    assert await _axi_read(dut, 0x100) & 0x1FFFF == 0x12345


def test_pdxch_regs_runner():
    run_test(
        hdl_toplevel="pdxch_regs",
        test_module="test_pdxch_regs",
        sources=[PRJ_PATH / "rtl" / "pdxch_regs.v"],
        build_name="regs",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
