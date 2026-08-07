import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

NUM_SRC = 1
NUM_DEST = 2
DATA_WIDTH = 8
USER_WIDTH = 2
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"


def set_lane(signal, lane, width, value):
    mask = ((1 << width) - 1) << (lane * width)
    signal.value = (int(signal.value) & ~mask) | ((value << (lane * width)) & mask)


def get_lane(signal, lane, width):
    return (int(signal.value) >> (lane * width)) & ((1 << width) - 1)


async def reset(dut):
    dut.rst.value = 1
    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tdest.value = 0
    dut.s_axis_tuser.value = 0
    dut.s_axis_tvalid.value = 0
    dut.m_axis_tready.value = 0
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 2)


@cocotb.test()
async def test_axis_switch_broadcasts_packets_under_backpressure(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)

    # Each source has a sequence of packets: (destination bitmask, words).
    packets = [
        [
            (0b11, [(0x11, 0), (0x12, 1)]),
            (0b11, [(0x31, 2), (0x32, 3)]),
        ],
    ]
    packet_index = [0] * NUM_SRC
    word_index = [0] * NUM_SRC
    expected = [[] for _ in range(NUM_DEST)]
    received = [[] for _ in range(NUM_DEST)]

    async def drive_sources():
        for cycle in range(300):
            await Timer(1, unit="ps")
            # Create a periodic independent backpressure pattern for both outputs.
            dut.m_axis_tready.value = 0b11 if cycle % 4 else 0b01

            active = []
            for source in range(NUM_SRC):
                if packet_index[source] == len(packets[source]):
                    set_lane(dut.s_axis_tvalid, source, 1, 0)
                    active.append(None)
                    continue

                destination, words = packets[source][packet_index[source]]
                data, user = words[word_index[source]]
                last = int(word_index[source] == len(words) - 1)
                set_lane(dut.s_axis_tdata, source, DATA_WIDTH, data)
                set_lane(dut.s_axis_tkeep, source, DATA_WIDTH // 8, 1)
                set_lane(dut.s_axis_tlast, source, 1, last)
                set_lane(dut.s_axis_tdest, source, NUM_DEST, destination)
                set_lane(dut.s_axis_tuser, source, USER_WIDTH, user)
                set_lane(dut.s_axis_tvalid, source, 1, 1)
                active.append((destination, data, user, last))

            await Timer(1, unit="ps")
            source_ready = [
                get_lane(dut.s_axis_tready, source, 1) for source in range(NUM_SRC)
            ]
            output_before_edge = []
            for destination in range(NUM_DEST):
                valid = get_lane(dut.m_axis_tvalid, destination, 1)
                ready = get_lane(dut.m_axis_tready, destination, 1)
                if valid and ready:
                    output_before_edge.append(
                        (
                            valid,
                            ready,
                            get_lane(dut.m_axis_tdata, destination, DATA_WIDTH),
                            get_lane(dut.m_axis_tkeep, destination, DATA_WIDTH // 8),
                            get_lane(dut.m_axis_tlast, destination, 1),
                            get_lane(dut.m_axis_tuser, destination, USER_WIDTH),
                        )
                    )
                else:
                    output_before_edge.append((valid, ready, 0, 0, 0, 0))

            await RisingEdge(dut.clk)

            for destination, output in enumerate(output_before_edge):
                valid, ready, data, keep, last, user = output
                if valid and ready:
                    received[destination].append((data, keep, last, user))

            for source, transaction in enumerate(active):
                if transaction is None or not source_ready[source]:
                    continue
                destination, data, user, last = transaction
                for output in range(NUM_DEST):
                    if (destination >> output) & 1:
                        expected[output].append((data, 1, last, user))
                if last:
                    packet_index[source] += 1
                    word_index[source] = 0
                else:
                    word_index[source] += 1

            if all(
                packet_index[source] == len(packets[source])
                for source in range(NUM_SRC)
            ):
                return
            await Timer(4, unit="ns")
        raise AssertionError("source packets did not complete")

    sender = cocotb.start_soon(drive_sources())
    await sender

    # Drain the registered output paths after the final input transfer.
    dut.s_axis_tvalid.value = 0
    dut.m_axis_tready.value = 0b11
    for _ in range(20):
        await Timer(1, unit="ps")
        output_before_edge = []
        for destination in range(NUM_DEST):
            valid = get_lane(dut.m_axis_tvalid, destination, 1)
            if valid:
                output_before_edge.append(
                    (
                        valid,
                        get_lane(dut.m_axis_tdata, destination, DATA_WIDTH),
                        get_lane(dut.m_axis_tkeep, destination, DATA_WIDTH // 8),
                        get_lane(dut.m_axis_tlast, destination, 1),
                        get_lane(dut.m_axis_tuser, destination, USER_WIDTH),
                    )
                )
            else:
                output_before_edge.append((valid, 0, 0, 0, 0))
        await RisingEdge(dut.clk)
        for destination, output in enumerate(output_before_edge):
            valid, data, keep, last, user = output
            if valid:
                received[destination].append((data, keep, last, user))
        if received == expected:
            break

    assert received == expected
    assert [word[0] for word in received[0]] == [0x11, 0x12, 0x31, 0x32]
    assert received[1] == received[0]


def test_axis_switch_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="axis_switch",
        verilog_sources=resolve_flt(prj_path / "axis_switch.flt"),
        parameters={
            "NUM_SRC": NUM_SRC,
            "NUM_DEST": NUM_DEST,
            "DATA_WIDTH": DATA_WIDTH,
            "USER_WIDTH": USER_WIDTH,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="axis_switch",
        hdl_toplevel_lang="verilog",
        test_module="test_axis_switch",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
