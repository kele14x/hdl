"""Bit-exact arithmetic model for the current streaming FFT RTL."""

from __future__ import annotations

import math
from dataclasses import dataclass, field

import numpy as np


@dataclass(frozen=True)
class FftConfig:
    """Compile-time and run-time settings used by ``fft.sv``."""

    log_fft_size: int = 12
    data_width: int = 16
    fft_size: int = 4096
    inverse: bool = False
    bit_reversed_input: bool = True

    @property
    def num_stages(self) -> int:
        return (self.log_fft_size + 1) // 2

    @property
    def internal_width(self) -> int:
        return self.data_width + 2

    @property
    def scale_shift(self) -> int:
        # The five twiddle multipliers always contribute /32. At the maximum
        # run-time size, the otherwise unscaled sixth stage gets an explicit
        # divide-by-two for /64. Smaller sizes retain their existing /32 gain.
        full_size_shift = int(self.fft_size == (1 << self.log_fft_size))
        return self.num_stages - 1 + full_size_shift

    @property
    def scale_factor(self) -> int:
        return 1 << self.scale_shift

    def validate(self) -> None:
        if self.log_fft_size < 1:
            raise ValueError("log_fft_size must be positive")
        if self.fft_size not in (1024, 2048, 4096):
            raise ValueError("the RTL run-time interface supports 1024/2048/4096")
        if self.fft_size > 1 << self.log_fft_size:
            raise ValueError("run-time FFT size exceeds the compiled FFT size")


@dataclass
class QuantizationStats:
    """Counts of values that exceed the corresponding RTL storage width."""

    butterfly_wraps: int = 0
    twiddle_wraps: int = 0
    coarse_twiddle_wraps: int = 0
    output_saturations: int = 0
    stage_peak: list[int] = field(default_factory=list)


def _as_int64(values: np.ndarray | list[int] | int) -> np.ndarray:
    return np.asarray(values, dtype=np.int64)


def wrap_signed(
    values: np.ndarray | list[int] | int,
    width: int,
    stats: QuantizationStats | None = None,
    counter: str | None = None,
) -> np.ndarray:
    """Wrap integers to a two's-complement signed value of ``width`` bits."""

    values = _as_int64(values)
    minimum = -(1 << (width - 1))
    maximum = (1 << (width - 1)) - 1
    if stats is not None and counter is not None:
        count = int(np.count_nonzero((values < minimum) | (values > maximum)))
        setattr(stats, counter, getattr(stats, counter) + count)

    modulus = 1 << width
    sign = 1 << (width - 1)
    unsigned = values & (modulus - 1)
    return np.where(unsigned >= sign, unsigned - modulus, unsigned).astype(np.int64)


def saturate_signed(
    values: np.ndarray | list[int] | int,
    width: int,
    stats: QuantizationStats | None = None,
) -> np.ndarray:
    values = _as_int64(values)
    minimum = -(1 << (width - 1))
    maximum = (1 << (width - 1)) - 1
    if stats is not None:
        stats.output_saturations += int(
            np.count_nonzero((values < minimum) | (values > maximum))
        )
    return np.clip(values, minimum, maximum).astype(np.int64)


def round_convergent_shift1(values: np.ndarray | list[int] | int) -> np.ndarray:
    """Divide signed integers by two with ties rounded to an even integer."""

    values = _as_int64(values)
    quotient = values >> 1
    increment = (values & 1) & (quotient & 1)
    return quotient + increment


def bit_reverse_indices(size: int) -> np.ndarray:
    width = int(math.log2(size))
    if 1 << width != size:
        raise ValueError("size must be a power of two")
    return np.asarray(
        [int(f"{index:0{width}b}"[::-1], 2) for index in range(size)],
        dtype=np.int64,
    )


