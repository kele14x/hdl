#!/usr/bin/env python3
"""Full-block/full-FFT LTE 20 MHz PDXCH system simulation."""

from __future__ import annotations

import csv

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Combine, Event, RisingEdge, Timer, with_timeout
from pdxch_reference import (
    best_body_alignment,
    pdxch_lte20_reference,
    qpsk_bfp9_resource_elements,
)
from pdxch_test_utils import PRJ_PATH, pdxch_sources, run_test
from test_pdxch import (
    ALL_ANTENNAS_ALL_CC,
    DL_BIST,
    DL_BW,
    DL_EN,
    DL_GAIN_BASE,
    DL_NPRB_BASE,
    DL_RAT,
    DL_RFS_OFFSET_BASE,
    DL_UD,
    UNITY_Q14,
    _axis_sources,
    _polyline,
    _pulse_sync,
    _reset,
    _signed16,
)

from hdl_tools.axi4lite import AxiLiteAgentConfig, AxiLiteMasterDriver
from hdl_tools.axis import AxisBeat, AxisFrame

NUM_CC = 3
NUM_ANT = 4
NUM_SYMBOLS = 4
NUM_PRB = 100
FFT_SIZE = 2048
SAMPLE_RATE_HZ = 30.72e6
RADIO_CYCLES_PER_SAMPLE = 16
TIME_DOMAIN_TOLERANCE = 5
CP_LENGTHS = (160, 144, 144, 144)
SYMBOL_SAMPLES = tuple(FFT_SIZE + cp for cp in CP_LENGTHS)
SYMBOL_RADIO_CYCLES = tuple(
    RADIO_CYCLES_PER_SAMPLE * length for length in SYMBOL_SAMPLES
)

LTE_ALL_CC = 0x000
BW_20_MHZ_ALL_CC = 0x222
ARTIFACT_DIR = PRJ_PATH / "sim_build" / "lte20m_full_4ch_3cc"


def _make_bfp9_frame(*, cc: int, antenna: int, symbol: int) -> AxisFrame:
    """Create one deterministic, full-band LTE 20 MHz BFP9 packet."""

    decompressed = qpsk_bfp9_resource_elements(
        num_prb=NUM_PRB,
        cc=cc,
        antenna=antenna,
        symbol=symbol,
    )
    mantissas = (
        np.column_stack((decompressed.real, decompressed.imag)).astype(np.int16) // 128
    )
    stream_bits = []
    for prb in range(NUM_PRB):
        stream_bits.append("00001111")
        for real, imag in mantissas[prb * 12 : (prb + 1) * 12]:
            stream_bits.append(f"{int(real) & 0x1FF:09b}")
            stream_bits.append(f"{int(imag) & 0x1FF:09b}")

    bit_string = "".join(stream_bits)
    stream_bytes = [
        int(bit_string[index : index + 8], 2) for index in range(0, len(bit_string), 8)
    ]
    user = cc << 27
    beats = []
    for offset in range(0, len(stream_bytes), 8):
        chunk = stream_bytes[offset : offset + 8]
        beats.append(
            AxisBeat(
                data=sum(byte << (8 * lane) for lane, byte in enumerate(chunk)),
                keep=(1 << len(chunk)) - 1,
                user=user,
                dest=0,
                last=offset + len(chunk) == len(stream_bytes),
            )
        )
    return AxisFrame(beats)


async def _configure_lte20(axi: AxiLiteMasterDriver):
    assert await axi.read(0x00) == 0x20250106
    await axi.write(DL_EN, ALL_ANTENNAS_ALL_CC)
    await axi.write(DL_RAT, LTE_ALL_CC)
    await axi.write(DL_BIST, 0)
    await axi.write(DL_BW, BW_20_MHZ_ALL_CC)
    await axi.write(DL_UD, 0x91)

    for cc in range(NUM_CC):
        await axi.write(DL_NPRB_BASE + 4 * cc, NUM_PRB)
        await axi.write(DL_RFS_OFFSET_BASE + 4 * cc, 0)
        for antenna in range(NUM_ANT):
            await axi.write(DL_GAIN_BASE + 4 * (cc * NUM_ANT + antenna), UNITY_Q14)

    assert await axi.read(DL_EN) & 0xFFF == ALL_ANTENNAS_ALL_CC
    assert await axi.read(DL_RAT) & 0xFFF == LTE_ALL_CC
    assert await axi.read(DL_BW) & 0xFFF == BW_20_MHZ_ALL_CC
    assert await axi.read(DL_NPRB_BASE) & 0x1FF == NUM_PRB


