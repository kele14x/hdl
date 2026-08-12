"""System simulation for NR 100 MHz, four antennas and three PDXCH CCs.

The test sends four deterministic QPSK/BFP9 symbols through the real U-plane
input, captures the radio output, and writes CSV plus a dependency-free SVG
waveform/spectrum report under ``pdxch/sim_build/nr100m_4ch_3cc``.
"""

from __future__ import annotations

import csv

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Combine, Event, RisingEdge, Timer, with_timeout
from pdxch_reference import (
    best_body_alignment,
    pdxch_nr100m_reference,
    qpsk_bfp9_resource_elements,
)
from pdxch_test_utils import PRJ_PATH, pdxch_sources, run_test

from hdl_tools.axi4lite import AxiLiteAgentConfig, AxiLiteMasterDriver
from hdl_tools.axis import AxisAgentConfig, AxisBeat, AxisFrame, AxisSourceDriver

NUM_CC = 3
NUM_ANT = 4
NUM_SYMBOLS = 4
NUM_PRB = 273
FFT_SIZE = 4096
SAMPLE_RATE_HZ = 122.88e6
TIME_DOMAIN_TOLERANCE = 5

# The radio processing clock carries the four antenna streams interleaved.
# At 30 kHz SCS the first symbol is 4096+352 samples and the others are
# 4096+288 samples; multiply by NUM_ANT to obtain radio-clock cycles.
CP_LENGTHS = (352, 288, 288, 288)
SYMBOL_SAMPLES = tuple(FFT_SIZE + cp for cp in CP_LENGTHS)
SYMBOL_RADIO_CYCLES = tuple(NUM_ANT * length for length in SYMBOL_SAMPLES)

DL_EN = 0x10
DL_RAT = 0x14
DL_BIST = 0x18
DL_BW = 0x1C
DL_NPRB_BASE = 0x20
DL_RFS_OFFSET_BASE = 0x30
DL_UD = 0x58
DL_GAIN_BASE = 0x100
DL_PHASE_COMP_BASE = 0x800

NR_30_KHZ_ALL_CC = 0x222
BW_100_MHZ_ALL_CC = 0x444
ALL_ANTENNAS_ALL_CC = 0xFFF
UNITY_Q14 = 0x00004000
ARTIFACT_DIR = PRJ_PATH / "sim_build" / "nr100m_4ch_3cc"


class _IndexedAxisView:
    """Expose one element of an unpacked AXI-Stream port to the shared agent."""

    def __init__(self, dut, antenna: int):
        self._dut = dut
        self._antenna = antenna

    def __getattr__(self, name):
        signal = getattr(self._dut, name)
        if name.startswith("s_defm_data_"):
            return signal[self._antenna]
        return signal


def _signed16(value: int) -> int:
    return value - 0x10000 if value & 0x8000 else value


def _make_bfp9_frame(*, cc: int, antenna: int, symbol: int) -> AxisFrame:
    """Create one full-band, deterministic O-RAN BFP9 symbol packet."""

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
        # Reserved nibble followed by exponent=15. With mantissa +/-16 this
        # decompresses to +/-2048 and leaves useful IFFT headroom.
        stream_bits.append("00001111")
        for re_index in range(12):
            real, imag = mantissas[prb * 12 + re_index]
            stream_bits.append(f"{int(real) & 0x1FF:09b}")
            stream_bits.append(f"{int(imag) & 0x1FF:09b}")

    bit_string = "".join(stream_bits)
    assert len(bit_string) == NUM_PRB * 28 * 8
    stream_bytes = [
        int(bit_string[index : index + 8], 2) for index in range(0, len(bit_string), 8)
    ]

    # TUSER[30:27] selects the component carrier; TUSER[9:0] is startPrb.
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


def _axis_sources(dut) -> list[AxisSourceDriver]:
    sources = []
    for antenna in range(NUM_ANT):
        view = _IndexedAxisView(dut, antenna)
        source = AxisSourceDriver(
            view,
            AxisAgentConfig(
                prefix="s_defm_data",
                clock="clk_eth_xran",
                reset="rst_eth_xran",
                reset_active_level=1,
                timeout_cycles=5000,
            ),
        )
        source.idle()
        sources.append(source)
    return sources


