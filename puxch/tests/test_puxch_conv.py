from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from puxch_test_utils import run_cocotb, sample_after_rising

NUM_ANT = 4


def signed_16(value):
    return value - 0x10000 if value & 0x8000 else value


async def reset_dut(dut):
    dut.rst.value = 1
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_sf.value = 0
    dut.din_sl.value = 0
    dut.din_sy.value = 0
    dut.din_chn.value = 0
    dut.din_dv.value = 0
    dut.din_last.value = 0
    dut.ctrl_rat.value = 2
    dut.ctrl_bw.value = 0
    dut.ctrl_nprb.value = 0
    await ClockCycles(dut.clk, 8)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 5)


@cocotb.test()
async def test_conv_zero_frequency_rotation_and_metadata(dut):
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    await reset_dut(dut)

    inputs = [
        (1200, -700, 0, 1, 1, 1),
        (-1300, 600, 1, 0, 0, 1),
        (1400, -500, 2, 0, 0, 1),
        (-1500, 400, 3, 0, 0, 1),
        (1600, -300, 0, 0, 0, 0),
        (-1700, 200, 1, 0, 0, 0),
        (1800, -100, 2, 0, 0, 0),
        (-1900, 50, 3, 0, 0, 0),
    ]
    for real, imag, channel, sf, sl, sy in inputs:
        await sample_after_rising(dut.clk)
        dut.din_dr.value = real & 0xFFFF
        dut.din_di.value = imag & 0xFFFF
        dut.din_chn.value = channel
        dut.din_sf.value = sf
        dut.din_sl.value = sl
        dut.din_sy.value = sy
        dut.din_dv.value = 1

    await sample_after_rising(dut.clk)
    dut.din_dv.value = 0
    dut.din_sf.value = 0
    dut.din_sl.value = 0
    dut.din_sy.value = 0

    outputs = []
    for _ in range(48):
        await sample_after_rising(dut.clk)
        if int(dut.dout_dv.value):
            outputs.append(
                (
                    signed_16(int(dut.dout_dr.value)),
                    signed_16(int(dut.dout_di.value)),
                    int(dut.dout_chn.value),
                    int(dut.dout_sf.value),
                    int(dut.dout_sl.value),
                    int(dut.dout_sy.value),
                    int(dut.dout_last.value),
                )
            )
        if len(outputs) == len(inputs):
            break

    assert len(outputs) == len(inputs)
    for expected, actual in zip(inputs, outputs, strict=True):
        real, imag, channel, sf, sl, sy = expected
        out_real, out_imag, out_channel, out_sf, out_sl, out_sy, out_last = actual
        assert abs(out_real - real) <= 1
        assert abs(out_imag - imag) <= 1
        assert (out_channel, out_sf, out_sl, out_sy, out_last) == (
            channel,
            sf,
            sl,
            sy,
            0,
        )


def test_puxch_conv_runner():
    run_cocotb(
        "puxch_conv",
        Path(__file__).stem,
        parameters={"NUM_ANT": NUM_ANT},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
