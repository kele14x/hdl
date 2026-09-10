"""Deterministic NumPy PRACH waveform and packed-I/Q file helpers."""

from __future__ import annotations

from pathlib import Path

import numpy as np

DEFAULT_WAVEFORM_PATH = (
    Path(__file__).resolve().parent.parent / "doc" / "tb_prach_top_input.txt"
)


def generate_lte_f0_iq(
    *, root: int = 129, amplitude: float = 0.8
) -> tuple[np.ndarray, np.ndarray]:
    """Generate a quantized LTE-F0-shaped waveform at 30.72 Msps.

    The 839-point Zadoff-Chu sequence is placed in the lowest six-RB PRACH
    occasion of a 20 MHz LTE carrier.  On the 1.25 kHz PRACH grid that
    864-RE occasion starts at -7200: 13 guard REs, 839 active REs, then
    12 guard REs.  A 24,576-point IFFT is followed by the LTE F0 cyclic
    prefix and guard interval.  The root and cyclic-shift selection are
    generic; callers needing cell-specific LTE conformance should derive
    them from the configured PRACH root sequence.
    """
    n_zc = 839
    n_fft = 24_576
    cp_length = 3_168
    guard_length = 2_976

    if np.gcd(root, n_zc) != 1:
        raise ValueError(f"root={root} is not coprime with N_ZC={n_zc}")
    if not 0 < amplitude <= 1:
        raise ValueError("amplitude must be in the interval (0, 1]")

    n = np.arange(n_zc)
    zadoff_chu = np.exp(-1j * np.pi * root * n * (n + 1) / n_zc)

    section_first_re = -7_200
    left_guard_re = 13
    centered_grid = np.zeros(n_fft, dtype=np.complex128)
    first_bin = n_fft // 2 + section_first_re + left_guard_re
    centered_grid[first_bin : first_bin + n_zc] = zadoff_chu
    sequence = np.fft.ifft(np.fft.ifftshift(centered_grid))

    scale = amplitude * ((1 << 15) - 1) / np.max(np.abs(sequence))
    sequence *= scale
    real = np.rint(sequence.real).astype(np.int16)
    imag = np.rint(sequence.imag).astype(np.int16)

    return (
        np.concatenate((real[-cp_length:], real, np.zeros(guard_length, np.int16))),
        np.concatenate((imag[-cp_length:], imag, np.zeros(guard_length, np.int16))),
    )


def pack_iq(real: np.ndarray, imag: np.ndarray) -> np.ndarray:
    """Pack signed 16-bit I/Q samples as ``{imag, real}`` words."""
    real_u16 = np.asarray(real, dtype=np.int16).view(np.uint16).astype(np.uint32)
    imag_u16 = np.asarray(imag, dtype=np.int16).view(np.uint16).astype(np.uint32)
    return (imag_u16 << 16) | real_u16


def write_iq_hex(path: Path, words: np.ndarray) -> None:
    """Write packed I/Q words in the format consumed by the RTL testbench."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(f"{int(word):08X}\n" for word in words), encoding="ascii")


def read_iq_hex(path: Path = DEFAULT_WAVEFORM_PATH) -> np.ndarray:
    """Read packed I/Q words from a generated text vector."""
    words = np.fromiter(
        (int(line, 16) for line in path.read_text(encoding="ascii").split()),
        dtype=np.uint32,
    )
    if words.size != 30_720:
        raise ValueError(f"expected 30720 F0 samples, got {words.size}")
    return words


def generate_waveform_file(path: Path = DEFAULT_WAVEFORM_PATH) -> None:
    """Generate the checked-in shared LTE F0 input vector."""
    real, imag = generate_lte_f0_iq()
    write_iq_hex(path, pack_iq(real, imag))


if __name__ == "__main__":
    generate_waveform_file()