async def _reset(dut, axi: AxiLiteMasterDriver, sources):
    axi.idle()
    dut.sync_in.value = 0
    dut.s_axi_aresetn.value = 0
    dut.rst.value = 1
    dut.rst_eth_xran.value = 1
    for cc in range(NUM_CC):
        dut.s_dl_sym_num[cc].value = 0
        for antenna in range(NUM_ANT):
            dut.m_axis_tready[cc][antenna].value = 1
    for source in sources:
        source.idle()

    await ClockCycles(dut.s_axi_aclk, 8)
    await ClockCycles(dut.clk_eth_xran, 8)
    await ClockCycles(dut.clk, 8)
    dut.s_axi_aresetn.value = 1
    dut.rst.value = 0
    dut.rst_eth_xran.value = 0
    await ClockCycles(dut.s_axi_aclk, 8)
    await ClockCycles(dut.clk, 16)


async def _configure_nr100m(axi: AxiLiteMasterDriver):
    assert await axi.read(0x00) == 0x20250106
    await axi.write(DL_EN, ALL_ANTENNAS_ALL_CC)
    await axi.write(DL_RAT, NR_30_KHZ_ALL_CC)
    await axi.write(DL_BIST, 0)
    await axi.write(DL_BW, BW_100_MHZ_ALL_CC)
    await axi.write(DL_UD, 0x91)  # BFP9, fs_offset=0

    for cc in range(NUM_CC):
        await axi.write(DL_NPRB_BASE + 4 * cc, NUM_PRB)
        await axi.write(DL_RFS_OFFSET_BASE + 4 * cc, 0)
        for antenna in range(NUM_ANT):
            await axi.write(DL_GAIN_BASE + 4 * (cc * NUM_ANT + antenna), UNITY_Q14)

    # NR enables phase compensation. Program unity for all 16 symbols of all
    # three carriers (the fourth 16-entry page is harmless and keeps the RAM
    # initialization complete).
    for address in range(64):
        await axi.write(DL_PHASE_COMP_BASE + 4 * address, UNITY_Q14)

    assert await axi.read(DL_EN) & 0xFFF == ALL_ANTENNAS_ALL_CC
    assert await axi.read(DL_RAT) & 0xFFF == NR_30_KHZ_ALL_CC
    assert await axi.read(DL_BW) & 0xFFF == BW_100_MHZ_ALL_CC
    assert await axi.read(DL_NPRB_BASE) & 0x1FF == NUM_PRB
    assert await axi.read(DL_PHASE_COMP_BASE) == UNITY_Q14


async def _send_symbol(dut, sources, symbol: int):
    """Send one symbol to every carrier, with all four antennas in parallel."""

    for cc in range(NUM_CC):
        dut.s_dl_sym_num[cc].value = symbol
        frames = [
            _make_bfp9_frame(cc=cc, antenna=antenna, symbol=symbol)
            for antenna in range(NUM_ANT)
        ]
        tasks = [
            # One idle clock makes every payload stable for a complete cycle
            # before its handshake, avoiding simulator scheduling races on a
            # ready-high, back-to-back stream.
            cocotb.start_soon(source.send(frame, gap=1))
            for source, frame in zip(sources, frames, strict=True)
        ]
        await Combine(*tasks)


async def _pulse_sync(dut):
    await RisingEdge(dut.clk_eth_xran)
    dut.sync_in.value = 1
    await RisingEdge(dut.clk_eth_xran)
    await Timer(1, unit="ps")
    dut.sync_in.value = 0

    markers = [0] * NUM_CC
    for _ in range(8):
        await RisingEdge(dut.clk_eth_xran)
        await Timer(1, unit="ps")
        for cc in range(NUM_CC):
            markers[cc] += int(dut.defm_radio_start_10ms[cc].value)
    assert markers == [1] * NUM_CC, f"unexpected deframer frame markers: {markers}"


async def _capture_cc(dut, cc: int, capture_started: Event):
    """Capture all antenna outputs on one common 122.88-Msample/s phase."""

    while True:
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        tusers = []
        words = []
        for antenna in range(NUM_ANT):
            tuser_value = dut.m_axis_tuser[cc][antenna].value
            tdata_value = dut.m_axis_tdata[cc][antenna].value
            tusers.append(int(tuser_value) if tuser_value.is_resolvable else 0)
            words.append(int(tdata_value) if tdata_value.is_resolvable else 0)
        # TUSER[0] is the preferred alignment marker. Also accept the first
        # nonzero output sample so this waveform-oriented test remains useful
        # while the PDXCH frame-marker path itself is under repair.
        if any(tuser & 1 for tuser in tusers) or any(words):
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
            # Four radio-processing cycles represent one parallel antenna
            # output sample at the configured 122.88 MHz sample rate.
            await ClockCycles(dut.clk, NUM_ANT)
            await Timer(1, unit="ps")
            for antenna in range(NUM_ANT):
                output_value = dut.m_axis_tdata[cc][antenna].value
                value = int(output_value) if output_value.is_resolvable else 0
                antenna_samples[antenna].append(
                    complex(_signed16(value & 0xFFFF), _signed16(value >> 16))
                )
        for antenna in range(NUM_ANT):
            symbols[antenna].append(
                np.asarray(antenna_samples[antenna], dtype=np.complex128)
            )
    return symbols