def _cmult_q15_shift16(
    ar: np.ndarray,
    ai: np.ndarray,
    br: np.ndarray,
    bi: np.ndarray,
    width: int,
    stats: QuantizationStats,
) -> tuple[np.ndarray, np.ndarray]:
    # Match cmult USE_3_MULT=0, ROUND=1, SHIFT=16 (round-to-nearest, ties-to-even).
    rounding = (1 << 15) - 1
    pr = ar * br - ai * bi
    pi = ai * br + ar * bi
    pr_full = pr + rounding + ((pr >> 16) & 1)
    pi_full = pi + rounding + ((pi >> 16) & 1)
    return (
        wrap_signed(pr_full >> 16, width, stats, "twiddle_wraps"),
        wrap_signed(pi_full >> 16, width, stats, "twiddle_wraps"),
    )


def _twiddle_coefficients(
    phase: np.ndarray, log_fft_size: int, inverse: bool
) -> tuple[np.ndarray, np.ndarray]:
    # Match the sized real-to-integer conversion in dds_lut_rom: round to the
    # nearest integer, with exact half-way values rounded away from zero.
    def round_real(values: np.ndarray) -> np.ndarray:
        return np.where(
            values >= 0.0, np.floor(values + 0.5), np.ceil(values - 0.5)
        ).astype(np.int64)

    amplitude = (1 << 15) - 2
    period = 1 << log_fft_size
    angle = 2.0 * math.pi * phase.astype(np.float64) / period
    real = round_real(amplitude * np.cos(angle))
    imag_sign = 1.0 if inverse else -1.0
    imag = round_real(imag_sign * amplitude * np.sin(angle))
    return real, imag


def _twiddle_stream(
    real: np.ndarray,
    imag: np.ndarray,
    log_fft_size: int,
    bypass: int,
    inverse: bool,
    width: int,
    stats: QuantizationStats,
) -> tuple[np.ndarray, np.ndarray]:
    if log_fft_size <= 2:
        return real.copy(), imag.copy()

    index = np.arange(real.size, dtype=np.int64)
    if bypass == 0b11:
        counter = np.zeros(real.size, dtype=np.int64)
    else:
        counter_width = log_fft_size if bypass == 0 else log_fft_size - 1
        counter = index & ((1 << counter_width) - 1)

    if log_fft_size % 2 == 0:
        msb = (counter >> (log_fft_size - 1)) & 1
        next_msb = (counter >> (log_fft_size - 2)) & 1
        quadrant = (next_msb << 1) | msb
        offset = counter & ((1 << (log_fft_size - 2)) - 1)
    else:
        quadrant = (counter >> (log_fft_size - 1)) & 1
        offset = counter & ((1 << (log_fft_size - 1)) - 1)

    phase = (quadrant * offset) & ((1 << log_fft_size) - 1)
    coeff_r, coeff_i = _twiddle_coefficients(phase, log_fft_size, inverse)
    return _cmult_q15_shift16(real, imag, coeff_r, coeff_i, width, stats)


def _butterfly_stream(
    real: np.ndarray,
    imag: np.ndarray,
    log_fft_size: int,
    width: int,
    scale: bool,
    stats: QuantizationStats,
) -> tuple[np.ndarray, np.ndarray]:
    block_size = 1 << log_fft_size
    half = block_size // 2
    if real.size % block_size:
        raise ValueError("stream length is not a multiple of the butterfly size")

    real_blocks = real.reshape(-1, block_size)
    imag_blocks = imag.reshape(-1, block_size)
    first_r, second_r = real_blocks[:, :half], real_blocks[:, half:]
    first_i, second_i = imag_blocks[:, :half], imag_blocks[:, half:]

    out_r = np.concatenate((first_r + second_r, first_r - second_r), axis=1)
    out_i = np.concatenate((first_i + second_i, first_i - second_i), axis=1)
    if scale:
        out_r = round_convergent_shift1(out_r)
        out_i = round_convergent_shift1(out_i)
    return (
        wrap_signed(out_r.reshape(-1), width, stats, "butterfly_wraps"),
        wrap_signed(out_i.reshape(-1), width, stats, "butterfly_wraps"),
    )


