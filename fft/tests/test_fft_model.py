import os
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ReadOnly, ReadWrite, RisingEdge
from cocotb_tools.runner import get_runner

from fft.tests.fft_fixed_model import FftConfig, bit_reverse_indices, fft_fixed
from tools.flt_tool import resolve_flt

PRJ_PATH = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM", "verilator")
NUM_ANT = 4


@pytest.mark.parametrize(
    ("fft_size", "scale_factor"), [(1024, 32), (2048, 32), (4096, 64)]
)
def test_current_width_and_scale_contract(fft_size, scale_factor):
    config = FftConfig(fft_size=fft_size)
    assert config.internal_width == 18
    assert config.scale_factor == scale_factor


@pytest.mark.parametrize(
    ("inverse", "bit_reversed_input"),
    [(False, True), (False, False), (True, True)],
    ids=["forward-dit", "forward-dif", "inverse-dit"],
)
@pytest.mark.parametrize("fft_size", [1024, 2048, 4096])
def test_model_tracks_numpy_for_low_level_input(fft_size, inverse, bit_reversed_input):
    rng = np.random.default_rng(0xF17 + fft_size)
    natural_r = rng.integers(-128, 129, size=fft_size, dtype=np.int64)
    natural_i = rng.integers(-128, 129, size=fft_size, dtype=np.int64)
    reverse_order = bit_reverse_indices(fft_size)
    input_order = reverse_order if bit_reversed_input else np.arange(fft_size)
    config = FftConfig(
        fft_size=fft_size,
        inverse=inverse,
        bit_reversed_input=bit_reversed_input,
    )

    output_r, output_i, stats = fft_fixed(
        natural_r[input_order], natural_i[input_order], config
    )
    if inverse:
        reference = np.fft.ifft(natural_r + 1j * natural_i) * fft_size
    else:
        reference = np.fft.fft(natural_r + 1j * natural_i)
    reference = reference / config.scale_factor
    if not bit_reversed_input:
        reference = reference[reverse_order]
    error = output_r + 1j * output_i - reference

    assert np.sqrt(np.mean(np.abs(error) ** 2)) < 4.0
    assert stats.butterfly_wraps == 0
    assert stats.twiddle_wraps == 0
    assert stats.coarse_twiddle_wraps == 0
    assert stats.output_saturations == 0


async def _sample_output(dut, outputs, last_events):
    await RisingEdge(dut.clk)
    await ReadOnly()
    valid = dut.dout_dv.value.is_resolvable and int(dut.dout_dv.value)
    if valid:
        channel = int(dut.dout_chn.value)
        outputs[channel].append(
            (dut.dout_dr.value.to_signed(), dut.dout_di.value.to_signed())
        )
    if dut.dout_last.value.is_resolvable and int(dut.dout_last.value):
        last_events.append(
            (
                bool(valid),
                tuple(len(channel) for channel in outputs),
                int(dut.dout_chn.value),
            )
        )


async def _drive_input_stream(dut, inputs, fft_size):
    for sample in range(fft_size):
        for antenna in range(NUM_ANT):
            await RisingEdge(dut.clk)
            await ReadWrite()
            dut.din_dr.value = int(inputs[antenna][0][sample])
            dut.din_di.value = int(inputs[antenna][1][sample])
            dut.din_chn.value = antenna
            dut.din_dv.value = 1
            dut.din_last.value = sample == fft_size - 1 and antenna == NUM_ANT - 1

    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.din_dv.value = 0
    dut.din_last.value = 0
    dut.din_dr.value = 0
    dut.din_di.value = 0


