import os
from pathlib import Path

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge
from libecpri import EcpriPacket, EthernetPacket, EcpriOdmMessage, EcpriIqMessage


# MARK: Env

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(1234567890)


# SOME_PARAMETER = int(os.environ.get("SOME_PARAMETER", 1))

GUI = os.environ.get("GUI", "false").lower() == "true"

TEST_NUM_PACKETS = int(os.environ.get("TEST_NUM_PACKETS", 100))


# MARK: Helper

input_queue = Queue()
output_queue = Queue()


async def reset(dut):
    """Reset the DUT"""
    dut.rst.value = 1
    dut.rx_eth_rst.value = 1

    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tuser.value = 0

    dut.rx_ptp_timestamp.value = 0
    dut.rx_ptp_timestamp_valid.value = 0

    dut.m_ptp_tready.value = 1
    dut.m_message_tready.value = 1

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    dut.rx_eth_rst.value = 0
    await ClockCycles(dut.clk, 10)


async def send_packet(dut, packet, user=None, timestamp=0):
    """Send a packet to the DUT"""
    # Sync to clock edge
    await RisingEdge(dut.rx_eth_clk)
    dut.s_axis_tvalid.value = 0
    # Send packet
    packet_bytes = bytes(packet)
    for i in range((len(packet_bytes) + 3) // 4):
        tdata = 0
        tkeep = 0
        for j in range(4):
            if i * 4 + j < len(packet_bytes):
                tdata += packet_bytes[i * 4 + j] << (8 * j)
                tkeep += 1 << j
        dut.s_axis_tdata.value = tdata
        dut.s_axis_tkeep.value = tkeep
        dut.s_axis_tlast.value = 1 if i == (len(packet_bytes) + 3) // 4 - 1 else 0
        dut.s_axis_tuser.value = user[i] if user is not None else 0
        dut.s_axis_tvalid.value = 1
        # OOB signals
        dut.rx_ptp_timestamp_valid.value = 1 if i == 0 else 0
        if i == 0:
            dut.rx_ptp_timestamp.value = timestamp
        # Wait for the word be accepted
        await RisingEdge(dut.rx_eth_clk)
        dut.s_axis_tvalid.value = 0


async def drive(dut):
    """Drive the input of DUT"""
    for _ in range(TEST_NUM_PACKETS):

        ethertype = rng.choice([0x0800, 0x88F7, 0xAEFE])

        if ethertype == 0x0800:
            # IPv4
            packet = EthernetPacket()
            packet.hdr.dest_mac = 0x001122334455
            packet.hdr.src_mac = 0x001122334466
            packet.hdr.ethertype = ethertype
            packet.hdr.with_vlan = rng.choice([True, False])
            if packet.hdr.with_vlan:
                packet.hdr.vlan_tag = rng.integers(0, 4095)

            payload_size = rng.integers(50, 100)
            packet.payload = rng.bytes(payload_size)

        elif ethertype == 0x88F7:
            # PTP
            packet = EthernetPacket()
            packet.hdr.dest_mac = 0x001122334455
            packet.hdr.src_mac = 0x001122334466
            packet.hdr.ethertype = ethertype

            payload_size = rng.integers(50, 100)
            packet.payload = rng.bytes(payload_size)

        elif ethertype == 0xAEFE:
            # eCPRI
            packet = EcpriPacket()
            packet.ethernet_hdr.dest_mac = 0x001122334455
            packet.ethernet_hdr.src_mac = 0x001122334466
            packet.ethernet_hdr.ethertype = 0xAEFE

            msg0 = EcpriOdmMessage()
            msg0.common_hdr.version = 1
            msg0.common_hdr.concat = 0
            msg0.common_hdr.message_type = 0
            msg0.common_hdr.payload_size = 20
            msg0.measurement_id = 0x01
            msg0.action_type = 0x02
            msg0.timestamp = 0x00112233445566778899
            msg0.compensation = 0xAABBCCDDEEFF0011

            packet.ecpri_messages = [msg0]

        await send_packet(dut, packet)


# MARK: Tests


@cocotb.test
async def test_ecpri_deframer_single_ecpri_iq_packet(dut):
    """Test with a single eCPRI IQ packet"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 4, units="ns").start())
    cocotb.start_soon(Clock(dut.rx_eth_clk, 6.4, units="ns").start())

    # Reset the DUT
    await reset(dut)

    # Send a single eCPRI packet
    packet = EcpriPacket()
    packet.ethernet_hdr.dest_mac = 0x001122334455
    packet.ethernet_hdr.src_mac = 0x001122334466
    packet.ethernet_hdr.ethertype = 0xAEFE

    msg0 = EcpriIqMessage()
    msg0.common_hdr.version = 1
    msg0.common_hdr.concat = 0
    msg0.common_hdr.message_type = 0
    msg0.common_hdr.payload_size = 24
    msg0.pc_id = 0x1234
    msg0.seq_id = 0xAB
    msg0.e_bit = 0x1
    msg0.subseq_id = 0x7F
    msg0.payload = rng.bytes(20)

    packet.messages = [msg0]
    timestamp = int(rng.integers(0, 1000))

    await send_packet(dut, packet, timestamp=timestamp)

    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


@cocotb.test
async def test_ecpri_deframer_single_ecpri_odm_packet(dut):
    """Test with a single eCPRI ODM packet"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 4, units="ns").start())
    cocotb.start_soon(Clock(dut.rx_eth_clk, 6.4, units="ns").start())

    # Reset the DUT
    await reset(dut)

    # Send a single eCPRI packet
    packet = EcpriPacket()
    packet.ethernet_hdr.dest_mac = 0x001122334455
    packet.ethernet_hdr.src_mac = 0x001122334466
    packet.ethernet_hdr.ethertype = 0xAEFE

    msg0 = EcpriOdmMessage()
    msg0.common_hdr.version = 1
    msg0.common_hdr.concat = 0
    msg0.common_hdr.message_type = 5
    msg0.common_hdr.payload_size = 20
    msg0.measurement_id = 0x01
    msg0.action_type = 0x02
    msg0.timestamp = 0x00112233445566778899
    msg0.compensation = 0xAABBCCDDEEFF0011

    packet.messages = [msg0]
    timestamp = int(rng.integers(0, 1000))

    await send_packet(dut, packet, timestamp=timestamp)

    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


@cocotb.test
async def test_ecpri_deframer_single_ptp_packet(dut):
    """Test with a single PTP packet"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 4, units="ns").start())
    cocotb.start_soon(Clock(dut.rx_eth_clk, 6.4, units="ns").start())

    # Reset the DUT
    await reset(dut)

    # Send a single PTP packet
    packet = EthernetPacket()
    packet.hdr.dest_mac = 0x001122334455
    packet.hdr.src_mac = 0x001122334466
    packet.hdr.ethertype = 0x88F7
    packet.payload = rng.bytes(46)
    timestamp = int(rng.integers(0, 1000))
    await send_packet(dut, packet, timestamp=timestamp)

    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


@cocotb.test
async def test_ecpri_deframer_single_oam_packet(dut):
    """Test with a single OAM packet"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 4, units="ns").start())
    cocotb.start_soon(Clock(dut.rx_eth_clk, 6.4, units="ns").start())

    # Reset the DUT
    await reset(dut)

    # Send a single OAM packet
    packet = EthernetPacket()
    packet.hdr.dest_mac = 0x001122334455
    packet.hdr.src_mac = 0x001122334466
    packet.hdr.ethertype = 0x0800
    packet.payload = rng.bytes(46)
    timestamp = int(rng.integers(0, 1000))
    await send_packet(dut, packet, timestamp=timestamp)

    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


@cocotb.test
async def test_ecpri_deframer_single_corrupt_packet(dut):
    """Test with a single corrupt packet"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 4, units="ns").start())
    cocotb.start_soon(Clock(dut.rx_eth_clk, 6.4, units="ns").start())

    # Reset the DUT
    await reset(dut)

    # Send a single corrupt packet
    packet = EthernetPacket()
    packet.hdr.dest_mac = 0x001122334455
    packet.hdr.src_mac = 0x001122334466
    packet.hdr.ethertype = 0xAEFE
    packet.payload = rng.bytes(46)
    user = [0] * 15
    user[4] = 1
    await send_packet(dut, packet, user=user)

    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


@cocotb.test
async def test_ecpri_deframer_random_packets(dut):
    """Test with random packets"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 4, units="ns").start())
    cocotb.start_soon(Clock(dut.rx_eth_clk, 6.4, units="ns").start())

    # Reset the DUT
    await reset(dut)

    # Run test multiple times
    await drive(dut)

    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


# MARK: Runner


def test_ecpri_deframer_runner():
    """Run the eCPRI Deframer test"""
    sim = "questa"

    hdl_toplevel = "ecpri_deframer"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "../cdc/rtl/cdc_async_rst.v",
        prj_path / "../cdc/rtl/cdc_gray.v",
        prj_path / "../cdc/rtl/cdc_pulse.v",
        prj_path / "../cdc/rtl/cdc_single.v",
        prj_path / "../common/rtl/delay.v",
        prj_path / "../fifo_async/rtl/fifo_async.v",
        prj_path / "../ram/rtl/ram_sdp.v",
        prj_path / "rtl/ecpri_deframer_common.v",
        prj_path / "rtl/ecpri_deframer_demux.v",
        prj_path / "rtl/ecpri_deframer_eth.v",
        prj_path / "rtl/ecpri_deframer_iq.v",
        prj_path / "rtl/ecpri_deframer_odm.v",
        prj_path / "rtl/ecpri_deframer_packet_fifo.v",
        prj_path / "rtl/ecpri_deframer.v",
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
        test_module="test_ecpri_deframer",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    test_ecpri_deframer_runner()
