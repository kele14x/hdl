"""Bit-exact reference model for the streaming PRACH 1536-point FFT RTL."""

from __future__ import annotations

from pathlib import Path

import numpy as np


def wrap18(values: np.ndarray | int) -> np.ndarray:
    """Wrap integers to a signed 18-bit two's-complement value."""
    values = np.asarray(values, dtype=np.int64)
    values &= 0x3FFFF
    return np.where(values >= (1 << 17), values - (1 << 18), values)


def saturate16(values: np.ndarray) -> np.ndarray:
    """Saturate 18-bit values to the signed 16-bit range."""
    values = np.asarray(values, dtype=np.int64)
    return np.clip(values, -(1 << 15), (1 << 15) - 1)


def _round_shift(product: np.ndarray, shift: int) -> np.ndarray:
    """type_cast TRUNC=shift, ROUND=1, SATURATE=0 on a 37-bit product."""
    round_up = ((product >> (shift - 1)) & 1) & (
        ((product >> shift) & 1) | ((product & ((1 << (shift - 1)) - 1)) != 0)
    )
    return (product >> shift) + round_up


def _cmult(ar, ai, tr, ti, shift):
    """cmult USE_3_MULT=0, ROUND=1, SATURATE=0, wrapped to 18 bits."""
    pr = ar * tr - ai * ti
    pi = ai * tr + ar * ti
    return wrap18(_round_shift(pr, shift)), wrap18(_round_shift(pi, shift))


def ditfft3_stage(xr, xi):
    """Stage 0: 3-point DIT via bf1 -> bf2 -> bf3 on blocks of 3."""
    n = xr.size
    assert n % 3 == 0
    out_r = np.empty(n, dtype=np.int64)
    out_i = np.empty(n, dtype=np.int64)
    for b in range(n // 3):
        x0r, x1r_, x2r = xr[3 * b], xr[3 * b + 1], xr[3 * b + 2]
        x0i, x1i, x2i = xi[3 * b], xi[3 * b + 1], xi[3 * b + 2]

        ar, ai = x0r, x0i
        br, bi = wrap18(x1r_ + x2r), wrap18(x1i + x2i)
        cr, ci = wrap18(x2r - x1r_), wrap18(x2i - x1i)

        pr, pi = wrap18(ar + br), wrap18(ai + bi)
        # op1(a, b) = (2a - b + 1) >> 1 with the low bit cleared, 19-bit result
        qr = wrap18((2 * ar - br + 1) >> 1)
        qi = wrap18((2 * ai - bi + 1) >> 1)
        # 0.8660j * C via the two DSPs: (-C_i * 56756 + 32768) >> 16
        rr = wrap18((ci * -56756 + 32768) >> 16)
        ri = wrap18((cr * 56756 + 32768) >> 16)

        out_r[3 * b + 0] = pr
        out_i[3 * b + 0] = pi
        out_r[3 * b + 1] = wrap18(qr + rr)
        out_i[3 * b + 1] = wrap18(qi + ri)
        out_r[3 * b + 2] = wrap18(qr - rr)
        out_i[3 * b + 2] = wrap18(qi - ri)
    return out_r, out_i


def _twiddle_rom(fft_size: int, rtl_dir: Path):
    entries = []
    with open(rtl_dir / f"prach_fft_{fft_size}.mem") as fh:
        for line in fh:
            word = int(line.strip(), 16)
            ti = (word >> 18) & 0x3FFFF
            tr = word & 0x3FFFF
            entries.append(
                (
                    tr - (1 << 18) if tr >= (1 << 17) else tr,
                    ti - (1 << 18) if ti >= (1 << 17) else ti,
                )
            )
    return np.asarray(entries, dtype=np.int64)


def ditfft2_stage(xr, xi, fft_size, scale, rom):
    """Radix-2 DIT stage: twiddle then butterfly, on blocks of fft_size."""
    n = xr.size
    half = fft_size // 2
    shift = 18 if scale else 17
    out_r = np.empty(n, dtype=np.int64)
    out_i = np.empty(n, dtype=np.int64)
    for b in range(n // fft_size):
        block_r = xr[b * fft_size : (b + 1) * fft_size]
        block_i = xi[b * fft_size : (b + 1) * fft_size]
        for k in range(half):
            # First-half sample is twiddled by ROM[0], second half by ROM[k].
            ar, ai = _cmult(block_r[k], block_i[k], rom[0, 0], rom[0, 1], shift)
            br, bi = _cmult(
                block_r[k + half], block_i[k + half], rom[k, 0], rom[k, 1], shift
            )
            out_r[b * fft_size + k] = wrap18(ar + br)
            out_i[b * fft_size + k] = wrap18(ai + bi)
            out_r[b * fft_size + k + half] = wrap18(ar - br)
            out_i[b * fft_size + k + half] = wrap18(ai - bi)
    return out_r, out_i


def prach_fft_fixed(input_r, input_i, rtl_dir: Path):
    """Run the RTL arithmetic on one 1536-sample block, natural order in/out."""
    fft_size = 1536
    r = np.asarray(input_r, dtype=np.int64).reshape(-1)
    i = np.asarray(input_i, dtype=np.int64).reshape(-1)
    assert r.size == fft_size and i.size == fft_size

    # Input register: 16-bit values sign-extended to 18 bits.
    r = wrap18(r)
    i = wrap18(i)

    r, i = ditfft3_stage(r, i)
    for stage in range(1, 10):
        size = 3 * (1 << stage)
        r, i = ditfft2_stage(
            r, i, size, scale=(stage % 2 == 1), rom=_twiddle_rom(size, rtl_dir)
        )

    return saturate16(r), saturate16(i)
