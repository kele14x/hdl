"""Bit-accurate helpers for the PRACH half-band decimation chain."""

from __future__ import annotations

from collections.abc import Sequence

HB2_COEFFICIENTS = (
    (-4105, 36873),
    (-4134, 36901),
    (-4249, 37013),
    (-4750, 37456),
)
HB4_COEFFICIENTS = (-669, 3099, -9939, 40231)
SIDEBAND_FIELDS = ("sf", "sl", "sy", "chn", "dv", "last")


def signed16(value: int) -> int:
    """Interpret the low 16 bits of *value* as a signed integer."""
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value


def unsigned16(value: int) -> int:
    """Return the 16-bit two's-complement representation of *value*."""
    return value & 0xFFFF


def _sample(values: Sequence[int], index: int) -> int:
    if 0 <= index < len(values):
        return values[index]
    return 0


def _rounded_filter_output(total: int) -> int:
    # The RTL adds 2**16, then selects dq[32:17] without saturation.
    return signed16((total + (1 << 16)) >> 17)


def hb2_sample(
    dp1: Sequence[int],
    dp2: Sequence[int],
    index: int,
    delay_base: int,
    coefficients: Sequence[int],
) -> int:
    """Return the HB2 result associated with sideband sample *index*."""
    a_pair = _sample(dp2, index + delay_base) + _sample(dp2, index - 2 * delay_base)
    b_pair = _sample(dp2, index) + _sample(dp2, index - delay_base)
    total = (
        a_pair * coefficients[0]
        + b_pair * coefficients[1]
        + (_sample(dp1, index) << 16)
    )
    return _rounded_filter_output(total)


def hb4_sample(
    dp1: Sequence[int],
    dp2: Sequence[int],
    index: int,
    delay_base: int,
    coefficients: Sequence[int] = HB4_COEFFICIENTS,
) -> int:
    """Return the HB4 result associated with sideband sample *index*."""
    pairs = (
        _sample(dp2, index + 3 * delay_base) + _sample(dp2, index - 4 * delay_base),
        _sample(dp2, index + 2 * delay_base) + _sample(dp2, index - 3 * delay_base),
        _sample(dp2, index + delay_base) + _sample(dp2, index - 2 * delay_base),
        _sample(dp2, index) + _sample(dp2, index - delay_base),
    )
    total = sum(pair * coefficient for pair, coefficient in zip(pairs, coefficients))
    total += _sample(dp1, index) << 16
    return _rounded_filter_output(total)


def shift_sideband(
    sideband: dict[str, list[int]], latency: int
) -> dict[str, list[int]]:
    """Apply the fixed-cycle sideband delay used by the RTL blocks."""
    length = len(sideband["dv"])
    shifted = {field: [0] * length for field in SIDEBAND_FIELDS}
    for field in SIDEBAND_FIELDS:
        for source_index in range(length - latency):
            shifted[field][source_index + latency] = sideband[field][source_index]
    return shifted


def reshape(
    dp1: Sequence[int],
    dp2: Sequence[int],
    sideband: dict[str, list[int]],
    size: int,
) -> tuple[list[int], list[int], dict[str, list[int]]]:
    """Cycle-accurate model of ``prach_reshape``."""
    length = len(dp1)
    half_size = size // 2
    latency = half_size + 1
    bit_index = half_size.bit_length() - 1
    dout1 = [0] * length
    dout2 = [0] * length

    for index in range(length - latency):
        output_index = index + latency
        swap_now = (sideband["chn"][index] >> bit_index) & 1
        future_index = index + half_size
        swap_future = (
            (sideband["chn"][future_index] >> bit_index) & 1
            if future_index < length
            else 0
        )

        dout1[output_index] = (
            _sample(dp2, index - half_size) if swap_now else _sample(dp1, index)
        )
        dout2[output_index] = (
            _sample(dp1, future_index) if swap_future else _sample(dp2, index)
        )

    return dout1, dout2, shift_sideband(sideband, latency)


def halfband2(
    dp1: Sequence[int],
    dp2: Sequence[int],
    sideband: dict[str, list[int]],
    delay_base: int,
    coefficients: Sequence[int],
) -> tuple[list[int], dict[str, list[int]]]:
    """Cycle-accurate valid-output model of ``prach_hb2``."""
    length = len(dp1)
    latency = delay_base + 8
    output = [0] * length
    for index in range(length - latency):
        output[index + latency] = hb2_sample(dp1, dp2, index, delay_base, coefficients)
    return output, shift_sideband(sideband, latency)


def halfband4(
    dp1: Sequence[int],
    dp2: Sequence[int],
    sideband: dict[str, list[int]],
    delay_base: int,
) -> tuple[list[int], dict[str, list[int]]]:
    """Cycle-accurate valid-output model of ``prach_hb4``."""
    length = len(dp1)
    latency = 3 * delay_base + 10
    output = [0] * length
    for index in range(length - latency):
        output[index + latency] = hb4_sample(dp1, dp2, index, delay_base)
    return output, shift_sideband(sideband, latency)


def model_decimation_chain(
    mixer_real: Sequence[int],
    mixer_imag: Sequence[int],
    sideband: dict[str, list[int]],
    trace: dict[str, tuple[list[int], list[int], dict[str, list[int]]]] | None = None,
) -> tuple[list[int], list[int], dict[str, list[int]]]:
    """Model the six reshape/HB stages and the final IQ reshape in ``prach_ddc``."""
    dp1 = list(mixer_real)
    dp2 = list(mixer_imag)
    metadata = {field: list(sideband[field]) for field in SIDEBAND_FIELDS}

    for stage in range(6):
        delay_base = 8 << stage
        dp1, dp2, metadata = reshape(dp1, dp2, metadata, delay_base)
        if trace is not None and stage >= 4:
            trace[f"hb{stage}_in"] = (dp1, dp2, metadata)
        if stage < 4:
            dp1, metadata = halfband2(
                dp1,
                dp2,
                metadata,
                delay_base,
                HB2_COEFFICIENTS[stage],
            )
        else:
            dp1, metadata = halfband4(dp1, dp2, metadata, delay_base)
            source_valid = metadata["dv"]
            dp1 = [sample if valid else 0 for sample, valid in zip(dp1, source_valid)]
            for field in SIDEBAND_FIELDS:
                metadata[field] = [
                    value if valid else 0
                    for value, valid in zip(metadata[field], source_valid)
                ]
            if stage == 4:
                # D128 consumes both 128-clock phases to form its taps, then
                # retains chn 0..7 as the decimated stream for D256.
                metadata["dv"] = [
                    valid and channel < 8
                    for valid, channel in zip(metadata["dv"], metadata["chn"])
                ]
        if trace is not None and stage >= 4:
            trace[f"hb{stage}_out"] = (dp1, [0] * len(dp1), metadata)
        dp2 = [0] * len(dp1)

    return reshape(dp1, dp2, metadata, 8)
