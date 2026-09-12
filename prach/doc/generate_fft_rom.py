"""Generate the checked-in PRACH FFT twiddle ROM files without MATLAB."""

from __future__ import annotations

import argparse
import math
from pathlib import Path


def generate_fft_roms(output_dir: Path, coefficient_width: int = 18) -> None:
    """Write the radix-3/radix-2 twiddle ROMs used by ``prach_fft``."""
    amplitude = (1 << (coefficient_width - 1)) - 2
    mask = (1 << coefficient_width) - 1
    for size in (3 * (1 << stage) for stage in range(1, 10)):
        values = []
        for index in range(size // 2):
            phase = 2.0 * math.pi * index / size
            real = round(amplitude * math.cos(phase)) & mask
            imag = round(-amplitude * math.sin(phase)) & mask
            values.append(f"{(imag << coefficient_width) | real:09X}")
        (output_dir / f"prach_fft_{size}.mem").write_text(
            "\n".join(values) + "\n", encoding="ascii"
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "output_dir",
        nargs="?",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "rtl",
    )
    args = parser.parse_args()
    generate_fft_roms(args.output_dir)


if __name__ == "__main__":
    main()
