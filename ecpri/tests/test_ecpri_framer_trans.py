import os
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge

# MARK: Env

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(1234567890)

# SOME_PARAMETER = int(os.environ.get("SOME_PARAMETER", 0))

GUI = os.environ.get("GUI", "false").lower() == "true"

SIM = os.environ.get("SIM", "verilator")

TEST_HAS_VLAN = int(os.environ.get("TEST_HAS_VLAN", 1))
TEST_NUM_PACKETS = int(os.environ.get("TEST_NUM_PACKETS", 100))
TEST_PACKET_SIZE_MIN = int(os.environ.get("TEST_PACKET_SIZE_MIN", 1))
TEST_PACKET_SIZE_MAX = int(os.environ.get("TEST_PACKET_SIZE_MAX", 100))

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

    dut.s_trans_messagetype.value = 0
    dut.s_trans_payloadsize.value = 0
    dut.s_trans_rtc_pc_id.value = 0

    dut.m_axis_tready.value = 0

    dut.ctrl_dest_mac.value = 0x001122334455
    dut.ctrl_src_mac.value = 0x001122334466
    dut.ctrl_has_vlan.value = TEST_HAS_VLAN
    dut.ctrl_vlan_tag.value = 0x7001

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def slave_driver(dut):
    """Drive the slave side of DUT"""
    for _ in range(TEST_NUM_PACKETS):
        packet_size = rng.integers(TEST_PACKET_SIZE_MIN, TEST_PACKET_SIZE_MAX + 1)
        packet_bytes = rng.bytes(packet_size)

        # Pre-packet gap
        gap = rng.choice([0, 1, 2, 3], p=[0.7, 0.1, 0.1, 0.1])
        dut.s_axis_tvalid.value = 0
        await ClockCycles(dut.clk, gap)

        # Send the packet
        dut.s_trans_payloadsize.value = int(packet_size)
        dut.s_trans_rtc_pc_id.value = int(rng.integers(0, 1 << 16))
        for i in range((len(packet_bytes) + 3) // 4):
            # Send the word
            tdata = 0
            tkeep = 0
            for j in range(4):
                if i * 4 + j < len(packet_bytes):
                    tdata += int(packet_bytes[i * 4 + j] << (8 * j))
                    tkeep += 1 << j
            dut.s_axis_tdata.value = tdata
            dut.s_axis_tkeep.value = tkeep
            dut.s_axis_tvalid.value = 1
            dut.s_axis_tlast.value = 1 if i == (len(packet_bytes) + 3) // 4 - 1 else 0
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
    p = np.zeros(0, dtype=np.uint8)
    while True:
        await RisingEdge(dut.clk)
        await ReadOnly()
        if dut.s_axis_tvalid.value and dut.s_axis_tready.value:
            a = [(int(dut.s_axis_tdata.value) >> (i * 8)) & 0xFF for i in range(4)]
            keep = dut.s_axis_tkeep.value
            if dut.s_axis_tlast.value:
                if keep == 1:
                    p = np.append(p, a[0:1])
                elif keep == 3:
                    p = np.append(p, a[0:2])
                elif keep == 7:
                    p = np.append(p, a[0:3])
                elif keep == 15:
                    p = np.append(p, a)
                else:
                    assert False, f"TKEEP value is invalid at TLAST: {keep}"
                input_queue.put_nowait(p)
                p = np.zeros(0, dtype=np.uint8)
            else:
                assert keep == 15, f"TKEEP value is invalid at none TLAST: {keep}"
                p = np.append(p, a)


async def master_monitor(dut):
    """Monitor the master side of DUT"""
    p = np.zeros(0, dtype=np.uint8)
    while True:
        await RisingEdge(dut.clk)
        await ReadOnly()
        if dut.m_axis_tvalid.value and dut.m_axis_tready.value:
            a = [(int(dut.m_axis_tdata.value) >> (i * 8)) & 0xFF for i in range(4)]
            keep = dut.m_axis_tkeep.value
            if dut.m_axis_tlast.value:
                if keep == 1:
                    p = np.append(p, a[0:1])
                elif keep == 3:
                    p = np.append(p, a[0:2])
                elif keep == 7:
                    p = np.append(p, a[0:3])
                elif keep == 15:
                    p = np.append(p, a)
                else:
                    assert False, f"TKEEP value is invalid at TLAST: {keep}"
                output_queue.put_nowait(p)
                p = np.zeros(0, dtype=np.uint8)
            else:
                assert keep == 15, f"TKEEP value is invalid at none TLAST: {keep}"
                p = np.append(p, a)


async def checker():
    """Check the output of DUT"""
    n = 0
    while True:
        p1 = await input_queue.get()
        p2 = await output_queue.get()
        n += 1
        cocotb.log.info("# %d / %d", n, TEST_NUM_PACKETS)
        header_len = 22 + TEST_HAS_VLAN * 4
        assert len(p1) + header_len == len(p2), "Length check failed"
        assert np.all(p1 == p2[header_len:]), "Data check failed"


# MARK: Tests


@cocotb.test
async def test_ecpri_framer_trans(dut):
    """Test case for eCPRI Framer Trans"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # Reset the DUT
    await reset(dut)

    # Run test multiple times
    cocotb.start_soon(master_monitor(dut))
    cocotb.start_soon(master_driver(dut))
    cocotb.start_soon(slave_monitor(dut))
    cocotb.start_soon(checker())

    await slave_driver(dut)

    await ClockCycles(dut.clk, 100)
    cocotb.log.info("Simulation finished")


def test_ecpri_framer_trans_runner():
    """Run the test for eCPRI Framer Trans"""
    hdl_toplevel = "ecpri_framer_trans"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "ecpri.flt")

    parameters = {}

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        parameters=parameters,
        waves=True,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_ecpri_framer_trans",
        waves=True,
        gui=False,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
