"""Shared BFP compression reference model."""

import math


def compress_prb(iq, width=9, fs_offset=0):
    """Compress one PRB of IQ data."""
    assert len(iq) == 24

    # Get the MSB position (minimum shift value).
    msb = 15
    for d in iq:
        d = d + 2**16 if d < 0 else d
        bins = f"{d:016b}"
        for s in range(16):
            if s == 15 or bins[s] != bins[s + 1]:
                break
        msb = min(s, msb)

    # For small IQ values, limit the shift to the mantissa width.
    shift = min(16 - width, msb)
    exp = max(0, 15 - fs_offset - shift)

    # Compress and round the IQ values. Saturate positive values to the
    # maximum signed mantissa value to prevent rounding overflow.
    iq = [math.floor(d * 2 ** (shift - 16 + width) + 0.5) for d in iq]
    iq = [min(d, 2 ** (width - 1) - 1) for d in iq]

    # Convert the IQ data into unsigned two's-complement form for packing.
    iq = [d + 2**width if d < 0 else d for d in iq]

    bins = "".join(f"{d:0{width}b}" for d in iq)

    packed_bytes = [exp]
    for i in range(0, len(bins), 8):
        packed_bytes.append(int(bins[i : i + 8], 2))
    return packed_bytes


def compress_section(iq, width=9, fs_offset=0):
    """Compress one section of IQ data."""
    assert len(iq) % 24 == 0

    packed_bytes = []
    for i in range(0, len(iq), 24):
        packed_bytes.extend(compress_prb(iq[i : i + 24], width, fs_offset))
    return packed_bytes
