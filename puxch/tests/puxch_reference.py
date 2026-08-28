"""Fixed-point reference model for the PUXCH receive path."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from fft.tests.fft_fixed_model import FftConfig, bit_reverse_indices, fft_fixed
from hdl_tools import bfp


@dataclass(frozen=True)
class PuxchReference:
    """Values at the output of the PUXCH FFT, before the readout RAM."""

    stream_real: np.ndarray
    stream_imag: np.ndarray


def _wrap_signed(values: np.ndarray, width: int) -> np.ndarray:
    values = np.asarray(values, dtype=np.int64)
    modulus = 1 << width
    sign = 1 << (width - 1)
    unsigned = values & (modulus - 1)
    return np.where(unsigned >= sign, unsigned - modulus, unsigned).astype(np.int64)


def _saturate_signed(values: np.ndarray, width: int) -> np.ndarray:
    return np.clip(
        np.asarray(values, dtype=np.int64), -(1 << (width - 1)), (1 << (width - 1)) - 1
    ).astype(np.int64)


def _round_shift(values: np.ndarray, shift: int) -> np.ndarray:
    """Match ``type_case`` ROUND=1 for a signed integer value."""

    values = np.asarray(values, dtype=np.int64)
    quotient = values >> shift
    dropped = values & ((1 << shift) - 1)
    round_up = ((dropped >> (shift - 1)) & 1) & (
        ((quotient & 1) != 0) | ((dropped & ((1 << (shift - 1)) - 1)) != 0)
    )
    return quotient + round_up.astype(np.int64)


def _real_multiply(values: np.ndarray, gain: int) -> np.ndarray:
    product = np.asarray(values, dtype=np.int64) * int(gain)
    return _saturate_signed(_round_shift(product, 14), 16)


def _dds_coefficients(phase: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Recreate the full 12-bit ``dds_lut`` ROM used by ``puxch_conv``."""

    phase = np.asarray(phase, dtype=np.int64) & 0xFFF
    angle = 2.0 * np.pi * phase / 4096.0
    amplitude = (1 << 15) - 2
    # A sized SystemVerilog real-to-integer conversion rounds ties away from
    # zero.  The LUT does not contain exact half-way values in this test.
    cos = np.where(
        np.cos(angle) >= 0,
        np.floor(amplitude * np.cos(angle) + 0.5),
        np.ceil(amplitude * np.cos(angle) - 0.5),
    ).astype(np.int64)
    sin = np.where(
        np.sin(angle) >= 0,
        np.floor(amplitude * np.sin(angle) + 0.5),
        np.ceil(amplitude * np.sin(angle) - 0.5),
    ).astype(np.int64)
    return cos, sin


