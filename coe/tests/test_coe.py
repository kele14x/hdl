"""Cocotb test for the CoE Module"""

import os
from pathlib import Path

import pytest
import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, RisingEdge
from libaxi4l import axi_reset, axi_read, axi_write

# MARK: Env

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng()

# SOME_PARAMETER = int(os.environ.get("SOME_PARAMETER", 1))

GUI = os.environ.get("GUI", "false").lower() == "true"

SIM = os.environ.get("SIM", "verilator")

TEST_NUM_SEQUENCE = 1024

REG_VERSION = 0x0
REG_SCRATCH0 = 0x4
REG_SCRATCH1 = 0x8
REG_TICK = 0x20

REG_DEFM_CTRL = 0x100
REG_DEFM_SRC_MAC_L = 0x108
REG_DEFM_SRC_MAC_H = 0x10C
REG_DEFM_DEST_MAC_L = 0x110
REG_DEFM_DEST_MAC_H = 0x114
REG_DEFM_SEQ_EN = 0x120
REG_DEFM_SEQ_ID0 = 0x124
REG_DEFM_SEQ_ID1 = 0x128
REG_DEFM_SEQ_ID2 = 0x12C
REG_DEFM_SEQ_ID3 = 0x130
REG_DEFM_TS_OFFSET = 0x134
REG_DEFM_TOTAL_PKT_CNT = 0x140
REG_DEFM_ECPRI_PKT_CNT = 0x148
REG_DEFM_TRANS_PKT_CNT = 0x150
REG_DEFM_ODM_PKT_CNT = 0x158

REG_FRAM_CTRL = 0x200
REG_FRAM_DEST_MAC_L = 0x208
REG_FRAM_DEST_MAC_H = 0x20C
REG_FRAM_SRC_MAC_L = 0x210
REG_FRAM_SRC_MAC_H = 0x214
REG_FRAM_VLAN_CTRL = 0x218
REG_FRAM_SEQ_EN = 0x220
REG_FRAM_SEQ_ID0 = 0x224
REG_FRAM_SEQ_ID1 = 0x228
REG_FRAM_SEQ_ID2 = 0x22C
REG_FRAM_SEQ_ID3 = 0x230
REG_FRAM_SEQ_CNT = 0x234

REG_ODM_CTRL = 0x300
REG_ODM_MEAS_INTERVAL = 0x308
REG_TS_DIFF_INGRESS_NS = 0x310
REG_TS_DIFF_INGRESS_SEC_L = 0x314
REG_TS_DIFF_INGRESS_SEC_H = 0x318
REG_TS_DIFF_EGRESS_NS = 0x320
REG_TS_DIFF_EGRESS_SEC_L = 0x324
REG_TS_DIFF_EGRESS_SEC_H = 0x328


# MARK: Helper


async def reset(dut):
    """Reset the DUT"""
    dut.rst.value = 1
    dut.s_axi_aresetn.value = 0
    dut.rx_eth_rst.value = 1
    dut.tx_eth_rst.value = 1

    await axi_reset(dut)

    # Ethernet interface
    dut.s_eth_rx_tdata.value = 0
    dut.s_eth_rx_tkeep.value = 0
    dut.s_eth_rx_tlast.value = 0
    dut.s_eth_rx_tvalid.value = 0
    #
    dut.m_eth_tx_tready.value = 1
    #
    dut.rx_ptp_timestamp.value = 0
    dut.rx_ptp_timestamp_valid.value = 0
    #
    dut.tx_ptp_timestamp.value = 0
    dut.tx_ptp_timestamp_tag.value = 0
    dut.tx_ptp_timestamp_valid.value = 0

    dut.pps_in.value = 0

    # Message interface
    dut.s_message_tdata.value = 0
    dut.s_message_tkeep.value = 0
    dut.s_message_tlast.value = 0
    dut.s_message_tvalid.value = 0
    #
    dut.m_message_tready.value = 1

    # Radio interface
    dut.s_axis_tx_tdata.value = 0
    dut.s_axis_tx_tuser.value = 0
    dut.s_axis_tx_tlast.value = 0
    dut.s_axis_tx_tvalid.value = 0
    #
    dut.m_axis_rx_tready.value = 1

    await ClockCycles(dut.clk, 100)
    dut.rst.value = 0
    dut.s_axi_aresetn.value = 1
    dut.rx_eth_rst.value = 0
    dut.tx_eth_rst.value = 0
    await ClockCycles(dut.clk, 100)


