"""Cocotb test for the rts Module"""

import os
from pathlib import Path

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge
from libaxi4l import axi_reset, axi_read, axi_write

# MARK: Env

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng()

# SOME_PARAMETER = int(os.environ.get("SOME_PARAMETER", 1))

GUI = os.environ.get("GUI", "false").lower() == "true"


REG_VERSION = 0x0
REG_SCRATCH0 = 0x4
REG_SCRATCH1 = 0x8

REG_SRC_SEL0 = 0x14
REG_SRC_SEL1 = 0x18
REG_SRC_SEL2 = 0x1C

REG_RAM_MODE = 0x30
REG_CW0_FREQ = 0x40
REG_CW0_POW = 0x44
REG_CW1_FREQ = 0x48
REG_CW1_POW = 0x4C

REG_RAM_ADDR_MSB = 0x100
REG_RAM0_OFFSET = 0x104
REG_RAM1_OFFSET = 0x108
REG_RAM2_OFFSET = 0x10C

REG_CAP_SEL = 0x200
REG_CAP_MODE = 0x204
REG_CAP_OFFSET = 0x208
REG_CAP_LEN = 0x20C
REG_CAP_CTRL = 0x210
REG_CAP_RAM_ADDR_MSB = 0x220

REG_INJT_RAM = 0x10000
REG_CAP_RAM = 0x18000

# MARK: Helper


async def reset(dut):
    """Reset the DUT"""
    dut.rst.value = 1
    dut.s_axi_aresetn.value = 0

    await axi_reset(dut)

    dut.rfs_in.value = 0
    dut.m_axis_tready.value = 1

    await ClockCycles(dut.s_axi_aclk, 10)
    dut.rst.value = 0
    dut.s_axi_aresetn.value = 1
    await ClockCycles(dut.clk, 10)


@cocotb.test
async def test_rts_axi(dut):
    """Test basic AXI operations"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 2, units="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.clk_l, 4, units="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, units="ns").start(start_high=False))

    # Reset the DUT
    await reset(dut)

    version = await axi_read(dut, REG_VERSION)
    assert version == 0x20240525

    await axi_write(dut, REG_SCRATCH0, 0x12345678)
    scratch0 = await axi_read(dut, REG_SCRATCH0)
    assert scratch0 == 0x12345678

    await axi_write(dut, REG_SCRATCH1, 0x9ABCDEF0)
    scratch1 = await axi_read(dut, REG_SCRATCH1)
    assert scratch1 == 0x9ABCDEF0

    # Test injection RAM

    for i in range(16):
        await axi_write(dut, REG_INJT_RAM + i * 4, 0x12345678 + i)

    # We have bug on RAM read/write switching latency, so we must wait some
    # clock cycles here
    await ClockCycles(dut.s_axi_aclk, 10)

    for i in range(16):
        data = await axi_read(dut, REG_INJT_RAM + i * 4)
        assert data == 0x12345678 + i

    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


# MARK: Tests


@cocotb.test
async def test_rts_cap(dut):
    """Test capture functionality"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 2, units="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.clk_l, 4, units="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, units="ns").start(start_high=False))

    # Reset the DUT
    await reset(dut)

    # Set source
    await axi_write(dut, REG_SRC_SEL0, 0x1)

    # Reset sequence counter
    await RisingEdge(dut.clk)
    dut.rfs_in.value = 1
    await RisingEdge(dut.clk)
    dut.rfs_in.value = 0

    # Set capture point, length and mode
    await axi_write(dut, REG_CAP_SEL, 0x00)
    await axi_write(dut, REG_CAP_MODE, 0x0)
    await axi_write(dut, REG_CAP_OFFSET, 0x0)
    await axi_write(dut, REG_CAP_LEN, 0x4)

    # Force trigger the capture
    await axi_write(dut, REG_CAP_CTRL, 0x2)

    # Wait for the capture to finish
    while True:
        status = await axi_read(dut, REG_CAP_CTRL)
        if status & 0x10 == 0x0:
            break

    # Read the capture RAM
    for i in range(16):
        data = await axi_read(dut, REG_CAP_RAM + i * 4)

    # Done
    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


# @cocotb.test
# async def test_rts(dut):
#     """Test case for rts Framer"""
#     cocotb.log.info("Simulation started")
#     # Create clock and start it
#     cocotb.start_soon(Clock(dut.clk, 2, units="ns").start(start_high=False))
#     cocotb.start_soon(Clock(dut.clk_l, 4, units="ns").start(start_high=False))
#     cocotb.start_soon(Clock(dut.s_axi_aclk, 10, units="ns").start(start_high=False))

#     # Reset the DUT
#     await reset(dut)

#     # Configure the DUT
#     await config(dut)

#     await RisingEdge(dut.clk)
#     dut.rfs_in.value = 1
#     await RisingEdge(dut.clk)
#     dut.rfs_in.value = 0

#     await ClockCycles(dut.clk, 10000)
#     cocotb.log.info("Simulation finished")


def test_rts_runner():
    """Run the rts tests"""
    sim = "questa"

    hdl_toplevel = "rts"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "../cdc/rtl/cdc_array_single.v",
        prj_path / "../cdc/rtl/cdc_async_rst.v",
        prj_path / "../cdc/rtl/cdc_gray.sv",
        prj_path / "../cdc/rtl/cdc_handshake_f.sv",
        prj_path / "../cdc/rtl/cdc_pulse.sv",
        prj_path / "../cdc/rtl/cdc_single.sv",
        prj_path / "../common/rtl/delay.v",
        prj_path / "../dds_lut/rtl/dds_lut_rom.v",
        prj_path / "../dds_lut/rtl/dds_lut.v",
        prj_path / "../fifo_async/rtl/fifo_async.v",
        prj_path / "../lfsr/rtl/lfsr.v",
        prj_path / "../mult/rtl/mult.v",
        prj_path / "../nco/rtl/nco.v",
        prj_path / "../ram/rtl/ram_sdp.v",
        prj_path / "../ram/rtl/ram_sdp_pipe.v",
        prj_path / "rtl/rts_cap_buffer.v",
        prj_path / "rtl/rts_cap_mux.v",
        prj_path / "rtl/rts_cap_ram.v",
        prj_path / "rtl/rts_cw.v",
        prj_path / "rtl/rts_mux.v",
        prj_path / "rtl/rts_ram_block.v",
        prj_path / "rtl/rts_ram_buffer.v",
        prj_path / "rtl/rts_ram.v",
        prj_path / "rtl/rts_regs.v",
        prj_path / "rtl/rts.v",
    ]

    test_args = [
        # f"-gSOME_PARAMETER={SOME_PARAMETER}",
    ]

    runner = get_runner(sim)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_args=test_args,
        test_module="test_rts",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    test_rts_runner()