async def _send_symbol(dut, sources, symbol: int):
    for cc in range(NUM_CC):
        dut.s_dl_sym_num[cc].value = symbol
        frames = [
            _make_bfp9_frame(cc=cc, antenna=antenna, symbol=symbol)
            for antenna in range(NUM_ANT)
        ]
        tasks = [
            cocotb.start_soon(source.send(frame, gap=1))
            for source, frame in zip(sources, frames, strict=True)
        ]
        await Combine(*tasks)


async def _capture_cc(dut, cc: int, capture_started: Event):
    while True:
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        users = []
        words = []
        for antenna in range(NUM_ANT):
            user = dut.m_axis_tuser[cc][antenna].value
            word = dut.m_axis_tdata[cc][antenna].value
            users.append(int(user) if user.is_resolvable else 0)
            words.append(int(word) if word.is_resolvable else 0)
        if any(user & 1 for user in users) or any(words):
            first_samples = [
                complex(_signed16(word & 0xFFFF), _signed16(word >> 16))
                for word in words
            ]
            break

    if cc == 0:
        capture_started.set()

    symbols = [[] for _ in range(NUM_ANT)]
    for symbol, symbol_samples in enumerate(SYMBOL_SAMPLES):
        antenna_samples = [
            [first_samples[antenna]] if symbol == 0 else []
            for antenna in range(NUM_ANT)
        ]
        for _ in range(symbol_samples - len(antenna_samples[0])):
            await ClockCycles(dut.clk, RADIO_CYCLES_PER_SAMPLE)
            await Timer(1, unit="ps")
            for antenna in range(NUM_ANT):
                output = dut.m_axis_tdata[cc][antenna].value
                word = int(output) if output.is_resolvable else 0
                antenna_samples[antenna].append(
                    complex(_signed16(word & 0xFFFF), _signed16(word >> 16))
                )
        for antenna in range(NUM_ANT):
            symbols[antenna].append(
                np.asarray(antenna_samples[antenna], dtype=np.complex128)
            )
    return symbols


def _spectrum(symbol: np.ndarray):
    useful = symbol[:FFT_SIZE]
    spectrum = np.fft.fftshift(np.fft.fft(useful))
    magnitude = 20 * np.log10(np.maximum(np.abs(spectrum), 1.0))
    magnitude -= np.max(magnitude)
    frequency_mhz = np.fft.fftshift(np.fft.fftfreq(FFT_SIZE, 1 / SAMPLE_RATE_HZ)) / 1e6
    return frequency_mhz, magnitude


def _make_references():
    return [
        [
            [
                pdxch_lte20_reference(
                    cc=cc,
                    antenna=antenna,
                    symbol=symbol,
                    num_prb=NUM_PRB,
                )
                for symbol in range(NUM_SYMBOLS)
            ]
            for antenna in range(NUM_ANT)
        ]
        for cc in range(NUM_CC)
    ]


