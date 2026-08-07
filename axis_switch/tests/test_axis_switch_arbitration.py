import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent

NUM_SRC = 2
NUM_DEST = 2
DATA_WIDTH = 8
USER_WIDTH = 2
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
GUI = os.environ.get("GUI", "false").lower() == "true"


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
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_axis_switch_serializes_contending_broadcast_packets(dut):
    """A packet owns all its destinations until its final transfer completes."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)

    # Both sources request both destinations together. Source 0 must win the
    # initial conflict and source 1 must not interleave into source 0's packet.
    packets = [
        [(0x10, 0x1, 0), (0x11, 0x2, 1)],
        [(0x20, 0x3, 0), (0x21, 0x0, 1)],
    ]
    word_index = [0, 0]
    received = [[] for _ in range(NUM_DEST)]
    expected = [(data, 1, last, user) for data, user, last in packets[0] + packets[1]]
    stalled_words = [None] * NUM_DEST
    first_ready_cycle = [None] * NUM_SRC

    for cycle in range(80):
        await FallingEdge(dut.clk)

        # Destination 1 stalls over several cycles while a word is pending.
        # The switch must retain both output payloads and prevent the selected
        # source from advancing until the entire broadcast can progress.
        dut.m_axis_tready.value = 0b01 if cycle in (4, 5, 10) else 0b11
        source_data = 0
        source_keep = 0
        source_last = 0
        source_dest = 0
        source_user = 0
        source_valid = 0
        for source in range(NUM_SRC):
            if word_index[source] == len(packets[source]):
                continue
            data, user, last = packets[source][word_index[source]]
            source_data |= data << (source * DATA_WIDTH)
            source_keep |= 1 << (source * (DATA_WIDTH // 8))
            source_last |= last << source
            source_dest |= 0b11 << (source * NUM_DEST)
            source_user |= user << (source * USER_WIDTH)
            source_valid |= 1 << source
        dut.s_axis_tdata.value = source_data
        dut.s_axis_tkeep.value = source_keep
        dut.s_axis_tlast.value = source_last
        dut.s_axis_tdest.value = source_dest
        dut.s_axis_tuser.value = source_user
        dut.s_axis_tvalid.value = source_valid

        await ReadOnly()
        source_ready = [
            get_lane(dut.s_axis_tready, source, 1) for source in range(NUM_SRC)
        ]
        output_snapshot = []
        for destination in range(NUM_DEST):
            valid = get_lane(dut.m_axis_tvalid, destination, 1)
            ready = get_lane(dut.m_axis_tready, destination, 1)
            payload = None
            if valid:
                payload = (
                    get_lane(dut.m_axis_tdata, destination, DATA_WIDTH),
                    get_lane(dut.m_axis_tkeep, destination, DATA_WIDTH // 8),
                    get_lane(dut.m_axis_tlast, destination, 1),
                    get_lane(dut.m_axis_tuser, destination, USER_WIDTH),
                )
            output_snapshot.append((valid, ready, payload))
            if valid and not ready:
                if stalled_words[destination] is None:
                    stalled_words[destination] = payload
                else:
                    assert payload == stalled_words[destination]
            else:
                stalled_words[destination] = None

        await RisingEdge(dut.clk)
        for source, ready in enumerate(source_ready):
            if ready and first_ready_cycle[source] is None:
                first_ready_cycle[source] = cycle
            if ready and word_index[source] != len(packets[source]):
                word_index[source] += 1

        for destination, (valid, ready, payload) in enumerate(output_snapshot):
            if valid and ready:
                received[destination].append(payload)

        if all(index == len(packet) for index, packet in zip(word_index, packets)):
            dut.s_axis_tvalid.value = 0
            dut.m_axis_tready.value = 0b11
            for _ in range(12):
                await FallingEdge(dut.clk)
                await ReadOnly()
                drain = []
                for destination in range(NUM_DEST):
                    valid = get_lane(dut.m_axis_tvalid, destination, 1)
                    payload = None
                    if valid:
                        payload = (
                            get_lane(dut.m_axis_tdata, destination, DATA_WIDTH),
                            get_lane(dut.m_axis_tkeep, destination, DATA_WIDTH // 8),
                            get_lane(dut.m_axis_tlast, destination, 1),
                            get_lane(dut.m_axis_tuser, destination, USER_WIDTH),
                        )
                    drain.append(
                        (
                            valid,
                            get_lane(dut.m_axis_tready, destination, 1),
                            payload,
                        )
                    )
                await RisingEdge(dut.clk)
                for destination, (valid, ready, payload) in enumerate(drain):
                    if valid and ready:
                        received[destination].append(payload)
                if received == [expected, expected]:
                    break
            break
    else:
        raise AssertionError(
            f"contending packets did not complete: word_index={word_index}"
        )

    assert received == [expected, expected]
    assert first_ready_cycle[0] is not None
    assert first_ready_cycle[1] is not None
    assert first_ready_cycle[0] < first_ready_cycle[1]


def test_axis_switch_arbitration_runner():
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
        test_module="test_axis_switch_arbitration",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
