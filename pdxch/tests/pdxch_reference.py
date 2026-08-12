"""Reference model for the NR 100 MHz PDXCH signal-processing path."""

from __future__ import annotations

import argparse
import csv
import math
from dataclasses import dataclass
from pathlib import Path

import numpy as np

from fft.tests.fft_fixed_model import FftConfig, bit_reverse_indices, fft_fixed


@dataclass(frozen=True)
class PdxchReferenceResult:
    """Reference vectors at the principal PDXCH processing boundaries."""

    resource_elements: np.ndarray
    fdv_stream: np.ndarray
    converter_stream: np.ndarray
    fixed_time_domain: np.ndarray
    time_domain: np.ndarray


def qpsk_bfp9_resource_elements(
    *, num_prb: int, cc: int, antenna: int, symbol: int
) -> np.ndarray:
    """Recreate the deterministic BFP9 stimulus after RTL decompression."""

    rng = np.random.default_rng(0x5A17 + 1000 * cc + 100 * antenna + symbol)
    qpsk = rng.integers(0, 2, size=(num_prb * 12, 2), dtype=np.int16)
    mantissas = np.where(qpsk == 0, -16, 16).astype(np.int64)

    # exponent=15 and fs_offset=0 in pdxch_fdv_buffer_readout produce a
    # signed BFP9 mantissa multiplied by 128. These stimulus values do not
    # exercise the decompressor saturation path.
    decompressed = mantissas * 128
    return decompressed[:, 0] + 1j * decompressed[:, 1]


def _wrap_signed(values: np.ndarray, width: int) -> np.ndarray:
    values = np.asarray(values, dtype=np.int64)
    modulus = 1 << width
    sign = 1 << (width - 1)
    unsigned = values & (modulus - 1)
    return np.where(unsigned >= sign, unsigned - modulus, unsigned).astype(np.int64)


def _sv_real_to_int(values: np.ndarray) -> np.ndarray:
    """Match SystemVerilog real-to-integer conversion (nearest, ties away)."""

    return np.where(values >= 0, np.floor(values + 0.5), np.ceil(values - 0.5)).astype(
        np.int64
    )


