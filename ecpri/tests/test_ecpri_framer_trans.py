import os
import random
import tempfile
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
from cocotb_tools.runner import get_runner

from common.tb.axis import AxisAgent, AxisAgentConfig, AxisRole
from common.tb.packets import (
    AxisCodecAgent,
    EcpriCodec,
    EcpriIqcMessage,
    EcpriIqMessage,
    RawBytesCodec,
)
from hdl_tools.flt_tool import resolve_flt

PRJ_PATH = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"
TEST_HAS_VLAN = int(os.environ.get("TEST_HAS_VLAN", "1"))
TEST_NUM_PACKETS = int(os.environ.get("TEST_NUM_PACKETS", "100"))
TEST_PACKET_SIZE_MIN = int(os.environ.get("TEST_PACKET_SIZE_MIN", "1"))
TEST_PACKET_SIZE_MAX = int(os.environ.get("TEST_PACKET_SIZE_MAX", "100"))


async def reset(dut):
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


@cocotb.test()
async def test_ecpri_framer_trans(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)

    rng = random.Random(0xEC_2026)
    source = AxisCodecAgent(
        AxisAgent(
            dut,
            AxisAgentConfig(
                prefix="s_axis",
                clock="clk",
                reset="rst",
                reset_active_level=1,
                role=AxisRole.SOURCE,
            ),
        ),
        RawBytesCodec(),
    )
    sink = AxisCodecAgent(
        AxisAgent(
            dut,
            AxisAgentConfig(
                prefix="m_axis",
                clock="clk",
                reset="rst",
                reset_active_level=1,
                role=AxisRole.SINK,
            ),
            ready_policy=lambda _cycle: rng.random() >= 0.1,
        ),
        EcpriCodec(),
    )
    await source.start()
    await sink.start()

    sequence_ids = [0] * 16
    for _ in range(TEST_NUM_PACKETS):
        payload = rng.randbytes(rng.randint(TEST_PACKET_SIZE_MIN, TEST_PACKET_SIZE_MAX))
        identifier = rng.randrange(1 << 16)
        message_type = rng.choice((0, 1))
        await FallingEdge(dut.clk)
        dut.s_trans_messagetype.value = message_type
        dut.s_trans_payloadsize.value = len(payload)
        dut.s_trans_rtc_pc_id.value = identifier

        await ClockCycles(dut.clk, rng.randrange(4))
        await source.send(payload, gap=lambda _index: rng.randrange(3))
        packet = await sink.receive()

        assert packet.ethernet_hdr.dest_mac == 0x001122334455
        assert packet.ethernet_hdr.src_mac == 0x001122334466
        assert packet.ethernet_hdr.ethertype == 0xAEFE
        assert packet.ethernet_hdr.with_vlan == bool(TEST_HAS_VLAN)
        if TEST_HAS_VLAN:
            assert packet.ethernet_hdr.vlan_tag == 0x7001

        assert len(packet.messages) == 1
        message = packet.messages[0]
        assert message.common_hdr.version == 1
        assert message.common_hdr.message_type == message_type
        assert message.common_hdr.payload_size == len(payload) + 4
        assert message.payload == payload
        if message_type == 0:
            assert isinstance(message, EcpriIqMessage)
            assert message.pc_id == identifier
        else:
            assert isinstance(message, EcpriIqcMessage)
            assert message.rtc_id == identifier
        channel = identifier & 0xF
        assert message.seq_id == sequence_ids[channel]
        assert message.e_bit == 0
        assert message.subseq_id == 0
        # The current RTL advances its per-channel sequence counter on every
        # accepted 32-bit payload beat.
        payload_beats = (len(payload) + 3) // 4
        sequence_ids[channel] = (sequence_ids[channel] + payload_beats) & 0xFF


def test_ecpri_framer_trans_runner():
    runner = get_runner(SIM)
    with tempfile.TemporaryDirectory(prefix="ecpri_framer_trans_") as run_dir:
        runner.build(
            hdl_toplevel="ecpri_framer_trans",
            sources=resolve_flt(PRJ_PATH / "ecpri.flt"),
            always=True,
            waves=True,
            build_dir=run_dir,
        )
        runner.test(
            hdl_toplevel="ecpri_framer_trans",
            hdl_toplevel_lang="verilog",
            test_module="test_ecpri_framer_trans",
            waves=True,
            gui=GUI,
            test_dir=run_dir,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