def _frequency_rotate(
    real: np.ndarray, imag: np.ndarray, *, fft_size: int, nprb: int, rat: int
) -> tuple[np.ndarray, np.ndarray]:
    """Model ``puxch_conv``'s per-sample NCO and Q1.15 complex multiply."""

    # The RTL uses a 12-bit phase accumulator.  For LTE it subtracts one from
    # the frequency word; NR uses nPRB*12 directly.
    pinc = (int(nprb) * 12 - (1 if rat == 0 else 0)) & 0xFFF
    sample_index = np.arange(len(real), dtype=np.int64)
    phase = ((sample_index * int(fft_size) * pinc) // 2) & 0xFFF
    cos, sin = _dds_coefficients(phase)
    product_real = (
        np.asarray(real, dtype=np.int64) * cos - np.asarray(imag, dtype=np.int64) * sin
    )
    product_imag = (
        np.asarray(imag, dtype=np.int64) * cos + np.asarray(real, dtype=np.int64) * sin
    )
    return _wrap_signed(_round_shift(product_real, 15), 16), _wrap_signed(
        _round_shift(product_imag, 15), 16
    )


def _fft_parameters(*, rat: int, bw: int) -> tuple[int, int, int, int]:
    """Return ``(FFT size, compiled log size, ctrl_size, ctrl_itlv)``."""

    if rat == 0:
        return 2048, 11, 1, 0
    if rat == 1:
        if bw <= 2:
            return 2048, 11, 1, 0
        return 4096, 12, 2, 1
    if bw <= 2:
        return 1024, 10, 0, 0
    if bw == 3:
        return 2048, 11, 1, 1
    return 4096, 12, 2, 2


def puxch_reference(
    real: np.ndarray,
    imag: np.ndarray,
    *,
    rat: int,
    bw: int,
    nprb: int,
    gain: int = 0x4000,
) -> PuxchReference:
    """Run one antenna and one component carrier through the PUXCH chain.

    ``real`` and ``imag`` are the samples at the output of ``puxch_resync``
    for one symbol.  The returned order is the stream order written to the
    PUXCH buffer (the buffer subsequently restores natural frequency order
    when its RAM addresses are read).
    """

    fft_size, log_fft_size, ctrl_size, ctrl_itlv = _fft_parameters(rat=rat, bw=bw)
    if len(real) != fft_size or len(imag) != fft_size:
        raise ValueError(
            f"expected {fft_size} samples, got {len(real)} and {len(imag)}"
        )

    real = _real_multiply(real, gain)
    imag = _real_multiply(imag, gain)
    index_step = {1024: 4, 2048: 2, 4096: 1}[fft_size]
    real, imag = _frequency_rotate(real, imag, fft_size=index_step, nprb=nprb, rat=rat)
    stream_real, stream_imag, stats = fft_fixed(
        real,
        imag,
        FftConfig(
            log_fft_size=log_fft_size,
            fft_size=fft_size,
            inverse=False,
            bit_reversed_input=False,
        ),
    )
    if stats.butterfly_wraps or stats.twiddle_wraps or stats.coarse_twiddle_wraps:
        raise AssertionError(f"reference FFT overflowed internally: {stats}")

    # ctrl_size is included in the parameter calculation above to make the
    # run-time/compile-time contract explicit.  The FFT model derives the
    # same scale from the selected full-size transform; ctrl_itlv is likewise
    # documented here because it determines the stream's channel cadence.
    del ctrl_size, ctrl_itlv
    return PuxchReference(stream_real=stream_real, stream_imag=stream_imag)


def raw_readout_words(
    reference: PuxchReference,
    *,
    start_prb: int,
    num_prb: int,
    internal_bfp9: bool = False,
) -> list[int]:
    """Pack the words emitted by ``puxch_buffer`` for one read request."""

    stream_real = reference.stream_real
    stream_imag = reference.stream_imag
    fft_size = len(stream_real)
    reverse = bit_reverse_indices(fft_size)
    first_beat = int(start_prb) * 6
    words: list[int] = []
    for beat in range(int(num_prb) * 6):
        values = []
        for pair in range(2):
            physical_address = 2 * (first_beat + beat) + pair
            stream_index = int(reverse[physical_address])
            real = int(stream_real[stream_index])
            imag = int(stream_imag[stream_index])
            if internal_bfp9:
                real, imag = internal_bfp9_roundtrip(real, imag)
            values.append((real, imag))
        (real0, imag0), (real1, imag1) = values
        # The PUXCH buffer emits network-byte-order IQ pairs.  This is the
        # inverse of {rd_data[55:48], ..., rd_data[7:0]} in puxch_buffer.sv.
        bytes_in_lane_order = [
            real0 >> 8,
            real0,
            imag0 >> 8,
            imag0,
            real1 >> 8,
            real1,
            imag1 >> 8,
            imag1,
        ]
        words.append(
            sum(
                (byte & 0xFF) << (8 * lane)
                for lane, byte in enumerate(bytes_in_lane_order)
            )
        )
    return words


def bfp9_readout_words(
    reference: PuxchReference,
    *,
    start_prb: int,
    num_prb: int,
    fs_offset: int = 0,
) -> tuple[list[int], list[int]]:
    """Pack mandatory BFP9 output words and their AXI-Stream keep values."""

    stream_real = reference.stream_real
    stream_imag = reference.stream_imag
    reverse = bit_reverse_indices(len(stream_real))
    packed_bytes: list[int] = []
    first_re = int(start_prb) * 12
    for prb in range(int(num_prb)):
        iq: list[int] = []
        for re_index in range(12):
            physical_address = first_re + prb * 12 + re_index
            stream_index = int(reverse[physical_address])
            real, imag = internal_bfp9_roundtrip(
                int(stream_real[stream_index]), int(stream_imag[stream_index])
            )
            iq.extend((real, imag))
        packed_bytes.extend(bfp.compress_prb(iq, width=9, fs_offset=fs_offset))

    words = []
    keeps = []
    for offset in range(0, len(packed_bytes), 8):
        chunk = packed_bytes[offset : offset + 8]
        words.append(sum(byte << (8 * lane) for lane, byte in enumerate(chunk)))
        keeps.append((1 << len(chunk)) - 1)
    return words, keeps


def internal_bfp9_roundtrip(real: int, imag: int) -> tuple[int, int]:
    """Model the per-RE BFP9 storage format used by the PUXCH buffer."""

    def msb_position(value: int) -> int:
        value &= 0xFFFF
        for index in range(15, 0, -1):
            if ((value >> index) ^ (value >> (index - 1))) & 1:
                return index
        return 0

    msb = max(msb_position(real), msb_position(imag))
    shift = min(15 - msb, 7)
    exponent = 15 - shift

    def roundtrip_component(value: int) -> int:
        rounded = ((value & 0xFFFF) << shift) & 0xFFFF
        rounded |= 0x003F
        if rounded != 0x7FFF:
            rounded = (rounded + 1) & 0xFFFF
        mantissa = rounded >> 7
        if mantissa & 0x100:
            mantissa -= 0x200
        return int(np.int16(mantissa << (exponent - 8)))

    return roundtrip_component(real), roundtrip_component(imag)
