"""Shared BFP compression and decompression reference model."""

import math
import os
import random


def compress_prb(iq, width=9, fs_offset=0):
    """Compress one PRB of IQ data."""
    assert len(iq) == 24

    # Get the MSB position (minimum shift value).
    msb = 15
    for d in iq:
        d = d + 2**16 if d < 0 else d
        bins = "{:016b}".format(d)
        for s in range(16):
            if s == 15 or bins[s] != bins[s + 1]:
                break
        msb = min(s, msb)

    # For small IQ values, limit the shift to the mantissa width.
    shift = min(16 - width, msb)
    exp = 15 - fs_offset - shift

    # Compress and round the IQ values. Saturate positive values to the
    # maximum signed mantissa value to prevent rounding overflow.
    iq = [math.floor(d * 2 ** (shift - 16 + width) + 0.5) for d in iq]
    iq = [min(d, 2 ** (width - 1) - 1) for d in iq]

    # Convert the IQ data into unsigned two's-complement form for packing.
    iq = [d + 2**width if d < 0 else d for d in iq]

    format_str = "{:0" + str(width) + "b}"
    bins = "".join(format_str.format(d) for d in iq)

    bytes = [exp]
    for i in range(0, len(bins), 8):
        bytes += [int(bins[i : i + 8], 2)]
    return bytes


def compress_section(iq, width=9, fs_offset=0):
    """Compress one section of IQ data."""
    assert len(iq) % 24 == 0

    bytes = []
    for i in range(0, len(iq), 24):
        bytes += compress_prb(iq[i : i + 24], width, fs_offset)
    return bytes


def decompress_prb(bytes, width=9, fs_offset=0):
    """Decompress one PRB of BFP data."""
    assert len(bytes) == width * 3 + 1

    exp = bytes[0]
    bins = "".join("{:08b}".format(d) for d in bytes[1:])
    iq = [int(bins[i : i + width], 2) for i in range(0, len(bins), width)]

    iq = [d if d <= 2 ** (width - 1) - 1 else d - 2**width for d in iq]
    iq = [math.floor(d * 2 ** (exp - width + fs_offset + 1) + 0.5) for d in iq]
    return iq


def decompress_section(bytes, width=9, fs_offset=0):
    """Decompress one section of BFP data."""
    num_bytes_per_prb = width * 3 + 1
    num_prb = len(bytes) // num_bytes_per_prb
    iq = []
    for i in range(0, num_prb * num_bytes_per_prb, num_bytes_per_prb):
        iq += decompress_prb(bytes[i : i + num_bytes_per_prb], width, fs_offset)
    return iq


def test_bfp():
    """Check the reference model's BFP round trip."""
    ud_iq_width = int(os.environ.get("UD_IQ_WIDTH", 9))
    num_prb = int(os.environ.get("NUM_PRB", 1000))

    iq_ref = [random.randint(-(2**15), 2**15 - 1) for _ in range(num_prb * 24)]
    bytes = compress_section(iq_ref, width=ud_iq_width)
    iq = decompress_section(bytes, width=ud_iq_width)

    assert len(bytes) == len(iq_ref) * (3 * ud_iq_width + 1) / 24
    assert len(iq_ref) == len(iq)
    err = [iq_ref[i] - iq[i] for i in range(num_prb * 24)]

    evm = sum(abs(e) for e in err) / sum(abs(e) for e in iq_ref)
    print(f"EVM = {evm * 100:.2f}%")
    assert evm < 0.015