async def radio_tx_driver(dut):
    """Radio TX Driver"""
    # Sequence update trigger
    dut.s_axis_tx_tuser.value = 1
    dut.pps_in.value = 1
    await RisingEdge(dut.clk)
    dut.s_axis_tx_tuser.value = 0
    dut.pps_in.value = 0

    # Data to transmit
    xi = np.round(
        10 ** (-15 / 20)
        * 2**15
        * np.cos(2 * np.pi * np.arange(TEST_NUM_SEQUENCE) * 1e6 / 30.72e6)
    )
    xq = np.round(
        10 ** (-15 / 20)
        * 2**15
        * np.sin(2 * np.pi * np.arange(TEST_NUM_SEQUENCE) * 1e6 / 30.72e6)
    )

    # Loop the sequence
    dut.s_axis_tx_tuser.value = 0
    dut.s_axis_tx_tlast.value = 0
    dut.s_axis_tx_tvalid.value = 1
    for i in range(TEST_NUM_SEQUENCE):
        for _ in range(8):  # 16 sequence
            data = 0
            for _ in range(12):  # 12 CCs
                data = (
                    (data << 32) | ((int(xq[i]) & 0xFFFF) << 16) | (int(xi[i]) & 0xFFFF)
                )
            dut.s_axis_tx_tdata.value = data
            await RisingEdge(dut.clk)
    dut.s_axis_tx_tvalid.value = 0


async def loopback_driver(dut):
    """Loopback the Ethernet Tx data to Rx"""
    dut.m_eth_tx_tready.value = 1
    while True:
        await RisingEdge(dut.rx_eth_clk)
        dut.s_eth_rx_tdata.value = dut.m_eth_tx_tdata.value
        dut.s_eth_rx_tkeep.value = dut.m_eth_tx_tkeep.value
        dut.s_eth_rx_tlast.value = dut.m_eth_tx_tlast.value
        dut.s_eth_rx_tuser.value = dut.m_eth_tx_tuser.value
        dut.s_eth_rx_tvalid.value = dut.m_eth_tx_tvalid.value


# MARK: Tests


@cocotb.test(timeout_time=100000, timeout_unit="ns")
async def test_coe_axi(dut):
    """Test for basic AXI read/write"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 2, units="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.tx_eth_clk, 3.2, units="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.rx_eth_clk, 3.2, units="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, units="ns").start(start_high=False))

    # Reset the DUT
    await reset(dut)

    version = await axi_read(dut, REG_VERSION)
    assert version == 0x20241017

    await axi_write(dut, REG_SCRATCH0, 0x12345678)
    scratch0 = await axi_read(dut, REG_SCRATCH0)
    assert scratch0 == 0x12345678

    await axi_write(dut, REG_SCRATCH1, 0x9ABCDEF0)
    scratch1 = await axi_read(dut, REG_SCRATCH1)
    assert scratch1 == 0x9ABCDEF0

    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


@cocotb.test(timeout_time=100000, timeout_unit="ns")
async def test_coe(dut):
    """Test case for eCPRI Framer"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 2, units="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.tx_eth_clk, 3.2, units="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.rx_eth_clk, 3.2, units="ns").start(start_high=False))
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, units="ns").start(start_high=False))

    # Reset the DUT
    await reset(dut)

    # Configure the DUT
    await axi_write(dut, REG_TICK, 0x2)

    # Deframer configuration
    await axi_write(dut, REG_DEFM_CTRL, 0x1)
    await axi_write(dut, REG_DEFM_SEQ_EN, 0x303)
    await axi_write(dut, REG_DEFM_SEQ_ID0, 0x3F3F1000)
    await axi_write(dut, REG_DEFM_SEQ_ID1, 0x3F3F3F3F)
    await axi_write(dut, REG_DEFM_SEQ_ID2, 0x3F3F1000)
    await axi_write(dut, REG_DEFM_SEQ_ID3, 0x3F3F3F3F)
    await axi_write(dut, REG_DEFM_TS_OFFSET, 0x40)

    # Framer configuration
    await axi_write(dut, REG_FRAM_CTRL, 0x1)
    await axi_write(dut, REG_FRAM_SEQ_EN, 0x303)
    await axi_write(dut, REG_FRAM_SEQ_ID0, 0x3F3F1000)
    await axi_write(dut, REG_FRAM_SEQ_ID1, 0x3F3F3F3F)
    await axi_write(dut, REG_FRAM_SEQ_ID2, 0x3F3F1000)
    await axi_write(dut, REG_FRAM_SEQ_ID3, 0x3F3F3F3F)
    await axi_write(dut, REG_FRAM_SEQ_CNT, 0x20)

    # ODM configuration
    await axi_write(dut, REG_ODM_MEAS_INTERVAL, 0x1000)

    # Start the driver
    cocotb.start_soon(loopback_driver(dut))
    await radio_tx_driver(dut)

    await ClockCycles(dut.clk, 1000)
    cocotb.log.info("Simulation finished")


def test_coe_runner():
    """Run the eCPRI tests"""
    hdl_toplevel = "coe"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "coe.flt")

    parameters = {}

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        build_args=[
            "--timing",
            "-Wno-WIDTHEXPAND",
            "-Wno-WIDTHTRUNC",
            "-Wno-MULTIDRIVEN",
            f"-I{prj_path / 'rtl'}",
            f"-I{prj_path.parent / 'ecpri' / 'rtl'}",
        ],
        waves=True,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_coe",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
