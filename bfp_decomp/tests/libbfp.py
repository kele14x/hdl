"""BFP compression and decompression reference model"""

import math
import os
import random


def compress_prb(iq, width=9, fs_offset=0):
    """Compress 1 PRB data."""
    assert len(iq) == 24

    # Get the MSB position (minimum shift value)
    msb = 15
    for d in iq:
        # Bin string
        d = d + 2**16 if d < 0 else d
        bins = "{:016b}".format(d)
        # Get the MSB position by search
        for s in range(16):
            if s == 15 or bins[s] != bins[s + 1]:
                break
        msb = min(s, msb)

    # For IQ that too small, shift too much is meaningless, we can limit the
    # the MSB value between [0, 16 - width]
    shift = min(16 - width, msb)

    # Get the exponent value from the final shift value, expect range is
    # [UD_WQ_WIDTH - 1, 15] when fs_offset is 0. Limit the max shift helps us
    # handle fs_offset easier
    exp = 15 - fs_offset - shift

    # Compress the IQ Bytes by shift and rounding,
    iq = [math.floor(d * 2 ** (shift - 16 + width) + 0.5) for d in iq]
    # Take care the rounding overflow
    iq = [min(d, 2**width - 1) for d in iq]

    # Convert the IQ data into "unsigned" format for proper processing
    iq = [d + 2**width if d < 0 else d for d in iq]

    # Serial into bit stream
    format_str = "{:0" + str(width) + "b}"
    bins = ""
    for d in iq:
        bins += format_str.format(d)

    # Byte list
    bytes = []
    bytes += [exp]
    for i in range(0, len(bins), 8):
        bytes += [int(bins[i : i + 8], 2)]
    return bytes


def compress_section(iq, width=9, fs_offset=0):
    """Compress 1 section data."""
    assert len(iq) % 24 == 0

    bytes = []
    for i in range(0, len(iq), 24):
        bytes += compress_prb(iq[i : i + 24], width, fs_offset)
    return bytes


def decompress_prb(bytes, width=9, fs_offset=0):
    """Decompress 1 PRB data."""
    assert len(bytes) == width * 3 + 1

    exp = bytes[0]
    # Bin string
    bins = ""
    for d in bytes[1:]:
        bins += "{:08b}".format(d)

    # Data list
    iq = []
    for i in range(0, len(bins), width):
        iq += [int(bins[i : i + width], 2)]

    # Decompress
    iq = [d if d <= 2 ** (width - 1) - 1 else d - 2**width for d in iq]
    iq = [math.floor(d * 2 ** (exp - width + fs_offset + 1) + 0.5) for d in iq]
    return iq


def decompress_section(bytes, width=9, fs_offset=0):
    """Decompress 1 section data."""
    num_bytes_per_prb = width * 3 + 1
    num_bytes = len(bytes)
    num_prb = math.floor(num_bytes / num_bytes_per_prb)
    iq = []
    for i in range(0, num_prb * num_bytes_per_prb, num_bytes_per_prb):
        iq += decompress_prb(bytes[i : i + num_bytes_per_prb], width, fs_offset)
    return iq


def test_bfp():
    # Test environment
    UD_IQ_WIDTH = int(os.environ.get("UD_WID_WIDTH", 9))
    NUM_PRB = int(os.environ.get("NUM_PRB", 1000))

    iq_ref = [random.randint(-(2**15), 2**15 - 1) for _ in range(NUM_PRB * 24)]
    bytes = compress_section(iq_ref)
    iq = decompress_section(bytes)

    assert len(bytes) == len(iq_ref) * (3 * UD_IQ_WIDTH + 1) / 24
    assert len(iq_ref) == len(iq)
    err = [iq_ref[i] - iq[i] for i in range(NUM_PRB * 24)]

    evm = sum([abs(e) for e in err]) / sum([abs(e) for e in iq_ref])
    print(f"EVM = {evm*100:.2f}%")
    assert evm < 0.015


if __name__ == "__main__":
    test_bfp()
