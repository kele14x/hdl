import os
from pathlib import Path

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge


# MARK: Env


prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(1234567890)

# SOME_PARAMETER = int(os.environ.get("SOME_PARAMETER", 0))

GUI = os.environ.get("GUI", "false").lower() == "true"

TEST_NUM_PACKETS = 100
TEST_PACKET_SIZE_MIN = 1
TEST_PACKET_SIZE_MAX = 128

DATA_BYTES = 8

# MARK: Helper


input_queue = Queue()
output_queue = Queue()


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


async def slave_driver(dut):
    """Drive the slave side of DUT"""
    for _ in range(TEST_NUM_PACKETS):
        packet_size = rng.integers(TEST_PACKET_SIZE_MIN, TEST_PACKET_SIZE_MAX, endpoint=True)
        packet_bytes = rng.bytes(packet_size)

        # Pre-packet gap
        gap = rng.choice([0, 1, 2, 3], p=[0.7, 0.1, 0.1, 0.1])
        await ClockCycles(dut.clk, gap)

        # Send the packet
        num_words = (len(packet_bytes) + DATA_BYTES - 1) // DATA_BYTES
        for i in range(num_words):
            # Send the word
            tdata = 0
            tkeep = 0
            for j in range(DATA_BYTES):
                if i * DATA_BYTES + j < len(packet_bytes):
                    tdata += int(packet_bytes[i * DATA_BYTES + j] << (8 * j))
                    tkeep += 1 << j
            dut.s_axis_tdata.value = tdata
            dut.s_axis_tkeep.value = tkeep
            dut.s_axis_tvalid.value = 1
            dut.s_axis_tlast.value = 1 if i == num_words - 1 else 0
            while True:
                await RisingEdge(dut.clk)
                if dut.s_axis_tready.value:
                    break
            dut.s_axis_tvalid.value = 0

            # Send pause
            pause = rng.choice([0, 1, 2], p=[0.8, 0.1, 0.1])
            await ClockCycles(dut.clk, pause)


async def master_driver(dut):
    """Drive the master side of DUT"""
    while True:
        dut.m_axis_tready.value = int(rng.choice([0, 1], p=[0.1, 0.9]))
        await RisingEdge(dut.clk)


async def slave_monitor(dut):
    """Monitor the slave side of DUT"""
    p = []
    while True:
        await RisingEdge(dut.clk)
        if dut.s_axis_tvalid.value and dut.s_axis_tready.value:
            a = [(dut.s_axis_tdata.value >> (i * 8)) & 0xFF for i in range(DATA_BYTES)]
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
                elif keep == 31:
                    p += a[0:5]
                elif keep == 63:
                    p += a[0:6]
                elif keep == 127:
                    p += a[0:7]
                elif keep == 255:
                    p += a[0:8]
                else:
                    assert False, f"TKEEP value is invalid: {keep}"
                input_queue.put_nowait(p)
                p = []
            else:
                assert keep == 255, f"TKEEP value is invalid: {keep}"
                p += a


async def master_monitor(dut):
    """Monitor the master side of DUT"""
    p = []
    while True:
        await RisingEdge(dut.clk)
        if dut.m_axis_tvalid.value and dut.m_axis_tready.value:
            a = [(dut.m_axis_tdata.value >> (i * 8)) & 0xFF for i in range(DATA_BYTES)]
            keep = dut.m_axis_tkeep.value
            if dut.m_axis_tlast.value:
                if keep == 1:
                    p += a[0:1]
                elif keep == 3:
                    p += a[0:2]
                elif keep == 7:
                    p += a[0:3]
                elif keep == 15:
                    p += a[0:4]
                elif keep == 31:
                    p += a[0:5]
                elif keep == 63:
                    p += a[0:6]
                elif keep == 127:
                    p += a[0:7]
                elif keep == 255:
                    p += a[0:8]
                else:
                    assert False, f"TKEEP value is invalid: {keep}"
                output_queue.put_nowait(p)
                p = []
            else:
                assert keep == 255, f"TKEEP value is invalid: {keep}"
                p += a


async def checker():
    """Check the output of DUT"""
    n = 0
    while True:
        # Get input data, skip if it is too short
        input_data = await input_queue.get()
        assert len(input_data) > 0

        # Get output data
        output_data = await output_queue.get()

        # Pad p1 with zeros if smaller than 60 bytes
        expected_data = input_data
        if len(expected_data) < 60:
            expected_data = expected_data + [0] * (60 - len(expected_data))

        n += 1
        cocotb.log.info("# %d / %d", n, TEST_NUM_PACKETS)

        # Quick check length
        assert len(expected_data) == len(output_data), (
            f"Check failed\n"  #
            f"Input length: {len(input_data)}\n"  #
            f"Expected length: {len(expected_data)}\n"  #
            f"Output length: {len(output_data)}\n"
        )

        assert expected_data == output_data, (  #
            f"Check failed\n"  #
            f"Input: {input_data}\n"  #
            f"Expected: {expected_data}\n"  #
            f"Output: {output_data}\n"
        )


# MARK: Tests


@cocotb.test
async def test_fh_framer_padding(dut):
    """Test case for eCPRI Framer"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    await reset(dut)

    # Run test multiple times
    cocotb.start_soon(master_monitor(dut))
    cocotb.start_soon(master_driver(dut))
    cocotb.start_soon(slave_monitor(dut))
    cocotb.start_soon(checker())

    await slave_driver(dut)

    await ClockCycles(dut.clk, 1000)
    cocotb.log.info("Simulation finished")


def test_fh_framer_padding_runner():
    """Run the test for FH Framer Buffer"""
    sim = "questa"

    hdl_toplevel = "fh_framer_padding"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "../axis_reg/rtl/axis_reg.v",
        prj_path / "rtl/fh_framer_padding.v",
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
        test_module="test_fh_framer_padding",
        waves=True,
        gui=False,
    )


if __name__ == "__main__":
    test_fh_framer_padding_runner()