def _write_csv(captures, references):
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    waveform_path = ARTIFACT_DIR / "pdxch_lte20_waveform.csv"
    with waveform_path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.writer(output)
        writer.writerow(
            [
                "cc",
                "antenna",
                "symbol",
                "sample",
                "rtl_i",
                "rtl_q",
                "fixed_reference_i",
                "fixed_reference_q",
            ]
        )
        for cc in range(NUM_CC):
            for antenna in range(NUM_ANT):
                for symbol, samples in enumerate(captures[cc][antenna]):
                    reference = references[cc][antenna][symbol].fixed_time_domain
                    for index, sample in enumerate(samples):
                        expected = reference[index] if index < FFT_SIZE else None
                        writer.writerow(
                            [
                                cc,
                                antenna,
                                symbol,
                                index,
                                int(sample.real),
                                int(sample.imag),
                                "" if expected is None else int(expected.real),
                                "" if expected is None else int(expected.imag),
                            ]
                        )

    spectrum_path = ARTIFACT_DIR / "pdxch_lte20_spectrum.csv"
    with spectrum_path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.writer(output)
        writer.writerow(["cc", "antenna", "frequency_mhz", "magnitude_db"])
        for cc in range(NUM_CC):
            for antenna in range(NUM_ANT):
                frequency, magnitude = _spectrum(captures[cc][antenna][1])
                writer.writerows(
                    (cc, antenna, f"{freq:.6f}", f"{mag:.3f}")
                    for freq, mag in zip(frequency, magnitude, strict=True)
                )

    summary_path = ARTIFACT_DIR / "pdxch_lte20_reference_summary.csv"
    with summary_path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.writer(output)
        writer.writerow(
            [
                "cc",
                "antenna",
                "symbol",
                "float_rms_error",
                "fixed_rms_error",
                "max_fixed_i_error",
                "max_fixed_q_error",
            ]
        )
        for cc in range(NUM_CC):
            for antenna in range(NUM_ANT):
                for symbol in range(NUM_SYMBOLS):
                    actual = captures[cc][antenna][symbol][:FFT_SIZE]
                    result = references[cc][antenna][symbol]
                    fixed_error = actual - result.fixed_time_domain
                    float_error = actual - result.time_domain
                    writer.writerow(
                        [
                            cc,
                            antenna,
                            symbol,
                            f"{np.sqrt(np.mean(np.abs(float_error) ** 2)):.6f}",
                            f"{np.sqrt(np.mean(np.abs(fixed_error) ** 2)):.6f}",
                            int(np.max(np.abs(fixed_error.real))),
                            int(np.max(np.abs(fixed_error.imag))),
                        ]
                    )
    return waveform_path, spectrum_path, summary_path