def fdv_readout_stream(
    resource_elements: np.ndarray, fft_size: int = 4096
) -> np.ndarray:
    """Model the FDV read-address rotation and bit-reversed stream order."""

    resource_elements = np.asarray(resource_elements, dtype=np.complex128)
    logical_count = resource_elements.size
    bit_reversed = bit_reverse_indices(fft_size)
    logical_index = (bit_reversed + logical_count // 2) & (fft_size - 1)
    stream = np.zeros(fft_size, dtype=np.complex128)
    active = logical_index < logical_count
    stream[active] = resource_elements[logical_index[active]]
    return stream


def fdv_lte20_readout_stream(resource_elements: np.ndarray) -> np.ndarray:
    """Model the LTE 20 MHz FDV mapping, including the null DC bin."""

    resource_elements = np.asarray(resource_elements, dtype=np.complex128)
    fft_size = 2048
    logical_count = resource_elements.size
    half_occupied = logical_count // 2
    bit_reversed = bit_reverse_indices(fft_size)
    logical_index = np.where(
        bit_reversed <= half_occupied,
        bit_reversed + half_occupied - 1,
        bit_reversed + half_occupied,
    ) & (fft_size - 1)
    stream = np.zeros(fft_size, dtype=np.complex128)
    active = (bit_reversed != 0) & (logical_index < logical_count)
    stream[active] = resource_elements[logical_index[active]]
    return stream


def frequency_converter_stream(
    fdv_stream: np.ndarray, *, phase_increment: int = -9
) -> np.ndarray:
    """Model ``pdxch_conv`` including its Q2.14 NCO and truncating cmult."""

    fdv_stream = np.asarray(fdv_stream, dtype=np.complex128)
    fft_size = fdv_stream.size
    index_reversed = bit_reverse_indices(fft_size)
    phase = (index_reversed * phase_increment) & 0x7F
    angle = 2 * math.pi * np.arange(128, dtype=np.float64) / 128
    cosine_lut = _sv_real_to_int(np.cos(angle) * (1 << 14))
    cosine = cosine_lut[phase]
    sine = cosine_lut[(phase - 32) & 0x7F]

    real = np.asarray(fdv_stream.real, dtype=np.int64)
    imag = np.asarray(fdv_stream.imag, dtype=np.int64)
    # cmult ROUND=0, SATURATE=0, SHIFT=14.
    converted_real = _wrap_signed((real * cosine - imag * sine) >> 14, 16)
    converted_imag = _wrap_signed((imag * cosine + real * sine) >> 14, 16)
    return converted_real + 1j * converted_imag


def pdxch_nr_reference(
    *, cc: int, antenna: int, symbol: int, num_prb: int, fft_size: int
) -> PdxchReferenceResult:
    """Run a fixed-point-aware NR PDXCH reference chain."""

    resource_elements = qpsk_bfp9_resource_elements(
        num_prb=num_prb,
        cc=cc,
        antenna=antenna,
        symbol=symbol,
    )
    fdv_stream = fdv_readout_stream(resource_elements, fft_size=fft_size)
    converter_stream = frequency_converter_stream(
        fdv_stream,
        phase_increment=-11 if symbol == 0 else -9,
    )
    config = FftConfig(
        fft_size=fft_size,
        inverse=True,
        bit_reversed_input=True,
    )
    output_real, output_imag, stats = fft_fixed(
        converter_stream.real.astype(np.int64),
        converter_stream.imag.astype(np.int64),
        config,
    )
    if stats.butterfly_wraps or stats.twiddle_wraps or stats.coarse_twiddle_wraps:
        raise AssertionError(f"reference FFT overflowed internally: {stats}")
    fixed_time_domain = output_real + 1j * output_imag

    # Independent floating-point reference: restore natural bin order and
    # apply the ideal, unquantized NCO ramp.
    bit_reversed = bit_reverse_indices(fft_size)
    phase_increment = -11 if symbol == 0 else -9
    phase = (bit_reversed * phase_increment) & 0x7F
    ideal_converter_stream = fdv_stream * np.exp(1j * 2 * math.pi * phase / 128)
    natural_frequency = ideal_converter_stream[bit_reversed]
    time_domain = np.fft.ifft(natural_frequency) * (fft_size / config.scale_factor)
    return PdxchReferenceResult(
        resource_elements=resource_elements,
        fdv_stream=fdv_stream,
        converter_stream=converter_stream,
        fixed_time_domain=fixed_time_domain,
        time_domain=time_domain,
    )


def pdxch_nr100m_reference(
    *, cc: int, antenna: int, symbol: int, num_prb: int = 273
) -> PdxchReferenceResult:
    """Run the fixed-point-aware 4096-point NR 100 MHz reference chain."""

    return pdxch_nr_reference(
        cc=cc,
        antenna=antenna,
        symbol=symbol,
        num_prb=num_prb,
        fft_size=4096,
    )


def pdxch_lte20_reference(
    *, cc: int, antenna: int, symbol: int, num_prb: int = 100
) -> PdxchReferenceResult:
    """Run the fixed-point-aware 2048-point LTE 20 MHz reference chain."""

    resource_elements = qpsk_bfp9_resource_elements(
        num_prb=num_prb,
        cc=cc,
        antenna=antenna,
        symbol=symbol,
    )
    fdv_stream = fdv_lte20_readout_stream(resource_elements)
    phase_increment = -10 if symbol == 0 else -9
    converter_stream = frequency_converter_stream(
        fdv_stream,
        phase_increment=phase_increment,
    )
    output_real, output_imag, stats = fft_fixed(
        converter_stream.real.astype(np.int64),
        converter_stream.imag.astype(np.int64),
        FftConfig(
            fft_size=2048,
            inverse=True,
            bit_reversed_input=True,
        ),
    )
    if stats.butterfly_wraps or stats.twiddle_wraps or stats.coarse_twiddle_wraps:
        raise AssertionError(f"reference FFT overflowed internally: {stats}")
    fixed_time_domain = output_real + 1j * output_imag

    bit_reversed = bit_reverse_indices(2048)
    phase = (bit_reversed * phase_increment) & 0x7F
    ideal_converter_stream = fdv_stream * np.exp(1j * 2 * math.pi * phase / 128)
    natural_frequency = ideal_converter_stream[bit_reversed]
    time_domain = np.fft.ifft(natural_frequency) * (2048 / 32)
    return PdxchReferenceResult(
        resource_elements=resource_elements,
        fdv_stream=fdv_stream,
        converter_stream=converter_stream,
        fixed_time_domain=fixed_time_domain,
        time_domain=time_domain,
    )


def best_body_alignment(
    captured: np.ndarray,
    reference: np.ndarray,
    *,
    max_offset: int = 512,
) -> tuple[int, np.ndarray]:
    """Find the signed sample offset with minimum complex RMS error.

    A positive offset means the capture starts before the reference body; a
    negative offset means the capture starts inside the reference body.
    """

    captured = np.asarray(captured, dtype=np.complex128)
    reference = np.asarray(reference, dtype=np.complex128)
    compare_length = min(reference.size, captured.size) - max_offset
    if compare_length <= 0:
        raise ValueError("captured vector is too short for alignment")

    best_offset = 0
    best_error = captured[:compare_length] - reference[:compare_length]
    best_rms = float(np.sqrt(np.mean(np.abs(best_error) ** 2)))
    for offset in range(-max_offset, max_offset + 1):
        captured_start = max(offset, 0)
        reference_start = max(-offset, 0)
        error = (
            captured[captured_start : captured_start + compare_length]
            - reference[reference_start : reference_start + compare_length]
        )
        rms = float(np.sqrt(np.mean(np.abs(error) ** 2)))
        if rms < best_rms:
            best_offset = offset
            best_error = error
            best_rms = rms
    return best_offset, best_error


def load_waveform_capture(
    path: Path, *, cc: int, antenna: int, symbol: int
) -> np.ndarray:
    """Load one CC/antenna/symbol vector from the test's waveform CSV."""

    samples = []
    with path.open(newline="", encoding="utf-8") as input_file:
        for row in csv.DictReader(input_file):
            if (
                int(row["cc"]) == cc
                and int(row["antenna"]) == antenna
                and int(row["symbol"]) == symbol
            ):
                real_key = "rtl_i" if "rtl_i" in row else "i"
                imag_key = "rtl_q" if "rtl_q" in row else "q"
                samples.append(complex(int(row[real_key]), int(row[imag_key])))
    if not samples:
        raise ValueError(f"no CC{cc}/antenna{antenna}/symbol{symbol} samples in {path}")
    return np.asarray(samples, dtype=np.complex128)


def _main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("waveform_csv", type=Path)
    parser.add_argument("--cc", type=int, default=0)
    parser.add_argument("--antenna", type=int, default=0)
    parser.add_argument("--reference-antenna", type=int)
    parser.add_argument("--fixed", action="store_true")
    parser.add_argument("--symbol", type=int, default=1)
    parser.add_argument("--max-offset", type=int, default=512)
    parser.add_argument("--inspect-frequency", action="store_true")
    args = parser.parse_args()

    captured = load_waveform_capture(
        args.waveform_csv,
        cc=args.cc,
        antenna=args.antenna,
        symbol=args.symbol,
    )
    result = pdxch_nr100m_reference(
        cc=args.cc,
        antenna=(
            args.antenna if args.reference_antenna is None else args.reference_antenna
        ),
        symbol=args.symbol,
    )
    reference = result.fixed_time_domain if args.fixed else result.time_domain
    offset, error = best_body_alignment(
        captured,
        reference,
        max_offset=args.max_offset,
    )
    print(
        f"CC{args.cc} antenna{args.antenna} symbol{args.symbol}: "
        f"offset={offset}, rms_error={np.sqrt(np.mean(np.abs(error) ** 2)):.6f}, "
        f"captured_rms={np.sqrt(np.mean(np.abs(captured) ** 2)):.3f}, "
        f"reference_rms={np.sqrt(np.mean(np.abs(reference) ** 2)):.3f}, "
        f"float_fixed_rms={np.sqrt(np.mean(np.abs(reference - result.fixed_time_domain) ** 2)):.3f}, "
        f"float_fixed_max={np.max(np.abs(reference - result.fixed_time_domain)):.3f}, "
        f"max_i_error={np.max(np.abs(error.real)):.0f}, "
        f"max_q_error={np.max(np.abs(error.imag)):.0f}"
    )
    nonzero = np.flatnonzero((error.real != 0) | (error.imag != 0))
    if args.fixed:
        print(
            f"nonzero_error_samples={nonzero.size}, "
            f"first_error_indices={nonzero[:8].tolist()}"
        )
    if args.inspect_frequency:
        body = captured[:4096]
        correlation = np.fft.ifft(np.fft.fft(body) * np.conj(np.fft.fft(reference)))
        circular_offset = int(np.argmax(np.abs(correlation)))
        circular_error = body - np.roll(reference, circular_offset)
        print(
            f"best circular offset={circular_offset}, "
            f"rms_error={np.sqrt(np.mean(np.abs(circular_error) ** 2)):.3f}"
        )
        recovered = np.fft.fft(body) / 64
        expected = result.converter_stream[bit_reverse_indices(4096)]
        recovered_active = np.flatnonzero(np.abs(recovered) > 1024)
        expected_active = np.flatnonzero(np.abs(expected) > 1024)
        print(
            "recovered active bins: "
            f"count={recovered_active.size}, first={recovered_active[:8].tolist()}, "
            f"last={recovered_active[-8:].tolist()}"
        )
        print(
            "expected active bins: "
            f"count={expected_active.size}, first={expected_active[:8].tolist()}, "
            f"last={expected_active[-8:].tolist()}"
        )
        active = np.intersect1d(recovered_active, expected_active)
        ratio = recovered[active] / expected[active]
        quadrants = np.round(np.angle(ratio) / (math.pi / 2)).astype(int) & 3
        print(
            "actual/expected phase quadrants: "
            + ", ".join(
                f"{quadrant * 90}deg={np.count_nonzero(quadrants == quadrant)}"
                for quadrant in range(4)
            )
        )
        print(
            "frequency-domain direct rms error: "
            f"{np.sqrt(np.mean(np.abs(recovered[active] - expected[active]) ** 2)):.3f}"
        )
        candidates = []
        natural_index = np.arange(4096)
        logical_index = (natural_index + 273 * 6) & 0xFFF
        valid = logical_index < 273 * 12
        for candidate_cc in range(3):
            for candidate_antenna in range(4):
                for candidate_symbol in range(4):
                    candidate_resource = qpsk_bfp9_resource_elements(
                        num_prb=273,
                        cc=candidate_cc,
                        antenna=candidate_antenna,
                        symbol=candidate_symbol,
                    )
                    for phase_increment in (-11, -9):
                        unmixed = recovered * np.exp(
                            -1j * 2 * math.pi * natural_index * phase_increment / 128
                        )
                        actual_signs = np.column_stack(
                            (
                                np.sign(unmixed[valid].real),
                                np.sign(unmixed[valid].imag),
                            )
                        )
                        expected_signs = np.column_stack(
                            (
                                np.sign(candidate_resource[logical_index[valid]].real),
                                np.sign(candidate_resource[logical_index[valid]].imag),
                            )
                        )
                        match = float(np.mean(actual_signs == expected_signs))
                        candidates.append(
                            (
                                match,
                                candidate_cc,
                                candidate_antenna,
                                candidate_symbol,
                                phase_increment,
                            )
                        )
        print(
            "best decoded QPSK matches: "
            + ", ".join(
                f"CC{cc}/ant{antenna}/sym{symbol}/pinc{increment}={100 * match:.1f}%"
                for match, cc, antenna, symbol, increment in sorted(
                    candidates, reverse=True
                )[:4]
            )
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(_main())
