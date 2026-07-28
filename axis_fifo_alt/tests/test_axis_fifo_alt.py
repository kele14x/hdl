import os
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, RisingEdge


# MARK: Env


prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(1234567890)

ASYNC_MODE = int(os.environ.get("ASYNC_MODE", 1))
FIFO_DEPTH = int(os.environ.get("FIFO_DEPTH", 32))
FIFO_LATENCY = int(os.environ.get("FIFO_LATENCY", 3))
DATA_WIDTH = int(os.environ.get("DATA_WIDTH", 64))
USER_WIDTH = int(os.environ.get("USER_WIDTH", 1))

GUI = os.environ.get("GUI", "false").lower() == "true"
SIM = os.environ.get("SIM", "verilator")

TEST_NUM_PACKETS = 100
TEST_PACKET_SIZE_MIN = 1
TEST_PACKET_SIZE_MAX = 30


# MARK: Helper


input_queue = Queue()
output_queue = Queue()


async def reset(dut):
    """Reset the DUT"""
    dut.s_axis_aresetn.value = 0

    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tuser.value = 0
    dut.s_axis_tvalid.value = 0

    dut.m_axis_tready.value = 0

    await ClockCycles(dut.s_axis_aclk, 10)
    dut.s_axis_aresetn.value = 1
    await ClockCycles(dut.s_axis_aclk, 10)


async def slave_driver(dut):
    """Drive the slave side of DUT"""
    await RisingEdge(dut.s_axis_aclk)
    for _ in range(TEST_NUM_PACKETS):
        packet_size = rng.integers(TEST_PACKET_SIZE_MIN, TEST_PACKET_SIZE_MAX + 1)
        packet_bytes = rng.bytes(packet_size)

        # Pre-packet gap
        gap = rng.choice([0, 1, 2, 3], p=[0.7, 0.1, 0.1, 0.1])
        await ClockCycles(dut.s_axis_aclk, gap)

        # Send the packet
        num_bytes = DATA_WIDTH // 8
        num_words = (len(packet_bytes) + num_bytes - 1) // num_bytes
        for i in range(num_words):
            # Send the word
            tdata = 0
            tkeep = 0
            tuser = int(rng.integers(0, 2**USER_WIDTH))
            for j in range(num_bytes):
                if i * num_bytes + j < len(packet_bytes):
                    tdata += int(packet_bytes[i * num_bytes + j] << (8 * j))
                    tkeep += 1 << j
            dut.s_axis_tdata.value = tdata
            dut.s_axis_tkeep.value = tkeep
            dut.s_axis_tlast.value = 1 if i == num_words - 1 else 0
            dut.s_axis_tuser.value = tuser
            dut.s_axis_tvalid.value = 1
            await RisingEdge(dut.s_axis_aclk)
            dut.s_axis_tvalid.value = 0

            # Send pause
            pause = rng.choice([0, 1, 2], p=[0.8, 0.1, 0.1])
            await ClockCycles(dut.s_axis_aclk, pause)


async def master_driver(dut):
    """Drive the master side of DUT"""
    while True:
        await RisingEdge(dut.m_axis_aclk)
        dut.m_axis_tready.value = int(rng.choice([0, 1], p=[0.2, 0.8]))


async def slave_monitor(dut):
    """Monitor the slave side of DUT"""
    p = np.zeros(0, dtype=np.uint8)
    discarded = False
    while True:
        await RisingEdge(dut.s_axis_aclk)
        if dut.s_axis_tvalid.value:
            # Check the discard flag
            if dut.err_discard.value:
                discarded = True
            # Read the data
            num_bytes = DATA_WIDTH // 8
            a = [(int(dut.s_axis_tdata.value) >> (i * 8)) & 0xFF for i in range(num_bytes)]
            keep = dut.s_axis_tkeep.value
            if dut.s_axis_tlast.value:
                assert keep in [2 ** (i + 1) - 1 for i in range(num_bytes)]
                for i in range(num_bytes):
                    if keep == 2 ** (i + 1) - 1:
                        p = np.append(p, a[0 : i + 1])
                if not discarded:
                    input_queue.put_nowait(p)
                p = np.zeros(0, dtype=np.uint8)
            else:
                assert keep == 2**num_bytes - 1
                p = np.append(p, a)


async def master_monitor(dut):
    """Monitor the master side of DUT"""
    p = np.zeros(0, dtype=np.uint8)
    check_continuous_valid = False
    while True:
        await RisingEdge(dut.m_axis_aclk)
        # Check the valid is continuous since it's in packet mode
        if check_continuous_valid:
            assert dut.m_axis_tvalid.value
        if dut.m_axis_tvalid.value:
            check_continuous_valid = True
        # Read the data
        num_bytes = DATA_WIDTH // 8
        if dut.m_axis_tvalid.value and dut.m_axis_tready.value:
            a = [(int(dut.m_axis_tdata.value) >> (i * 8)) & 0xFF for i in range(num_bytes)]
            keep = dut.m_axis_tkeep.value
            if dut.m_axis_tlast.value:
                assert keep in [2 ** (i + 1) - 1 for i in range(num_bytes)]
                for i in range(num_bytes):
                    if keep == 2 ** (i + 1) - 1:
                        p = np.append(p, a[0:i+1])
                output_queue.put_nowait(p)
                p = np.zeros(0, dtype=np.uint8)
                check_continuous_valid = False
            else:
                assert keep == 2**num_bytes - 1
                p = np.append(p, a)


async def checker():
    """Check the output of DUT"""
    n = 0
    while True:
        p1 = await input_queue.get()
        p2 = await output_queue.get()
        n += 1
        cocotb.log.info("# %d / %d", n, TEST_NUM_PACKETS)
        assert np.array_equal(p1, p2)


# MARK: Tests


@cocotb.test
async def test_axis_fifo_alt(dut):
    """Test case for eCPRI Packet FIFO"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.s_axis_aclk, 8).start())
    cocotb.start_soon(Clock(dut.m_axis_aclk, 10).start())

    # Reset the DUT
    await reset(dut)

    # Run test multiple times
    cocotb.start_soon(master_monitor(dut))
    cocotb.start_soon(master_driver(dut))
    cocotb.start_soon(slave_monitor(dut))
    cocotb.start_soon(checker())

    await slave_driver(dut)

    await ClockCycles(dut.s_axis_aclk, 100)
    cocotb.log.info("Simulation finished")


def test_axis_fifo_alt_runner():
    """Run the test for eCPRI Packet FIFO"""
    hdl_toplevel = "axis_fifo_alt"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "axis_fifo_alt.flt")

    parameters = {
        "ASYNC_MODE": ASYNC_MODE,
        "FIFO_DEPTH": FIFO_DEPTH,
        "FIFO_LATENCY": FIFO_LATENCY,
        "DATA_WIDTH": DATA_WIDTH,
        "USER_WIDTH": USER_WIDTH,
    }

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        build_args=["--timing", "-Wno-WIDTHTRUNC", "-Wno-MULTIDRIVEN"],
        waves=True,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_axis_fifo_alt",
        waves=True,
        gui=False,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
