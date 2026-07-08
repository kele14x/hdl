"""Cocotb test for the eCPRI Module"""

import os
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge
from libaxi4l import axi_reset, axi_read, axi_write

# MARK: Env

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng()

# SOME_PARAMETER = int(os.environ.get("SOME_PARAMETER", 1))

GUI = os.environ.get("GUI", "false").lower() == "true"

SIM = os.environ.get("SIM", "verilator")

TEST_NUM_PACKETS = 10

TEST_PACKET_SIZE_MIN = 100
TEST_PACKET_SIZE_MAX = 100

rx_queue = Queue()
tx_queue = Queue()

# MARK: Helper


async def reset(dut):
    """Reset the DUT"""
    dut.rst.value = 1
    dut.s_axi_aresetn.value = 0
    dut.rx_eth_rst.value = 1
    dut.tx_eth_rst.value = 1

    await axi_reset(dut)

    # Framer interface
    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tvalid.value = 0
    #
    dut.s_trans_payloadsize.value = 0
    dut.s_trans_rtc_pc_id.value = 0
    dut.s_trans_seqid.value = 0
    dut.s_trans_ebit.value = 0
    dut.s_trans_subseqid.value = 0

    # Ethernet interface
    dut.m_eth_fram_tready.value = 0
    #
    dut.rx_ptp_timestamp.value = 0
    dut.rx_ptp_timestamp_valid.value = 0
    #
    dut.tx_ptp_timestamp.value = 0
    dut.tx_ptp_timestamp_tag.value = 0
    dut.tx_ptp_timestamp_valid.value = 0

    # PTP interface
    dut.s_ptp_tdata.value = 0
    dut.s_ptp_tkeep.value = 0
    dut.s_ptp_tlast.value = 0
    dut.s_ptp_tuser.value = 0
    dut.s_ptp_tvalid.value = 0

    # Message interface
    dut.s_message_tdata.value = 0
    dut.s_message_tkeep.value = 0
    dut.s_message_tlast.value = 0
    dut.s_message_tvalid.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    dut.s_axi_aresetn.value = 1
    dut.rx_eth_rst.value = 0
    dut.tx_eth_rst.value = 0
    await ClockCycles(dut.clk, 10)


async def config(dut):
    """Configure the DUT"""
    version = await axi_read(dut, 0x0)
    assert version == 0x20230411

    await axi_write(dut, 0x4, 0x12345678)
    scratch0 = await axi_read(dut, 0x4)
    assert scratch0 == 0x12345678

    await axi_write(dut, 0x8, 0x9ABCDEF0)
    scratch1 = await axi_read(dut, 0x8)
    assert scratch1 == 0x9ABCDEF0

    # odm_meas_interval
    await axi_write(dut, 0x308, 0x1000)


async def ethernet_master_driver(dut):
    """Drive the Ethernet master interface of DUT"""
    await RisingEdge(dut.tx_eth_clk)
    dut.m_eth_fram_tready.value = 1


async def ethernet_slave_driver(dut):
    """Drive the Ethernet slave interface of DUT"""
    await RisingEdge(dut.clk)
    # for _ in range(TEST_NUM_PACKETS):
    #     packet_size = np.random.randint(TEST_PACKET_SIZE_MIN, TEST_PACKET_SIZE_MAX + 1)
    #     packet_bytes = np.random.randint(0, 256, size=packet_size)

    #     # Pre-packet gap
    #     gap = np.random.randint(0, 10)
    #     await ClockCycles(dut.clk, gap)

    #     # OOB signals
    #     dut.s_trans_payloadsize.value = packet_size
    #     dut.s_trans_rtc_pc_id.value = 0
    #     dut.s_trans_seqid.value = 0
    #     dut.s_trans_ebit.value = 0
    #     dut.s_trans_subseqid.value = 0

    #     # Send the packet
    #     for i in range((len(packet_bytes) + 3) // 4):
    #         # Send one word
    #         tdata = 0
    #         tkeep = 0
    #         for j in range(4):
    #             if i * 4 + j < len(packet_bytes):
    #                 tdata += int(packet_bytes[i * 4 + j] << (8 * j))
    #                 tkeep += 1 << j
    #         dut.s_axis_tdata.value = tdata
    #         dut.s_axis_tkeep.value = tkeep
    #         dut.s_axis_tvalid.value = 1
    #         dut.s_axis_tlast.value = 1 if i == (len(packet_bytes) + 3) // 4 - 1 else 0
    #         # Wait the transaction to be accepted
    #         while True:
    #             await RisingEdge(dut.clk)
    #             if dut.s_axis_tready.value:
    #                 break
    #         # Done for word
    #         dut.s_axis_tvalid.value = 0


# MARK: Tests


@cocotb.test
async def test_ecpri(dut):
    """Test case for eCPRI Framer"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 2, units="ns").start())
    cocotb.start_soon(Clock(dut.tx_eth_clk, 3.2, units="ns").start())
    cocotb.start_soon(Clock(dut.rx_eth_clk, 3.2, units="ns").start())
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, units="ns").start())

    # Reset the DUT
    await reset(dut)

    # Configure the DUT
    await config(dut)

    # Start the driver
    cocotb.start_soon(ethernet_master_driver(dut))
    cocotb.start_soon(ethernet_slave_driver(dut))

    await ClockCycles(dut.clk, 10000)
    cocotb.log.info("Simulation finished")


def test_ecpri_runner():
    """Run the eCPRI tests"""
    hdl_toplevel = "ecpri"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "../cdc/rtl/cdc_async_rst.sv",
        prj_path / "../cdc/rtl/cdc_gray.sv",
        prj_path / "../cdc/rtl/cdc_handshake_f.sv",
        prj_path / "../cdc/rtl/cdc_pulse.sv",
        prj_path / "../cdc/rtl/cdc_single.sv",
        prj_path / "../common/rtl/delay.v",
        prj_path / "../fifo_async/rtl/fifo_async.v",
        prj_path / "../fifo_sync/rtl/fifo_sync.v",
        prj_path / "../ram/rtl/ram_sdp.v",
        prj_path / "rtl/ecpri_deframer_common.v",
        prj_path / "rtl/ecpri_deframer_demux.v",
        prj_path / "rtl/ecpri_deframer_eth.v",
        prj_path / "rtl/ecpri_deframer_iq.v",
        prj_path / "rtl/ecpri_deframer_odm.v",
        prj_path / "rtl/ecpri_deframer.v",
        prj_path / "rtl/ecpri_framer_fifo.v",
        prj_path / "rtl/ecpri_framer_message.v",
        prj_path / "rtl/ecpri_framer_odm.v",
        prj_path / "rtl/ecpri_framer_ptp.v",
        prj_path / "rtl/ecpri_framer_reg.v",
        prj_path / "rtl/ecpri_framer_trans_reg.v",
        prj_path / "rtl/ecpri_framer_trans.v",
        prj_path / "rtl/ecpri_framer.v",
        prj_path / "rtl/ecpri_if.v",
        prj_path / "rtl/ecpri_odm.v",
        prj_path / "rtl/ecpri_packet_fifo.v",
        prj_path / "rtl/ecpri_regs.v",
        prj_path / "rtl/ecpri_statistics.v",
        prj_path / "rtl/ecpri_switch.v",
        prj_path / "rtl/ecpri.v",
    ]

    parameters = {}

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_ecpri",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
