import os
from pathlib import Path

import cocotb
import numpy as np
import numpy.typing as npt
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge


from typing import Optional

# MARK: Env


prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(1234567890)

# SOME_PARAMETER = int(os.environ.get("SOME_PARAMETER", 0))

GUI = os.environ.get("GUI", "false").lower() == "true"

SIM = os.environ.get("SIM", "verilator")

TEST_NUM_PACKETS = 1000
TEST_PACKET_SIZE_MIN = 1
TEST_PACKET_SIZE_MAX = 80


# MARK: Helper


input_queue = Queue()
output_queue = Queue()


class Packet:
    """Packet class to hold data bytes"""

    data: Optional[bytes] = None
    user: int = 0
    pre_gap: int = 0
    post_gap: int = 0


async def reset(dut):
    """Reset the DUT"""
    dut.rst.value = 1

    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0

    dut.m_axis_tready.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def slave_driver(dut, packets: list[Packet]):
    """Drive the slave side of DUT"""
    post_gap = 0
    for packet in packets:
        # Pre-packet gap
        gap = max(post_gap, packet.pre_gap)
        await ClockCycles(dut.clk, gap)

        packet_data = packet.data
        if packet_data is not None:
            # Send the packet
            for i in range((len(packet_data) + 3) // 4):
                # Send the word
                tdata = 0
                tkeep = 0
                for j in range(4):
                    if i * 4 + j < len(packet_data):
                        tdata += (packet_data[i * 4 + j] & 0xFF) << (j * 8)
                        tkeep += 1 << j
                dut.s_axis_tdata.value = int(tdata)
                dut.s_axis_tkeep.value = tkeep
                dut.s_axis_tlast.value = (
                    1 if i == (len(packet_data) + 3) // 4 - 1 else 0
                )
                dut.s_axis_tuser.value = packet.user
                dut.s_axis_tvalid.value = 1

                # Wait for the slave to be ready
                while True:
                    await RisingEdge(dut.clk)
                    if dut.s_axis_tready.value:
                        break
                dut.s_axis_tvalid.value = 0

                # Insert some bubbles
                # bubble = rng.choice([0, 1, 2], p=[0.9, 0.05, 0.05])
                # await ClockCycles(dut.clk, bubble)

        # Post-packet gap
        post_gap = packet.post_gap


async def master_driver(dut, p: float):
    """Drive the master side of DUT"""
    while True:
        ready = rng.choice([0, 1], p=[1 - p, p])
        dut.m_axis_tready.value = int(ready)
        await RisingEdge(dut.clk)


async def slave_monitor(dut):
    """Monitor the slave side of DUT"""
    p = []
    while True:
        await RisingEdge(dut.clk)
        if dut.s_axis_tvalid.value and dut.s_axis_tready.value:
            a = [(dut.s_axis_tdata.value >> (i * 8)) & 0xFF for i in range(4)]
            keep = dut.s_axis_tkeep.value
            if dut.s_axis_tlast.value:
                if keep == 1:
                    p += a[0:1]
                elif keep == 3:
                    p += a[0:2]
                elif keep == 7:
                    p += a[0:3]
                elif keep == 15:
                    p += a[0:4]
                else:
                    assert False, f"TKEEP value is invalid: {keep}"
                input_queue.put_nowait(p)
                p = []
            else:
                assert keep == 15, f"TKEEP value is invalid: {keep}"
                p += a


async def master_monitor(dut):
    """Monitor the master side of DUT"""
    p = []
    continuous = False
    while True:
        await RisingEdge(dut.clk)
        # Check that the data is continues
        if continuous and not dut.m_axis_tvalid.value:
            assert False, "TVALID is not continuous"
        if dut.m_axis_tvalid.value and dut.m_axis_tready.value:
            a = [(dut.m_axis_tdata.value >> (i * 8)) & 0xFF for i in range(4)]
            keep = dut.m_axis_tkeep.value
            continuous = True
            if dut.m_axis_tlast.value:
                if keep == 1:
                    p += a[0:1]
                elif keep == 3:
                    p += a[0:2]
                elif keep == 7:
                    p += a[0:3]
                elif keep == 15:
                    p += a[0:4]
                else:
                    assert False, f"TKEEP value is invalid: {keep}"
                output_queue.put_nowait(p)
                p = []
                continuous = False
            else:
                assert keep == 15, f"TKEEP value is invalid: {keep}"
                p += a


async def checker():
    """Check the output of DUT"""
    n = 0
    while True:
        # Get input data, skip if it is too short
        input_data = await input_queue.get()
        # Get output data
        output_data = await output_queue.get()
        # Expected ta is, input padding with zeros if smaller than 60 bytes
        expected_data = input_data
        if len(expected_data) < 60:
            expected_data = expected_data + [0] * (60 - len(expected_data))

        n += 1
        cocotb.log.info("# %d", n)
        assert expected_data == output_data, (  #
            f"Check failed\n"  #
            f"Input: length = {len(input_data)}, data = {input_data}\n"  #
            f"Expected: length = {len(expected_data)}, data = {expected_data}\n"  #
            f"Output: length = {len(output_data)}, data = {output_data}\n"
        )


# MARK: Tests


@cocotb.test
async def test_ecpri_framer_padding_single(dut):
    """Test case for eCPRI Framer"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    await reset(dut)

    # Test cases
    packets = []

    packet = Packet()
    packet.data = rng.bytes(61)
    packet.user = int(rng.integers(0, 2**18))

    packets.append(packet)

    # Run test multiple
    cocotb.start_soon(master_monitor(dut))
    cocotb.start_soon(slave_monitor(dut))
    cocotb.start_soon(checker())

    cocotb.start_soon(master_driver(dut, 1))
    await slave_driver(dut, packets)

    await ClockCycles(dut.clk, 1000)
    cocotb.log.info("Simulation finished")


@cocotb.test
async def test_ecpri_framer_padding_random(dut):
    """Test case for eCPRI Framer"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    await reset(dut)

    # Test cases
    packets = []
    for _ in range(TEST_NUM_PACKETS):
        size = int(rng.integers(TEST_PACKET_SIZE_MIN, TEST_PACKET_SIZE_MAX))
        packet = Packet()
        packet.data = rng.bytes(size)
        packet.user = int(rng.integers(0, 2**18))
        packet.pre_gap = int(rng.choice([0, 1, 2], p=[0.5, 0.4, 0.1]))
        packet.post_gap = int(rng.choice([0, 1, 2], p=[0.5, 0.4, 0.1]))
        packets.append(packet)

    # Run test multiple times
    cocotb.start_soon(master_monitor(dut))
    cocotb.start_soon(slave_monitor(dut))
    cocotb.start_soon(checker())

    cocotb.start_soon(master_driver(dut, 0.9))
    await slave_driver(dut, packets)

    await ClockCycles(dut.clk, 1000)
    cocotb.log.info("Simulation finished")


def test_ecpri_framer_padding_runner():
    """Run the test for eCPRI Framer Ethernet"""
    hdl_toplevel = "ecpri_framer_padding"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "../axis_reg/rtl/axis_reg.v",
        prj_path / "rtl/ecpri_framer_padding.v",
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
        test_module="test_ecpri_framer_padding",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