@cocotb.test()
async def test_fft_rtl_matches_fixed_model(dut):
    fft_size = int(os.environ.get("FFT_RUNTIME_SIZE", "4096"))
    inverse = bool(int(os.environ.get("FFT_INVERSE", "0")))
    bit_reversed_input = bool(int(os.environ.get("FFT_BIT_REVERSED_INPUT", "1")))
    vector_mode = os.environ.get("FFT_VECTOR_MODE", "low-level")
    ctrl_size = {1024: 0b00, 2048: 0b01, 4096: 0b10}[fft_size]
    config = FftConfig(
        fft_size=fft_size,
        inverse=inverse,
        bit_reversed_input=bit_reversed_input,
    )
    order = bit_reverse_indices(fft_size) if bit_reversed_input else np.arange(fft_size)
    rng = np.random.default_rng(0xC0C07B + fft_size)

    inputs = []
    expected = []
    for _ in range(NUM_ANT):
        if vector_mode == "stress":
            natural_r = rng.integers(-(1 << 15), 1 << 15, size=fft_size)
            natural_i = rng.integers(-(1 << 15), 1 << 15, size=fft_size)
        else:
            natural_r = rng.integers(-128, 129, size=fft_size, dtype=np.int64)
            natural_i = rng.integers(-128, 129, size=fft_size, dtype=np.int64)
        stream_r = natural_r[order]
        stream_i = natural_i[order]
        inputs.append((stream_r, stream_i))
        expected_r, expected_i, stats = fft_fixed(stream_r, stream_i, config)
        if vector_mode == "stress":
            # With all six stages scaled, this seeded full-input-range vector
            # remains inside the signed 18-bit internal datapath.
            assert stats.butterfly_wraps == 0
            assert stats.twiddle_wraps == 0
            assert stats.coarse_twiddle_wraps == 0
        else:
            assert stats.butterfly_wraps == 0
            assert stats.twiddle_wraps == 0
            assert stats.coarse_twiddle_wraps == 0
        expected.append(
            list(zip(expected_r.tolist(), expected_i.tolist(), strict=True))
        )

    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    dut.rst.value = 1
    dut.ctrl_size.value = ctrl_size
    dut.ctrl_itlv.value = 0b10
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_sf.value = 0
    dut.din_sl.value = 0
    dut.din_sy.value = 0
    dut.din_chn.value = 0
    dut.din_dv.value = 0
    dut.din_last.value = 0
    outputs = [[] for _ in range(NUM_ANT)]
    last_events = []

    for _ in range(10):
        await _sample_output(dut, outputs, last_events)
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.rst.value = 0

    # Drive and sample in parallel.  Each input is written after one rising
    # edge and is therefore sampled by the DUT on the next rising edge; the
    # sampler observes the DUT after that same edge without halving throughput.
    cocotb.start_soon(_drive_input_stream(dut, inputs, fft_size))

    for _ in range(2 * fft_size * NUM_ANT + 2048):
        await _sample_output(dut, outputs, last_events)
        if all(len(channel) >= fft_size for channel in outputs):
            break

    assert [len(channel) for channel in outputs] == [fft_size] * NUM_ANT
    assert last_events == [(True, (fft_size,) * NUM_ANT, NUM_ANT - 1)]
    for antenna in range(NUM_ANT):
        assert outputs[antenna] == expected[antenna]


@pytest.mark.parametrize(
    ("fft_size", "inverse", "bit_reversed_input", "vector_mode"),
    [
        (1024, 0, 1, "low-level"),
        (2048, 0, 1, "low-level"),
        (4096, 0, 1, "low-level"),
        (4096, 0, 0, "low-level"),
        (1024, 1, 1, "low-level"),
        (4096, 0, 1, "stress"),
    ],
    ids=[
        "1k-forward-dit",
        "2k-forward-dit",
        "4k-forward-dit",
        "4k-forward-dif",
        "1k-inverse-dit",
        "4k-forward-dynamic-range-stress",
    ],
)
def test_fft_rtl_runner(
    fft_size, inverse, bit_reversed_input, vector_mode, monkeypatch
):
    monkeypatch.setenv("FFT_RUNTIME_SIZE", str(fft_size))
    monkeypatch.setenv("FFT_INVERSE", str(inverse))
    monkeypatch.setenv("FFT_BIT_REVERSED_INPUT", str(bit_reversed_input))
    monkeypatch.setenv("FFT_VECTOR_MODE", vector_mode)
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="fft",
        sources=resolve_flt(PRJ_PATH / "fft.flt"),
        parameters={
            "NUM_ANT": NUM_ANT,
            "LOG_FFT_SIZE": 12,
            "DATA_WIDTH": 16,
            "INV_FFT": inverse,
            "BIT_REVERSED_INPUT": bit_reversed_input,
        },
        always=True,
        build_dir=PRJ_PATH
        / "sim_build"
        / f"questa_fft_{fft_size}_{inverse}_{bit_reversed_input}_{vector_mode}",
        waves=False,
    )
    runner.test(
        hdl_toplevel="fft",
        hdl_toplevel_lang="verilog",
        test_module="test_fft_model",
        testcase="test_fft_rtl_matches_fixed_model",
    )
