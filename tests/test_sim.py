import pytest

from hdl_tools.sim import assert_x_or_zero, quote_string_parameters


def test_quotes_strings_only_for_raw_simulators():
    params = {"WRITE_MODE": "WRITE_FIRST", "DEPTH": 8}

    quoted = {"WRITE_MODE": '"WRITE_FIRST"', "DEPTH": 8}
    assert quote_string_parameters("verilator", params) == quoted
    assert quote_string_parameters("icarus", params) == quoted
    assert quote_string_parameters("Verilator", params) == quoted

    assert quote_string_parameters("questa", params) == params
    assert quote_string_parameters("modelsim", params) == params


class _Value:
    def __init__(self, bits):
        self._bits = bits

    @property
    def is_resolvable(self):
        return self._bits is not None

    def __int__(self):
        if self._bits is None:
            raise ValueError("unresolvable")
        return self._bits


def test_assert_x_or_zero_matches_simulator_state_model():
    assert_x_or_zero("verilator", _Value(0))
    assert_x_or_zero("icarus", _Value(None))
    assert_x_or_zero("questa", _Value(None))

    with pytest.raises(AssertionError):
        assert_x_or_zero("verilator", _Value(5))
    with pytest.raises(AssertionError):
        assert_x_or_zero("icarus", _Value(0))
