import os
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb_tools.runner import get_runner
from hdl_tools.flt_tool import resolve_flt
from cocotb.triggers import ClockCycles, RisingEdge


# MARK: Env


prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng()

# BIT_REVERSED_INPUT = int(os.environ.get("BIT_REVERSED_INPUT", 1))

GUI = os.environ.get("GUI", "false").lower() == "true"

SIM = os.environ.get("SIM", "verilator")


# MARK: Helper


input_queue = Queue()
output_queue = Queue()


async def reset(dut):
    """Reset the DUT"""
    dut.rst.value = 1
    # I/Q message
    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    #
    dut.s_trans_payloadsize.value = 0
    dut.s_trans_rtc_pc_id.value = 0
    # ODM message
    dut.s_axis_odm_tvalid.value = 0
    #
    dut.s_odm_measurementid.value = 0
    dut.s_odm_actiontype.value = 0
    dut.s_odm_timestamp.value = 0
    dut.s_odm_compensation.value = 0
    # PTP message
    dut.s_ptp_tdata.value = 0
    dut.s_ptp_tkeep.value = 0
    dut.s_ptp_tlast.value = 0
    dut.s_ptp_tuser.value = 0
    dut.s_ptp_tvalid.value = 0
    # Message
    dut.s_message_tdata.value = 0
    dut.s_message_tkeep.value = 0
    dut.s_message_tlast.value = 0
    dut.s_message_tvalid.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


# class AxisDriver:
#     """AXI-Stream Driver"""

#     def __init__(self, aclk, /, tdata=None, tkeep=None, tlast=None, tuser=None, tvalid=None, tready=None):
#         self.aclk = aclk
#         self.tdata = tdata
#         self.tkeep = tkeep
#         self.tlast = tlast
#         self.tvalid = tvalid
#         self.tready = tready
#         self.tuser = tuser

#         if self.tdata is not None:
#             self.num_bytes = (self.tdata.range.left - self.tdata.range.right + 1) // 8
#         else:
#             self.num_bytes = 0

#     async def reset(self):
#         """Reset the interface"""
#         if self.tdata is not None:
#             self.tdata.value = 0
#         if self.tkeep is not None:
#             self.tkeep.value = 0
#         if self.tlast is not None:
#             self.tlast.value = 0
#         if self.tuser is not None:
#             self.tuser.value = 0
#         self.tvalid.value = 0

#     async def send(self, packet, user=None, gap=0):
#         """Send a stream of bytes"""
#         packet_bytes = bytes(packet)
#         num_words = (len(packet_bytes) + self.num_bytes - 1) // self.num_bytes

#         # Send inter frame gap
#         for _ in range(gap):
#             self.tvalid.value = 0
#             await RisingEdge(self.aclk)
#         # Send the packet
#         for i in range(num_words):
#             tdata = 0
#             tkeep = 0
#             for j in range(self.num_bytes):
#                 if i * self.num_bytes + j < len(packet_bytes):
#                     tdata += packet_bytes[i * self.num_bytes + j] << (8 * j)
#                     tkeep += 1 << j
#             if self.tdata is not None:
#                 self.tdata.value = tdata
#             if self.tkeep is not None:
#                 self.tkeep.value = tkeep
#             if self.tlast is not None:
#                 self.tlast.value = 1 if i == num_words - 1 else 0
#             if self.tuser is not None:
#                 self.tuser.value = user
#             self.tvalid.value = 1
#             await RisingEdge(self.aclk)
#             if self.tready is not None:
#                 while True:
#                     if self.tready.value == 1:
#                         break
#                 await RisingEdge(self.aclk)
#             self.tvalid.value = 0


async def message_driver(dut):
    """Drive the message slave interface of DUT"""
    for _ in range(10):
        packet_bytes = rng.bytes(100)
        # Send the packet
        for i in range((len(packet_bytes) + 3) // 4):
            tdata = 0
            tkeep = 0
            for j in range(4):
                if i * 4 + j < len(packet_bytes):
                    tdata += packet_bytes[i * 4 + j] << (8 * j)
                    tkeep += 1 << j
            dut.s_message_tdata.value = tdata
            dut.s_message_tkeep.value = tkeep
            dut.s_message_tlast.value = 1 if i == (len(packet_bytes) + 3) // 4 - 1 else 0
            dut.s_message_tvalid.value = 1
            await RisingEdge(dut.clk)
            # Wait for the ready signal
            while True:
                if dut.s_message_tready.value:
                    break
                await RisingEdge(dut.clk)
            dut.s_message_tvalid.value = 0
        # Done


async def master_driver(dut):
    """Drive the master interface of DUT"""
    dut.m_axis_tready.value = 1


# MARK: Tests


@cocotb.test
async def test_ecpri_framer(dut):
    """Test case for eCPRI"""
    cocotb.log.info("Simulation started")
    # Create clock and start it
    cocotb.start_soon(Clock(dut.clk, 10).start())

    # Reset the DUT
    await reset(dut)

    # Run test multiple times
    cocotb.start_soon(master_driver(dut))
    cocotb.start_soon(message_driver(dut))

    await ClockCycles(dut.clk, 1000)
    cocotb.log.info("Simulation finished")


# MARK: Runner


def test_ecpri_framer_runner():
    """Run the eCPRI test"""
    hdl_toplevel = "ecpri_framer"
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
        test_module="test_ecpri_framer",
        waves=True,
        gui=False,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
