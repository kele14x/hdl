import os
import struct
import tempfile
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"


def write_pcap(path, packets):
    content = struct.pack("<IHHIIII", 0xA1B2C3D4, 2, 4, 0, 0, 65535, 1)
    for timestamp_us, packet in packets:
        content += struct.pack("<IIII", 0, timestamp_us, len(packet), len(packet))
        content += packet
    path.write_bytes(content)


def stream_word(packet, index):
    word = packet[index * 8 : (index + 1) * 8]
    return (
        int.from_bytes(word.ljust(8, b"\x00"), "little"),
        (1 << len(word)) - 1,
        int((index + 1) * 8 >= len(packet)),
    )


async def monitor_stream(dut, received):
    while True:
        await RisingEdge(dut.aclk)
        if int(dut.m_eth_tvalid.value) and int(dut.m_eth_tready.value):
            received.put_nowait(
                (
                    int(dut.m_eth_tdata.value),
                    int(dut.m_eth_tkeep.value),
                    int(dut.m_eth_tlast.value),
                )
            )


@cocotb.test()
async def test_eth_injector_replays_pcap_with_backpressure(dut):
    cocotb.start_soon(Clock(dut.aclk, 8, unit="ns").start(start_high=False))
    dut.aresetn.value = 0
    dut.m_eth_tready.value = 0
    await ClockCycles(dut.aclk, 2)
    assert int(dut.m_eth_tvalid.value) == 0

    received = Queue()
    cocotb.start_soon(monitor_stream(dut, received))
    dut.aresetn.value = 1
    await ClockCycles(dut.aclk, 2)
    assert int(dut.m_eth_tvalid.value) == 1
    held = (
        int(dut.m_eth_tdata.value),
        int(dut.m_eth_tkeep.value),
        int(dut.m_eth_tlast.value),
    )
    await ClockCycles(dut.aclk, 3)
    assert (
        int(dut.m_eth_tdata.value),
        int(dut.m_eth_tkeep.value),
        int(dut.m_eth_tlast.value),
    ) == held

    dut.m_eth_tready.value = 1
    first_packet = bytes(range(1, 11))
    second_packet = bytes(range(0xA0, 0xA8))
    expected = [
        # send_buffer advances after the accepting edge. Its first registered
        # beat is therefore observable on the release edge and the following
        # edge before the next beat is registered.
        stream_word(first_packet, 0),
        stream_word(first_packet, 0),
        stream_word(first_packet, 1),
        stream_word(second_packet, 0),
    ]
    for word in expected:
        assert await with_timeout(received.get(), 1, "us") == word
    await ClockCycles(dut.aclk, 2)
    assert int(dut.m_eth_tvalid.value) == 0


def test_eth_injector_runner():
    with tempfile.TemporaryDirectory(prefix="eth_injector_pcap_") as temporary_dir:
        pcap_file = Path(temporary_dir) / "packets.pcap"
        write_pcap(
            pcap_file,
            [(0, bytes(range(1, 11))), (1, bytes(range(0xA0, 0xA8)))],
        )
        runner = get_runner(SIM)
        runner.build(
            hdl_toplevel="eth_injector_tb",
            sources=[
                *resolve_flt(prj_path / "eth_injector.flt"),
                prj_path / "tests" / "eth_injector_tb.sv",
            ],
            parameters={"PCAP_FILE": f'"{pcap_file.as_posix()}"'},
            always=True,
            build_args=["--timing", "-Wno-ZERODLY", "-Wno-MULTIDRIVEN"],
            waves=True,
        )
        runner.test(
            hdl_toplevel="eth_injector_tb",
            hdl_toplevel_lang="verilog",
            test_module="test_eth_injector",
            gui=GUI,
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