def _coarse_twiddle_stream(
    real: np.ndarray,
    imag: np.ndarray,
    log_fft_size: int,
    inverse: bool,
    width: int,
    stats: QuantizationStats,
) -> tuple[np.ndarray, np.ndarray]:
    index = np.arange(real.size, dtype=np.int64)
    counter = index & ((1 << log_fft_size) - 1)
    rotate = (counter >> (log_fft_size - 2)) == 0b11

    out_r = real.copy()
    out_i = imag.copy()
    if inverse:
        out_r[rotate] = -imag[rotate]
        out_i[rotate] = real[rotate]
    else:
        out_r[rotate] = imag[rotate]
        out_i[rotate] = -real[rotate]
    return (
        wrap_signed(out_r, width, stats, "coarse_twiddle_wraps"),
        wrap_signed(out_i, width, stats, "coarse_twiddle_wraps"),
    )


def _stage_bypass(stage: int, config: FftConfig) -> int:
    active_log_size = int(math.log2(config.fft_size))
    if config.bit_reversed_input:
        active_butterflies = max(0, min(2, active_log_size - 2 * stage))
        return {0: 0b11, 1: 0b10, 2: 0b00}[active_butterflies]

    first_active = config.log_fft_size - active_log_size
    active_butterflies = max(0, min(2, 2 - first_active + 2 * stage))
    return {0: 0b11, 1: 0b01, 2: 0b00}[active_butterflies]


def _stage_log_size(stage: int, config: FftConfig) -> int:
    if config.bit_reversed_input:
        return min(2 * stage + 2, config.log_fft_size)
    return min(2 * (config.num_stages - stage), config.log_fft_size)


def fft_fixed(
    input_real: np.ndarray | list[int],
    input_imag: np.ndarray | list[int],
    config: FftConfig | None = None,
) -> tuple[np.ndarray, np.ndarray, QuantizationStats]:
    """Run the current RTL's arithmetic and stage ordering on one channel."""

    config = config or FftConfig()
    config.validate()
    real = _as_int64(input_real).reshape(-1)
    imag = _as_int64(input_imag).reshape(-1)
    if real.size != config.fft_size or imag.size != config.fft_size:
        raise ValueError("input vectors must match fft_size")

    stats = QuantizationStats()
    real = wrap_signed(real, config.data_width)
    imag = wrap_signed(imag, config.data_width)
    width = config.internal_width

    for stage in range(config.num_stages):
        log_size = _stage_log_size(stage, config)
        bypass = _stage_bypass(stage, config)
        has_second_butterfly = log_size % 2 == 0
        first_log_size = log_size - 1 if has_second_butterfly else log_size
        scale_stage = log_size <= 2 and config.fft_size == (1 << config.log_fft_size)

        if config.bit_reversed_input:
            real, imag = _twiddle_stream(
                real, imag, log_size, bypass, config.inverse, width, stats
            )
            if not (bypass & 0b01):
                real, imag = _butterfly_stream(
                    real, imag, first_log_size, width, False, stats
                )
            if has_second_butterfly and not (bypass & 0b10):
                real, imag = _coarse_twiddle_stream(
                    real, imag, log_size, config.inverse, width, stats
                )
                real, imag = _butterfly_stream(
                    real, imag, log_size, width, scale_stage, stats
                )
        else:
            if has_second_butterfly and not (bypass & 0b01):
                real, imag = _butterfly_stream(
                    real, imag, log_size, width, False, stats
                )
                real, imag = _coarse_twiddle_stream(
                    real, imag, log_size, config.inverse, width, stats
                )
            if not (bypass & 0b10):
                real, imag = _butterfly_stream(
                    real, imag, first_log_size, width, scale_stage, stats
                )
            real, imag = _twiddle_stream(
                real, imag, log_size, bypass, config.inverse, width, stats
            )

        stats.stage_peak.append(
            max(int(np.max(np.abs(real))), int(np.max(np.abs(imag))))
        )

    return (
        saturate_signed(real, config.data_width, stats),
        saturate_signed(imag, config.data_width, stats),
        stats,
    )
