import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge
from cocotb_tools.runner import get_runner
from hdl_tools.flt_tool import resolve_flt


prj_path = Path(__file__).resolve().parent.parent
USER_WIDTH = 17
SIM = os.environ.get("SIM", "verilator")


def make_packet(num_prb, seed):
    """Build a BFP9 packet directly from its wire-level bit format."""
    stream_bits = ""
    expected = []

    for prb in range(num_prb):
        exponent = (seed + prb + 3) & 0xF
        stream_bits += "0000" + f"{exponent:04b}"
        for word in range(6):
            values = [
                (seed + 37 * prb + 11 * word + lane) & 0x1FF
                for lane in range(4)
            ]
            iq_word = int("".join(f"{value:09b}" for value in values), 2)
            stream_bits += f"{iq_word:036b}"
            expected.append((iq_word, exponent, prb == num_prb - 1 and word == 5))

    assert len(stream_bits) % 8 == 0
    stream_bytes = [int(stream_bits[i : i + 8], 2) for i in range(0, len(stream_bits), 8)]

    words = []
    for offset in range(0, len(stream_bytes), 8):
        chunk = stream_bytes[offset : offset + 8]
        tdata = sum(byte << (8 * index) for index, byte in enumerate(chunk))
        tkeep = (1 << len(chunk)) - 1
        words.append((tdata, tkeep, offset + len(chunk) == len(stream_bytes)))

    return words, expected


async def reset(dut):
    dut.rst.value = 1
    dut.s_axis_tdata.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tuser.value = 0
    dut.s_axis_tvalid.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 2)


@cocotb.test()
async def test_bfp_gearbox(dut):
    cocotb.start_soon(Clock(dut.clk, period=10, units="ns").start())
    await reset(dut)

    packets = [
        make_packet(1, 0x12),
        make_packet(2, 0x2A),
        make_packet(3, 0x51),
    ]
    input_words = []
    expected = []
    for packet_index, (words, outputs) in enumerate(packets):
        user = 0x1200 + packet_index * 0x31
        for word_index, (tdata, tkeep, tlast) in enumerate(words):
            # Only the first accepted beat is meaningful by contract.  Make
            # the later values deliberately different to check that the RTL
            # latches TUSER at the first handshake.
            beat_user = user if word_index == 0 else 0x7FFF - word_index
            input_words.append((tdata, tkeep, tlast, beat_user))
        expected.extend((iq, exp, last, user) for iq, exp, last in outputs)

    received = []
    word_index = 0
    saw_input_backpressure = False

    def drive_word(index):
        tdata, tkeep, tlast, tuser = input_words[index]
        dut.s_axis_tdata.value = tdata
        dut.s_axis_tkeep.value = tkeep
        dut.s_axis_tlast.value = int(tlast)
        dut.s_axis_tuser.value = tuser
        dut.s_axis_tvalid.value = 1

    drive_word(0)

    for cycle in range(3000):
        await ReadOnly()

        input_fire = bool(dut.s_axis_tvalid.value and dut.s_axis_tready.value)
        output_valid = bool(dut.m_axis_tvalid.value)
        saw_input_backpressure |= bool(dut.s_axis_tvalid.value and not dut.s_axis_tready.value)

        if output_valid:
            received.append(
                (
                    int(dut.m_axis_tdata.value),
                    int(dut.m_axis_exp.value),
                    int(dut.m_axis_tlast.value),
                    int(dut.m_axis_tuser.value),
                )
            )

        await RisingEdge(dut.clk)

        if input_fire:
            word_index += 1
            if word_index == len(input_words):
                dut.s_axis_tvalid.value = 0
                dut.s_axis_tlast.value = 0
            else:
                drive_word(word_index)

        if word_index == len(input_words) and len(received) == len(expected):
            break
    else:
        raise AssertionError("gearbox did not finish within the cycle limit")

    assert len(received) == len(expected)
    assert saw_input_backpressure
    for index, (actual, reference) in enumerate(zip(received, expected)):
        assert actual == reference, (
            f"output mismatch at index {index}: actual={actual}, reference={reference}"
        )


def test_bfp_gearbox_runner():
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="bfp_gearbox",
        sources=resolve_flt(prj_path / "bfp_gearbox.flt"),
        parameters={"USER_WIDTH": USER_WIDTH},
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="bfp_gearbox",
        hdl_toplevel_lang="verilog",
        test_module="test_bfp_gearbox",
        waves=True,
        gui=False,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