def _write_svg(captures):
    svg_path = ARTIFACT_DIR / "pdxch_lte20_waveform_spectrum.svg"
    width = 1440
    margin = 55
    panel_width = (width - 2 * margin) / NUM_ANT
    panel_height = 205
    height = margin + NUM_CC * panel_height + 45
    colors = ("#39d0ff", "#64e572", "#ffcf56", "#ff6fb5")
    parts = [
        (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" '
            f'height="{height}" viewBox="0 0 {width} {height}">'
        ),
        '<rect width="100%" height="100%" fill="#0b1020"/>',
        (
            "<style>text{font-family:Segoe UI,Arial;fill:#dce7ff}"
            ".axis{stroke:#52627d;stroke-width:1}"
            ".grid{stroke:#26334b;stroke-width:1}"
            ".trace{fill:none;stroke-width:1.2}</style>"
        ),
        '<text x="55" y="27" font-size="20">PDXCH LTE 20 MHz — full block / full FFT — 3 CC × 4 antennas</text>',
        '<text x="55" y="48" font-size="13" fill="#8fa7cc">100 PRBs, 15 kHz SCS, 30.72 MS/s; unwindowed FFT with LTE DC null</text>',
    ]

    for cc in range(NUM_CC):
        for antenna in range(NUM_ANT):
            x = margin + antenna * panel_width
            y = margin + cc * panel_height
            panel_w = panel_width - 15
            panel_h = panel_height - 45
            _, magnitude = _spectrum(captures[cc][antenna][1])
            points = _polyline(
                magnitude,
                x=x,
                y=y,
                width=panel_w,
                height=panel_h,
                y_min=-80,
                y_max=0,
            )
            dc_level = np.clip(magnitude[FFT_SIZE // 2], -80, 0)
            dc_y = y + panel_h - (dc_level + 80) * (panel_h / 80)
            parts.extend(
                [
                    f'<rect x="{x}" y="{y}" width="{panel_w}" height="{panel_h}" fill="#111a2e"/>',
                    f'<line class="grid" x1="{x}" y1="{y + panel_h / 2}" x2="{x + panel_w}" y2="{y + panel_h / 2}"/>',
                    f'<line class="grid" x1="{x + panel_w / 2}" y1="{y}" x2="{x + panel_w / 2}" y2="{y + panel_h}"/>',
                    f'<polyline class="trace" stroke="{colors[antenna]}" points="{points}"/>',
                    f'<circle cx="{x + panel_w / 2}" cy="{dc_y}" r="3" fill="#ff6b6b"/>',
                    f'<text x="{x + 7}" y="{y + 17}" font-size="12">CC{cc} / ant {antenna}</text>',
                    f'<text x="{x}" y="{y + panel_h + 17}" font-size="11">-15.36</text>',
                    f'<text x="{x + panel_w - 30}" y="{y + panel_h + 17}" font-size="11">15.36</text>',
                ]
            )
            if cc == 0 and antenna == 0:
                parts.append(
                    f'<text x="{x + panel_w / 2 + 6}" y="{y + panel_h - 8}" font-size="11" fill="#ff9a9a">DC null</text>'
                )

    parts.append(
        f'<text x="{width / 2 - 55}" y="{height - 8}" font-size="12">Frequency (MHz)</text>'
    )
    parts.append("</svg>")
    svg_path.write_text("\n".join(parts), encoding="utf-8")
    return svg_path


@cocotb.test()
async def test_lte20_full_block_full_fft_waveform_and_dc_null(dut):
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())

    axi = AxiLiteMasterDriver(
        dut,
        AxiLiteAgentConfig(
            prefix="s_axi",
            clock="s_axi_aclk",
            reset="s_axi_aresetn",
            reset_active_level=0,
            timeout_cycles=100,
        ),
    )
    sources = _axis_sources(dut)
    await _reset(dut, axi, sources)
    await _configure_lte20(axi)
    await ClockCycles(dut.clk, 32)

    await _send_symbol(dut, sources, 0)
    await _send_symbol(dut, sources, 1)
    capture_started = Event()
    capture_tasks = [
        cocotb.start_soon(_capture_cc(dut, cc, capture_started)) for cc in range(NUM_CC)
    ]
    await _pulse_sync(dut)

    await with_timeout(capture_started.wait(), 200, timeout_unit="us")
    await ClockCycles(dut.clk, 512)
    await _send_symbol(dut, sources, 2)
    await ClockCycles(dut.clk, SYMBOL_RADIO_CYCLES[0] - 512)
    await _send_symbol(dut, sources, 3)

    captures = [None for _ in range(NUM_CC)]
    for cc in range(NUM_CC):
        captures[cc] = await with_timeout(capture_tasks[cc], 500, timeout_unit="us")
    references = _make_references()

    failures = []
    for cc in range(NUM_CC):
        for antenna in range(NUM_ANT):
            frequency, magnitude = _spectrum(captures[cc][antenna][1])
            active = magnitude > -1
            assert np.count_nonzero(active) == NUM_PRB * 12
            dc_index = int(np.argmin(np.abs(frequency)))
            assert magnitude[dc_index] < -45, (
                f"CC{cc}/ant{antenna} DC is only {magnitude[dc_index]:.2f} dBc"
            )

            for symbol in range(NUM_SYMBOLS):
                actual = captures[cc][antenna][symbol][:FFT_SIZE]
                expected = references[cc][antenna][symbol].time_domain
                offset, error = best_body_alignment(actual, expected, max_offset=8)
                rms_error = float(np.sqrt(np.mean(np.abs(error) ** 2)))
                if rms_error > TIME_DOMAIN_TOLERANCE:
                    failures.append(
                        f"CC{cc}/ant{antenna}/sym{symbol}: offset={offset}, "
                        f"RMS error={rms_error:.3f}"
                    )

    waveform_path, spectrum_path, summary_path = _write_csv(captures, references)
    svg_path = _write_svg(captures)
    dut._log.info("LTE waveform CSV: %s", waveform_path)
    dut._log.info("LTE spectrum CSV: %s", spectrum_path)
    dut._log.info("LTE reference summary: %s", summary_path)
    dut._log.info("LTE waveform/spectrum SVG: %s", svg_path)
    assert not failures, "LTE20 reference mismatches:\n" + "\n".join(failures)


def test_pdxch_lte_runner():
    run_test(
        hdl_toplevel="pdxch",
        test_module="test_pdxch_lte",
        sources=pdxch_sources("pdxch.flt"),
        parameters={
            "NUM_CC": NUM_CC,
            "NUM_ANT": NUM_ANT,
            "HALF_BLOCK": 0,
            "HALF_FFT": 0,
        },
        build_name="lte20m_full_4ch_3cc",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
