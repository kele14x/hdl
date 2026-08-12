#!/usr/bin/env python3
"""Fast unit tests for the PDXCH floating/fixed-point reference model."""

from __future__ import annotations

import numpy as np
from pdxch_reference import (
    best_body_alignment,
    fdv_lte20_readout_stream,
    pdxch_lte20_reference,
    pdxch_nr100m_reference,
    qpsk_bfp9_resource_elements,
)

from fft.tests.fft_fixed_model import bit_reverse_indices


def test_float_reference_is_within_five_lsb_rms_of_fixed_model():
    result = pdxch_nr100m_reference(cc=0, antenna=0, symbol=1)
    error = result.fixed_time_domain - result.time_domain

    assert result.time_domain.shape == (4096,)
    assert np.sqrt(np.mean(np.abs(error) ** 2)) < 5


def test_alignment_reports_signed_sample_offset():
    reference = np.arange(32) + 1j * np.arange(32)[::-1]
    captured = np.concatenate((np.asarray([99 + 99j]), reference))

    offset, error = best_body_alignment(captured, reference, max_offset=1)

    assert offset == 1
    assert np.array_equal(error, np.zeros_like(error))


def test_lte20_fdv_mapping_inserts_one_dc_null():
    resource_elements = qpsk_bfp9_resource_elements(
        num_prb=100, cc=0, antenna=0, symbol=0
    )
    stream = fdv_lte20_readout_stream(resource_elements)
    natural_frequency = stream[bit_reverse_indices(2048)]

    assert natural_frequency[0] == 0
    assert np.count_nonzero(natural_frequency) == 1200
    assert np.array_equal(natural_frequency[1:601], resource_elements[600:])
    assert np.array_equal(natural_frequency[-600:], resource_elements[:600])
    assert np.count_nonzero(natural_frequency[601:-600]) == 0


def test_lte20_float_reference_is_within_five_lsb_rms_of_fixed_model():
    result = pdxch_lte20_reference(cc=0, antenna=0, symbol=1)
    error = result.fixed_time_domain - result.time_domain

    assert result.time_domain.shape == (2048,)
    assert np.sqrt(np.mean(np.abs(error) ** 2)) < 5