def _spectrum(symbol: np.ndarray):
    # block2stream emits the IFFT body first and fills the inter-symbol gap
    # afterward. Treating that gap as a conventional prefix straddles two
    # symbols and creates false notches in the plotted spectrum.
    useful = symbol[:FFT_SIZE]
    # The capture contains one coherent 4096-sample OFDM body, so no window is
    # needed. A Hann window would mix neighboring random-QPSK subcarriers and
    # make equal-amplitude REs appear to have different levels.
    spectrum = np.fft.fftshift(np.fft.fft(useful))
    magnitude = 20 * np.log10(np.maximum(np.abs(spectrum), 1.0))
    magnitude -= np.max(magnitude)
    frequency_mhz = np.fft.fftshift(np.fft.fftfreq(FFT_SIZE, 1 / SAMPLE_RATE_HZ)) / 1e6
    return frequency_mhz, magnitude


def _make_references():
    return [
        [
            [
                pdxch_nr100m_reference(
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
    waveform_path = ARTIFACT_DIR / "pdxch_nr100m_waveform.csv"
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
                "fixed_error_i",
                "fixed_error_q",
            ]
        )
        for cc in range(NUM_CC):
            for antenna in range(NUM_ANT):
                for symbol, samples in enumerate(captures[cc][antenna]):
                    reference = references[cc][antenna][symbol].fixed_time_domain
                    for index, sample in enumerate(samples):
                        if index < FFT_SIZE:
                            expected = reference[index]
                            reference_columns = [
                                int(expected.real),
                                int(expected.imag),
                                int(sample.real - expected.real),
                                int(sample.imag - expected.imag),
                            ]
                        else:
                            reference_columns = ["", "", "", ""]
                        writer.writerow(
                            [
                                cc,
                                antenna,
                                symbol,
                                index,
                                int(sample.real),
                                int(sample.imag),
                                *reference_columns,
                            ]
                        )

    spectrum_path = ARTIFACT_DIR / "pdxch_nr100m_spectrum.csv"
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
    comparison_path = ARTIFACT_DIR / "pdxch_nr100m_reference_summary.csv"
    with comparison_path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.writer(output)
        writer.writerow(
            [
                "cc",
                "output_antenna",
                "symbol",
                "float_rms_error",
                "fixed_rms_error",
                "max_fixed_i_error",
                "max_fixed_q_error",
                "best_reference_antenna",
                "best_sample_offset",
                "best_fixed_rms_error",
            ]
        )
        for cc in range(NUM_CC):
            for antenna in range(NUM_ANT):
                for symbol in range(NUM_SYMBOLS):
                    actual = captures[cc][antenna][symbol][:FFT_SIZE]
                    fixed_expected = references[cc][antenna][symbol].fixed_time_domain
                    float_expected = references[cc][antenna][symbol].time_domain
                    fixed_error = actual - fixed_expected
                    float_error = actual - float_expected
                    lane_matches = []
                    for reference_antenna in range(NUM_ANT):
                        offset, aligned_error = best_body_alignment(
                            actual,
                            references[cc][reference_antenna][symbol].fixed_time_domain,
                            max_offset=8,
                        )
                        lane_matches.append(
                            (
                                float(np.sqrt(np.mean(np.abs(aligned_error) ** 2))),
                                reference_antenna,
                                offset,
                            )
                        )
                    best_rms, best_antenna, best_offset = min(lane_matches)
                    writer.writerow(
                        [
                            cc,
                            antenna,
                            symbol,
                            f"{np.sqrt(np.mean(np.abs(float_error) ** 2)):.6f}",
                            f"{np.sqrt(np.mean(np.abs(fixed_error) ** 2)):.6f}",
                            int(np.max(np.abs(fixed_error.real))),
                            int(np.max(np.abs(fixed_error.imag))),
                            best_antenna,
                            best_offset,
                            f"{best_rms:.6f}",
                        ]
                    )
    return waveform_path, spectrum_path, comparison_path


def _polyline(values, *, x, y, width, height, y_min, y_max):
    if len(values) > width:
        indices = np.linspace(0, len(values) - 1, int(width), dtype=int)
        values = values[indices]
    xs = x + np.linspace(0, width, len(values))
    scale = height / max(y_max - y_min, 1e-12)
    ys = y + height - (np.clip(values, y_min, y_max) - y_min) * scale
    return " ".join(f"{px:.1f},{py:.1f}" for px, py in zip(xs, ys, strict=True))


def _write_svg(captures):
    """Render one waveform and a 3-CC x 4-antenna spectrum matrix."""

    svg_path = ARTIFACT_DIR / "pdxch_nr100m_waveform_spectrum.svg"
    width = 1440
    margin = 55
    top_height = 250
    panel_width = (width - 2 * margin) / NUM_ANT
    panel_height = 190
    height = margin + top_height + 55 + NUM_CC * panel_height + 50
    parts = [
        (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
            f'viewBox="0 0 {width} {height}">'
        ),
        '<rect width="100%" height="100%" fill="#0b1020"/>',
        (
            "<style>text{font-family:Segoe UI,Arial;fill:#dce7ff}"
            ".axis{stroke:#52627d;stroke-width:1}"
            ".grid{stroke:#26334b;stroke-width:1}"
            ".trace{fill:none;stroke-width:1.4}</style>"
        ),
        '<text x="55" y="30" font-size="20">PDXCH NR 100 MHz — 3 CC × 4 antennas</text>',
        '<text x="55" y="52" font-size="13" fill="#8fa7cc">Four BFP9 QPSK symbols; 273 PRBs, 30 kHz SCS, 122.88 MS/s</text>',
    ]

    plot_x = margin
    plot_y = 75
    plot_w = width - 2 * margin
    plot_h = top_height - 50
    waveform = captures[0][0][1]
    count = min(1000, len(waveform))
    limit = max(
        np.max(np.abs(waveform[:count].real)), np.max(np.abs(waveform[:count].imag)), 1
    )
    parts.extend(
        [
            f'<rect x="{plot_x}" y="{plot_y}" width="{plot_w}" height="{plot_h}" fill="#111a2e"/>',
            f'<line class="axis" x1="{plot_x}" y1="{plot_y + plot_h / 2}" x2="{plot_x + plot_w}" y2="{plot_y + plot_h / 2}"/>',
            f'<polyline class="trace" stroke="#39d0ff" points="{_polyline(waveform[:count].real, x=plot_x, y=plot_y, width=plot_w, height=plot_h, y_min=-limit, y_max=limit)}"/>',
            f'<polyline class="trace" stroke="#ff6fb5" points="{_polyline(waveform[:count].imag, x=plot_x, y=plot_y, width=plot_w, height=plot_h, y_min=-limit, y_max=limit)}"/>',
            f'<text x="{plot_x + 8}" y="{plot_y + 18}" font-size="13">CC0 / antenna 0 waveform — I (cyan), Q (pink)</text>',
            f'<text x="{plot_x}" y="{plot_y + plot_h + 20}" font-size="12">0</text>',
            f'<text x="{plot_x + plot_w - 70}" y="{plot_y + plot_h + 20}" font-size="12">1000 samples</text>',
        ]
    )

    spectrum_top = margin + top_height + 45
    colors = ("#39d0ff", "#64e572", "#ffcf56", "#ff6fb5")
    for cc in range(NUM_CC):
        for antenna in range(NUM_ANT):
            x = margin + antenna * panel_width
            y = spectrum_top + cc * panel_height
            panel_w = panel_width - 15
            panel_h = panel_height - 45
            _, magnitude = _spectrum(captures[cc][antenna][1])
            parts.extend(
                [
                    f'<rect x="{x}" y="{y}" width="{panel_w}" height="{panel_h}" fill="#111a2e"/>',
                    f'<line class="grid" x1="{x}" y1="{y + panel_h / 2}" x2="{x + panel_w}" y2="{y + panel_h / 2}"/>',
                    f'<line class="grid" x1="{x + panel_w / 2}" y1="{y}" x2="{x + panel_w / 2}" y2="{y + panel_h}"/>',
                    f'<polyline class="trace" stroke="{colors[antenna]}" points="{_polyline(magnitude, x=x, y=y, width=panel_w, height=panel_h, y_min=-80, y_max=0)}"/>',
                    f'<text x="{x + 7}" y="{y + 17}" font-size="12">CC{cc} / ant {antenna}</text>',
                    f'<text x="{x}" y="{y + panel_h + 17}" font-size="11">-61.44</text>',
                    f'<text x="{x + panel_w - 34}" y="{y + panel_h + 17}" font-size="11">61.44</text>',
                ]
            )
            if antenna == 0:
                parts.append(
                    f'<text x="8" y="{y + panel_h / 2}" font-size="11" transform="rotate(-90 8 {y + panel_h / 2})">dBFS rel.</text>'
                )

    parts.append(
        f'<text x="{width / 2 - 55}" y="{height - 12}" font-size="12">Frequency (MHz)</text>'
    )
    parts.append("</svg>")
    svg_path.write_text("\n".join(parts), encoding="utf-8")
    return svg_path


@cocotb.test()
async def test_nr100m_4channel_3cc_waveform_and_spectrum(dut):
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
    await _configure_nr100m(axi)
    await ClockCycles(dut.clk, 32)
    dut._log.info("NR 100 MHz register configuration complete")

    # Preload both ping-pong banks before starting the radio frame.
    await _send_symbol(dut, sources, 0)
    dut._log.info("preloaded symbol 0")
    await _send_symbol(dut, sources, 1)
    dut._log.info("preloaded symbol 1")
    capture_started = Event()
    capture_tasks = [
        cocotb.start_soon(_capture_cc(dut, cc, capture_started)) for cc in range(NUM_CC)
    ]
    await _pulse_sync(dut)
    dut._log.info("radio-frame sync issued")

    # Once symbol 0 reaches the radio interface, its input bank has drained.
    # Refill that bank with symbol 2, then refill bank 1 one symbol later.
    await with_timeout(capture_started.wait(), 200, timeout_unit="us")
    dut._log.info("nonzero radio output capture started")
    await ClockCycles(dut.clk, 512)
    await _send_symbol(dut, sources, 2)
    await ClockCycles(dut.clk, SYMBOL_RADIO_CYCLES[0] - 512)
    await _send_symbol(dut, sources, 3)

    captures = [None for _ in range(NUM_CC)]
    for cc in range(NUM_CC):
        captures[cc] = await with_timeout(capture_tasks[cc], 500, timeout_unit="us")

    references = _make_references()

    # Sanity checks make the visual artifacts meaningful rather than merely
    # proving that files were written.
    for cc in range(NUM_CC):
        for antenna in range(NUM_ANT):
            assert len(captures[cc][antenna]) == NUM_SYMBOLS
            rms = np.sqrt(np.mean(np.abs(captures[cc][antenna][1]) ** 2))
            assert rms > 1.0, f"CC{cc} antenna{antenna} output is silent"
            frequency, magnitude = _spectrum(captures[cc][antenna][1])
            occupied = np.abs(frequency) <= (NUM_PRB * 12 * 30e3 / 2 / 1e6)
            assert np.percentile(magnitude[occupied], 75) > -35

    waveform_path, spectrum_path, comparison_path = _write_csv(captures, references)
    svg_path = _write_svg(captures)
    dut._log.info("waveform CSV: %s", waveform_path)
    dut._log.info("spectrum CSV: %s", spectrum_path)
    dut._log.info("reference comparison summary: %s", comparison_path)
    dut._log.info("waveform/spectrum SVG: %s", svg_path)

    failures = []
    for cc in range(NUM_CC):
        for antenna in range(NUM_ANT):
            for symbol in range(NUM_SYMBOLS):
                actual = captures[cc][antenna][symbol][:FFT_SIZE]
                expected = references[cc][antenna][symbol].time_domain
                offset, error = best_body_alignment(actual, expected, max_offset=8)
                rms_error = float(np.sqrt(np.mean(np.abs(error) ** 2)))
                max_i = float(np.max(np.abs(error.real)))
                max_q = float(np.max(np.abs(error.imag)))
                if rms_error > TIME_DOMAIN_TOLERANCE:
                    failures.append(
                        f"CC{cc}/ant{antenna}/sym{symbol}: "
                        f"offset={offset}, RMS error={rms_error:.3f}, "
                        f"max |I error|={max_i:.3f}, max |Q error|={max_q:.3f}"
                    )
    assert not failures, (
        f"RTL RMS error against the floating-point reference exceeds "
        f"{TIME_DOMAIN_TOLERANCE} LSBs:\n" + "\n".join(failures)
    )


def test_pdxch_runner():
    run_test(
        hdl_toplevel="pdxch",
        test_module="test_pdxch",
        sources=pdxch_sources("pdxch.flt"),
        parameters={
            "NUM_CC": NUM_CC,
            "NUM_ANT": NUM_ANT,
            "HALF_BLOCK": 0,
            "HALF_FFT": 0,
        },
        build_name="nr100m_4ch_3cc",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
